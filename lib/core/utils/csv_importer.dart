import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../models/item.dart';
import '../models/import_result.dart';

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
      // Index 2: ITEM CODE / ID (كود الصنف)
      // Index 3: BARCODE (باركود)
      // Index 4: ITEM NAME (اسم الصنف)
      // Index 5: STOCK UNIT (الوحده)
      // Index 10: SUB-CATEGORY ID (النوع) <- This matches TypeID in sub_categories_import.csv
      // Index 11: UNIT PRICE (سعر الوحده)

      final id = row[2].toString().trim().replaceAll('.0', '');
      final name = row[4].toString().trim();
      final subCategoryId = row[10].toString().trim().replaceAll(
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
}
