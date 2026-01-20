import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/reports_service.dart';
import '../../../../core/models/supplier.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../widgets/report_dialog.dart';

class SupplierBalancesReport {
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final reportsService = ReportsService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final suppliers = await reportsService.getSupplierBalances();

      if (context.mounted) {
        Navigator.of(context).pop();

        ReportDialog.show(
          context,
          l10n.supplierBalancesReport,
          _buildBalancesTable(l10n, suppliers),
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

  static Widget _buildBalancesTable(
    AppLocalizations l10n,
    List<Supplier> suppliers,
  ) {
    return Column(
      children: [
        Expanded(
          child: DataTable2(
            columns: [
              DataColumn2(label: Text(l10n.supplier ?? 'المورد'), size: ColumnSize.L),
              DataColumn2(label: Text(l10n.balance ?? 'الرصيد'), size: ColumnSize.M, textAlign: TextAlign.right),
            ],
            rows: suppliers.map((s) {
              return DataRow(cells: [
                DataCell(Text(s.name)),
                DataCell(Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    CurrencyFormatter.format(s.balance ?? 0.0),
                    style: TextStyle(
                      color: (s.balance ?? 0) > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
