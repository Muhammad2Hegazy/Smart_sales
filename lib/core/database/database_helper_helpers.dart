part of 'database_helper.dart';

extension DatabaseHelperHelpers on DatabaseHelper {
  /// Format stock quantity for smart display
  /// Returns formatted string with the most meaningful unit
  Future<Map<String, String>> formatStockForDisplay(String rawMaterialId) async {
    final material = await getRawMaterialById(rawMaterialId);
    if (material == null) {
      throw Exception('Raw material not found: $rawMaterialId');
    }

    final totalQuantity = material.totalQuantity;
    debugPrint('formatStockForDisplay: ${material.name}, baseUnit: ${material.baseUnit}, totalQuantity: $totalQuantity');
    String quantityDisplay;
    String unitDisplay;

    if (material.baseUnit == 'gram') {
      // Weight-based: show kg if >= 1000g, otherwise grams
      if (totalQuantity >= 1000) {
        final kilos = totalQuantity / 1000.0;
        final remainingGrams = (totalQuantity % 1000).round();
        if (remainingGrams > 0) {
          quantityDisplay = '${kilos.toStringAsFixed(0)} كيلو\n$remainingGrams جرام';
        } else {
          quantityDisplay = '${kilos.toStringAsFixed(2)} كيلو';
        }
        unitDisplay = 'كيلو / جرام';
      } else {
        quantityDisplay = totalQuantity.toStringAsFixed(2);
        unitDisplay = 'جرام';
      }
    } else if (material.baseUnit == 'ml') {
      // Volume-based: show liters if >= 1000ml, otherwise ml
      if (totalQuantity >= 1000) {
        final liters = totalQuantity / 1000.0;
        final remainingMl = (totalQuantity % 1000).round();
        if (remainingMl > 0) {
          quantityDisplay = '${liters.toStringAsFixed(0)} لتر\n$remainingMl مل';
        } else {
          quantityDisplay = '${liters.toStringAsFixed(2)} لتر';
        }
        unitDisplay = 'لتر / مل';
      } else {
        quantityDisplay = totalQuantity.toStringAsFixed(2);
        unitDisplay = 'مل';
      }
    } else if (material.baseUnit == 'carton') {
      // Carton-based: show cartons + remaining bottles
      unitDisplay = 'كرتونة / زجاجة';
      
      if (totalQuantity <= 0) {
        // Out of stock - still show correct unit
        quantityDisplay = '0';
      } else {
        final units = await getRawMaterialUnits(rawMaterialId);
        final bottleUnit = units.firstWhere(
          (u) => u.unit == 'bottle' || u.unit == 'زجاجة',
          orElse: () => RawMaterialUnit(
            id: '',
            rawMaterialId: rawMaterialId,
            unit: 'bottle',
            conversionFactorToBase: 1.0 / 20.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final bottlesPerCarton = (1.0 / bottleUnit.conversionFactorToBase).round();
        final totalBottles = (totalQuantity * bottlesPerCarton).round();
        final cartons = (totalBottles / bottlesPerCarton).floor();
        final remainingBottles = totalBottles % bottlesPerCarton;

        if (cartons > 0 && remainingBottles > 0) {
          quantityDisplay = '$cartons كرتونة ($bottlesPerCarton)\n+ $remainingBottles زجاجة';
        } else if (cartons > 0) {
          quantityDisplay = '$cartons كرتونة ($bottlesPerCarton)';
        } else if (totalBottles > 0) {
          quantityDisplay = '$totalBottles زجاجة';
        } else {
          quantityDisplay = '0';
        }
      }
    } else if (material.baseUnit == 'packet') {
      // Packet-based: totalQuantity is in packets (base unit)
      // 1 packet = 10kg = 10000g
      final totalPackets = totalQuantity;
      final wholePackets = totalPackets.floor();
      final fractionalPackets = totalPackets - wholePackets;
      final remainingKg = fractionalPackets * 10.0; // 1 packet = 10kg

      if (wholePackets > 0 && remainingKg > 0.01) {
        quantityDisplay = '$wholePackets باكيت\n+ ${remainingKg.toStringAsFixed(2)} كيلو';
      } else if (wholePackets > 0) {
        quantityDisplay = '$wholePackets باكيت';
      } else if (remainingKg > 0.01) {
        quantityDisplay = '${remainingKg.toStringAsFixed(2)} كيلو';
      } else {
        quantityDisplay = '0';
      }
      unitDisplay = 'باكيت / كيلو';
    } else if (material.baseUnit == 'jar') {
      // Jar-based: show strictly as jars
      quantityDisplay = totalQuantity.toStringAsFixed(0);
      unitDisplay = 'جرة';
    } else if (material.baseUnit == 'piece') {
      // Piece-based
      quantityDisplay = totalQuantity.toStringAsFixed(0);
      unitDisplay = 'قطعة';
    } else {
      // Default
      quantityDisplay = totalQuantity.toStringAsFixed(2);
      unitDisplay = material.baseUnit;
    }

    return {
      'quantity': quantityDisplay,
      'unit': unitDisplay,
    };
  }

  /// Automatically import data from CSV files
  Future<void> importDataFromCsv({
    required String categoriesPath,
    required String subCategoriesPath,
    required String itemsPath,
  }) async {
    final result = await CsvImporter.importFromCsv(
      categoriesPath: categoriesPath,
      subCategoriesPath: subCategoriesPath,
      itemsPath: itemsPath,
    );

    final db = await database;
    final batch = db.batch();

    // Get master device ID if exists
    final masters = await db.query('masters');
    final masterDeviceId = masters.isNotEmpty
        ? masters.first['master_device_id'] as String
        : '';
    final now = DateTime.now().toIso8601String();

    // 1. Categories
    for (var cat in result.categories) {
      batch.insert('categories', {
        'id': cat.id,
        'name': cat.name,
        'master_device_id': masterDeviceId,
        'sync_status': 'pending',
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 2. Subcategories
    for (var sub in result.subCategories) {
      batch.insert('sub_categories', {
        'id': sub.id,
        'category_id': sub.categoryId,
        'name': sub.name,
        'master_device_id': masterDeviceId,
        'sync_status': 'pending',
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 3. Items
    for (var item in result.items) {
      batch.insert('items', {
        'id': item.id,
        'name': item.name,
        'sub_category_id': item.subCategoryId,
        'price': item.price,
        'has_notes': 0,
        'stock_quantity': 0.0,
        'stock_unit': item.stockUnit,
        'is_pos_only': item.isPosOnly ? 1 : 0,
        'master_device_id': masterDeviceId,
        'sync_status': 'pending',
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Automatically import inventory data (raw materials) from CSV files
  Future<void> importInventoryFromCsv({
    required String categoriesPath,
    required String subCategoriesPath,
    required String rawMaterialsPath,
  }) async {
    final result = await CsvImporter.importInventoryFromCsv(
      categoriesPath: categoriesPath,
      subCategoriesPath: subCategoriesPath,
      rawMaterialsPath: rawMaterialsPath,
    );

    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    // 1. Raw Material Categories
    for (var cat in result.categories) {
      batch.insert('raw_material_categories', {
        'id': cat.id,
        'name': cat.name,
        'created_at': cat.createdAt.toIso8601String(),
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 2. Raw Material Subcategories
    for (var sub in result.subCategories) {
      batch.insert('raw_material_sub_categories', {
        'id': sub.id,
        'category_id': sub.categoryId,
        'name': sub.name,
        'created_at': sub.createdAt.toIso8601String(),
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 3. Raw Materials
    for (var material in result.rawMaterials) {
      batch.insert('raw_materials', {
        'id': material.id,
        'name': material.name,
        'sub_category_id': material.subCategoryId,
        'unit': material.unit,
        'base_unit': material.baseUnit,
        'stock_quantity': material.stockQuantity,
        'minimum_alert_quantity': material.minimumAlertQuantity,
        'created_at': material.createdAt.toIso8601String(),
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }
}
