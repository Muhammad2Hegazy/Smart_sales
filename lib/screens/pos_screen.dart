import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/models/cart_item.dart';
import '../core/models/item.dart';
import '../core/models/low_stock_warning.dart';
import '../core/utils/invoice_printer.dart';
import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_event.dart';
import '../bloc/cart/cart_state.dart';
import '../bloc/sales/sales_bloc.dart';
import '../bloc/financial/financial_bloc.dart';
import '../bloc/product/product_bloc.dart';
import '../bloc/product/product_event.dart';
import '../core/services/payment_service.dart';
import '../core/utils/tax_settings_helper.dart';
import '../core/database/database_helper.dart';
import 'pos/widgets/pos_table_menu.dart';
import 'pos/widgets/pos_selected_tables.dart';
import 'pos/widgets/pos_categories_menu.dart';
import 'pos/widgets/pos_subcategories_menu.dart';
import 'pos/widgets/pos_items_grid.dart';
import 'pos/widgets/pos_cart_items_list.dart';
import 'pos/widgets/pos_cart_footer.dart';

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
        discountAmount: 0.0, // Will be calculated on payment
        serviceCharge: 0.0, // Will be calculated on payment
        deliveryTax: 0.0, // Will be calculated on payment
        hospitalityTax: 0.0, // Will be calculated on payment
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
    
    // Save pending invoice after generating order number
    _savePendingInvoiceForTable(tableNumber);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return BlocListener<CartBloc, CartState>(
      listener: (context, cartState) {
        // Sync CartBloc changes back to _tableCarts
        // This ensures that when items are added/removed/updated via CartBloc,
        // the changes are reflected in _tableCarts for the active table
        if (_activeTableNumber != null && mounted) {
          // Convert CartBloc items (which are stored as individual items with quantity=1)
          // back to _tableCarts format (grouped by item id with total quantity)
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
          
          // Only update if items actually changed to avoid infinite loops
          final currentItems = _tableCarts[_activeTableNumber!] ?? [];
          if (!_areItemsEqual(currentItems, updatedItems)) {
            setState(() {
              // Update _tableCarts - this can be an empty list if all items are deleted
              _tableCarts[_activeTableNumber!] = updatedItems;
            });
            
            // Save pending invoice after cart changes (even if cart is empty)
            // This ensures the pending invoice is updated/deleted as needed
            _savePendingInvoiceForTable(_activeTableNumber!);
          }
        }
      },
      child: BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        return Row(
          children: [
            // Table Selection Menu
            POSTableMenu(
              selectedTableNumbers: _selectedTableNumbers,
              onTableSelected: (tableNumbers) async {
                final previousTables = List<String>.from(_selectedTableNumbers);
                final isTableRemoved = tableNumbers.length < previousTables.length;
                
                // If a table was removed, save current state before clearing
                if (isTableRemoved) {
                  await _savePendingInvoices();
                }
                
                setState(() {
                  _selectedTableNumbers = tableNumbers;
                  
                  // Set active table to the last selected table (or first if only one)
                  if (tableNumbers.isNotEmpty) {
                    _activeTableNumber = tableNumbers.last;
                  } else {
                    _activeTableNumber = null;
                    _selectedCategoryId = null;
                    _selectedSubCategoryId = null;
                      context.read<CartBloc>().add(const ClearCart());
                    }
                });
                
                // Load pending invoices for new table selection
                if (tableNumbers.isNotEmpty && !isTableRemoved) {
                  // Load pending invoices for all newly selected tables
                  for (final tableNumber in tableNumbers) {
                    // Always load to ensure we have the latest data
                    await _loadPendingInvoiceForTable(tableNumber);
                
                    // Generate order number if needed
                    if (!_tableOrderNumbers.containsKey(tableNumber)) {
                      await _ensureOrderNumberForTable(tableNumber);
                    }
                  }
                  
                  // Update display cart for active table after loading
                  if (mounted) {
                    _updateDisplayCart();
                  }
                }
              },
            ),
            // Selected Tables Widget
            if (_selectedTableNumbers.isNotEmpty)
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
                  // Switch active table
                  setState(() {
                    _activeTableNumber = tableNumber;
                  });
                  _updateDisplayCart();
                },
                onTableRemoved: (tableNumber) async {
                  // Prevent removing table if it has items in cart
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
                  
                  final newTables = List<String>.from(_selectedTableNumbers)
                    ..remove(tableNumber);
                  
                  // Save current state before removing table
                  await _savePendingInvoices();
                  
                  setState(() {
                    _selectedTableNumbers = newTables;
                    if (newTables.isEmpty) {
                      _activeTableNumber = null;
                      _selectedCategoryId = null;
                      _selectedSubCategoryId = null;
                      context.read<CartBloc>().add(const ClearCart());
                    } else {
                      // Set active table to last remaining table
                      _activeTableNumber = newTables.last;
                      // Load pending invoices for remaining tables
                      _loadPendingInvoicesForTables(newTables);
                }
                  });
              },
            ),
            // Categories Menu (only if at least one table is selected)
            if (_selectedTableNumbers.isNotEmpty)
              POSCategoriesMenu(
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    _selectedSubCategoryId = null;
                  });
                },
              )
            else
              // Placeholder when no table is selected
              Container(
                width: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    right: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_restaurant_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.selectTable,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Please select a table to start an order',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // SubCategories Menu (if category selected and table is selected)
            if (_selectedTableNumbers.isNotEmpty && _selectedCategoryId != null)
              POSSubCategoriesMenu(
                selectedCategoryId: _selectedCategoryId,
                selectedSubCategoryId: _selectedSubCategoryId,
                onSubCategorySelected: (value) {
                  setState(() {
                    _selectedSubCategoryId = value;
                  });
                },
              ),
            // Items Grid (if subcategory selected and table is selected)
            if (_selectedTableNumbers.isNotEmpty && _selectedSubCategoryId != null)
              Expanded(
                child: POSItemsGrid(
                  selectedSubCategoryId: _selectedSubCategoryId,
                  onItemTap: (item) {
                    _addItemToCart(context, item);
                    // Auto-save pending invoices after adding item
                    _savePendingInvoices();
                  },
                ),
              )
            else if (_selectedTableNumbers.isEmpty)
              // Placeholder when no table is selected
              Expanded(
                child: Container(
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
                ),
              ),
            // Cart Sidebar (only show when items are in cart)
            if (cartState.items.isNotEmpty)
              Container(
                width: 400,
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
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_cart, color: Colors.white),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            '${l10n.cart} (${cartState.itemCount})',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: POSCartItemsList(),
                    ),
                    POSCartFooter(
                      allowPrinting: _allowPrinting,
                      discountPercentage: _displayDiscountPercentage,
                      onPrintingChanged: (value) {
                        setState(() {
                          _allowPrinting = value;
                        });
                      },
                      onDiscountChanged: (value) async {
                        if (_activeTableNumber != null) {
                        setState(() {
                            // Apply discount to active table only
                            _tableDiscounts[_activeTableNumber!] = value;
                        });
                          await _savePendingInvoiceForTable(_activeTableNumber!);
                        }
                      },
                      onPrintCustomerInvoice: () => _printCustomerInvoice(context, cartState, l10n),
                      onPrintKitchenInvoice: () => _printKitchenInvoice(context, cartState, l10n),
                      onProcessPayment: () => _completePayment(context, 'cash', l10n),
                      onClearCart: () async {
                        if (_activeTableNumber != null) {
                        setState(() {
                            // Clear cart for active table only
                            _tableCarts[_activeTableNumber!] = [];
                            _tableDiscounts[_activeTableNumber!] = 0.0;
                        });
                          await _savePendingInvoiceForTable(_activeTableNumber!);
                        }
                        if (mounted) {
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

  // Payment and printing methods
  Future<void> _printCustomerInvoice(
    BuildContext context,
    CartState cartState,
    AppLocalizations l10n,
  ) async {
    try {
      // Show loading indicator
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
      
      // Calculate service charge and delivery tax
      final serviceChargeRate = await TaxSettingsHelper.loadServiceChargeRate();
      final serviceCharge = _hasRegularTable()
                           ? finalTotal * serviceChargeRate
                           : 0.0;
      
      final deliveryTaxRate = await TaxSettingsHelper.loadDeliveryTaxRate();
      final deliveryTax = _hasDeliveryTable()
                          ? finalTotal * deliveryTaxRate
                          : 0.0;
      
      // Calculate hospitality discount (for hospitality orders) - applied as discount, not tax
      final hospitalityTaxRate = await TaxSettingsHelper.loadHospitalityTaxRate();
      final hospitalityDiscount = _hasHospitalityTable()
                                  ? subtotal * hospitalityTaxRate
                                  : 0.0;
      
      // Total discount includes both manual discount and hospitality discount
      final totalDiscountAmount = discountAmount + hospitalityDiscount;
      
      // Use current order number from cart, or generate new one if not set
      final dbHelper = DatabaseHelper();
      final orderNumber = cartState.orderNumber ?? await dbHelper.getNextOrderNumber();
      // Invoice number equals order number
      final invoiceNumber = orderNumber;
      debugPrint('_printCustomerInvoice: Using orderNumber=$orderNumber, invoiceNumber=$invoiceNumber');
      
      await InvoicePrinter.printCustomerInvoice(
        items: cartState.items,
        total: finalTotal + serviceCharge + deliveryTax,
        discountPercentage: _displayDiscountPercentage,
        discountAmount: totalDiscountAmount, // Includes hospitality discount
        serviceCharge: serviceCharge,
        deliveryTax: deliveryTax,
        hospitalityTax: hospitalityDiscount, // Store as discount amount (using hospitalityTax field for backward compatibility)
        tableNumber: _getTableNumberString(),
        orderNumber: orderNumber.toString(),
        invoiceNumber: invoiceNumber.toString(),
        l10n: l10n,
      );
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print dialog opened'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Print error: $e');
      debugPrint('Stack trace: $stackTrace');
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
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preparing print...'),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      
      // Use current order number from cart, or generate new one if not set
      final dbHelper = DatabaseHelper();
      final orderNumber = cartState.orderNumber ?? await dbHelper.getNextOrderNumber();
      debugPrint('_printKitchenInvoice: Using orderNumber=$orderNumber');
      
      await InvoicePrinter.printKitchenInvoice(
        items: cartState.items,
        tableNumber: _getTableNumberString(),
        orderNumber: orderNumber.toString(),
        l10n: l10n,
      );
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print dialog opened'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Print error: $e');
      debugPrint('Stack trace: $stackTrace');
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
      // Check if active table has items
      if (_activeTableNumber == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please select a table'),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      final activeTableItems = _tableCarts[_activeTableNumber] ?? [];
      if (activeTableItems.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cart is empty'),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processing payment...'),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Get Blocs - they should be provided in main_screen.dart
      final salesBloc = context.read<SalesBloc>();
      final financialBloc = context.read<FinancialBloc>();
      
      final paymentService = PaymentService(
        salesBloc: salesBloc,
        financialBloc: financialBloc,
      );
      
      // Calculate tax rates
      final hospitalityTaxRate = await TaxSettingsHelper.loadHospitalityTaxRate();
      final serviceChargeRate = await TaxSettingsHelper.loadServiceChargeRate();
      final deliveryTaxRate = await TaxSettingsHelper.loadDeliveryTaxRate();
      
      // Ensure active table has order number
      final dbHelper = DatabaseHelper();
      if (!_tableOrderNumbers.containsKey(_activeTableNumber)) {
        final nextOrderNumber = await dbHelper.getNextOrderNumber();
        _tableOrderNumbers[_activeTableNumber!] = nextOrderNumber;
      }
      
      // Process payment for active table only
      final tableNumber = _activeTableNumber!;
      final tableItems = activeTableItems;
      
      // Calculate totals for this table's cart
      final tableSubtotal = tableItems.fold(0.0, (sum, item) => sum + item.total);
      final tableDiscountPercentage = _tableDiscounts[tableNumber] ?? 0.0;
      final tableDiscountAmount = tableSubtotal * (tableDiscountPercentage / 100);
      
      // Calculate hospitality discount for this table
      final tableHospitalityDiscount = tableNumber == 'hospitality'
          ? tableSubtotal * hospitalityTaxRate
                                  : 0.0;
      
      // Total discount includes both manual discount and hospitality discount
      final tableTotalDiscountAmount = tableDiscountAmount + tableHospitalityDiscount;
      final tableFinalTotal = tableSubtotal - tableTotalDiscountAmount;
      
      // Calculate charges for this specific table
      double tableServiceCharge = 0.0;
      double tableDeliveryTax = 0.0;
      
      if (tableNumber == 'delivery') {
        tableDeliveryTax = tableFinalTotal * deliveryTaxRate;
      } else if (int.tryParse(tableNumber) != null) {
        tableServiceCharge = tableFinalTotal * serviceChargeRate;
      }
      
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
      
      // Show low stock warnings if any
      if (result.warnings.isNotEmpty && context.mounted) {
        _showLowStockWarnings(context, result.warnings);
      }
      
      debugPrint('_completePayment: Processed payment for active table: $tableNumber');
      
      // Wait a bit to ensure database save is complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Auto-print customer invoice if printing is enabled
      if (_allowPrinting) {
        try {
          // Print invoice for active table only
          final tableOrderNumber = _tableOrderNumbers[tableNumber]!;
          
          await InvoicePrinter.printCustomerInvoice(
            items: tableItems,
            total: tableTotalWithCharges,
            discountPercentage: tableDiscountPercentage,
            discountAmount: tableTotalDiscountAmount,
            serviceCharge: tableServiceCharge,
            deliveryTax: tableDeliveryTax,
            hospitalityTax: tableHospitalityDiscount,
            tableNumber: tableNumber,
            orderNumber: tableOrderNumber.toString(),
            invoiceNumber: tableOrderNumber.toString(),
            l10n: l10n,
          );
        } catch (e) {
          // Print error is non-critical, sale is already saved
          debugPrint('Print error: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sale saved but print failed: $e'),
                backgroundColor: AppColors.warning,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
      
      // Clear cart for active table only (but keep table in selected list)
      if (!mounted) return;
      
      // Delete pending invoice for active table after successful payment
      await dbHelper.deletePendingInvoiceByTableNumbers([tableNumber]);
      
      // Remove the paid table from selected tables
      setState(() {
        _selectedTableNumbers.remove(tableNumber);
        _tableCarts.remove(tableNumber);
        _tableDiscounts.remove(tableNumber);
        _tableOrderNumbers.remove(tableNumber);
        
        // If no tables remain, close all tables (clear everything)
        if (_selectedTableNumbers.isEmpty) {
          _activeTableNumber = null;
        _selectedCategoryId = null;
        _selectedSubCategoryId = null;
          if (mounted) {
            context.read<CartBloc>().add(const ClearCart());
          }
        } else {
          // Set active table to last remaining table
          _activeTableNumber = _selectedTableNumbers.last;
          _updateDisplayCart();
        }
      });

      // Show success message (warnings are shown separately)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saleRecorded),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Payment error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _addItemToCart(BuildContext context, Item item) async {
    // Prevent adding items if no table is selected
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
    
    // Add item to active table's cart only
    if (_activeTableNumber == null) return;
    
    setState(() {
      final tableItems = _tableCarts[_activeTableNumber] ?? [];
      final existingIndex = tableItems.indexWhere((cartItem) => cartItem.id == item.id);
      
      if (existingIndex != -1) {
        // Update quantity if item exists
        tableItems[existingIndex] = CartItem(
          id: tableItems[existingIndex].id,
          name: tableItems[existingIndex].name,
          price: tableItems[existingIndex].price,
          quantity: tableItems[existingIndex].quantity + 1,
        );
      } else {
        // Add new item
        tableItems.add(CartItem(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: 1,
        ));
      }
      _tableCarts[_activeTableNumber!] = tableItems;
    });
    
    // Update display cart
    _updateDisplayCart();
    
    // Save pending invoice for active table
    await _savePendingInvoiceForTable(_activeTableNumber!);
  }

  void _showLowStockWarnings(BuildContext context, List<LowStockWarning> warnings) {
    // Separate critical and warning messages
    final criticalWarnings = warnings.where((w) => w.isCritical).toList();
    final regularWarnings = warnings.where((w) => !w.isCritical).toList();
    
    // Show critical warnings first in a dialog
    if (criticalWarnings.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: AppColors.error, size: 28),
              const SizedBox(width: AppSpacing.md),
              const Text('تحذير: المخزون منخفض جداً'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المخزون التالي منخفض جداً أو نفد:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                ...criticalWarnings.map((warning) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: AppColors.error, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          warning.message,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
                if (regularWarnings.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'تحذيرات أخرى:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...regularWarnings.map((warning) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            warning.message,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('موافق'),
            ),
          ],
        ),
      );
    } else if (regularWarnings.isNotEmpty) {
      // Show regular warnings in a snackbar
      final warningMessages = regularWarnings.map((w) => w.message).join('\n');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.white),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'تحذير: المخزون منخفض',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(warningMessages),
            ],
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'إغلاق',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }
}
