import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../models/item.dart';
import '../models/import_result.dart';
import '../models/raw_material.dart';
import '../models/raw_material_category.dart';
import '../models/raw_material_sub_category.dart';
import '../models/inventory_import_result.dart';

class CsvImporter {
  static Future<ImportResult> importFromCsv({
    required String categoriesPath,
    required String subCategoriesPath,
    required String itemsPath,
    bool isPosOnly = true,
  }) async {
    final categories = await _importCategories(categoriesPath);
    final subCategories = await _importSubCategories(subCategoriesPath);
    final items = await _importItems(itemsPath, isPosOnly: isPosOnly);

    return ImportResult(
      categories: categories,
      subCategories: subCategories,
      items: items,
    );
  }

  static Future<InventoryImportResult> importInventoryFromCsv({
    required String categoriesPath,
    required String subCategoriesPath,
    required String rawMaterialsPath,
  }) async {
    final categories = await _importRawMaterialCategories(categoriesPath);
    final subCategories = await _importRawMaterialSubCategories(subCategoriesPath);
    final rawMaterials = await _importRawMaterials(rawMaterialsPath);

    return InventoryImportResult(
      categories: categories,
      subCategories: subCategories,
      rawMaterials: rawMaterials,
    );
  }

  static Future<List<Item>> importRawMaterialsCsv(String filePath) async {
    return _importItems(filePath, isPosOnly: false);
  }

  static Future<List<Category>> _importCategories(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final content = utf8.decode(bytes, allowMalformed: true);
    final fields = const CsvToListConverter().convert(content);

    if (fields.isEmpty) return [];

    final categories = <Category>[];
    // Skip header
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 2) continue;

      final id = row[0].toString().trim().replaceAll('.0', '');
      final name = row[1].toString().trim();

      if (id.isEmpty || name.isEmpty) continue;

