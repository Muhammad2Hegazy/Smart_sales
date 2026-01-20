import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../blocs/cart/cart_bloc.dart';
import '../../../blocs/cart/cart_state.dart';

/// Cart footer widget that displays total, printing options, and payment button
class POSCartFooter extends StatefulWidget {
  final bool allowPrinting;
  final double discountPercentage;
  final ValueChanged<bool> onPrintingChanged;
  final Future<void> Function(double) onDiscountChanged;
  final VoidCallback onPrintCustomerInvoice;
  final VoidCallback onPrintKitchenInvoice;
  final VoidCallback onProcessPayment;
  final Future<void> Function()? onClearCart;

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
    if (widget.discountPercentage != oldWidget.discountPercentage) {
      final currentText = _discountController.text;
      final expectedText = widget.discountPercentage > 0
          ? CurrencyFormatter.formatDouble(widget.discountPercentage, 1)
          : '';
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
        final subtotal = cartState.total;
        final discountAmount = subtotal * (widget.discountPercentage / 100);
        final finalTotal = subtotal - discountAmount;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary Rows (Compact)
              _buildSummaryRow('${l10n.totalInvoice}:', CurrencyFormatter.format(cartState.total)),
              if (widget.discountPercentage > 0)
                _buildSummaryRow(
                  '${l10n.discount} (${widget.discountPercentage}%):',
                  '-${CurrencyFormatter.format(discountAmount)}',
                  isError: true,
                ),
              const Divider(height: AppSpacing.sm),
              _buildSummaryRow(
                '${l10n.total}:',
                CurrencyFormatter.format(finalTotal),
                isTotal: true,
              ),

              const SizedBox(height: AppSpacing.sm),

              // Actions Row (Compact)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _discountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      decoration: InputDecoration(
                        labelText: '${l10n.discount} %',
                        suffixText: '%',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      style: AppTextStyles.bodySmall,
                      onChanged: (value) async {
                        final discount = double.tryParse(value) ?? 0.0;
                        await widget.onDiscountChanged(discount > 100 ? 100 : discount);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Checkbox(
                    value: widget.allowPrinting,
                    onChanged: (value) => widget.onPrintingChanged(value ?? false),
                    visualDensity: VisualDensity.compact,
                  ),
                  Flexible(
                    child: Text(
                      l10n.allowPrinting,
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Buttons Grid
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: l10n.printKitchenInvoice.split(' ').last, // Use last word as label if too long
                      onPressed: cartState.items.isEmpty ? null : widget.onPrintKitchenInvoice,
                      type: AppButtonType.outline,
                      icon: Icons.restaurant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: l10n.printCustomerInvoice.split(' ').last, // Use last word as label
                      onPressed: cartState.items.isEmpty ? null : widget.onPrintCustomerInvoice,
                      type: AppButtonType.outline,
                      icon: Icons.print,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: l10n.pay,
                      onPressed: cartState.items.isEmpty ? null : widget.onProcessPayment,
                      type: AppButtonType.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 1,
                    child: AppButton(
                      label: l10n.clearCart.split(' ').first, // Use first word
                      onPressed: cartState.items.isEmpty ? null : widget.onClearCart,
                      type: AppButtonType.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isError = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal ? AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold) : AppTextStyles.bodySmall,
          ),
          Text(
            value,
            style: isTotal
                ? AppTextStyles.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)
                : AppTextStyles.bodySmall.copyWith(color: isError ? AppColors.error : null, fontWeight: isError ? FontWeight.bold : null),
          ),
        ],
      ),
    );
  }
}
