import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/models/user_permission.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/data_sources/local/user_management_local_data_source.dart';
import '../../../core/repositories/user_management_repository.dart';

/// Table selection menu widget
class POSTableMenu extends StatefulWidget {
  final List<String> selectedTableNumbers;
  final ValueChanged<List<String>> onTableSelected;

  const POSTableMenu({
    super.key,
    required this.selectedTableNumbers,
    required this.onTableSelected,
  });

  @override
  State<POSTableMenu> createState() => _POSTableMenuState();
}

class _POSTableMenuState extends State<POSTableMenu> {
  bool _hasHospitalityPermission = false;

  @override
  void initState() {
    super.initState();
    _checkHospitalityPermission();
  }

  Future<void> _checkHospitalityPermission() async {
    try {
      final dbHelper = DatabaseHelper();
      final userManagementLocalDataSource = UserManagementLocalDataSource();
      final userManagementRepository = UserManagementRepository(
        userManagementLocalDataSource,
        dbHelper,
      );
      final permissionService = PermissionService(dbHelper, userManagementRepository);
      final hasPermission = await permissionService.hasPermission(
        PermissionKeys.posAccessHospitalityTable,
      );
      if (mounted) {
        setState(() {
          _hasHospitalityPermission = hasPermission;
        });
      }
    } catch (e) {
      // On error, default to false (no permission)
      if (mounted) {
        setState(() {
          _hasHospitalityPermission = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
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
            child: Text(
              l10n.tables,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                // Takeaway
                _buildTableItem(
                  context,
                  l10n.takeaway,
                  'takeaway',
                  widget.selectedTableNumbers.contains('takeaway'),
                  Icons.shopping_bag_outlined,
                ),
                // Delivery
                _buildTableItem(
                  context,
                  l10n.delivery,
                  'delivery',
                  widget.selectedTableNumbers.contains('delivery'),
                  Icons.delivery_dining_outlined,
                ),
                // Hospitality Table (only if user has permission)
                if (_hasHospitalityPermission)
                  _buildTableItem(
                    context,
                    l10n.hospitalityTable,
                    'hospitality',
                    widget.selectedTableNumbers.contains('hospitality'),
                    Icons.restaurant_outlined,
                  ),
                const Divider(),
                // Tables 1-100
                for (int i = 1; i <= 100; i++)
                  _buildTableItem(
                    context,
                    '${l10n.table} $i',
                    i.toString(),
                    widget.selectedTableNumbers.contains(i.toString()),
                    Icons.table_restaurant_outlined,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableItem(
    BuildContext context,
    String label,
    String value,
    bool isSelected,
    IconData icon,
  ) {
    return InkWell(
      onTap: () {
        final currentSelection = List<String>.from(widget.selectedTableNumbers);
        if (isSelected) {
          currentSelection.remove(value);
        } else {
          currentSelection.add(value);
        }
        widget.onTableSelected(currentSelection);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

