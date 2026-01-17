import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'base_dao.dart';
import '../models/raw_material.dart';
import '../models/raw_material_category.dart';
import '../models/raw_material_sub_category.dart';
import '../models/raw_material_batch.dart';
import '../models/raw_material_unit.dart';

/// Data Access Object for Raw Materials operations
class RawMaterialsDao extends BaseDao {

  // ============ Raw Material Categories ============

  /// Insert a raw material category
  Future<void> insertRawMaterialCategory(RawMaterialCategory category) async {
    final db = await database;
    await db.insert(
      'raw_material_categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all raw material categories
  Future<List<RawMaterialCategory>> getAllRawMaterialCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('raw_material_categories');
    return maps.map((map) => RawMaterialCategory.fromMap(map)).toList();
  }

  /// Delete a raw material category
  Future<void> deleteRawMaterialCategory(String id) async {
    final db = await database;
    await db.delete('raw_material_categories', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Raw Material SubCategories ============

  /// Insert a raw material subcategory
  Future<void> insertRawMaterialSubCategory(RawMaterialSubCategory subCategory) async {
    final db = await database;
    await db.insert(
      'raw_material_sub_categories',
      subCategory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all raw material subcategories
  Future<List<RawMaterialSubCategory>> getAllRawMaterialSubCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('raw_material_sub_categories');
    return maps.map((map) => RawMaterialSubCategory.fromMap(map)).toList();
  }

  /// Get raw material subcategories by category ID
  Future<List<RawMaterialSubCategory>> getRawMaterialSubCategoriesByCategoryId(String categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_material_sub_categories',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return maps.map((map) => RawMaterialSubCategory.fromMap(map)).toList();
  }

  /// Delete a raw material subcategory
  Future<void> deleteRawMaterialSubCategory(String id) async {
    final db = await database;
    await db.delete('raw_material_sub_categories', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Raw Materials ============

  /// Insert a raw material
  Future<void> insertRawMaterial(RawMaterial material) async {
    final db = await database;
    await db.insert(
      'raw_materials',
      material.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple raw materials
  Future<void> insertRawMaterials(List<RawMaterial> materials) async {
    final db = await database;
    final batch = db.batch();
    for (var material in materials) {
      batch.insert('raw_materials', material.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Get all raw materials
  Future<List<RawMaterial>> getAllRawMaterials() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('raw_materials');
    return maps.map((map) => RawMaterial.fromMap(map)).toList();
  }

  /// Get raw materials by subcategory ID
  Future<List<RawMaterial>> getRawMaterialsBySubCategoryId(String subCategoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_materials',
      where: 'sub_category_id = ?',
      whereArgs: [subCategoryId],
    );
    return maps.map((map) => RawMaterial.fromMap(map)).toList();
  }

  /// Delete all raw materials
  Future<void> deleteAllRawMaterials() async {
    final db = await database;
    await db.delete('raw_material_batches');
    await db.delete('raw_materials');
  }

  /// Get raw material by ID
  Future<RawMaterial?> getRawMaterialById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_materials',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RawMaterial.fromMap(maps.first);
  }

  /// Update a raw material
  Future<void> updateRawMaterial(RawMaterial material) async {
    final db = await database;
    await db.update(
      'raw_materials',
      material.toMap(),
      where: 'id = ?',
      whereArgs: [material.id],
    );
  }

  /// Delete a raw material
  Future<void> deleteRawMaterial(String id) async {
    final db = await database;
    await db.delete('raw_materials', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Raw Material Batches ============

  /// Insert a raw material batch
  Future<void> insertRawMaterialBatch(RawMaterialBatch batch) async {
    final db = await database;
    await db.insert(
      'raw_material_batches',
      batch.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // After inserting, recalculate stock quantity
    await _recalculateStockQuantity(batch.rawMaterialId);
  }

  /// Insert multiple raw material batches
  Future<void> insertRawMaterialBatches(List<RawMaterialBatch> batches) async {
    final db = await database;
    final batch = db.batch();
    for (var b in batches) {
      batch.insert('raw_material_batches', b.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Get raw material batches by raw material ID
  Future<List<RawMaterialBatch>> getRawMaterialBatches(String rawMaterialId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_material_batches',
      where: 'raw_material_id = ?',
      whereArgs: [rawMaterialId],
    );
    return maps.map((map) => RawMaterialBatch.fromMap(map)).toList();
  }

  /// Get raw material batch by ID
  Future<RawMaterialBatch?> getRawMaterialBatchById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_material_batches',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RawMaterialBatch.fromMap(maps.first);
  }

  /// Update a raw material batch
  Future<void> updateRawMaterialBatch(RawMaterialBatch batch) async {
    final db = await database;
    await db.update(
      'raw_material_batches',
      batch.toMap(),
      where: 'id = ?',
      whereArgs: [batch.id],
    );
    
    // After updating, recalculate stock quantity
    await _recalculateStockQuantity(batch.rawMaterialId);
  }

  /// Recalculate stock quantity from all batches
  Future<void> _recalculateStockQuantity(String rawMaterialId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity) as total FROM raw_material_batches WHERE raw_material_id = ?',
      [rawMaterialId],
    );
    final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    await db.update(
      'raw_materials',
      {'stock_quantity': total},
      where: 'id = ?',
      whereArgs: [rawMaterialId],
    );
  }

  /// Delete a raw material batch
  Future<void> deleteRawMaterialBatch(String id) async {
    final db = await database;
    
    // Get batch info first
    final batch = await getRawMaterialBatchById(id);
    if (batch == null) return;
    
    await db.delete('raw_material_batches', where: 'id = ?', whereArgs: [id]);
    
    // Recalculate stock
    await _recalculateStockQuantity(batch.rawMaterialId);
  }

  // ============ Raw Material Units ============

  /// Insert a raw material unit
  Future<void> insertRawMaterialUnit(RawMaterialUnit unit) async {
    final db = await database;
    await db.insert(
      'raw_material_units',
      unit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get raw material units by raw material ID
  Future<List<RawMaterialUnit>> getRawMaterialUnits(String rawMaterialId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_material_units',
      where: 'raw_material_id = ?',
      whereArgs: [rawMaterialId],
    );
    return maps.map((map) => RawMaterialUnit.fromMap(map)).toList();
  }

  // ============ Stock Management ============

  /// Add raw material to stock
  Future<void> addRawMaterialStock(String rawMaterialId, double quantity, String unit) async {
    final db = await database;
    
    // Convert to base unit quantity
    final convertedQuantity = await convertToBaseUnit(rawMaterialId, quantity, unit);
    
    // Get current stock
    final material = await getRawMaterialById(rawMaterialId);
    if (material == null) return;
    
    final newStock = material.stockQuantity + convertedQuantity;
    
    await db.update(
      'raw_materials',
      {'stock_quantity': newStock},
      where: 'id = ?',
      whereArgs: [rawMaterialId],
    );
  }

  /// Convert quantity from input unit to base unit
  Future<double> convertToBaseUnit(String rawMaterialId, double quantity, String unit) async {
    final material = await getRawMaterialById(rawMaterialId);
    if (material == null) return quantity;
    
    final baseUnit = material.baseUnit;
    
    // If same unit, no conversion needed
    if (unit.toLowerCase() == baseUnit.toLowerCase()) {
      return quantity;
    }
    
    // Get conversion units
    final units = await getRawMaterialUnits(rawMaterialId);
    
    for (var u in units) {
      if (u.unit.toLowerCase() == unit.toLowerCase()) {
        return quantity * u.conversionFactorToBase;
      }
    }
    
    // Standard conversions
    final conversions = {
      'kg': {'gram': 1000.0, 'g': 1000.0},
      'gram': {'kg': 0.001, 'kilogram': 0.001},
      'g': {'kg': 0.001, 'kilogram': 0.001},
      'liter': {'ml': 1000.0, 'milliliter': 1000.0},
      'ml': {'liter': 0.001, 'l': 0.001},
      'carton': {'bottle': 12.0},
      'bottle': {'carton': 1/12},
    };
    
    final fromUnit = unit.toLowerCase();
    final toUnit = baseUnit.toLowerCase();
    
    if (conversions.containsKey(fromUnit) && conversions[fromUnit]!.containsKey(toUnit)) {
      return quantity * conversions[fromUnit]![toUnit]!;
    }
    
    return quantity;
  }

  /// Format stock for display - returns Map with 'quantity' and 'unit' keys
  Future<Map<String, String>> formatStockForDisplay(String rawMaterialId) async {
    final material = await getRawMaterialById(rawMaterialId);
    if (material == null) return {'quantity': '0', 'unit': ''};
    
    final stock = material.stockQuantity;
    final baseUnit = material.baseUnit;
    
    // Smart formatting based on quantity and unit
    if (baseUnit.toLowerCase() == 'gram' || baseUnit.toLowerCase() == 'g') {
      if (stock >= 1000) {
        return {
          'quantity': (stock / 1000).toStringAsFixed(2),
          'unit': 'كيلو',
        };
      }
      return {
        'quantity': stock.toStringAsFixed(0),
        'unit': 'جرام',
      };
    }
    
    if (baseUnit.toLowerCase() == 'ml' || baseUnit.toLowerCase() == 'milliliter') {
      if (stock >= 1000) {
        return {
          'quantity': (stock / 1000).toStringAsFixed(2),
          'unit': 'لتر',
        };
      }
      return {
        'quantity': stock.toStringAsFixed(0),
        'unit': 'مل',
      };
    }
    
    if (baseUnit.toLowerCase() == 'carton') {
      return {
        'quantity': stock.toStringAsFixed(0),
        'unit': 'كرتونة / زجاجة',
      };
    }
    
    if (baseUnit.toLowerCase() == 'packet') {
      return {
        'quantity': stock.toStringAsFixed(0),
        'unit': 'باكيت',
      };
    }
    
    if (baseUnit.toLowerCase() == 'jar') {
      return {
        'quantity': stock.toStringAsFixed(0),
        'unit': 'جرة',
      };
    }
    
    if (baseUnit.toLowerCase() == 'piece') {
      return {
        'quantity': stock.toStringAsFixed(0),
        'unit': 'قطعة',
      };
    }
    
    return {
      'quantity': stock.toStringAsFixed(2),
      'unit': baseUnit,
    };
  }

  /// Create a new raw material with common defaults
  Future<RawMaterial> createRawMaterial(String name, String unit, String subCategoryId, {String? baseUnit}) async {
    final db = await database;
    final id = const Uuid().v4();
    final now = DateTime.now();
    
    final material = RawMaterial(
      id: id,
      subCategoryId: subCategoryId,
      name: name,
      unit: unit,
      baseUnit: baseUnit ?? unit,
      stockQuantity: 0,
      minimumAlertQuantity: 0,
      createdAt: now,
      updatedAt: now,
    );
    
    await db.insert('raw_materials', material.toMap());
    
    return material;
  }

  /// Get or create a raw material by name
  Future<RawMaterial> getOrCreateRawMaterial(String name, String unit, String subCategoryId, {String? baseUnit}) async {
    final db = await database;
    
    // Check if material exists
    final existing = await db.query(
      'raw_materials',
      where: 'name = ? AND sub_category_id = ?',
      whereArgs: [name, subCategoryId],
    );
    
    if (existing.isNotEmpty) {
      return RawMaterial.fromMap(existing.first);
    }
    
    return await createRawMaterial(name, unit, subCategoryId, baseUnit: baseUnit);
  }
}
