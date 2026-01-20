import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_border_radius.dart';
import '../../core/models/raw_material.dart';
import '../../core/models/raw_material_batch.dart';
import '../../core/models/raw_material_category.dart';
import '../../core/models/raw_material_sub_category.dart';
import '../../core/models/raw_material_unit.dart';
import '../../core/database/database_helper.dart';
import 'package:uuid/uuid.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<RawMaterialCategory> _categories = [];
  RawMaterialCategory? _selectedCategory;
  RawMaterialSubCategory? _selectedSubCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper = DatabaseHelper();
      final categories = await dbHelper.getAllRawMaterialCategories();
      
      // Preserve selected category and subcategory by ID
      final selectedCategoryId = _selectedCategory?.id;
      final selectedSubCategoryId = _selectedSubCategory?.id;
      
      setState(() {
        _categories = categories;
        
        // Restore selected category if it still exists
        if (selectedCategoryId != null && categories.isNotEmpty) {
          try {
            _selectedCategory = categories.firstWhere(
              (cat) => cat.id == selectedCategoryId,
            );
            
            // Restore selected subcategory if it still exists
            if (_selectedCategory != null && selectedSubCategoryId != null && _selectedCategory!.subCategories.isNotEmpty) {
              try {
                _selectedSubCategory = _selectedCategory!.subCategories.firstWhere(
                  (subCat) => subCat.id == selectedSubCategoryId,
                );
              } catch (e) {
                _selectedSubCategory = null;
              }
            } else {
              _selectedSubCategory = null;
            }
          } catch (e) {
            _selectedCategory = null;
            _selectedSubCategory = null;
          }
        } else {
          _selectedCategory = null;
          _selectedSubCategory = null;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.inventory),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Categories Menu
                _buildCategoriesMenu(context, l10n),
                // SubCategories Menu (if category selected)
                if (_selectedCategory != null)
                  _buildSubCategoriesMenu(context, l10n),
                // Materials Menu (if subcategory selected)
                if (_selectedSubCategory != null)
                  Expanded(
                    child: _buildMaterialsMenu(context, l10n),
                  ),
              ],
            ),
    );
  }

  Widget _buildCategoriesMenu(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.category, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'الفئات',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory?.id == category.id;
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategory = null;
                        _selectedSubCategory = null;
                      } else {
                        _selectedCategory = category;
                        _selectedSubCategory = null;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoriesMenu(BuildContext context, AppLocalizations l10n) {
    if (_selectedCategory == null) {
      return const SizedBox.shrink();
    }

    final subCategories = _selectedCategory!.subCategories;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.subdirectory_arrow_right, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'الفئات الفرعية',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: subCategories.length,
              itemBuilder: (context, index) {
                final subCategory = subCategories[index];
                final isSelected = _selectedSubCategory?.id == subCategory.id;
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedSubCategory = null;
                      } else {
                        _selectedSubCategory = subCategory;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected
                              ? AppColors.secondary
                              : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            subCategory.name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.secondary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsMenu(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    if (_selectedSubCategory == null) {
      return const SizedBox.shrink();
    }

    final materials = _selectedSubCategory!.materials;

    if (materials.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
        ),
        child: Center(
          child: Text(
            'لا توجد مواد خام',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2, color: AppColors.textPrimary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'المواد الخام',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DataRow2>>(
              future: _buildTableRows(context, l10n, materials),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final rows = snapshot.data ?? [];
                return DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 800,
                  headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.1)),
                  headingRowHeight: 50,
                  dataRowHeight: 50,
                  smRatio: 0.75,
                  lmRatio: 1.5,
                  columns: [
                    DataColumn2(
                      label: Text(
                        'اسم المادة',
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
                      ),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Text(
                        'الوحدة',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Text(
                        'السعر الإجمالي',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      size: ColumnSize.M,
                    ),
                    const DataColumn2(
                      label: Text(''),
                      size: ColumnSize.S,
                    ),
                  ],
                  rows: rows,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<DataRow2>> _buildTableRows(
    BuildContext context,
    AppLocalizations l10n,
    List<RawMaterial> materials,
  ) async {
    final rows = <DataRow2>[];

    for (var material in materials) {
      // Calculate total price (sum of price per unit * quantity for all batches)
      double? totalPrice;
      if (material.batches.isNotEmpty) {
        final batchesWithPrice = material.batches.where((b) => b.price != null).toList();
        if (batchesWithPrice.isNotEmpty) {
          // Calculate total price: sum of (price per unit * quantity) for each batch
          double totalValue = 0.0;
          for (var batch in batchesWithPrice) {
            // price is per unit, so total = price per unit * quantity
            totalValue += (batch.price! * batch.quantity);
          }
          totalPrice = totalValue;
        }
      }
      
      // Use formatStockForDisplay for smart display
      final dbHelper = DatabaseHelper();
      Map<String, String> displayInfo;
      try {
        displayInfo = await dbHelper.formatStockForDisplay(material.id);
      } catch (e) {
        debugPrint('Error formatting display for ${material.name}: $e');
        // Fallback: use base unit display
        if (material.baseUnit == 'gram') {
          if (material.totalQuantity >= 1000) {
            displayInfo = {
              'quantity': '${(material.totalQuantity / 1000.0).toStringAsFixed(2)} كيلو',
              'unit': 'كيلو',
            };
          } else {
            displayInfo = {
              'quantity': material.totalQuantity.toStringAsFixed(2),
              'unit': 'جرام',
            };
          }
        } else if (material.baseUnit == 'ml') {
          if (material.totalQuantity >= 1000) {
            displayInfo = {
              'quantity': '${(material.totalQuantity / 1000.0).toStringAsFixed(2)} لتر',
              'unit': 'لتر',
            };
          } else {
            displayInfo = {
              'quantity': material.totalQuantity.toStringAsFixed(2),
              'unit': 'مل',
            };
          }
        } else if (material.baseUnit == 'carton') {
          displayInfo = {
            'quantity': material.totalQuantity.toStringAsFixed(0),
            'unit': 'كرتونة / زجاجة',
          };
        } else if (material.baseUnit == 'packet') {
          displayInfo = {
            'quantity': material.totalQuantity.toStringAsFixed(0),
            'unit': 'باكيت',
          };
        } else if (material.baseUnit == 'jar') {
          displayInfo = {
            'quantity': material.totalQuantity.toStringAsFixed(0),
            'unit': 'جرة',
          };
        } else if (material.baseUnit == 'piece') {
          displayInfo = {
            'quantity': material.totalQuantity.toStringAsFixed(0),
            'unit': 'قطعة',
          };
        } else {
          displayInfo = {
            'quantity': material.totalQuantity.toStringAsFixed(2),
            'unit': material.baseUnit,
          };
        }
      }
      String quantityDisplay = material.isInStock 
          ? displayInfo['quantity']! 
          : l10n.outOfStock;
      String unitDisplay = displayInfo['unit']!;
      
      // Single row for each material
      rows.add(
        DataRow2(
          cells: [
            DataCell(Text(material.name)),
            DataCell(
              Text(
                quantityDisplay,
                style: TextStyle(
                  color: material.isInStock ? null : AppColors.error,
                  fontWeight: material.isInStock ? null : FontWeight.bold,
                ),
              ),
            ),
            DataCell(Text(unitDisplay)),
            DataCell(
              Text(
                totalPrice != null
                    ? '${totalPrice.toStringAsFixed(2)} ج.م'
                    : '-',
              ),
            ),
            DataCell(
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditMaterialPopup(context, l10n, material),
                tooltip: l10n.edit,
              ),
            ),
          ],
        ),
      );
    }

    return rows;
  }


  Future<void> _showEditMaterialPopup(
    BuildContext context,
    AppLocalizations l10n,
    RawMaterial material, {
    RawMaterialBatch? batch,
  }) async {
    // Available units based on base unit
    List<String> availableUnits = [];
    if (material.baseUnit == 'gram') {
      availableUnits = ['جرام', 'كيلو'];
    } else if (material.baseUnit == 'ml') {
      availableUnits = ['مل', 'لتر'];
    } else if (material.baseUnit == 'piece') {
      availableUnits = ['قطعة'];
    } else if (material.baseUnit == 'carton') {
      availableUnits = ['كرتونة', 'زجاجة'];
    } else {
      availableUnits = [material.baseUnit];
    }
    
    // Set default selected unit - convert base unit to Arabic if needed
    String getDefaultUnit() {
      if (material.baseUnit == 'gram') return 'جرام';
      if (material.baseUnit == 'ml') return 'مل';
      if (material.baseUnit == 'piece') return 'قطعة';
      if (material.baseUnit == 'carton') return 'كرتونة';
      if (material.baseUnit == 'packet') return 'باكيت';
      if (material.baseUnit == 'jar') return 'جرة';
      return material.baseUnit;
    }
    
    String selectedUnit = batch != null 
        ? getDefaultUnit()
        : (availableUnits.contains(getDefaultUnit()) 
            ? getDefaultUnit() 
            : availableUnits.first);
    
    // For water (carton-based), track bottles per carton
    int bottlesPerCarton = 20; // Default
    if (material.baseUnit == 'carton') {
      final dbHelper = DatabaseHelper();
      final units = await dbHelper.getRawMaterialUnits(material.id);
      final bottleUnit = units.firstWhere(
        (u) => u.unit == 'bottle' || u.unit == 'زجاجة',
        orElse: () => RawMaterialUnit(
          id: '',
          rawMaterialId: material.id,
          unit: 'bottle',
          conversionFactorToBase: 1.0 / 20.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      bottlesPerCarton = (1.0 / bottleUnit.conversionFactorToBase).round();
    }
    
    // Convert quantity from base unit to display unit when editing
    String initialQuantityText = '';
    if (batch != null) {
      final quantityInBaseUnit = batch.quantity;
      // Convert from base unit to selected unit for display
      if (selectedUnit != material.baseUnit) {
        // Need to convert from base unit to display unit
        // For gram -> kilogram: divide by 1000
        if (material.baseUnit == 'gram' && selectedUnit == 'كيلو') {
          initialQuantityText = (quantityInBaseUnit / 1000.0).toStringAsFixed(2);
        }
        // For ml -> liter: divide by 1000
        else if (material.baseUnit == 'ml' && selectedUnit == 'لتر') {
          initialQuantityText = (quantityInBaseUnit / 1000.0).toStringAsFixed(2);
        }
        // For carton -> bottle: multiply by bottles per carton
        else if (material.baseUnit == 'carton' && selectedUnit == 'زجاجة') {
          // bottlesPerCarton is already calculated above
          initialQuantityText = (quantityInBaseUnit * bottlesPerCarton).toStringAsFixed(0);
        }
        // For packet -> kilogram: multiply by 10 (1 packet = 10kg)
        else if (material.baseUnit == 'packet' && selectedUnit == 'كيلو') {
          initialQuantityText = (quantityInBaseUnit * 10.0).toStringAsFixed(2);
        }
        // For packet -> gram: multiply by 10000 (1 packet = 10000g)
        else if (material.baseUnit == 'packet' && selectedUnit == 'جرام') {
          initialQuantityText = (quantityInBaseUnit * 10000.0).toStringAsFixed(2);
        }
        else {
          initialQuantityText = quantityInBaseUnit.toStringAsFixed(2);
        }
      } else {
        initialQuantityText = quantityInBaseUnit.toStringAsFixed(2);
      }
    }
    
    final quantityController = TextEditingController(
      text: initialQuantityText,
    );
    final priceController = TextEditingController(
      text: batch?.price?.toStringAsFixed(2) ?? '',
    );
    DateTime? selectedExpiryDate = batch?.expiryDate;
    
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          // Local state for bottles per carton
          int localBottlesPerCarton = bottlesPerCarton;
          
          return AlertDialog(
          title: Text(batch != null ? l10n.editMaterial : 'إضافة كمية'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اسم المادة',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(material.name),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'الوحدة',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<String>(
                  initialValue: selectedUnit,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  items: availableUnits.map((unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedUnit = value ?? availableUnits.first;
                    });
                  },
                ),
                // Show bottles per carton selector for water when adding new batch
                if (material.baseUnit == 'carton' && batch == null && selectedUnit == 'كرتونة')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'عدد الزجاجات في الكرتونة',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<int>(
                        initialValue: localBottlesPerCarton,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        items: [20, 24].map((count) {
                          return DropdownMenuItem<int>(
                            value: count,
                            child: Text('$count زجاجة'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            localBottlesPerCarton = value ?? 20;
                            bottlesPerCarton = localBottlesPerCarton;
                          });
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'الكمية',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    hintText: 'أدخل الكمية',
                    suffixText: selectedUnit,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'السعر لكل وحدة (ج.م)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    hintText: 'أدخل السعر لكل $selectedUnit',
                    suffixText: 'ج.م / $selectedUnit',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.expiryDate,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedExpiryDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedExpiryDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedExpiryDate != null
                                ? DateFormat('yyyy-MM-dd').format(selectedExpiryDate!)
                                : 'اختياري',
                            style: TextStyle(
                              color: selectedExpiryDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (quantityController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseEnterQuantity),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final quantity = double.tryParse(quantityController.text);
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseEnterValidQuantity),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final price = priceController.text.isNotEmpty
                    ? double.tryParse(priceController.text)
                    : null;

                try {
                  final dbHelper = DatabaseHelper();
                  
                  if (batch != null) {
                    // Update existing batch
                    // Convert quantity to base unit if needed
                    double quantityInBaseUnit = quantity;
                    if (selectedUnit != material.baseUnit) {
                      quantityInBaseUnit = await dbHelper.convertToBaseUnit(
                        material.id,
                        quantity,
                        selectedUnit,
                      );
                    }
                    
                    final updatedBatch = batch.copyWith(
                      quantity: quantityInBaseUnit,
                      price: price,
                      expiryDate: selectedExpiryDate,
                      updatedAt: DateTime.now(),
                    );

                    await dbHelper.updateRawMaterialBatch(updatedBatch);
                  } else {
                    // Add new batch
                    // Convert quantity to base unit if needed
                    double quantityInBaseUnit = quantity;
                    if (selectedUnit != material.baseUnit) {
                      quantityInBaseUnit = await dbHelper.convertToBaseUnit(
                        material.id,
                        quantity,
                        selectedUnit,
                      );
                    }
                    
                    final now = DateTime.now();
                    final newBatch = RawMaterialBatch(
                      id: const Uuid().v4(),
                      rawMaterialId: material.id,
                      quantity: quantityInBaseUnit,
                      price: price,
                      expiryDate: selectedExpiryDate,
                      createdAt: now,
                      updatedAt: now,
                    );

                    await dbHelper.insertRawMaterialBatch(newBatch);
                    
                    // Update conversion factor for water if carton was selected
                    if (material.baseUnit == 'carton' && selectedUnit == 'كرتونة') {
                      // Update conversion factor: 1 bottle = 1/bottlesPerCarton carton
                      final conversionFactor = 1.0 / bottlesPerCarton;
                      final db = await dbHelper.database;
                      await db.update(
                        'raw_material_units',
                        {
                          'conversion_factor_to_base': conversionFactor,
                          'updated_at': DateTime.now().toIso8601String(),
                        },
                        where: 'raw_material_id = ? AND (unit = ? OR unit = ?)',
                        whereArgs: [material.id, 'bottle', 'زجاجة'],
                      );
                    }
                    
                    // Stock quantity is automatically recalculated in insertRawMaterialBatch
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(batch != null ? l10n.batchUpdatedSuccessfully : l10n.batchAddedSuccessfully),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
        },
      ),
    );

    quantityController.dispose();
    priceController.dispose();
  }

}

