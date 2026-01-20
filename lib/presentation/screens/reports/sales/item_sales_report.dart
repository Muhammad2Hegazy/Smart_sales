import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../blocs/product/product_bloc.dart';
import '../../../blocs/product/product_state.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/models/item.dart';
import '../../../../core/models/sale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/report_dialog.dart';

class ItemSalesReport {
  static Future<void> show(BuildContext context, int? selectedFloor) async {
    final l10n = AppLocalizations.of(context)!;
    final productBloc = context.read<ProductBloc>();
    
    // Show input form dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => BlocProvider<ProductBloc>.value(
        value: productBloc,
        child: _ItemSalesInputDialog(l10n: l10n),
      ),
    );

    if (result != null && context.mounted) {
      final selectedItem = result['item'] as Item;
      final startDate = result['startDate'] as DateTime;
      final endDate = result['endDate'] as DateTime;
      final yearlySales = result['yearlySales'] as bool;

      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      try {
        // Get sales data
        final dbHelper = DatabaseHelper();
        
        // Adjust dates if yearly sales
        DateTime finalStartDate = startDate;
        DateTime finalEndDate = endDate;
        
        if (yearlySales) {
          // From start of current year to current date
          final now = DateTime.now();
          finalStartDate = DateTime(now.year, 1, 1, 0, 0, 0);
          finalEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        }

        // Get all sales in date range
        final sales = await dbHelper.getSalesByDateRange(finalStartDate, finalEndDate);
        
        // Filter sales items by selected item
        final List<Map<String, dynamic>> reportData = [];
        
        // Sort sales by date for invoice numbering
        final sortedSales = List<Sale>.from(sales)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        int invoiceCounter = 1;
        final Map<String, int> saleInvoiceMap = {};
        for (var sale in sortedSales) {
          saleInvoiceMap[sale.id] = invoiceCounter++;
        }
        
        for (var sale in sales) {
          for (var saleItem in sale.items) {
            // Only include items matching selected item
            if (saleItem.itemId == selectedItem.id) {
              // Get invoice number from map
              final invoiceNumber = saleInvoiceMap[sale.id] ?? 1;
              
              // Calculate discount per item
              final itemTotal = saleItem.quantity * saleItem.price;
              final itemDiscount = sale.discountPercentage > 0
                  ? (itemTotal * sale.discountPercentage / 100)
                  : 0.0;
              final netValue = itemTotal - itemDiscount;
              
              reportData.add({
                'entryTime': sale.createdAt,
                'invoiceNumber': invoiceNumber,
                'itemName': saleItem.itemName,
                'quantity': saleItem.quantity,
                'salePrice': saleItem.price,
                'discount': itemDiscount,
                'netValue': netValue,
              });
            }
          }
        }

        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Show report
        if (context.mounted && reportData.isNotEmpty) {
          ReportDialog.show(
            context,
            l10n.salesReportByItem,
            _buildItemSalesReportTable(
              l10n,
              selectedItem,
              finalStartDate,
              finalEndDate,
              reportData,
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا توجد بيانات للعرض'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تحميل البيانات: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  static Widget _buildItemSalesReportTable(
    AppLocalizations l10n,
    Item item,
    DateTime startDate,
    DateTime endDate,
    List<Map<String, dynamic>> reportData,
  ) {
    final dateFormat = DateFormat('M/d/yyyy');
    final timeFormat = DateFormat('M/d/yyyy h:mm:ss a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Report Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.salesReportByItem,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اسم الصنف: ${item.name}',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                'التاريخ من: ${dateFormat.format(startDate)}',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                'التاريخ الى: ${dateFormat.format(endDate)}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        // DataTable2 for better data display
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 1000,
              headingRowColor: WidgetStateProperty.all(AppColors.background),
              headingRowHeight: 50,
              dataRowHeight: 50,
              columns: [
                DataColumn2(
                  label: Text(
                    'وقت البيع',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  size: ColumnSize.L,
                ),
                DataColumn2(
                  label: Text(
                    'رقم الفاتورة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  size: ColumnSize.M,
                ),
                DataColumn2(
                  label: Text(
                    'الكمية',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  size: ColumnSize.S,
                ),
                DataColumn2(
                  label: Text(
                    'سعر المنتج',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  size: ColumnSize.M,
                ),
                DataColumn2(
                  label: Text(
                    'خصم',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  size: ColumnSize.M,
                ),
                DataColumn2(
                  label: Text(
                    'صافي القيمة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  size: ColumnSize.M,
                ),
              ],
              rows: reportData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final isEven = index % 2 == 0;
                
                return DataRow2(
                  color: WidgetStateProperty.all(
                    isEven ? Colors.white : AppColors.background,
                  ),
                  cells: [
                    DataCell(
                      Text(
                        timeFormat.format(data['entryTime'] as DateTime),
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    DataCell(
                      Text(
                        data['invoiceNumber'].toString(),
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      placeholder: true,
                    ),
                    DataCell(
                      Text(
                        data['quantity'].toString(),
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      placeholder: true,
                    ),
                    DataCell(
                      Text(
                        (data['salePrice'] as double).toStringAsFixed(2),
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                      placeholder: true,
                    ),
                    DataCell(
                      Text(
                        (data['discount'] as double).toStringAsFixed(2),
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                      placeholder: true,
                    ),
                    DataCell(
                      Text(
                        (data['netValue'] as double).toStringAsFixed(2),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      placeholder: true,
                    ),
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

class _ItemSalesInputDialog extends StatefulWidget {
  final AppLocalizations l10n;

  const _ItemSalesInputDialog({required this.l10n});

  @override
  State<_ItemSalesInputDialog> createState() => _ItemSalesInputDialogState();
}

class _ItemSalesInputDialogState extends State<_ItemSalesInputDialog> {
  Item? _selectedItem;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _yearlySales = false;

  @override
  void initState() {
    super.initState();
    // Set end date to end of day
    _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        } else {
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.l10n.salesReportByItem,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Item Selection
            BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                final items = state.items;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اسم الصنف',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<Item>(
                      initialValue: _selectedItem,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      items: items.map((item) {
                        return DropdownMenuItem<Item>(
                          value: item,
                          child: Text(item.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedItem = value;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            // Yearly Sales Checkbox
            Row(
              children: [
                Checkbox(
                  value: _yearlySales,
                  onChanged: (value) {
                    setState(() {
                      _yearlySales = value ?? false;
                      // Update dates when yearly sales is toggled
                      if (_yearlySales) {
                        final now = DateTime.now();
                        _startDate = DateTime(now.year, 1, 1, 0, 0, 0);
                        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                      }
                    });
                  },
                ),
                Text(
                  'مبيعات العام',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Date Range
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'التاريخ من',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('M/d/yyyy').format(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'التاريخ الى',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('M/d/yyyy').format(_endDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(widget.l10n.cancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _selectedItem == null
                      ? null
                      : () => Navigator.of(context).pop({
                            'item': _selectedItem,
                            'startDate': _startDate,
                            'endDate': _endDate,
                            'yearlySales': _yearlySales,
                          }),
                  child: Text('استعلام'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
