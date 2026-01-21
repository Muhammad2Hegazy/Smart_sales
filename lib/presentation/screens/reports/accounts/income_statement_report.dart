import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/reports_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../widgets/report_dialog.dart';
import '../widgets/report_widgets.dart';

class IncomeStatementReport {
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();

    final result = await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (context) => _DateRangeDialog(l10n: l10n, startDate: startDate, endDate: endDate),
    );

    if (result != null && context.mounted) {
      startDate = result['startDate']!;
      endDate = result['endDate']!;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final reportsService = ReportsService();
        final data = await reportsService.getIncomeStatement(
          startDate: startDate,
          endDate: endDate,
        );

        if (context.mounted) {
          Navigator.of(context).pop();

          ReportDialog.show(
            context,
            l10n.incomeStatementReport,
            _buildStatement(l10n, data),
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
  }

  static Widget _buildStatement(
    AppLocalizations l10n,
    Map<String, double> data,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ReportWidgets.buildReportSection(
            'الإيرادات',
            [
              ReportWidgets.buildReportRow('صافي المبيعات', CurrencyFormatter.format(data['totalSales']!)),
              ReportWidgets.buildReportRow('إيرادات أخرى', CurrencyFormatter.format(data['otherRevenues']!)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ReportWidgets.buildReportSection(
            'المصروفات',
            [
              ReportWidgets.buildReportRow('إجمالي المشتريات', CurrencyFormatter.format(data['totalPurchases']!)),
              ReportWidgets.buildReportRow('مصروفات أخرى', CurrencyFormatter.format(data['otherExpenses']!)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'صافي الربح / الخسارة',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  CurrencyFormatter.format(data['netProfit']!),
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: (data['netProfit'] ?? 0) >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRangeDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final DateTime startDate;
  final DateTime endDate;

  const _DateRangeDialog({required this.l10n, required this.startDate, required this.endDate});

  @override
  State<_DateRangeDialog> createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<_DateRangeDialog> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.selectPeriod),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _startDate = date);
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(DateFormat('M/d/yyyy').format(_startDate)),
            ),
          ),
          const Icon(Icons.arrow_forward, size: 16),
          Expanded(
            child: TextButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _endDate = date);
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(DateFormat('M/d/yyyy').format(_endDate)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.l10n.cancel)),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'startDate': _startDate,
            'endDate': _endDate,
          }),
          child: Text(widget.l10n.ok),
        ),
      ],
    );
  }
}
