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
  String? _selectedTableNumber;
  bool _allowPrinting = false;
  double _discountPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    // Load product data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductBloc>().add(const LoadProducts());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        return Row(
          children: [
            // Table Selection Menu
            POSTableMenu(
              selectedTableNumber: _selectedTableNumber,
              onTableSelected: (value) async {
                setState(() {
                  // If table is deselected or changed, clear all selections
                  if (_selectedTableNumber != value) {
                    _selectedCategoryId = null;
                    _selectedSubCategoryId = null;
                    // Clear cart when table changes
                    if (_selectedTableNumber != null && value != null) {
                      context.read<CartBloc>().add(const ClearCart());
                    }
                  }
                  _selectedTableNumber = value;
                });
                
                // Generate order number when a new table is selected
                if (value != null) {
                  final dbHelper = DatabaseHelper();
                  final nextOrderNumber = await dbHelper.getNextOrderNumber();
                  context.read<CartBloc>().add(SetOrderNumber(nextOrderNumber));
                }
              },
            ),
            // Categories Menu (only if table is selected)
            if (_selectedTableNumber != null)
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
            if (_selectedTableNumber != null && _selectedCategoryId != null)
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
            if (_selectedTableNumber != null && _selectedSubCategoryId != null)
              Expanded(
                child: POSItemsGrid(
                  selectedSubCategoryId: _selectedSubCategoryId,
                  onItemTap: (item) => _addItemToCart(context, item),
                ),
              )
            else if (_selectedTableNumber == null)
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
                      discountPercentage: _discountPercentage,
                      onPrintingChanged: (value) {
                        setState(() {
                          _allowPrinting = value;
                        });
                      },
                      onDiscountChanged: (value) {
                        setState(() {
                          _discountPercentage = value;
                        });
                      },
                      onPrintCustomerInvoice: () => _printCustomerInvoice(context, cartState, l10n),
                      onPrintKitchenInvoice: () => _printKitchenInvoice(context, cartState, l10n),
                      onProcessPayment: () => _completePayment(context, 'cash', l10n),
                      onClearCart: () {
                        context.read<CartBloc>().add(const ClearCart());
                        setState(() {
                          _discountPercentage = 0.0;
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
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
      final discountAmount = subtotal * (_discountPercentage / 100);
      final finalTotal = subtotal - discountAmount;
      
      // Calculate service charge and delivery tax
      final serviceChargeRate = await TaxSettingsHelper.loadServiceChargeRate();
      final serviceCharge = _selectedTableNumber != null && 
                           _selectedTableNumber != 'takeaway' && 
                           _selectedTableNumber != 'delivery' 
                           ? finalTotal * serviceChargeRate
                           : 0.0;
      
      final deliveryTaxRate = await TaxSettingsHelper.loadDeliveryTaxRate();
      final deliveryTax = _selectedTableNumber == 'delivery'
                          ? finalTotal * deliveryTaxRate
                          : 0.0;
      
      // Calculate hospitality discount (for hospitality orders) - applied as discount, not tax
      final hospitalityTaxRate = await TaxSettingsHelper.loadHospitalityTaxRate();
      final hospitalityDiscount = _selectedTableNumber == 'hospitality'
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
        discountPercentage: _discountPercentage,
        discountAmount: totalDiscountAmount, // Includes hospitality discount
        serviceCharge: serviceCharge,
        deliveryTax: deliveryTax,
        hospitalityTax: hospitalityDiscount, // Store as discount amount (using hospitalityTax field for backward compatibility)
        tableNumber: _selectedTableNumber,
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
        tableNumber: _selectedTableNumber,
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
      final cartState = context.read<CartBloc>().state;
      if (cartState.items.isEmpty) {
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
      
      // Calculate totals with discount
      final subtotal = cartState.total;
      final discountAmount = subtotal * (_discountPercentage / 100);
      
      // Calculate hospitality discount (for hospitality orders) - applied as discount, not tax
      final hospitalityTaxRate = await TaxSettingsHelper.loadHospitalityTaxRate();
      final hospitalityDiscount = _selectedTableNumber == 'hospitality'
                                  ? subtotal * hospitalityTaxRate
                                  : 0.0;
      
      // Total discount includes both manual discount and hospitality discount
      final totalDiscountAmount = discountAmount + hospitalityDiscount;
      final finalTotal = subtotal - totalDiscountAmount;
      
      // Calculate service charge (for dine-in orders)
      final serviceChargeRate = await TaxSettingsHelper.loadServiceChargeRate();
      final serviceCharge = _selectedTableNumber != null && 
                           _selectedTableNumber != 'takeaway' && 
                           _selectedTableNumber != 'delivery' &&
                           _selectedTableNumber != 'hospitality'
                           ? finalTotal * serviceChargeRate
                           : 0.0;
      
      // Calculate delivery tax (for delivery orders)
      final deliveryTaxRate = await TaxSettingsHelper.loadDeliveryTaxRate();
      final deliveryTax = _selectedTableNumber == 'delivery'
                          ? finalTotal * deliveryTaxRate
                          : 0.0;
      
      final finalTotalWithCharges = finalTotal + serviceCharge + deliveryTax;
      
      // Save sale to database (this will be saved to reports)
      final result = await paymentService.processPayment(
        items: cartState.items,
        total: finalTotalWithCharges,
        tableNumber: _selectedTableNumber,
        paymentMethod: method,
        discountPercentage: _discountPercentage,
        discountAmount: totalDiscountAmount, // Includes hospitality discount
        serviceCharge: serviceCharge,
        deliveryTax: deliveryTax,
        hospitalityTax: hospitalityDiscount, // Store as discount amount (using hospitalityTax field for backward compatibility)
        l10n: l10n,
      );
      
      // Show low stock warnings if any
      if (result.warnings.isNotEmpty && context.mounted) {
        _showLowStockWarnings(context, result.warnings);
      }
      
      // Use current order number from cart, or generate new one if not set
      final dbHelper = DatabaseHelper();
      final orderNumber = cartState.orderNumber ?? await dbHelper.getNextOrderNumber();
      // Invoice number equals order number
      final invoiceNumber = orderNumber;
      debugPrint('_completePayment: Using orderNumber=$orderNumber, invoiceNumber=$invoiceNumber');
      
      // Wait a bit to ensure database save is complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Auto-print customer invoice if printing is enabled
      if (_allowPrinting) {
        try {
          
          await InvoicePrinter.printCustomerInvoice(
            items: cartState.items,
            total: finalTotalWithCharges,
            discountPercentage: _discountPercentage,
            discountAmount: totalDiscountAmount, // Includes hospitality discount
            serviceCharge: serviceCharge,
            deliveryTax: deliveryTax,
            hospitalityTax: hospitalityDiscount, // Store as discount amount (using hospitalityTax field for backward compatibility)
            tableNumber: _selectedTableNumber,
            orderNumber: orderNumber.toString(),
            invoiceNumber: invoiceNumber.toString(),
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
      
      // Clear cart and reset POS screen for new invoice
      if (!mounted) return;
      if (context.mounted) {
        context.read<CartBloc>().add(const ClearCart());
      }
      
      // Generate new order number for next order (after payment)
      final nextOrderNumber = await dbHelper.getNextOrderNumber();
      if (context.mounted && _selectedTableNumber != null) {
        context.read<CartBloc>().add(SetOrderNumber(nextOrderNumber));
      }
      
      // Reset all selections for new customer
      setState(() {
        _selectedCategoryId = null;
        _selectedSubCategoryId = null;
        _selectedTableNumber = null;
        _allowPrinting = false;
        _discountPercentage = 0.0;
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

  void _addItemToCart(BuildContext context, Item item) {
    // Prevent adding items if no table is selected
    if (_selectedTableNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.selectTable} to start an order'),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    context.read<CartBloc>().add(
      AddItemToCart(
        CartItem(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: 1,
        ),
      ),
    );
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
