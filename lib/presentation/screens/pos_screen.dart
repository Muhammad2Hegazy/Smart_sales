import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/models/cart_item.dart';
import '../../core/models/item.dart';
import '../../core/models/low_stock_warning.dart';
import '../../core/utils/invoice_printer.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_event.dart';
import '../blocs/cart/cart_state.dart';
import '../blocs/sales/sales_bloc.dart';
import '../blocs/financial/financial_bloc.dart';
import '../blocs/product/product_bloc.dart';
import '../blocs/product/product_event.dart';
import '../../core/services/payment_service.dart';
import '../../core/utils/tax_settings_helper.dart';
import '../../core/database/database_helper.dart';
import 'pos/widgets/pos_table_menu.dart';
import 'pos/widgets/pos_selected_tables.dart';
import 'pos/widgets/pos_categories_menu.dart';
import 'pos/widgets/pos_subcategories_menu.dart';
import 'pos/widgets/pos_items_grid.dart';
import 'pos/widgets/pos_cart_items_list.dart';
import 'pos/widgets/pos_cart_footer.dart';
import 'pos/widgets/pos_search_field.dart';

class POSScreen extends StatelessWidget {
  const POSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No AppBar here - it's handled by InvoicesTabs
    return const _POSContent();
  }
}

class _POSContent extends StatefulWidget {
  const _POSContent();

  @override
  State<_POSContent> createState() => _POSContentState();
}

class _POSContentState extends State<_POSContent> {
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String _searchQuery = '';
  List<String> _selectedTableNumbers = [];
  String? _activeTableNumber; // The currently active table for adding items
  final Map<String, int> _tableOrderNumbers = {}; // Map of table number to order number
  final Map<String, List<CartItem>> _tableCarts = {}; // Map of table number to cart items
  final Map<String, double> _tableDiscounts = {}; // Map of table number to discount percentage
  bool _allowPrinting = false;

