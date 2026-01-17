import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'base_dao.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';

/// Data Access Object for Supplier and Purchase operations
class SuppliersDao extends BaseDao {

  // ============ Suppliers ============

  /// Insert a supplier
  Future<void> insertSupplier(Supplier supplier) async {
    final db = await database;
    await db.insert(
      'suppliers',
      supplier.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all suppliers
  Future<List<Supplier>> getAllSuppliers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('suppliers');
    return maps.map((map) => Supplier.fromMap(map)).toList();
  }

  /// Get supplier by ID
  Future<Supplier?> getSupplierById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Supplier.fromMap(maps.first);
  }

  // ============ Purchases ============

  /// Get the next purchase invoice number as formatted string
  Future<String> getNextPurchaseInvoiceNumber() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM purchases WHERE created_at >= ? AND created_at < ?',
        [todayStart.toIso8601String(), todayEnd.toIso8601String()],
      );
      
      if (result.isEmpty) return 'PUR-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-001';
      
      final countValue = result.first['count'];
      int count = 0;
      if (countValue is int) {
        count = countValue;
      } else if (countValue is num) {
        count = countValue.toInt();
      } else {
        count = int.tryParse(countValue.toString()) ?? 0;
      }
      
      final nextNumber = (count + 1).toString().padLeft(3, '0');
      return 'PUR-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$nextNumber';
    } catch (e) {
      debugPrint('Error getting next purchase invoice number: $e');
      final now = DateTime.now();
      return 'PUR-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-001';
    }
  }

  /// Insert a purchase with items
  Future<void> insertPurchase(Purchase purchase) async {
    final db = await database;
    final batch = db.batch();
    
    batch.insert(
      'purchases',
      purchase.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    for (var item in purchase.items) {
      batch.insert(
        'purchase_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// Get purchases by supplier ID
  Future<List<Purchase>> getPurchasesBySupplierId(
    String supplierId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String where = 'supplier_id = ?';
    List<dynamic> whereArgs = [supplierId];
    
    if (startDate != null) {
      where += ' AND created_at >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where += ' AND created_at <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'purchases',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    
    return Future.wait(maps.map((map) async {
      final purchase = Purchase.fromMap(map);
      final items = await getPurchaseItemsByPurchaseId(purchase.id);
      return purchase.copyWith(items: items);
    }));
  }

  /// Get purchase items by purchase ID
  Future<List<PurchaseItem>> getPurchaseItemsByPurchaseId(String purchaseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'purchase_items',
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
    return maps.map((map) => PurchaseItem.fromMap(map)).toList();
  }

  /// Get all purchases
  Future<List<Purchase>> getAllPurchases({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;
    
    if (startDate != null && endDate != null) {
      where = 'created_at >= ? AND created_at <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    } else if (startDate != null) {
      where = 'created_at >= ?';
      whereArgs = [startDate.toIso8601String()];
    } else if (endDate != null) {
      where = 'created_at <= ?';
      whereArgs = [endDate.toIso8601String()];
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'purchases',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    
    return Future.wait(maps.map((map) async {
      final purchase = Purchase.fromMap(map);
      final items = await getPurchaseItemsByPurchaseId(purchase.id);
      return purchase.copyWith(items: items);
    }));
  }
}
