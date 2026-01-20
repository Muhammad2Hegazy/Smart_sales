import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/reports_service.dart';
import '../../../../core/models/supplier.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../widgets/report_dialog.dart';

class SupplierPurchasesReport {
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    // Default to last 30 days
    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final reportsService = ReportsService();
      final reportData = await reportsService.getSupplierPurchasesReport(
        startDate: startDate,
        endDate: endDate,
      );

      if (context.mounted) {
        Navigator.of(context).pop();

        ReportDialog.show(
          context,
          l10n.supplierPurchasesReport,
          _buildPurchasesTable(l10n, reportData),
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

  static Widget _buildPurchasesTable(
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
              minWidth: 800,
              headingRowColor: WidgetStateProperty.all(AppColors.background),
              columns: [
                DataColumn2(
                  label: Text(l10n.supplier, style: const TextStyle(fontWeight: FontWeight.bold)),
                  size: ColumnSize.L,
                ),
                DataColumn2(
                  label: Text(l10n.totalPurchases, style: const TextStyle(fontWeight: FontWeight.bold)),
                  size: ColumnSize.M,
                ),
                DataColumn2(
                  label: Text(l10n.paidAmount, style: const TextStyle(fontWeight: FontWeight.bold)),
                  size: ColumnSize.M,
                ),
                DataColumn2(
                  label: Text(l10n.unpaidAmount, style: const TextStyle(fontWeight: FontWeight.bold)),
                  size: ColumnSize.M,
                ),
              ],
              rows: reportData.map((data) {
                final supplier = data['supplier'] as Supplier;
                return DataRow(
                  cells: [
                    DataCell(Text(supplier.name)),
                    DataCell(Align(
                      alignment: Alignment.centerRight,
                      child: Text(CurrencyFormatter.format(data['totalPurchases'] as double)),
                    )),
                    DataCell(Align(
                      alignment: Alignment.centerRight,
                      child: Text(CurrencyFormatter.format(data['totalPaid'] as double)),
                    )),
                    DataCell(Align(
                      alignment: Alignment.centerRight,
                      child: Text(CurrencyFormatter.format(data['unpaid'] as double)),
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
