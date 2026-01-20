import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/reports_service.dart';
import '../../../../core/models/financial_transaction.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../widgets/report_dialog.dart';

class GeneralLedgerReport {
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final reportsService = ReportsService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final transactions = await reportsService.getGeneralLedger();

      if (context.mounted) {
        Navigator.of(context).pop();

        ReportDialog.show(
          context,
          l10n.generalLedgerReport,
          _buildLedgerTable(l10n, transactions),
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

  static Widget _buildLedgerTable(
    AppLocalizations l10n,
    List<FinancialTransaction> transactions,
  ) {
    final dateFormat = DateFormat('M/d/yyyy HH:mm');

    return Column(
      children: [
        Expanded(
          child: DataTable2(
            columns: [
              DataColumn2(label: Text(l10n.date), size: ColumnSize.M),
              DataColumn2(label: Text(l10n.type), size: ColumnSize.S),
              DataColumn2(label: Text(l10n.amount), size: ColumnSize.S),
              DataColumn2(label: Text(l10n.notes), size: ColumnSize.L),
            ],
            rows: transactions.map((t) {
              return DataRow(cells: [
                DataCell(Text(dateFormat.format(t.createdAt))),
                DataCell(Text(t.type == TransactionType.cashIn ? 'قبض' : 'صرف')),
                DataCell(Align(
                  alignment: Alignment.centerRight,
                  child: Text(CurrencyFormatter.format(t.amount)),
                )),
                DataCell(Text(t.notes ?? '')),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
