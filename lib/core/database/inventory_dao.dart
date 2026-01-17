import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'base_dao.dart';
import '../models/inventory_movement.dart';
import '../models/low_stock_warning.dart';
import '../models/raw_material.dart';
import '../models/invoice.dart';
import '../models/shift_report.dart';
import 'recipes_dao.dart';
import 'raw_materials_dao.dart';

/// Data Access Object for Inventory operations
class InventoryDao extends BaseDao {
  final RecipesDao _recipesDao = RecipesDao();
  final RawMaterialsDao _rawMaterialsDao = RawMaterialsDao();

  // ============ Inventory Movements ============

  /// Insert an inventory movement
  Future<void> insertInventoryMovement(InventoryMovement movement) async {
    final db = await database;
    await db.insert(
      'inventory_movements',
      movement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get inventory movements by item ID
  Future<List<InventoryMovement>> getInventoryMovementsByItemId(
    String itemId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String where = 'item_id = ?';
    List<dynamic> whereArgs = [itemId];
    
    if (startDate != null) {
      where += ' AND created_at >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where += ' AND created_at <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'inventory_movements',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => InventoryMovement.fromMap(map)).toList();
  }

  /// Get inventory movements by type
  Future<List<InventoryMovement>> getInventoryMovementsByType(
    String movementType, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String where = 'movement_type = ?';
    List<dynamic> whereArgs = [movementType];
    
    if (startDate != null) {
      where += ' AND created_at >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where += ' AND created_at <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'inventory_movements',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => InventoryMovement.fromMap(map)).toList();
  }

  // ============ Stock Deduction ============

  /// Deduct raw materials from inventory based on recipe when item is sold
  Future<List<LowStockWarning>> deductInventoryForSale(String itemId, int quantity) async {
    final warnings = <LowStockWarning>[];
    
    // Get recipe for the item
    final recipe = await _recipesDao.getRecipeByItemId(itemId);
    if (recipe == null) return warnings;
    
    // Get recipe ingredients
    final ingredients = await _recipesDao.getRecipeIngredients(recipe.id);
    
    for (var ingredient in ingredients) {
      // Get raw material
      final rawMaterial = await _rawMaterialsDao.getRawMaterialById(ingredient.rawMaterialId);
      if (rawMaterial == null) continue;
      
      // Calculate quantity to deduct (per item * number of items sold)
      final quantityToDeduct = ingredient.quantity * quantity;
      
      // Check for low stock warning
      final warning = _checkLowStock(
        rawMaterial: rawMaterial,
        requiredQuantity: quantityToDeduct,
      );
      if (warning != null) {
        warnings.add(warning);
      }
      
      // Deduct from stock
      final newStock = rawMaterial.stockQuantity - quantityToDeduct;
      await _rawMaterialsDao.updateRawMaterial(rawMaterial.copyWith(
        stockQuantity: newStock < 0 ? 0 : newStock,
        updatedAt: DateTime.now(),
      ));
      
      // Record inventory movement
      final now = DateTime.now();
      await insertInventoryMovement(InventoryMovement(
        id: const Uuid().v4(),
        itemId: ingredient.rawMaterialId,
        movementType: 'sale_deduction',
        quantity: -quantityToDeduct,
        notes: 'Deducted for sale of item $itemId (qty: $quantity)',
        createdAt: now,
        masterDeviceId: '',
        syncStatus: 'pending',
        updatedAt: now,
      ));
    }
    
    return warnings;
  }

  /// Check if raw material stock is low
  LowStockWarning? _checkLowStock({
    required RawMaterial rawMaterial,
    required double requiredQuantity,
  }) {
    final currentStock = rawMaterial.stockQuantity;
    final minimumStock = rawMaterial.minimumAlertQuantity;
    final remainingStock = currentStock - requiredQuantity;
    
    // Calculate percentage remaining
    final percentageRemaining = minimumStock > 0 
        ? (remainingStock / minimumStock) * 100 
        : (remainingStock > 0 ? 100 : 0);
    
    if (remainingStock <= 0 || (minimumStock > 0 && remainingStock < minimumStock)) {
      return LowStockWarning(
        rawMaterialId: rawMaterial.id,
        rawMaterialName: rawMaterial.name,
        currentQuantity: currentStock,
        requiredQuantity: requiredQuantity,
        unit: rawMaterial.unit,
        percentageRemaining: percentageRemaining.toDouble(),
      );
    }
    
    return null;
  }

  /// Calculate and deduct stock for invoice items
  Future<List<LowStockWarning>> calculateAndDeductStock(List<Map<String, dynamic>> invoiceItems) async {
    final warnings = <LowStockWarning>[];
    
    for (var item in invoiceItems) {
      final itemId = item['itemId'] as String;
      final quantity = item['quantity'] as int;
      
      final itemWarnings = await deductInventoryForSale(itemId, quantity);
      warnings.addAll(itemWarnings);
    }
    
    return warnings;
  }

  // ============ Shift Reports ============

  /// Insert a shift report
  Future<void> insertShiftReport(ShiftReport report) async {
    final db = await database;
    await db.insert(
      'shift_reports',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get shift reports by date range
  Future<List<ShiftReport>> getShiftReportsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? floorId,
  }) async {
    final db = await database;
    String where = 'created_at >= ? AND created_at <= ?';
    List<dynamic> whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    
    if (floorId != null) {
      where += ' AND floor_id = ?';
      whereArgs.add(floorId);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'shift_reports',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ShiftReport.fromMap(map)).toList();
  }

  /// Get shift report by ID
  Future<ShiftReport?> getShiftReportById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shift_reports',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ShiftReport.fromMap(maps.first);
  }

  // ============ Invoices ============

  /// Insert an invoice
  Future<void> insertInvoice(Invoice invoice) async {
    final db = await database;
    await db.insert(
      'invoices',
      invoice.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Create an invoice and process stock deduction
  Future<Map<String, dynamic>> createInvoice({
    required DateTime date,
    required double totalAmount,
    required List<Map<String, dynamic>> invoiceItems,
  }) async {
    final db = await database;
    final invoiceId = const Uuid().v4();
    
    // Deduct stock
    final warnings = await calculateAndDeductStock(invoiceItems);
    
    // Create invoice
    await db.insert('invoices', {
      'id': invoiceId,
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Create invoice items
    for (var item in invoiceItems) {
      await db.insert('invoice_items', {
        'id': const Uuid().v4(),
        'invoice_id': invoiceId,
        'item_id': item['itemId'],
        'quantity': item['quantity'],
        'unit_price': item['unitPrice'],
        'total': item['total'],
      });
    }
    
    return {
      'invoiceId': invoiceId,
      'warnings': warnings,
    };
  }
}
