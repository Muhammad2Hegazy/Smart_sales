import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/reports_service.dart';
import '../../../../core/models/category.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../widgets/report_dialog.dart';

class InventoryByCategoryReport {
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final reportsService = ReportsService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final reportData = await reportsService.getInventoryByCategory();

      if (context.mounted) {
        Navigator.of(context).pop();

        ReportDialog.show(
          context,
          l10n.inventoryCountByCategory,
          _buildInventoryByCategoryTable(l10n, reportData),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  static Widget _buildInventoryByCategoryTable(
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
                  label: Text(l10n.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                  size: ColumnSize.L,
                ),
                DataColumn2(
                  label: Text(l10n.totalQuantity ?? 'إجمالي الكمية', style: const TextStyle(fontWeight: FontWeight.bold)),
                  size: ColumnSize.M,
                  textAlign: TextAlign.center,
                ),
                DataColumn2(
                  label: Text(l10n.totalValue ?? 'إجمالي القيمة', style: const TextStyle(fontWeight: FontWeight.bold)),
                  size: ColumnSize.M,
                  textAlign: TextAlign.right,
                ),
              ],
              rows: reportData.map((data) {
                final category = data['category'] as Category;
                return DataRow(
                  cells: [
                    DataCell(Text(category.name)),
                    DataCell(Center(child: Text(data['totalQuantity'].toString()))),
                    DataCell(Align(
                      alignment: Alignment.centerRight,
                      child: Text(CurrencyFormatter.format(data['totalValue'] as double)),
                    )),
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
