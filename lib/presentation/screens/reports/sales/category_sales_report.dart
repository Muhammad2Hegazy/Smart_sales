import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../l10n/app_localizations.dart';
import '../../../bloc/product/product_bloc.dart';
import '../../../bloc/product/product_state.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/category.dart';
import '../../core/models/sale.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/report_dialog.dart';

class CategorySalesReport {
  static Future<void> show(BuildContext context, int? selectedFloor) async {
    final l10n = AppLocalizations.of(context)!;
    final productBloc = context.read<ProductBloc>();
    
    // Show input form dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => BlocProvider<ProductBloc>.value(
        value: productBloc,
        child: _CategorySalesInputDialog(l10n: l10n),
      ),
    );

    if (result != null && context.mounted) {
      final selectedCategory = result['category'] as Category;
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
        
        // Get all categories and items
        final categories = await dbHelper.getAllCategories();
        final subCategories = await dbHelper.getAllSubCategories();
        final items = await dbHelper.getAllItems();

        // Filter sales items by category
        final List<Map<String, dynamic>> reportData = [];
        
        // Create maps for faster lookup
        final itemsMap = {for (var item in items) item.id: item};
        final subCategoriesMap = {for (var sub in subCategories) sub.id: sub};
        final categoriesMap = {for (var cat in categories) cat.id: cat};
        
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
            // Find item
            final item = itemsMap[saleItem.itemId];
            if (item == null) continue;

            // Find subcategory
            final subCategory = subCategoriesMap[item.subCategoryId];
            if (subCategory == null) continue;

            // Find category
            final category = categoriesMap[subCategory.categoryId];
            if (category == null) continue;

            // Only include items from selected category
            if (category.id == selectedCategory.id) {
              // Get invoice number from map
              final invoiceNumber = saleInvoiceMap[sale.id] ?? 1;
              
              // Calculate discount per item
              final itemDiscount = sale.total > 0 
                  ? (sale.discountAmount * (saleItem.total / sale.total))
                  : 0.0;
              
              reportData.add({
                'entryTime': sale.createdAt,
                'invoiceNumber': invoiceNumber,
                'itemName': saleItem.itemName,
                'quantity': saleItem.quantity,
                'salePrice': saleItem.price,
                'discount': itemDiscount,
                'netValue': saleItem.total - itemDiscount,
              });
            }
          }
        }

        // Close loading
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Show report
        if (context.mounted && reportData.isNotEmpty) {
          ReportDialog.show(
            context,
            l10n.salesReportByCategory,
            _buildCategorySalesReportTable(
              l10n,
              selectedCategory,
              finalStartDate,
              finalEndDate,
              reportData,
            ),
          );
        } else if (context.mounted) {
          ReportDialog.show(
            context,
            l10n.salesReportByCategory,
            Center(
              child: Text(
                l10n.noSalesFound,
                style: AppTextStyles.bodyLarge,
              ),
            ),
          );
        }
      } catch (e) {
        // Close loading
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        
        if (context.mounted) {
          ReportDialog.show(
            context,
            l10n.salesReportByCategory,
            Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
      }
    }
  }



  static Widget _buildCategorySalesReportTable(
    AppLocalizations l10n,
    Category category,
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
                l10n.salesReportByCategory,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اسم الفئه: ${category.name}',
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
                    'اسم الصنف',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  size: ColumnSize.L,
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
                        data['itemName'] as String,
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

// Input Form Dialog
class _CategorySalesInputDialog extends StatefulWidget {
  final AppLocalizations l10n;

  const _CategorySalesInputDialog({required this.l10n});

  @override
  State<_CategorySalesInputDialog> createState() => _CategorySalesInputDialogState();
}

class _CategorySalesInputDialogState extends State<_CategorySalesInputDialog> {
  Category? _selectedCategory;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _yearlySales = false;

  @override
  void initState() {
    super.initState();
    // Set default dates
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day, 5, 0, 0);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
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
          _startDate = DateTime(picked.year, picked.month, picked.day, 5, 0, 0);
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
              widget.l10n.salesReportByCategory,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Category Selection
            BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                final categories = state.categories;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اسم الفئه',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<Category>(
                      initialValue: _selectedCategory,
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
                      items: categories.map((category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'من تاريخ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                DateFormat('M/d/yyyy').format(_startDate),
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حتى تاريخ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                DateFormat('M/d/yyyy').format(_endDate),
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Query Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedCategory == null
                    ? null
                    : () {
                        Navigator.of(context).pop({
                          'category': _selectedCategory,
                          'startDate': _startDate,
                          'endDate': _endDate,
                          'yearlySales': _yearlySales,
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'استعلام',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
