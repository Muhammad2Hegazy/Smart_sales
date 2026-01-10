import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../bloc/cart/cart_bloc.dart';
import '../../../bloc/cart/cart_state.dart';

/// Cart footer widget that displays total, printing options, and payment button
class POSCartFooter extends StatefulWidget {
  final bool allowPrinting;
  final double discountPercentage;
  final ValueChanged<bool> onPrintingChanged;
  final ValueChanged<double> onDiscountChanged;
  final VoidCallback onPrintCustomerInvoice;
  final VoidCallback onPrintKitchenInvoice;
  final VoidCallback onProcessPayment;
  final VoidCallback onClearCart;

  const POSCartFooter({
    super.key,
    required this.allowPrinting,
    required this.discountPercentage,
    required this.onPrintingChanged,
    required this.onDiscountChanged,
    required this.onPrintCustomerInvoice,
    required this.onPrintKitchenInvoice,
    required this.onProcessPayment,
    required this.onClearCart,
  });

  @override
  State<POSCartFooter> createState() => _POSCartFooterState();
}

class _POSCartFooterState extends State<POSCartFooter> {
  late TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController(
      text: widget.discountPercentage > 0 
          ? CurrencyFormatter.formatDouble(widget.discountPercentage, 1) 
          : '',
    );
  }

  @override
  void didUpdateWidget(POSCartFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controller if discount changed from outside (not from user typing)
    if (widget.discountPercentage != oldWidget.discountPercentage) {
      final currentText = _discountController.text;
      final expectedText = widget.discountPercentage > 0 
          ? CurrencyFormatter.formatDouble(widget.discountPercentage, 1)
          : '';
      // Only update if the text doesn't match (to avoid interfering with typing)
      if (currentText != expectedText && 
          (currentText.isEmpty || double.tryParse(currentText) == null || 
           (double.tryParse(currentText) ?? 0) != widget.discountPercentage)) {
        _discountController.text = expectedText;
      }
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        // Calculate discount and final total
        final subtotal = cartState.total;
        final discountAmount = subtotal * (widget.discountPercentage / 100);
        final finalTotal = subtotal - discountAmount;
        
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtotal Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Subtotal:',
                      style: AppTextStyles.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      CurrencyFormatter.format(cartState.total),
                      style: AppTextStyles.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // Discount Input Row
              TextField(
                controller: _discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Discount %',
                  helperText: 'Enter 1-100 for discount percentage',
                  suffixText: '%',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  isDense: true,
                ),
                style: AppTextStyles.bodyMedium,
                onChanged: (value) {
                  if (value.isEmpty) {
                    widget.onDiscountChanged(0.0);
                    return;
                  }
                  
                  // Parse the value
                  final discount = double.tryParse(value) ?? 0.0;
                  
                  // Only clamp if value exceeds 100, otherwise just update
                  if (discount > 100.0) {
                    // Only update controller if it doesn't already show 100
                    if (_discountController.text != '100') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _discountController.value = TextEditingValue(
                            text: '100',
                            selection: TextSelection.collapsed(offset: 3),
                          );
                        }
                      });
                    }
                    widget.onDiscountChanged(100.0);
                  } else {
                    // Valid value - just update the discount without touching controller
                    widget.onDiscountChanged(discount);
                  }
                },
              ),
              
              // Discount Amount Row (if discount > 0)
              if (widget.discountPercentage > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Discount:',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '-${CurrencyFormatter.format(discountAmount)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              
              // Final Total Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${l10n.total}:',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      CurrencyFormatter.format(finalTotal),
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Allow Printing Checkbox
              Row(
                children: [
                  Checkbox(
                    value: widget.allowPrinting,
                    onChanged: (value) => widget.onPrintingChanged(value ?? false),
                  ),
                  Expanded(
                    child: Text(
                      l10n.allowPrinting,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Print Buttons
              AppButton(
                label: l10n.printCustomerInvoice,
                onPressed: cartState.items.isEmpty ? null : widget.onPrintCustomerInvoice,
                type: AppButtonType.outline,
                icon: Icons.print,
                isFullWidth: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: l10n.printKitchenInvoice,
                onPressed: cartState.items.isEmpty ? null : widget.onPrintKitchenInvoice,
                type: AppButtonType.outline,
                icon: Icons.restaurant,
                isFullWidth: true,
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Pay Button
              AppButton(
                label: l10n.pay,
                onPressed: cartState.items.isEmpty ? null : widget.onProcessPayment,
                type: AppButtonType.secondary,
                isFullWidth: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // Clear Cart Button
              AppButton(
                label: l10n.clearCart,
                onPressed: cartState.items.isEmpty ? null : widget.onClearCart,
                type: AppButtonType.outline,
                isFullWidth: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

