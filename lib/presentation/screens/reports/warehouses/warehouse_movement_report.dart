import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/reports_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../widgets/report_dialog.dart';

class WarehouseMovementReport {
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final reportsService = ReportsService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final summary = await reportsService.getInventoryMovementSummary(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      if (context.mounted) {
        Navigator.of(context).pop();

        ReportDialog.show(
          context,
          l10n.warehouseMovementReport,
          _buildMovementSummary(l10n, summary),
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

  static Widget _buildMovementSummary(
    AppLocalizations l10n,
    Map<String, dynamic> summary,
  ) {
    final types = summary.keys.toList();

    return Column(
      children: [
        Expanded(
          child: DataTable2(
            columns: [
              DataColumn2(label: Text(l10n.type ?? 'النوع'), size: ColumnSize.L),
              DataColumn2(label: Text(l10n.count ?? 'العدد'), size: ColumnSize.M, textAlign: TextAlign.center),
              DataColumn2(label: Text(l10n.totalValue ?? 'إجمالي القيمة'), size: ColumnSize.M, textAlign: TextAlign.right),
            ],
            rows: types.map((type) {
              final data = summary[type] as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(Text(type)),
                DataCell(Center(child: Text(data['count'].toString()))),
                DataCell(Align(
                  alignment: Alignment.centerRight,
                  child: Text(CurrencyFormatter.format(data['totalValue'] as double)),
                )),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
