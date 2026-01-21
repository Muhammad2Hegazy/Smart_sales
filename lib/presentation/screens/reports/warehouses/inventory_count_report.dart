import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/reports_service.dart';
import '../../../../core/models/item.dart';
import '../widgets/report_dialog.dart';

class InventoryCountReport {
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final reportsService = ReportsService();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final reportData = await reportsService.getInventoryCount();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading

        ReportDialog.show(
          context,
          l10n.inventoryCount,
          _buildInventoryCountTable(l10n, reportData),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  static Widget _buildInventoryCountTable(
    AppLocalizations l10n,
    List<Map<String, dynamic>> reportData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 600,
              headingRowColor: WidgetStateProperty.all(AppColors.background),
              columns: [
                DataColumn2(
                  label: Text(l10n.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  size: ColumnSize.L,
                ),
                DataColumn2(
                  label: Text(l10n.quantity, style: const TextStyle(fontWeight: FontWeight.bold)),
                  size: ColumnSize.M,
                  numeric: true,
                ),
                DataColumn2(
                  label: Text(l10n.unit, style: const TextStyle(fontWeight: FontWeight.bold)),
                  size: ColumnSize.S,
                ),
              ],
              rows: reportData.map((data) {
                final item = data['item'] as Item;
                return DataRow(
                  cells: [
                    DataCell(Text(item.name)),
                    DataCell(Center(child: Text(data['currentQuantity'].toString()))),
                    DataCell(Center(child: Text(data['unit'].toString()))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
