import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/models/cart_item.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../bloc/cart/cart_bloc.dart';
import '../../../bloc/cart/cart_event.dart';
import '../../../bloc/cart/cart_state.dart';

/// Cart items list widget for POS screen
class POSCartItemsList extends StatelessWidget {
  const POSCartItemsList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        if (cartState.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (cartState.orderNumber != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'رقم الطلب: ${cartState.orderNumber}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Text(
                  l10n.cartEmpty,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Order Number Display
            if (cartState.orderNumber != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'رقم الطلب: ${cartState.orderNumber}',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            // Items List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: cartState.items.length,
                itemBuilder: (context, index) {
                  final item = cartState.items[index];
                  return _CartItemWidget(item: item);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CartItemWidget extends StatefulWidget {
  final CartItem item;

  const _CartItemWidget({required this.item});

  @override
  State<_CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<_CartItemWidget> {
  late TextEditingController _quantityController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void didUpdateWidget(_CartItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantity != widget.item.quantity && !_isEditing) {
      _quantityController.text = widget.item.quantity.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    CurrencyFormatter.format(item.price),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Quantity controls
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    iconSize: 18,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () {
                      if (item.quantity > 1) {
                        context.read<CartBloc>().add(
                          UpdateItemQuantity(item.id, item.quantity - 1),
                        );
                      } else {
                        context.read<CartBloc>().add(RemoveItemFromCart(item.id));
                      }
                    },
                  ),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      controller: _quantityController,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        isDense: true,
                      ),
                      onTap: () {
                        setState(() {
                          _isEditing = true;
                        });
                        _quantityController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _quantityController.text.length,
                        );
                      },
                      onChanged: (value) {
                        if (value.isEmpty) {
                          return; // Don't update if empty, wait for user to finish
                        }
                        final quantity = int.tryParse(value);
                        if (quantity != null && quantity > 0) {
                          context.read<CartBloc>().add(
                            UpdateItemQuantity(item.id, quantity),
                          );
                        }
                      },
                      onSubmitted: (value) {
                        setState(() {
                          _isEditing = false;
                        });
                        if (value.isEmpty) {
                          // If empty, restore to 1
                          _quantityController.text = '1';
                          context.read<CartBloc>().add(
                            UpdateItemQuantity(item.id, 1),
                          );
                          return;
                        }
                        final quantity = int.tryParse(value) ?? 1;
                        if (quantity <= 0) {
                          context.read<CartBloc>().add(RemoveItemFromCart(item.id));
                        } else {
                          context.read<CartBloc>().add(
                            UpdateItemQuantity(item.id, quantity),
                          );
                        }
                      },
                      onEditingComplete: () {
                        setState(() {
                          _isEditing = false;
                        });
                        final value = _quantityController.text;
                        if (value.isEmpty) {
                          _quantityController.text = '1';
                          context.read<CartBloc>().add(
                            UpdateItemQuantity(item.id, 1),
                          );
                          return;
                        }
                        final quantity = int.tryParse(value) ?? 1;
                        if (quantity <= 0) {
                          context.read<CartBloc>().add(RemoveItemFromCart(item.id));
                        } else {
                          context.read<CartBloc>().add(
                            UpdateItemQuantity(item.id, quantity),
                          );
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    iconSize: 18,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () {
                      context.read<CartBloc>().add(
                        UpdateItemQuantity(item.id, item.quantity + 1),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Total
            SizedBox(
              width: 80,
              child: Text(
                CurrencyFormatter.format(item.total),
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              onPressed: () {
                context.read<CartBloc>().add(RemoveItemFromCart(item.id));
              },
            ),
          ],
        ),
      ),
    );
  }
}