  @override
  void initState() {
    super.initState();
    // Load product data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductBloc>().add(const LoadProducts());
    });
  }

  /// Load pending invoice for a specific table
  Future<void> _loadPendingInvoiceForTable(String tableNumber) async {
    try {
      final dbHelper = DatabaseHelper();
      final pendingInvoice = await dbHelper.getPendingInvoiceByTableNumbers([tableNumber]);
      
      if (!mounted) return;
      
      if (pendingInvoice != null) {
        // Restore cart items for this table
        final items = (pendingInvoice['items'] as List)
            .map((item) => CartItem(
                  id: item['id'] as String,
                  name: item['name'] as String,
                  price: (item['price'] as num).toDouble(),
                  quantity: item['quantity'] as int,
                ))
            .toList();
        
        setState(() {
          _tableCarts[tableNumber] = items;
          
          // Restore order number for this table
          if (pendingInvoice['table_order_numbers'] != null) {
            final orderNumbersMap = Map<String, int>.from(
              pendingInvoice['table_order_numbers'] as Map,
            );
            if (orderNumbersMap.containsKey(tableNumber)) {
              _tableOrderNumbers[tableNumber] = orderNumbersMap[tableNumber]!;
            }
          }
          
          // Restore discount for this table
          _tableDiscounts[tableNumber] = pendingInvoice['discount_percentage'] as double;
        });
        
        debugPrint('Loaded pending invoice for table $tableNumber: ${items.length} items');
      } else {
        // Initialize empty cart for new table (only if not already set or empty)
        if (!_tableCarts.containsKey(tableNumber) || _tableCarts[tableNumber]!.isEmpty) {
          setState(() {
            _tableCarts[tableNumber] = [];
            _tableDiscounts[tableNumber] = 0.0;
          });
          debugPrint('No pending invoice found for table $tableNumber, initialized empty cart');
        }
      }
    } catch (e) {
      debugPrint('Error loading pending invoice for table $tableNumber: $e');
      setState(() {
        _tableCarts[tableNumber] = [];
        _tableDiscounts[tableNumber] = 0.0;
      });
    }
  }
  
  /// Load pending invoices for all selected tables
  Future<void> _loadPendingInvoicesForTables(List<String> tableNumbers) async {
    for (final tableNumber in tableNumbers) {
      await _loadPendingInvoiceForTable(tableNumber);
    }
    _updateDisplayCart();
  }
  
  /// Update the display cart to show items from the active table only
  void _updateDisplayCart() {
    if (_activeTableNumber == null) {
      context.read<CartBloc>().add(const ClearCart());
      return;
    }
    
    // Get items from active table only
    final activeTableItems = _tableCarts[_activeTableNumber] ?? [];
    
    // Update the cart bloc with active table's items
    context.read<CartBloc>().add(const ClearCart());
    for (final item in activeTableItems) {
      for (int i = 0; i < item.quantity; i++) {
        context.read<CartBloc>().add(AddItemToCart(item.copyWith(quantity: 1)));
      }
    }
  }
  
  /// Get discount percentage for the active table
  double get _displayDiscountPercentage {
    if (_activeTableNumber == null) return 0.0;
    return _tableDiscounts[_activeTableNumber] ?? 0.0;
  }
  
  /// Check if two item lists are equal
  bool _areItemsEqual(List<CartItem> list1, List<CartItem> list2) {
    if (list1.length != list2.length) return false;
    
    final map1 = {for (var item in list1) item.id: item};
    final map2 = {for (var item in list2) item.id: item};
    
    if (map1.length != map2.length) return false;
    
    for (final entry in map1.entries) {
      final item2 = map2[entry.key];
      if (item2 == null || 
          item2.quantity != entry.value.quantity ||
          item2.price != entry.value.price ||
          item2.name != entry.value.name) {
        return false;
      }
    }
    
    return true;
  }

  /// Helper method to check if any selected table is a regular table (not takeaway/delivery/hospitality)
  bool _hasRegularTable() {
    return _selectedTableNumbers.any((table) => 
      table != 'takeaway' && 
      table != 'delivery' && 
      table != 'hospitality' &&
      int.tryParse(table) != null
    );
  }

  /// Helper method to check if any selected table is delivery
  bool _hasDeliveryTable() {
    return _selectedTableNumbers.contains('delivery');
  }

  /// Helper method to check if any selected table is hospitality
  bool _hasHospitalityTable() {
    return _selectedTableNumbers.contains('hospitality');
  }

  /// Helper method to get table number string for display/payment
  String? _getTableNumberString() {
    if (_selectedTableNumbers.isEmpty) return null;
    if (_selectedTableNumbers.length == 1) return _selectedTableNumbers.first;
    return _selectedTableNumbers.join(', ');
  }

  /// Save pending invoice for a specific table
  Future<void> _savePendingInvoiceForTable(String tableNumber) async {
    try {
      final dbHelper = DatabaseHelper();
      final tableItems = _tableCarts[tableNumber] ?? [];
      
      if (tableItems.isEmpty) {
        // Delete pending invoice if cart is empty
        await dbHelper.deletePendingInvoiceByTableNumbers([tableNumber]);
        return;
      }
      
      final items = tableItems.map((item) => {
        'id': item.id,
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
      }).toList();
      
      final tableOrderNumbers = <String, int>{};
      if (_tableOrderNumbers.containsKey(tableNumber)) {
        tableOrderNumbers[tableNumber] = _tableOrderNumbers[tableNumber]!;
      }
      
      await dbHelper.savePendingInvoice(
        tableNumbers: [tableNumber],
        items: items,
        tableOrderNumbers: tableOrderNumbers,
        discountPercentage: _tableDiscounts[tableNumber] ?? 0.0,
        discountAmount: 0.0,
        serviceCharge: 0.0,
        deliveryTax: 0.0,
        hospitalityTax: 0.0,
      );
    } catch (e) {
      debugPrint('Error saving pending invoice for table $tableNumber: $e');
    }
  }
  
  /// Save pending invoices for all selected tables
  Future<void> _savePendingInvoices() async {
    for (final tableNumber in _selectedTableNumbers) {
      await _savePendingInvoiceForTable(tableNumber);
    }
  }
  
  /// Generate order number for a table if it doesn't have one
  Future<void> _ensureOrderNumberForTable(String tableNumber) async {
    if (_tableOrderNumbers.containsKey(tableNumber)) return;
    
    final dbHelper = DatabaseHelper();
    final nextOrderNumber = await dbHelper.getNextOrderNumber();
    
    setState(() {
      _tableOrderNumbers[tableNumber] = nextOrderNumber;
    });
    
    _savePendingInvoiceForTable(tableNumber);
  }

  void _handleTableRemoved(String tableNumber) async {
    final tableItems = _tableCarts[tableNumber] ?? [];
    if (tableItems.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot remove table with items in cart. Please clear cart first or complete payment.'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final newTables = List<String>.from(_selectedTableNumbers)..remove(tableNumber);
    await _savePendingInvoices();

    setState(() {
      _selectedTableNumbers = newTables;
      if (newTables.isEmpty) {
        _activeTableNumber = null;
        _selectedCategoryId = null;
        _selectedSubCategoryId = null;
        context.read<CartBloc>().add(const ClearCart());
      } else {
        _activeTableNumber = newTables.last;
        _loadPendingInvoicesForTables(newTables);
      }
    });
  }

  Future<void> _addItemToCart(BuildContext context, Item item) async {
    if (_selectedTableNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.selectTable} to start an order'),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_activeTableNumber == null) return;

    setState(() {
      final tableItems = _tableCarts[_activeTableNumber] ?? [];
      final existingIndex = tableItems.indexWhere((cartItem) => cartItem.id == item.id);

      if (existingIndex != -1) {
        tableItems[existingIndex] = CartItem(
          id: tableItems[existingIndex].id,
          name: tableItems[existingIndex].name,
          price: tableItems[existingIndex].price,
          quantity: tableItems[existingIndex].quantity + 1,
        );
      } else {
        tableItems.add(CartItem(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: 1,
        ));
      }
      _tableCarts[_activeTableNumber!] = tableItems;
    });

    _updateDisplayCart();
    await _savePendingInvoiceForTable(_activeTableNumber!);
  }

  Widget _buildNoTableSelectedPlaceholder(AppLocalizations l10n) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant_outlined,
              size: 96,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.selectTable,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please select a table to start an order',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return BlocListener<CartBloc, CartState>(
      listener: (context, cartState) {
        if (_activeTableNumber != null && mounted) {
          final Map<String, CartItem> itemsMap = {};
          for (final item in cartState.items) {
            if (itemsMap.containsKey(item.id)) {
              final existing = itemsMap[item.id]!;
              itemsMap[item.id] = CartItem(
                id: existing.id,
                name: existing.name,
                price: existing.price,
                quantity: existing.quantity + item.quantity,
              );
            } else {
              itemsMap[item.id] = item;
            }
          }
          
          final updatedItems = itemsMap.values.toList();
          final currentItems = _tableCarts[_activeTableNumber!] ?? [];
          if (!_areItemsEqual(currentItems, updatedItems)) {
            setState(() {
              _tableCarts[_activeTableNumber!] = updatedItems;
            });
            _savePendingInvoiceForTable(_activeTableNumber!);
          }
        }
      },
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          return Row(
            children: [
              // Table Selection Sidebar (Compact)
              POSTableMenu(
                selectedTableNumbers: _selectedTableNumbers,
                onTableSelected: (tableNumbers) async {
                  final previousTables = List<String>.from(_selectedTableNumbers);
                  final isTableRemoved = tableNumbers.length < previousTables.length;
                  
                  if (isTableRemoved) {
                    await _savePendingInvoices();
                  }
                  
                  setState(() {
                    _selectedTableNumbers = tableNumbers;
                    if (tableNumbers.isNotEmpty) {
                      _activeTableNumber = tableNumbers.last;
                    } else {
                      _activeTableNumber = null;
                      _selectedCategoryId = null;
                      _selectedSubCategoryId = null;
                      context.read<CartBloc>().add(const ClearCart());
                    }
                  });

                  if (tableNumbers.isNotEmpty && !isTableRemoved) {
                    for (final tableNumber in tableNumbers) {
                      await _loadPendingInvoiceForTable(tableNumber);
                      if (!_tableOrderNumbers.containsKey(tableNumber)) {
                        await _ensureOrderNumberForTable(tableNumber);
                      }
                    }
                    if (mounted) {
                      _updateDisplayCart();
                    }
                  }
                },
              ),

              // Main Area
              Expanded(
                child: Column(
                  children: [
                    // Top Bar
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: POSSearchField(
                                  onChanged: (value) => setState(() => _searchQuery = value),
                                ),
                              ),
                              if (_selectedTableNumbers.isNotEmpty) ...[
                                const SizedBox(width: AppSpacing.md),
                                POSSelectedTables(
                                  selectedTableNumbers: _selectedTableNumbers,
                                  activeTableNumber: _activeTableNumber,
                                  tableItemCounts: Map.fromEntries(
                                    _selectedTableNumbers.map((tableNumber) {
                                      final items = _tableCarts[tableNumber] ?? [];
                                      final totalCount = items.fold(0, (sum, item) => sum + item.quantity);
                                      return MapEntry(tableNumber, totalCount);
                                    }),
                                  ),
                                  onTableSelected: (tableNumber) {
                                    setState(() => _activeTableNumber = tableNumber);
                                    _updateDisplayCart();
                                  },
                                  onTableRemoved: _handleTableRemoved,
                                ),
                              ],
                            ],
                          ),
                          if (_selectedTableNumbers.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            POSCategoriesMenu(
                              selectedCategoryId: _selectedCategoryId,
                              onCategorySelected: (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                  _selectedSubCategoryId = null;
                                });
                              },
                            ),
                            if (_selectedCategoryId != null)
                              POSSubCategoriesMenu(
                                selectedCategoryId: _selectedCategoryId,
                                selectedSubCategoryId: _selectedSubCategoryId,
                                onSubCategorySelected: (value) {
                                  setState(() => _selectedSubCategoryId = value);
                                },
                              ),
                          ],
                        ],
                      ),
                    ),

                    // Items Grid
                    Expanded(
                      child: _selectedTableNumbers.isEmpty
                        ? _buildNoTableSelectedPlaceholder(l10n)
                        : POSItemsGrid(
                            selectedCategoryId: _selectedCategoryId,
                            selectedSubCategoryId: _selectedSubCategoryId,
                            searchQuery: _searchQuery,
                            onItemTap: (item) {
                              _addItemToCart(context, item);
                              _savePendingInvoices();
                            },
                          ),
                    ),
                  ],
                ),
              ),

              // Cart Sidebar
              if (cartState.items.isNotEmpty)
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 10,
                        offset: const Offset(-2, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        color: AppColors.primary,
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${l10n.cart} (${cartState.itemCount})',
                              style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: POSCartItemsList()),
                      POSCartFooter(
                        allowPrinting: _allowPrinting,
                        discountPercentage: _displayDiscountPercentage,
                        onPrintingChanged: (value) => setState(() => _allowPrinting = value),
                        onDiscountChanged: (value) async {
                          if (_activeTableNumber != null) {
                            setState(() => _tableDiscounts[_activeTableNumber!] = value);
                            await _savePendingInvoiceForTable(_activeTableNumber!);
                          }
                        },
                        onPrintCustomerInvoice: () => _printCustomerInvoice(context, cartState, l10n),
                        onPrintKitchenInvoice: () => _printKitchenInvoice(context, cartState, l10n),
                        onProcessPayment: () => _completePayment(context, 'cash', l10n),
                        onClearCart: () async {
                          if (_activeTableNumber != null) {
                            setState(() {
                              _tableCarts[_activeTableNumber!] = [];
                              _tableDiscounts[_activeTableNumber!] = 0.0;
                            });
                            await _savePendingInvoiceForTable(_activeTableNumber!);
                          }
                          if (context.mounted) {
                            context.read<CartBloc>().add(const ClearCart());
                          }
                        },
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Payment and printing methods (Keep existing ones)
  Future<void> _printCustomerInvoice(
    BuildContext context,
    CartState cartState,
    AppLocalizations l10n,
  ) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preparing print...'),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      
      final subtotal = cartState.total;
      final discountAmount = subtotal * (_displayDiscountPercentage / 100);
      final finalTotal = subtotal - discountAmount;
      
      final serviceChargeRate = await TaxSettingsHelper.loadServiceChargeRate();
      final serviceCharge = _hasRegularTable() ? finalTotal * serviceChargeRate : 0.0;
      
      final deliveryTaxRate = await TaxSettingsHelper.loadDeliveryTaxRate();
      final deliveryTax = _hasDeliveryTable() ? finalTotal * deliveryTaxRate : 0.0;
      
      final hospitalityTaxRate = await TaxSettingsHelper.loadHospitalityTaxRate();
      final hospitalityDiscount = _hasHospitalityTable() ? subtotal * hospitalityTaxRate : 0.0;
      
      final totalDiscountAmount = discountAmount + hospitalityDiscount;
      
      final dbHelper = DatabaseHelper();
      final orderNumber = cartState.orderNumber ?? await dbHelper.getNextOrderNumber();
      final invoiceNumber = orderNumber;
      
      await InvoicePrinter.printCustomerInvoice(
        items: cartState.items,
        total: finalTotal + serviceCharge + deliveryTax,
        discountPercentage: _displayDiscountPercentage,
        discountAmount: totalDiscountAmount,
        serviceCharge: serviceCharge,
        deliveryTax: deliveryTax,
        hospitalityTax: hospitalityDiscount,
        tableNumber: _getTableNumberString(),
        orderNumber: orderNumber.toString(),
        invoiceNumber: invoiceNumber.toString(),
        l10n: l10n,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print dialog opened'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  Future<void> _printKitchenInvoice(
    BuildContext context,
    CartState cartState,
    AppLocalizations l10n,
  ) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preparing print...'),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      
      final dbHelper = DatabaseHelper();
      final orderNumber = cartState.orderNumber ?? await dbHelper.getNextOrderNumber();
      
      await InvoicePrinter.printKitchenInvoice(
        items: cartState.items,
        tableNumber: _getTableNumberString(),
        orderNumber: orderNumber.toString(),
        l10n: l10n,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print dialog opened'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  Future<void> _completePayment(
    BuildContext context,
    String method,
    AppLocalizations l10n,
  ) async {
    try {
      if (_activeTableNumber == null) return;
      
      final activeTableItems = _tableCarts[_activeTableNumber] ?? [];
      if (activeTableItems.isEmpty) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processing payment...'),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      final salesBloc = context.read<SalesBloc>();
      final financialBloc = context.read<FinancialBloc>();
      final paymentService = PaymentService(salesBloc: salesBloc, financialBloc: financialBloc);
      
      final hospitalityTaxRate = await TaxSettingsHelper.loadHospitalityTaxRate();
      final serviceChargeRate = await TaxSettingsHelper.loadServiceChargeRate();
      final deliveryTaxRate = await TaxSettingsHelper.loadDeliveryTaxRate();
      
      final dbHelper = DatabaseHelper();
      if (!_tableOrderNumbers.containsKey(_activeTableNumber)) {
        _tableOrderNumbers[_activeTableNumber!] = await dbHelper.getNextOrderNumber();
      }
      
      final tableNumber = _activeTableNumber!;
      final tableItems = activeTableItems;
      final tableSubtotal = tableItems.fold(0.0, (sum, item) => sum + item.total);
      final tableDiscountPercentage = _tableDiscounts[tableNumber] ?? 0.0;
      final tableDiscountAmount = tableSubtotal * (tableDiscountPercentage / 100);
      final tableHospitalityDiscount = tableNumber == 'hospitality' ? tableSubtotal * hospitalityTaxRate : 0.0;
      final tableTotalDiscountAmount = tableDiscountAmount + tableHospitalityDiscount;
      final tableFinalTotal = tableSubtotal - tableTotalDiscountAmount;
      
      double tableServiceCharge = tableNumber == 'delivery' ? 0.0 : (int.tryParse(tableNumber) != null ? tableFinalTotal * serviceChargeRate : 0.0);
      double tableDeliveryTax = tableNumber == 'delivery' ? tableFinalTotal * deliveryTaxRate : 0.0;
      
      final tableTotalWithCharges = tableFinalTotal + tableServiceCharge + tableDeliveryTax;
      
      final result = await paymentService.processPayment(
        items: tableItems,
        total: tableTotalWithCharges,
        tableNumber: tableNumber,
        paymentMethod: method,
        discountPercentage: tableDiscountPercentage,
        discountAmount: tableTotalDiscountAmount,
        serviceCharge: tableServiceCharge,
        deliveryTax: tableDeliveryTax,
        hospitalityTax: tableHospitalityDiscount,
        l10n: l10n,
      );
      
      if (result.warnings.isNotEmpty && context.mounted) {
        _showLowStockWarnings(context, result.warnings);
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_allowPrinting) {
        try {
          final tableOrderNumber = _tableOrderNumbers[tableNumber]!;
          await InvoicePrinter.printCustomerInvoice(
            items: tableItems,
            total: tableTotalWithCharges,
            discountPercentage: tableDiscountPercentage,
            discountAmount: tableTotalDiscountAmount,
            serviceCharge: serviceCharge,
            deliveryTax: deliveryTax,
            hospitalityTax: hospitalityDiscount,
            tableNumber: tableNumber,
            orderNumber: tableOrderNumber.toString(),
            invoiceNumber: tableOrderNumber.toString(),
            l10n: l10n,
          );
        } catch (e) {
          debugPrint('Print error: $e');
        }
      }
      
      if (!mounted) return;
      await dbHelper.deletePendingInvoiceByTableNumbers([tableNumber]);
      
      setState(() {
        _selectedTableNumbers.remove(tableNumber);
        _tableCarts.remove(tableNumber);
        _tableDiscounts.remove(tableNumber);
        _tableOrderNumbers.remove(tableNumber);
        
        if (_selectedTableNumbers.isEmpty) {
          _activeTableNumber = null;
          _selectedCategoryId = null;
          _selectedSubCategoryId = null;
          context.read<CartBloc>().add(const ClearCart());
        } else {
          _activeTableNumber = _selectedTableNumbers.last;
          _updateDisplayCart();
        }
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saleRecorded), backgroundColor: AppColors.secondary, duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing payment: $e'), backgroundColor: AppColors.error, duration: const Duration(seconds: 5)),
        );
      }
    }
  }

  void _showLowStockWarnings(BuildContext context, List<LowStockWarning> warnings) {
    final criticalWarnings = warnings.where((w) => w.isCritical).toList();
    final regularWarnings = warnings.where((w) => !w.isCritical).toList();
    
    if (criticalWarnings.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(children: [Icon(Icons.warning, color: AppColors.error, size: 28), const SizedBox(width: AppSpacing.md), const Text('تحذير: المخزون منخفض جداً')]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('المخزون التالي منخفض جداً أو نفد:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                ...criticalWarnings.map((warning) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(children: [Icon(Icons.error, color: AppColors.error, size: 20), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(warning.message, style: const TextStyle(fontSize: 14)))]),
                )),
                if (regularWarnings.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md), const Divider(), const SizedBox(height: AppSpacing.md),
                  const Text('تحذيرات أخرى:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  ...regularWarnings.map((warning) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(children: [Icon(Icons.warning_amber, color: AppColors.warning, size: 20), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(warning.message, style: const TextStyle(fontSize: 14)))]),
                  )),
                ],
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('موافق'))],
        ),
      );
    } else if (regularWarnings.isNotEmpty) {
      final warningMessages = regularWarnings.map((w) => w.message).join('\n');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [Icon(Icons.warning_amber, color: Colors.white), SizedBox(width: AppSpacing.sm), Text('تحذير: المخزون منخفض', style: TextStyle(fontWeight: FontWeight.bold))]),
              const SizedBox(height: AppSpacing.sm), Text(warningMessages),
            ],
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'إغلاق', textColor: Colors.white, onPressed: () {}),
        ),
      );
    }
  }
}
