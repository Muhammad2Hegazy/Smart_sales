import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/reports_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../widgets/report_dialog.dart';

class AccountBalancesReport {
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final reportsService = ReportsService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final balances = await reportsService.getAccountBalances();

      if (context.mounted) {
        Navigator.of(context).pop();

        ReportDialog.show(
          context,
          l10n.accountBalancesReport,
          _buildBalancesTable(l10n, balances),
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
    Map<String, double> balances,
  ) {
    return Column(
      children: [
        Expanded(
          child: DataTable2(
            columns: [
              DataColumn2(label: Text(l10n.account), size: ColumnSize.L),
              DataColumn2(label: Text(l10n.balance), size: ColumnSize.M),
            ],
            rows: [
              DataRow(cells: [
                const DataCell(Text('النقدية في الخزينة')),
                DataCell(Align(
                  alignment: Alignment.centerRight,
                  child: Text(CurrencyFormatter.format(balances['cashInHand']!)),
                )),
              ]),
              DataRow(cells: [
                const DataCell(Text('رصيد الفيزا')),
                DataCell(Align(
                  alignment: Alignment.centerRight,
                  child: Text(CurrencyFormatter.format(balances['visaBalance']!)),
                )),
              ]),
              DataRow(cells: [
                const DataCell(Text('ديون الموردين')),
                DataCell(Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    CurrencyFormatter.format(balances['supplierDebts']!),
                    style: const TextStyle(color: Colors.red),
                  ),
                )),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}
