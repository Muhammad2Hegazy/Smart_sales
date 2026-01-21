import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/reports_service.dart';
import '../../../../core/models/item.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../blocs/product/product_bloc.dart';
import '../../../blocs/product/product_state.dart';
import '../widgets/report_dialog.dart';

class ItemByMovementReport {
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final productBloc = context.read<ProductBloc>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => BlocProvider<ProductBloc>.value(
        value: productBloc,
        child: _ItemTrendInputDialog(l10n: l10n),
      ),
    );

    if (result != null && context.mounted) {
      final selectedItem = result['item'] as Item;
      final startDate = result['startDate'] as DateTime;
      final endDate = result['endDate'] as DateTime;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final reportsService = ReportsService();
        final trend = await reportsService.getItemSalesTrend(
          itemId: selectedItem.id,
          startDate: startDate,
          endDate: endDate,
        );

        if (context.mounted) {
          Navigator.of(context).pop();

          ReportDialog.show(
            context,
            l10n.itemByMovementReport,
            _buildTrendTable(l10n, selectedItem, trend),
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

  static Widget _buildTrendTable(
    AppLocalizations l10n,
    Item item,
    List<Map<String, dynamic>> trend,
  ) {
    final dateFormat = DateFormat('M/d/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            '${l10n.item}: ${item.name}',
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
              minWidth: 600,
              headingRowColor: WidgetStateProperty.all(AppColors.background),
              columns: [
                DataColumn2(
                  label: Text(l10n.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                  size: ColumnSize.L,
                ),
                DataColumn2(
                  label: Text(l10n.quantity, style: const TextStyle(fontWeight: FontWeight.bold)),
                  size: ColumnSize.M,
                  numeric: true,
                ),
                DataColumn2(
                  label: Text(l10n.totalValue, style: const TextStyle(fontWeight: FontWeight.bold)),
                  size: ColumnSize.M,
                  numeric: true,
                ),
              ],
              rows: trend.map((data) {
                return DataRow(
                  cells: [
                    DataCell(Text(dateFormat.format(data['date'] as DateTime))),
                    DataCell(Center(child: Text(data['quantity'].toString()))),
                    DataCell(Align(
                      alignment: Alignment.centerRight,
                      child: Text(CurrencyFormatter.format(data['totalSales'] as double)),
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

class _ItemTrendInputDialog extends StatefulWidget {
  final AppLocalizations l10n;

  const _ItemTrendInputDialog({required this.l10n});

  @override
  State<_ItemTrendInputDialog> createState() => _ItemTrendInputDialogState();
}

class _ItemTrendInputDialogState extends State<_ItemTrendInputDialog> {
  Item? _selectedItem;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.itemByMovementReport),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              return DropdownButtonFormField<Item>(
                value: _selectedItem,
                isExpanded: true,
                decoration: InputDecoration(labelText: widget.l10n.item),
                items: state.items.map((item) {
                  return DropdownMenuItem(value: item, child: Text(item.name));
                }).toList(),
                onChanged: (val) => setState(() => _selectedItem = val),
              );
            },
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
          onPressed: _selectedItem == null
              ? null
              : () => Navigator.pop(context, {
                    'item': _selectedItem,
                    'startDate': _startDate,
                    'endDate': _endDate,
                  }),
          child: Text(widget.l10n.ok),
        ),
      ],
    );
  }
}
