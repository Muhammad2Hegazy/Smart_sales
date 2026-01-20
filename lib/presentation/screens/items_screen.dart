import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_border_radius.dart';
import '../core/models/item.dart';
import '../core/models/category.dart';
import '../core/models/sub_category.dart';
import '../core/models/recipe.dart';
import '../core/models/recipe_ingredient.dart';
import '../core/models/raw_material.dart';
import '../core/utils/currency_formatter.dart';
// No longer needed here as dbHelper handles it
// import '../core/utils/csv_importer.dart';
// import '../core/models/import_result.dart';
import 'package:file_picker/file_picker.dart';
import '../core/database/database_helper.dart';
import '../blocs/product/product_bloc.dart';
import '../blocs/product/product_event.dart';
import '../blocs/product/product_state.dart';
import 'package:uuid/uuid.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;

  @override
  void initState() {
    super.initState();
    // Silent Refresh from CSV and Load products on enter
    _performSilentAutoImport();
  }

  Future<void> _performSilentAutoImport() async {
    try {
      final itemsDir = Directory('items');
      if (itemsDir.existsSync()) {
        final categoriesPath = p.join('items', 'categories_import.csv');
        final subCategoriesPath = p.join('items', 'sub_categories_import.csv');
        final itemsPath = p.join('items', 'items_import.csv');

        if (File(categoriesPath).existsSync() &&
            File(subCategoriesPath).existsSync() &&
            File(itemsPath).existsSync()) {
          // Import silently without showing snackbars or dialogs
          await DatabaseHelper().importDataFromCsv(
            categoriesPath: categoriesPath,
            subCategoriesPath: subCategoriesPath,
            itemsPath: itemsPath,
          );
        }
      }
    } catch (e) {
      debugPrint('Silent auto-import error: $e');
    } finally {
      // Always load products after sync attempt
      if (mounted) {
        context.read<ProductBloc>().add(const LoadProducts());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.items),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: ElevatedButton.icon(
              onPressed: () => _showImportItemsDialog(context, l10n),
              icon: const Icon(Icons.upload_file, size: 18),
              label: Text(l10n.importItemsButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: ElevatedButton.icon(
              onPressed: () => _showAddItemDialog(context, l10n),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(l10n.addItem),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, productState) {
          return Row(
            children: [
              // Categories Menu
              _buildCategoriesMenu(context, productState, l10n),
              // SubCategories Menu (if category selected)
              if (_selectedCategory != null)
                _buildSubCategoriesMenu(context, productState, l10n),
              // Items Menu (if subcategory selected)
              if (_selectedSubCategory != null)
                Expanded(child: _buildItemsMenu(context, productState, l10n)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showImportItemsDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final productBloc = context.read<ProductBloc>();

    await showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [BlocProvider<ProductBloc>.value(value: productBloc)],
        child: AlertDialog(
          title: Text(l10n.importFromExcel),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Import from 'items' Folder (New CSV Logic)
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _handleImportFromItemsFolder(context, l10n);
                  },
                  icon: const Icon(Icons.folder_shared, size: 20),
                  label: const Text('Import from "items" Folder (CSV)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Manual Categories (CSV)
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _handleImportCategoriesCsv(context, l10n);
                  },
                  icon: const Icon(Icons.category_outlined, size: 20),
                  label: Text('${l10n.importCategories} (CSV)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Manual Subcategories (CSV)
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _handleImportSubCategoriesCsv(context, l10n);
                  },
                  icon: const Icon(Icons.subdirectory_arrow_right, size: 20),
                  label: Text('${l10n.importSubCategories} (CSV)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Manual Items (CSV)
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _handleImportItemsCsv(context, l10n);
                  },
                  icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                  label: Text('${l10n.importItemsButton} (CSV)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.close),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImportFromItemsFolder(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    if (!mounted) return;
    try {
      // Look for the 'items' folder in the current directory (project root)
      final itemsDir = Directory('items');
      if (!itemsDir.existsSync()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find "items" folder in project root.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final categoriesPath = p.join('items', 'categories_import.csv');
      final subCategoriesPath = p.join('items', 'sub_categories_import.csv');
      final itemsPath = p.join('items', 'items_import.csv');

      if (!File(categoriesPath).existsSync() ||
          !File(subCategoriesPath).existsSync() ||
          !File(itemsPath).existsSync()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Some CSV files are missing in "items" folder.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final dbHelper = DatabaseHelper();
      await dbHelper.importDataFromCsv(
        categoriesPath: categoriesPath,
        subCategoriesPath: subCategoriesPath,
        itemsPath: itemsPath,
      );

      if (context.mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context); // Remove loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data imported successfully from "items" folder.'),
            backgroundColor: Colors.teal,
          ),
        );
        // Refresh products
        context.read<ProductBloc>().add(const LoadProducts());
      }
    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context))
          Navigator.pop(context); // Remove loading if active
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleImportCategoriesCsv(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;

    // Manual individual CSV import implementation...
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Manual CSV import not fully implemented yet. Use "Import from items Folder".',
        ),
      ),
    );
  }

  Future<void> _handleImportSubCategoriesCsv(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;
  }

  Future<void> _handleImportItemsCsv(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;
  }

  Future<void> _showEditItemDialog(
    BuildContext context,
    Item item,
    ProductState productState,
    AppLocalizations l10n,
  ) async {
    final productBloc = context.read<ProductBloc>();
    final priceController = TextEditingController(
      text: item.price.toStringAsFixed(2),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [BlocProvider<ProductBloc>.value(value: productBloc)],
        child: AlertDialog(
          title: Text('${l10n.editItem}: ${item.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.price,
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
                    hintText: l10n.enterPrice,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
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
                final price = double.tryParse(priceController.text);
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.enterPrice),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                try {
                  final dbHelper = DatabaseHelper();
                  await dbHelper.updateItemPriceAndStock(
                    item.id,
                    price,
                    item.stockQuantity,
                    item.stockUnit,
                  );

                  await Future.delayed(const Duration(milliseconds: 100));
                  productBloc.add(const LoadProducts());

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.itemUpdated),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating item: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    priceController.dispose();
  }

  Future<void> _showAddItemDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final productBloc = context.read<ProductBloc>();
    final productState = productBloc.state;

    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final categoryNameController = TextEditingController();
    final subCategoryNameController = TextEditingController();

    Category? selectedCategory;
    SubCategory? selectedSubCategory;
    bool createNewCategory = false;
    bool createNewSubCategory = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [BlocProvider<ProductBloc>.value(value: productBloc)],
        child: StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(l10n.addItem),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  Text(
                    l10n.itemName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      hintText: l10n.enterItemName,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Category Selection
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.category,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            DropdownButtonFormField<Category>(
                              // ignore: deprecated_member_use
                              value: selectedCategory,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.md,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                              ),
                              items: [
                                DropdownMenuItem<Category>(
                                  value: null,
                                  child: Text(l10n.createNewCategory),
                                ),
                                ...productState.categories.map((cat) {
                                  return DropdownMenuItem<Category>(
                                    value: cat,
                                    child: Text(cat.name),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedCategory = value;
                                  createNewCategory = value == null;
                                  selectedSubCategory = null;
                                  createNewSubCategory = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (createNewCategory) ...[
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.newCategoryName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              TextField(
                                controller: categoryNameController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.md,
                                    ),
                                  ),
                                  hintText: l10n.enterCategoryName,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Sub Category Selection
                  if (selectedCategory != null || createNewCategory) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.selectSubCategory,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              DropdownButtonFormField<SubCategory>(
                                // ignore: deprecated_member_use
                                value: selectedSubCategory,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.md,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem<SubCategory>(
                                    value: null,
                                    child: Text(l10n.createNewSubCategory),
                                  ),
                                  ...productState.subCategories
                                      .where(
                                        (sub) => selectedCategory != null
                                            ? sub.categoryId ==
                                                  selectedCategory!.id
                                            : true,
                                      )
                                      .map((sub) {
                                        return DropdownMenuItem<SubCategory>(
                                          value: sub,
                                          child: Text(sub.name),
                                        );
                                      }),
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedSubCategory = value;
                                    createNewSubCategory = value == null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        if (createNewSubCategory) ...[
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.newSubCategoryName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextField(
                                  controller: subCategoryNameController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppBorderRadius.md,
                                      ),
                                    ),
                                    hintText: l10n.enterSubCategoryName,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Price
                  Text(
                    l10n.price,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      hintText: l10n.enterPrice,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
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
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(l10n.enterItemName),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  if (createNewCategory &&
                      categoryNameController.text.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(l10n.pleaseEnterCategoryName),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  if (selectedCategory == null && !createNewCategory) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(l10n.category),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  if (createNewSubCategory &&
                      subCategoryNameController.text.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(l10n.pleaseEnterSubCategoryName),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  if ((selectedCategory == null || createNewCategory) &&
                      (selectedSubCategory == null && !createNewSubCategory)) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(l10n.selectSubCategory),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  final price = double.tryParse(priceController.text);
                  if (price == null || price <= 0) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(l10n.enterPrice),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  try {
                    final dbHelper = DatabaseHelper();
                    String finalCategoryId;
                    String finalSubCategoryId;

                    // Create category if needed
                    if (createNewCategory) {
                      finalCategoryId = DateTime.now().millisecondsSinceEpoch
                          .toString();
                      await dbHelper.insertCategories([
                        Category(
                          id: finalCategoryId,
                          name: categoryNameController.text,
                        ),
                      ]);
                    } else {
                      finalCategoryId = selectedCategory!.id;
                    }

                    // Create subcategory if needed
                    if (createNewSubCategory) {
                      finalSubCategoryId = DateTime.now().millisecondsSinceEpoch
                          .toString();
                      await dbHelper.insertSubCategories([
                        SubCategory(
                          id: finalSubCategoryId,
                          name: subCategoryNameController.text,
                          categoryId: finalCategoryId,
                        ),
                      ]);
                    } else {
                      finalSubCategoryId = selectedSubCategory!.id;
                    }

                    // Create item
                    final newItem = Item(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      subCategoryId: finalSubCategoryId,
                      price: price,
                      stockQuantity: 0.0,
                      stockUnit: 'number',
                      isPosOnly: true,
                    );

                    await dbHelper.insertItems([newItem]);
                    productBloc.add(const LoadProducts());

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.itemAdded),
                          backgroundColor: AppColors.secondary,
                        ),
                      );
                    }
                  } catch (e) {
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${l10n.errorAddingItem}: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );

    nameController.dispose();
    priceController.dispose();
    categoryNameController.dispose();
    subCategoryNameController.dispose();
  }

  Widget _buildCategoriesMenu(
    BuildContext context,
    ProductState productState,
    AppLocalizations l10n,
  ) {
    final categories = productState.categories;

    if (categories.isEmpty) {
      return Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(right: BorderSide(color: AppColors.border)),
        ),
        child: Center(
          child: Text(
            l10n.noCategories,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Row(
              children: [
                const Icon(Icons.category, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.category,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
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

  Widget _buildSubCategoriesMenu(
    BuildContext context,
    ProductState productState,
    AppLocalizations l10n,
  ) {
    if (_selectedCategory == null) {
      return const SizedBox.shrink();
    }

    final subCategories = productState.subCategories
        .where((sub) => sub.categoryId == _selectedCategory!.id)
        .toList();

    if (subCategories.isEmpty) {
      return Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(right: BorderSide(color: AppColors.border)),
        ),
        child: Center(
          child: Text(
            l10n.noSubcategories,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(color: AppColors.secondary),
            child: Row(
              children: [
                const Icon(Icons.folder, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.subCategory,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildItemsMenu(
    BuildContext context,
    ProductState productState,
    AppLocalizations l10n,
  ) {
    if (_selectedSubCategory == null) {
      return const SizedBox.shrink();
    }

    final items = productState.items
        .where((item) => item.subCategoryId == _selectedSubCategory!.id)
        .toList();

    if (items.isEmpty) {
      return Container(
        decoration: BoxDecoration(color: AppColors.surface),
        child: Center(
          child: Text(
            l10n.noItemsFound,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: AppColors.surface),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(color: AppColors.accent),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.items,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: () =>
                      _showEditItemDialog(context, item, productState, l10n),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                CurrencyFormatter.format(item.price),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.restaurant_menu, size: 20),
                          color: AppColors.primary,
                          onPressed: () =>
                              _showManageRecipeDialog(context, item, l10n),
                          tooltip: l10n.manageRecipe,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          color: AppColors.accent,
                          onPressed: () => _showEditItemDialog(
                            context,
                            item,
                            productState,
                            l10n,
                          ),
                          tooltip: l10n.edit,
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

  Future<void> _showManageRecipeDialog(
    BuildContext context,
    Item item,
    AppLocalizations l10n,
  ) async {
    final dbHelper = DatabaseHelper();
    Recipe? recipe = await dbHelper.getRecipeByItemId(item.id);
    final rawMaterials = await dbHelper.getAllRawMaterials();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('${l10n.manageRecipe} - ${item.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recipe == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        l10n.noRecipeFound,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    ...(recipe?.ingredients ?? []).map((ingredient) {
                      final material = rawMaterials.firstWhere(
                        (m) => m.id == ingredient.rawMaterialId,
                        orElse: () => RawMaterial(
                          id: '',
                          name: 'Unknown',
                          unit: 'number',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                      return ListTile(
                        title: Text(material.name),
                        subtitle: Text(
                          '${ingredient.quantity} ${material.unit}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () async {
                                await _showEditIngredientDialog(
                                  dialogContext,
                                  l10n,
                                  recipe!,
                                  ingredient,
                                  material,
                                  rawMaterials,
                                  () async {
                                    recipe = await dbHelper.getRecipeByItemId(
                                      item.id,
                                    );
                                    setDialogState(() {});
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                                color: AppColors.error,
                              ),
                              onPressed: () async {
                                await dbHelper.deleteRecipeIngredient(
                                  ingredient.id,
                                );
                                recipe = await dbHelper.getRecipeByItemId(
                                  item.id,
                                );
                                setDialogState(() {});
                                if (dialogContext.mounted) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.ingredientDeletedSuccessfully,
                                      ),
                                      backgroundColor: AppColors.secondary,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  const Divider(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (recipe == null) {
                        // Create new recipe
                        final newRecipe = Recipe(
                          id: const Uuid().v4(),
                          itemId: item.id,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        await dbHelper.insertRecipe(newRecipe);
                        recipe = await dbHelper.getRecipeByItemId(item.id);
                        setDialogState(() {});
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(l10n.recipeCreatedSuccessfully),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        }
                      }

                      // Add ingredient
                      await _showAddIngredientDialog(
                        dialogContext,
                        l10n,
                        recipe!,
                        rawMaterials,
                        () async {
                          recipe = await dbHelper.getRecipeByItemId(item.id);
                          setDialogState(() {});
                        },
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(
                      recipe == null ? l10n.createRecipe : l10n.addIngredient,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.close),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddIngredientDialog(
    BuildContext context,
    AppLocalizations l10n,
    Recipe recipe,
    List<RawMaterial> rawMaterials,
    VoidCallback onSuccess,
  ) async {
    final dbHelper = DatabaseHelper();
    RawMaterial? selectedMaterial;
    final quantityController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.addIngredient),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.selectRawMaterial,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<RawMaterial>(
                  initialValue: selectedMaterial,
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
                  items: rawMaterials.map((material) {
                    return DropdownMenuItem<RawMaterial>(
                      value: material,
                      child: Text(material.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMaterial = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.ingredientQuantity,
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
                    hintText: l10n.pleaseEnterIngredientQuantity,
                    suffixText: selectedMaterial?.unit ?? '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
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
                if (selectedMaterial == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseSelectRawMaterial),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                if (quantityController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseEnterIngredientQuantity),
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

                try {
                  final ingredient = RecipeIngredient(
                    id: const Uuid().v4(),
                    recipeId: recipe.id,
                    rawMaterialId: selectedMaterial!.id,
                    quantity: quantity,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  await dbHelper.insertRecipeIngredient(ingredient);
                  onSuccess();

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.ingredientAddedSuccessfully),
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
        ),
      ),
    );

    quantityController.dispose();
  }

  Future<void> _showEditIngredientDialog(
    BuildContext context,
    AppLocalizations l10n,
    Recipe recipe,
    RecipeIngredient ingredient,
    RawMaterial material,
    List<RawMaterial> rawMaterials,
    VoidCallback onSuccess,
  ) async {
    final dbHelper = DatabaseHelper();
    RawMaterial? selectedMaterial = material;
    final quantityController = TextEditingController(
      text: ingredient.quantity.toStringAsFixed(2),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.editIngredient),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.selectRawMaterial,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<RawMaterial>(
                  initialValue: selectedMaterial,
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
                  items: rawMaterials.map((material) {
                    return DropdownMenuItem<RawMaterial>(
                      value: material,
                      child: Text(material.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMaterial = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.ingredientQuantity,
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
                    hintText: l10n.pleaseEnterIngredientQuantity,
                    suffixText: selectedMaterial?.unit ?? '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
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
                if (selectedMaterial == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseSelectRawMaterial),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                if (quantityController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseEnterIngredientQuantity),
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

                try {
                  final updatedIngredient = ingredient.copyWith(
                    rawMaterialId: selectedMaterial!.id,
                    quantity: quantity,
                    updatedAt: DateTime.now(),
                  );

                  await dbHelper.updateRecipeIngredient(updatedIngredient);
                  onSuccess();

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.ingredientUpdatedSuccessfully),
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
        ),
      ),
    );

    quantityController.dispose();
  }
}
