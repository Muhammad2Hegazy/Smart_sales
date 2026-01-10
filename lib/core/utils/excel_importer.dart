import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../models/item.dart';
import '../models/note.dart';

/// Result of importing items with categories and subcategories
class ImportResult {
  final List<Category> categories;
  final List<SubCategory> subCategories;
  final List<Item> items;

  ImportResult({
    required this.categories,
    required this.subCategories,
    required this.items,
  });
}

class ExcelImporter {
  static Future<FilePickerResult?> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    return result;
  }

  static Future<List<Category>> importCategories(String filePath) async {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final categories = <Category>[];

    // Look for "Category" or "Categories" sheet first, otherwise use first sheet
    var sheetName = excel.tables.keys.firstWhere(
      (name) => name.toLowerCase().contains('categor'),
      orElse: () => excel.tables.keys.first,
    );
    
    final sheet = excel.tables[sheetName]!;
    
    // Skip header row (row 0)
    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.rows[rowIndex];
      if (row.isEmpty) continue;
      
      // Format 1: Column A = ID, Column B = Name
      // Format 2: Column A = TypeID, Column B = Category Code, Column C = Name
      
      if (row.length >= 2) {
        String id = '';
        String name = '';
        
        // Check if Column C exists and has data (Format 2)
        if (row.length >= 3 && row[2] != null && row[2]!.value != null) {
          // Format 2: Column A = TypeID, Column B = Category Code, Column C = Name
          final idCell = row[0];
          if (idCell != null && idCell.value != null) {
            id = idCell.value.toString();
          }
          
          final nameCell = row[2]; // Column C
          name = (nameCell?.value?.toString() ?? '').trim();
        } else {
          // Format 1: Column A = ID, Column B = Name
          final idCell = row[0];
          if (idCell != null && idCell.value != null) {
            id = idCell.value.toString();
          }
          
          final nameCell = row[1];
          name = (nameCell?.value?.toString() ?? '').trim();
        }
        
        // Skip if name is empty
        if (name.isEmpty) continue;
        
        categories.add(
          Category(
            id: id,
            name: name,
          ),
        );
      }
    }

    return categories;
  }

  static Future<List<SubCategory>> importSubCategories(String filePath) async {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final subCategories = <SubCategory>[];

    // Look for "SubCategory" or "SubCategories" sheet first, otherwise use first sheet
    var sheetName = excel.tables.keys.firstWhere(
      (name) => name.toLowerCase().contains('subcategor') || 
                name.toLowerCase().contains('sub categor') ||
                name.toLowerCase().contains('type'),
      orElse: () => excel.tables.keys.first,
    );
    
    final sheet = excel.tables[sheetName]!;
    
    // Skip header row (row 0)
    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.rows[rowIndex];
      if (row.isEmpty) continue;
      
      // Format: Column A = TypeID, Column B = Category Code, Column C = Name
      
      if (row.length >= 3) {
        // Get ID - Column A (TypeID)
        final idCell = row[0];
        String id = '';
        if (idCell != null && idCell.value != null) {
          id = idCell.value.toString();
        }
        
        // Get Category ID - Column B (Category Code)
        final categoryIdCell = row[1];
        String categoryId = '';
        if (categoryIdCell != null && categoryIdCell.value != null) {
          categoryId = categoryIdCell.value.toString();
        }
        
        // Get Name - Column C (Name)
        final nameCell = row[2];
        final name = (nameCell?.value?.toString() ?? '').trim();
        
        // Skip if name is empty
        if (name.isEmpty) continue;
        
        subCategories.add(
          SubCategory(
            id: id,
            name: name,
            categoryId: categoryId,
          ),
        );
      }
    }

    return subCategories;
  }

  static Future<List<Item>> importItems(String filePath, {bool isPosOnly = false}) async {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final items = <Item>[];

    // Look for "Items" sheet first, otherwise use first sheet
    var sheetName = excel.tables.keys.firstWhere(
      (name) => name.toLowerCase().contains('item'),
      orElse: () => excel.tables.keys.first,
    );
    
    final sheet = excel.tables[sheetName]!;
    
    // Skip header row (row 0)
    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.rows[rowIndex];
      if (row.isEmpty) continue;
      
      // Format: Column C = Item Code (ID), Column E = Item Name, Column J = Category, Column K = Type (Sub Category), Column L = Price
      // Column indices: C=2, E=4, J=9, K=10, L=11
      
      if (row.length >= 12) {
        // Get ID - Column C (index 2) - Item Code
        final idCell = row[2];
        String id = '';
        if (idCell != null && idCell.value != null) {
          id = idCell.value.toString();
        }
        
        // Get Name - Column E (index 4) - Item Name
        final nameCell = row[4];
        final name = (nameCell?.value?.toString() ?? '').trim();
        
        // Skip if name is empty
        if (name.isEmpty) continue;
        
        // Get Sub Category ID - Column K (index 10) - Type
        final subCategoryIdCell = row[10];
        String subCategoryId = '';
        if (subCategoryIdCell != null && subCategoryIdCell.value != null) {
          subCategoryId = subCategoryIdCell.value.toString();
        }
        
        // Get Price - Column L (index 11) - Unit Price
        final priceCell = row[11];
        double price = 0.0;
        if (priceCell != null && priceCell.value != null) {
          final priceStr = priceCell.value.toString();
          price = double.tryParse(priceStr) ?? 0.0;
        }
        
        // Has Notes - Check if item has notes (we'll link this when notes are imported)
        bool hasNotes = false;

        items.add(
          Item(
            id: id,
            name: name,
            subCategoryId: subCategoryId,
            price: price,
            hasNotes: hasNotes,
            stockQuantity: 0.0,
            stockUnit: 'number',
            isPosOnly: isPosOnly,
          ),
        );
      }
    }

    return items;
  }

  /// Import items with categories and subcategories from the same Excel file
  /// This function extracts categories from Column J and subcategories from Column K
  /// and creates them automatically if they don't exist
  static Future<ImportResult> importItemsWithCategories(
    String filePath, {
    bool isPosOnly = false,
  }) async {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    // Look for "Items" sheet first, otherwise use first sheet
    var sheetName = excel.tables.keys.firstWhere(
      (name) => name.toLowerCase().contains('item'),
      orElse: () => excel.tables.keys.first,
    );
    
    final sheet = excel.tables[sheetName]!;
    
    // Maps to track unique categories and subcategories
    final categoryMap = <String, String>{}; // category name -> category ID
    final subCategoryMap = <String, Map<String, String>>{}; // category ID -> (subcategory name -> subcategory ID)
    final items = <Item>[];
    int categoryCounter = 1;
    int subCategoryCounter = 1;
    
    // First pass: collect all unique categories and subcategories
    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.rows[rowIndex];
      if (row.isEmpty) continue;
      
      if (row.length >= 12) {
        // Get Category Name - Column J (index 9)
        final categoryCell = row[9];
        String categoryName = '';
        if (categoryCell != null && categoryCell.value != null) {
          categoryName = (categoryCell.value.toString()).trim();
        }
        
        // Get Sub Category Name - Column K (index 10) - Type
        final subCategoryCell = row[10];
        String subCategoryName = '';
        if (subCategoryCell != null && subCategoryCell.value != null) {
          subCategoryName = (subCategoryCell.value.toString()).trim();
        }
        
        // Skip if both are empty
        if (categoryName.isEmpty && subCategoryName.isEmpty) continue;
        
        // Create category if it doesn't exist
        if (categoryName.isNotEmpty && !categoryMap.containsKey(categoryName)) {
          final categoryId = 'cat_${DateTime.now().millisecondsSinceEpoch}_$categoryCounter';
          categoryMap[categoryName] = categoryId;
          categoryCounter++;
        }
        
        // Create subcategory if it doesn't exist
        if (categoryName.isNotEmpty && subCategoryName.isNotEmpty) {
          final categoryId = categoryMap[categoryName]!;
          if (!subCategoryMap.containsKey(categoryId)) {
            subCategoryMap[categoryId] = <String, String>{};
          }
          if (!subCategoryMap[categoryId]!.containsKey(subCategoryName)) {
            final subCategoryId = 'subcat_${DateTime.now().millisecondsSinceEpoch}_$subCategoryCounter';
            subCategoryMap[categoryId]![subCategoryName] = subCategoryId;
            subCategoryCounter++;
          }
        }
      }
    }
    
    // Build Category and SubCategory lists
    final categories = categoryMap.entries.map((entry) {
      return Category(
        id: entry.value,
        name: entry.key,
      );
    }).toList();
    
    final subCategories = <SubCategory>[];
    subCategoryMap.forEach((categoryId, subCategoryNameMap) {
      subCategoryNameMap.forEach((subCategoryName, subCategoryId) {
        subCategories.add(
          SubCategory(
            id: subCategoryId,
            name: subCategoryName,
            categoryId: categoryId,
          ),
        );
      });
    });
    
    // Second pass: import items with proper subcategory IDs
    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.rows[rowIndex];
      if (row.isEmpty) continue;
      
      if (row.length >= 12) {
        // Get ID - Column C (index 2) - Item Code
        final idCell = row[2];
        String id = '';
        if (idCell != null && idCell.value != null) {
          id = idCell.value.toString();
        }
        
        // Get Name - Column E (index 4) - Item Name
        final nameCell = row[4];
        final name = (nameCell?.value?.toString() ?? '').trim();
        
        // Skip if name is empty
        if (name.isEmpty) continue;
        
        // Get Category Name - Column J (index 9)
        final categoryCell = row[9];
        String categoryName = '';
        if (categoryCell != null && categoryCell.value != null) {
          categoryName = (categoryCell.value.toString()).trim();
        }
        
        // Get Sub Category Name - Column K (index 10) - Type
        final subCategoryCell = row[10];
        String subCategoryName = '';
        if (subCategoryCell != null && subCategoryCell.value != null) {
          subCategoryName = (subCategoryCell.value.toString()).trim();
        }
        
        // Find subcategory ID
        String subCategoryId = '';
        if (categoryName.isNotEmpty && subCategoryName.isNotEmpty) {
          final categoryId = categoryMap[categoryName];
          if (categoryId != null && subCategoryMap.containsKey(categoryId)) {
            subCategoryId = subCategoryMap[categoryId]![subCategoryName] ?? '';
          }
        }
        
        // Get Price - Column L (index 11) - Unit Price
        final priceCell = row[11];
        double price = 0.0;
        if (priceCell != null && priceCell.value != null) {
          final priceStr = priceCell.value.toString();
          price = double.tryParse(priceStr) ?? 0.0;
        }
        
        // Has Notes - Check if item has notes (we'll link this when notes are imported)
        bool hasNotes = false;

        items.add(
          Item(
            id: id,
            name: name,
            subCategoryId: subCategoryId,
            price: price,
            hasNotes: hasNotes,
            stockQuantity: 0.0,
            stockUnit: 'number',
            isPosOnly: isPosOnly,
          ),
        );
      }
    }

    return ImportResult(
      categories: categories,
      subCategories: subCategories,
      items: items,
    );
  }
  
  // Import raw materials (same format as items but isPosOnly = false)
  static Future<List<Item>> importRawMaterials(String filePath) async {
    return importItems(filePath, isPosOnly: false);
  }

  static Future<List<Note>> importNotes(String filePath) async {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final notes = <Note>[];

    // Look for "Note" or "Notes" sheet first, otherwise use first sheet
    var sheetName = excel.tables.keys.firstWhere(
      (name) => name.toLowerCase().contains('note') ||
                name.toLowerCase().contains('ملاحظات'),
      orElse: () => excel.tables.keys.first,
    );
    
    final sheet = excel.tables[sheetName]!;
    
    // Check if first row has header in Column A
    bool isSimpleFormat = false;
    if (sheet.rows.isNotEmpty && sheet.rows[0].isNotEmpty) {
      final headerCell = sheet.rows[0][0];
      if (headerCell != null && headerCell.value != null) {
        final header = headerCell.value.toString().toLowerCase();
        if (header.contains('note') || header.contains('ملاحظات')) {
          isSimpleFormat = true;
        }
      }
    }
    
    if (isSimpleFormat) {
      // Simple format: Column B contains note text starting from row 4 (index 3)
      for (var rowIndex = 3; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.rows[rowIndex];
        if (row.isEmpty || row.length < 2) continue;
        
        // Get Text - Column B (index 1)
        final textCell = row[1];
        final text = (textCell?.value?.toString() ?? '').trim();
        
        // Skip if text is empty
        if (text.isEmpty) continue;
        
        // Generate ID
        final id = 'note_${rowIndex}_${notes.length}';
        
        notes.add(
          Note(
            id: id,
            itemId: '', // Will be linked when items are imported
            text: text,
          ),
        );
      }
    } else {
      // Standard format: Column A = ID, Column B = Item ID, Column C = Text
      for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.rows[rowIndex];
        if (row.isEmpty) continue;
        
        if (row.length >= 3) {
          // Get ID - Column A (index 0)
          final idCell = row[0];
          String id = '';
          if (idCell != null && idCell.value != null) {
            id = idCell.value.toString();
          }
          
          // Get Item ID - Column B (index 1)
          final itemIdCell = row[1];
          String itemId = '';
          if (itemIdCell != null && itemIdCell.value != null) {
            itemId = itemIdCell.value.toString();
          }
          
          // Get Text - Column C (index 2)
          final textCell = row[2];
          final text = (textCell?.value?.toString() ?? '').trim();
          
          // Skip if text is empty
          if (text.isEmpty) continue;
          
          notes.add(
            Note(
              id: id,
              itemId: itemId,
              text: text,
            ),
          );
        }
      }
    }

    return notes;
  }
}