      categories.add(Category(id: id, name: name));
    }
    return categories;
  }

  static Future<List<SubCategory>> _importSubCategories(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final content = utf8.decode(bytes, allowMalformed: true);
    final fields = const CsvToListConverter().convert(content);

    if (fields.isEmpty) return [];

    final subCategories = <SubCategory>[];
    // Skip header
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 3) continue;

      final id = row[0].toString().trim().replaceAll('.0', '');
      final categoryId = row[1].toString().trim().replaceAll('.0', '');
      final name = row[2].toString().trim();

      if (id.isEmpty || name.isEmpty) continue;

      subCategories.add(
        SubCategory(id: id, categoryId: categoryId, name: name),
      );
    }
    return subCategories;
  }

  static Future<List<Item>> _importItems(
    String filePath, {
    bool isPosOnly = true,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final content = utf8.decode(bytes, allowMalformed: true);
    final fields = const CsvToListConverter().convert(content);

    if (fields.isEmpty) return [];

    final items = <Item>[];
    // Skip header
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 12) continue;

      // REVISED MAPPING based on sample data analysis:
      // Index 1: Long Item Identifier (e.g., 12020001)
      // Index 2: SUB-CATEGORY ID (e.g., 1, 926, 927) <- This matches SC ID in sub_categories_import.csv
      // Index 3: ITEM CODE / ID (e.g., 9999.0)
      // Index 4: ITEM NAME (اسم الصنف)
      // Index 5: STOCK UNIT (الوحده)
      // Index 10: CATEGORY ID (e.g., 1.0) <- This correlates to Category ID, not SubCategory.
      // Index 11: UNIT PRICE (سعر الوحده)

      final id = row[3].toString().trim().replaceAll('.0', '');
      final name = row[4].toString().trim();
      final subCategoryId = row[2].toString().trim().replaceAll(
        '.0',
        '',
      ); // Correctly map to SubCategory
      final stockUnit = row[5].toString().trim();
      final priceStr = row[11].toString().trim();
      final price = double.tryParse(priceStr) ?? 0.0;

      if (id.isEmpty || name.isEmpty) continue;

      items.add(
        Item(
          id: id,
          name: name,
          subCategoryId: subCategoryId,
          price: price,
          stockUnit: stockUnit,
          isPosOnly: isPosOnly,
        ),
      );
    }
    return items;
  }

  static Future<List<RawMaterialCategory>> _importRawMaterialCategories(String filePath) async {
    if (!File(filePath).existsSync()) return [];
    final bytes = await File(filePath).readAsBytes();
    final content = utf8.decode(bytes, allowMalformed: true);
    final fields = const CsvToListConverter().convert(content);

    if (fields.isEmpty) return [];

    final categories = <RawMaterialCategory>[];
    final now = DateTime.now();
    // Skip header
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 2) continue;

      final id = row[0].toString().trim().replaceAll('.0', '');
      final name = row[1].toString().trim();

      if (id.isEmpty || name.isEmpty) continue;

      categories.add(RawMaterialCategory(
        id: id,
        name: name,
        createdAt: now,
        updatedAt: now,
      ));
    }
    return categories;
  }

  static Future<List<RawMaterialSubCategory>> _importRawMaterialSubCategories(String filePath) async {
    if (!File(filePath).existsSync()) return [];
    final bytes = await File(filePath).readAsBytes();
    final content = utf8.decode(bytes, allowMalformed: true);
    final fields = const CsvToListConverter().convert(content);

    if (fields.isEmpty) return [];

    final subCategories = <RawMaterialSubCategory>[];
    final now = DateTime.now();
    // Skip header
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 3) continue;

      final id = row[0].toString().trim().replaceAll('.0', '');
      final categoryId = row[1].toString().trim().replaceAll('.0', '');
      final name = row[2].toString().trim();

      if (id.isEmpty || name.isEmpty) continue;

      subCategories.add(
        RawMaterialSubCategory(
          id: id,
          categoryId: categoryId,
          name: name,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    return subCategories;
  }

  static Future<List<RawMaterial>> _importRawMaterials(String filePath) async {
    if (!File(filePath).existsSync()) return [];
    final bytes = await File(filePath).readAsBytes();
    final content = utf8.decode(bytes, allowMalformed: true);
    final fields = const CsvToListConverter().convert(content);

    if (fields.isEmpty) return [];

    final rawMaterials = <RawMaterial>[];
    final now = DateTime.now();
    // Skip header
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 6) continue;

      // Expected columns: id, name, subCategoryId, unit, baseUnit, minimumAlertQuantity
      final id = row[0].toString().trim().replaceAll('.0', '');
      final name = row[1].toString().trim();
      final subCategoryId = row[2].toString().trim().replaceAll('.0', '');
      final unit = row[3].toString().trim();
      final baseUnit = row[4].toString().trim();
      final minAlertQtyStr = row[5].toString().trim();
      final minAlertQty = double.tryParse(minAlertQtyStr) ?? 0.0;

      if (id.isEmpty || name.isEmpty) continue;

      rawMaterials.add(
        RawMaterial(
          id: id,
          name: name,
          subCategoryId: subCategoryId,
          unit: unit,
          baseUnit: baseUnit,
          minimumAlertQuantity: minAlertQty,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    return rawMaterials;
  }

  static Future<String> exportInventoryToCsv(List<RawMaterial> materials) async {
    final List<List<dynamic>> rows = [];
    
    // Add header
    rows.add([
      'id',
      'name',
      'subCategoryId',
      'unit',
      'baseUnit',
      'minimumAlertQuantity'
    ]);

    for (var material in materials) {
      rows.add([
        material.id,
        material.name,
        material.subCategoryId,
        material.unit,
        material.baseUnit,
        material.minimumAlertQuantity,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  static Future<String> exportRawMaterialCategoriesToCsv(List<RawMaterialCategory> categories) async {
    final List<List<dynamic>> rows = [];
    
    // Add header
    rows.add(['id', 'name']);

    for (var cat in categories) {
      rows.add([cat.id, cat.name]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  static Future<String> exportRawMaterialSubCategoriesToCsv(List<RawMaterialSubCategory> subCategories) async {
    final List<List<dynamic>> rows = [];
    
    // Add header
    rows.add(['id', 'categoryId', 'name']);

    for (var sub in subCategories) {
      rows.add([sub.id, sub.categoryId, sub.name]);
    }

    return const ListToCsvConverter().convert(rows);
  }
}
