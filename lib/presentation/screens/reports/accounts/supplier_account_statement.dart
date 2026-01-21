import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/reports_service.dart';
import '../../../../core/models/supplier.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/database/database_helper.dart';
import '../widgets/report_dialog.dart';

class SupplierAccountStatement {
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final dbHelper = DatabaseHelper();
    final suppliers = await dbHelper.getAllSuppliers();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SupplierSelectionDialog(l10n: l10n, suppliers: suppliers),
    );

    if (result != null && context.mounted) {
      final selectedSupplier = result['supplier'] as Supplier;
      final startDate = result['startDate'] as DateTime;
      final endDate = result['endDate'] as DateTime;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final reportsService = ReportsService();
        final statement = await reportsService.getSupplierAccountStatement(
          supplierId: selectedSupplier.id,
          startDate: startDate,
          endDate: endDate,
        );

        if (context.mounted) {
          Navigator.of(context).pop();

          ReportDialog.show(
            context,
            l10n.supplierAccountStatement,
            _buildStatementTable(l10n, selectedSupplier, statement),
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

  static Widget _buildStatementTable(
    AppLocalizations l10n,
    Supplier supplier,
    List<Map<String, dynamic>> statement,
  ) {
    final dateFormat = DateFormat('M/d/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            '${l10n.supplierAccountStatement}: ${supplier.name}',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
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
                DataColumn2(label: Text(l10n.date), size: ColumnSize.M),
                DataColumn2(label: Text(l10n.invoiceNumber), size: ColumnSize.M),
                DataColumn2(label: Text(l10n.total), size: ColumnSize.S, numeric: true),
                DataColumn2(label: const Text('Paid'), size: ColumnSize.S, numeric: true),
                DataColumn2(label: Text(l10n.balance), size: ColumnSize.S, numeric: true),
              ],
              rows: statement.map((data) {
                return DataRow(cells: [
                  DataCell(Text(dateFormat.format(data['date'] as DateTime))),
                  DataCell(Text(data['invoiceNumber'].toString())),
                  DataCell(Align(alignment: Alignment.centerRight, child: Text(CurrencyFormatter.format(data['total'] as double)))),
                  DataCell(Align(alignment: Alignment.centerRight, child: Text(CurrencyFormatter.format(data['paid'] as double)))),
                  DataCell(Align(alignment: Alignment.centerRight, child: Text(CurrencyFormatter.format(data['balance'] as double)))),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SupplierSelectionDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final List<Supplier> suppliers;

  const _SupplierSelectionDialog({required this.l10n, required this.suppliers});

  @override
  State<_SupplierSelectionDialog> createState() => _SupplierSelectionDialogState();
}

class _SupplierSelectionDialogState extends State<_SupplierSelectionDialog> {
  Supplier? _selectedSupplier;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.supplierAccountStatement),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Supplier>(
            value: _selectedSupplier,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Supplier'),
            items: widget.suppliers.map((s) {
              return DropdownMenuItem(value: s, child: Text(s.name));
            }).toList(),
            onChanged: (val) => setState(() => _selectedSupplier = val),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
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
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.l10n.cancel)),
        ElevatedButton(
          onPressed: _selectedSupplier == null
              ? null
              : () => Navigator.pop(context, {
                    'supplier': _selectedSupplier,
                    'startDate': _startDate,
                    'endDate': _endDate,
                  }),
          child: Text(widget.l10n.ok),
        ),
      ],
    );
  }
}
