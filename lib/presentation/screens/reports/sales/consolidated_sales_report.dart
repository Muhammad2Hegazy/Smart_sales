import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../widgets/report_dialog.dart';

class ConsolidatedSalesReport {
  static Future<void> show(BuildContext context, int? selectedFloor) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Show input form dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ConsolidatedSalesInputDialog(l10n: l10n),
    );

    if (result != null && context.mounted) {
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
        
        // Get all items, categories, and subcategories
        final items = await dbHelper.getAllItems();
        final categories = await dbHelper.getAllCategories();
        final subCategories = await dbHelper.getAllSubCategories();
        
        // Create maps for faster lookup
        final itemsMap = {for (var item in items) item.id: item};
        final subCategoriesMap = {for (var sub in subCategories) sub.id: sub};
        final categoriesMap = {for (var cat in categories) cat.id: cat};
        
        // Aggregate sales by item
        final Map<String, Map<String, dynamic>> itemSales = {};
        
        for (var sale in sales) {
          for (var saleItem in sale.items) {
            final itemId = saleItem.itemId;
            if (!itemSales.containsKey(itemId)) {
              final item = itemsMap[itemId];
              final subCategory = item != null ? subCategoriesMap[item.subCategoryId] : null;
              final category = subCategory != null ? categoriesMap[subCategory.categoryId] : null;
              
              itemSales[itemId] = {
                'itemName': saleItem.itemName,
                'categoryName': category?.name ?? 'غير محدد',
                'subCategoryName': subCategory?.name ?? 'غير محدد',
                'quantity': 0,
                'totalSales': 0.0,
                'totalDiscount': 0.0,
                'netSales': 0.0,
              };
            }
            
            final itemData = itemSales[itemId]!;
            final itemTotal = saleItem.quantity * saleItem.price;
            final itemDiscount = sale.discountPercentage > 0
                ? (itemTotal * sale.discountPercentage / 100)
                : 0.0;
            final netValue = itemTotal - itemDiscount;
            
            itemData['quantity'] = (itemData['quantity'] as int) + saleItem.quantity;
            itemData['totalSales'] = (itemData['totalSales'] as double) + itemTotal;
            itemData['totalDiscount'] = (itemData['totalDiscount'] as double) + itemDiscount;
            itemData['netSales'] = (itemData['netSales'] as double) + netValue;
          }
        }
        
        // Convert to list and sort by net sales descending
        final reportData = itemSales.values.toList()
          ..sort((a, b) => (b['netSales'] as double).compareTo(a['netSales'] as double));

        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Show report
        if (context.mounted && reportData.isNotEmpty) {
          ReportDialog.show(
            context,
            l10n.consolidatedSalesReport,
            _buildConsolidatedSalesReportTable(
              l10n,
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

  static Widget _buildConsolidatedSalesReportTable(
    AppLocalizations l10n,
    DateTime startDate,
    DateTime endDate,
    List<Map<String, dynamic>> reportData,
  ) {
    final dateFormat = DateFormat('M/d/yyyy');
    
    // Calculate totals
    final totalQuantity = reportData.fold<int>(
      0,
      (sum, data) => sum + (data['quantity'] as int),
    );
    final totalSales = reportData.fold<double>(
      0.0,
      (sum, data) => sum + (data['totalSales'] as double),
    );
    final totalDiscount = reportData.fold<double>(
      0.0,
      (sum, data) => sum + (data['totalDiscount'] as double),
    );
    final totalNetSales = reportData.fold<double>(
      0.0,
      (sum, data) => sum + (data['netSales'] as double),
    );

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
                l10n.consolidatedSalesReport,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
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
              minWidth: 1200,
              headingRowColor: WidgetStateProperty.all(AppColors.background),
              headingRowHeight: 50,
              dataRowHeight: 50,
              columns: [
                DataColumn2(
                  label: Text(
                    'اسم الصنف',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  size: ColumnSize.L,
                ),
                DataColumn2(
                  label: Text(
                    'الفئة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                    'إجمالي المبيعات',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  size: ColumnSize.M,
                ),
                DataColumn2(
                  label: Text(
                    'إجمالي الخصم',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  size: ColumnSize.M,
                ),
                DataColumn2(
                  label: Text(
                    'صافي المبيعات',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  size: ColumnSize.M,
                ),
              ],
              rows: [
                ...reportData.asMap().entries.map((entry) {
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
                          data['itemName'] as String,
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                      DataCell(
                        Text(
                          data['categoryName'] as String,
                          style: AppTextStyles.bodySmall,
                        ),
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
                          CurrencyFormatter.format(data['totalSales'] as double),
                          style: AppTextStyles.bodySmall,
                          textAlign: TextAlign.right,
                        ),
                        placeholder: true,
                      ),
                      DataCell(
                        Text(
                          CurrencyFormatter.format(data['totalDiscount'] as double),
                          style: AppTextStyles.bodySmall,
                          textAlign: TextAlign.right,
                        ),
                        placeholder: true,
                      ),
                      DataCell(
                        Text(
                          CurrencyFormatter.format(data['netSales'] as double),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        placeholder: true,
                      ),
                    ],
                  );
                }),
                // Summary row
                DataRow2(
                  color: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.1)),
                  cells: [
                    DataCell(
                      Text(
                        'الإجمالي',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const DataCell(Text('')),
                    DataCell(
                      Text(
                        totalQuantity.toString(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      placeholder: true,
                    ),
                    DataCell(
                      Text(
                        CurrencyFormatter.format(totalSales),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      placeholder: true,
                    ),
                    DataCell(
                      Text(
                        CurrencyFormatter.format(totalDiscount),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      placeholder: true,
                    ),
                    DataCell(
                      Text(
                        CurrencyFormatter.format(totalNetSales),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      placeholder: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsolidatedSalesInputDialog extends StatefulWidget {
  final AppLocalizations l10n;

  const _ConsolidatedSalesInputDialog({required this.l10n});

  @override
  State<_ConsolidatedSalesInputDialog> createState() => _ConsolidatedSalesInputDialogState();
}

class _ConsolidatedSalesInputDialogState extends State<_ConsolidatedSalesInputDialog> {
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
              widget.l10n.consolidatedSalesReport,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
                  onPressed: () => Navigator.of(context).pop({
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
