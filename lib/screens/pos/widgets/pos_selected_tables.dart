import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';

/// Widget to display selected tables
class POSSelectedTables extends StatelessWidget {
  final List<String> selectedTableNumbers;
  final String? activeTableNumber;
  final Map<String, int> tableItemCounts; // Map of table number to item count
  final ValueChanged<String> onTableSelected;
  final ValueChanged<String> onTableRemoved;

  const POSSelectedTables({
    super.key,
    required this.selectedTableNumbers,
    this.activeTableNumber,
    this.tableItemCounts = const {},
    required this.onTableSelected,
    required this.onTableRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (selectedTableNumbers.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.selectedTables,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selectedTableNumbers.isNotEmpty)
                  Text(
                    '${selectedTableNumbers.length}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: selectedTableNumbers.length,
              itemBuilder: (context, index) {
                final tableNumber = selectedTableNumbers[index];
                final itemCount = tableItemCounts[tableNumber] ?? 0;
                return _buildSelectedTableItem(context, tableNumber, itemCount, l10n);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTableItem(
    BuildContext context,
    String tableNumber,
    int itemCount,
    AppLocalizations l10n,
  ) {
    String displayName;
    IconData icon;
    
    switch (tableNumber) {
      case 'takeaway':
        displayName = l10n.takeaway;
        icon = Icons.shopping_bag_outlined;
        break;
      case 'delivery':
        displayName = l10n.delivery;
        icon = Icons.delivery_dining_outlined;
        break;
      case 'hospitality':
        displayName = l10n.hospitalityTable;
        icon = Icons.restaurant_outlined;
        break;
      default:
        displayName = '${l10n.table} $tableNumber';
        icon = Icons.table_restaurant_outlined;
    }
    
    final isActive = activeTableNumber == tableNumber;
    
    return InkWell(
      onTap: () => onTableSelected(tableNumber),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        color: isActive
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.1),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isActive ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (itemCount > 0)
                    Text(
                      '$itemCount items',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isActive ? Colors.white70 : AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            if (itemCount == 0)
              GestureDetector(
                onTap: () => onTableRemoved(tableNumber),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: isActive ? Colors.white : AppColors.error,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white24 : AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$itemCount',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isActive ? Colors.white : AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

