import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'base_dao.dart';
import '../models/sale.dart';
import 'devices_dao.dart';

/// Data Access Object for Sales and SaleItems operations
class SalesDao extends BaseDao {
  final DevicesDao _devicesDao = DevicesDao();

  /// Ensure sales table has all required columns
  Future<void> ensureSalesTableColumns(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(sales)");
      final columnNames = result.map((row) => row['name'] as String).toSet();
      
      if (!columnNames.contains('discount_percentage')) {
        await db.execute('ALTER TABLE sales ADD COLUMN discount_percentage REAL NOT NULL DEFAULT 0.0');
        debugPrint('Added discount_percentage column to sales table');
      }
      
      if (!columnNames.contains('discount_amount')) {
        await db.execute('ALTER TABLE sales ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0.0');
        debugPrint('Added discount_amount column to sales table');
      }
      
      if (!columnNames.contains('service_charge')) {
        await db.execute('ALTER TABLE sales ADD COLUMN service_charge REAL NOT NULL DEFAULT 0.0');
        debugPrint('Added service_charge column to sales table');
      }
      
      if (!columnNames.contains('delivery_tax')) {
        await db.execute('ALTER TABLE sales ADD COLUMN delivery_tax REAL NOT NULL DEFAULT 0.0');
        debugPrint('Added delivery_tax column to sales table');
      }
      
      if (!columnNames.contains('hospitality_tax')) {
        await db.execute('ALTER TABLE sales ADD COLUMN hospitality_tax REAL NOT NULL DEFAULT 0.0');
        debugPrint('Added hospitality_tax column to sales table');
      }
      
      if (!columnNames.contains('device_id')) {
        await db.execute('ALTER TABLE sales ADD COLUMN device_id TEXT');
        debugPrint('Added device_id column to sales table');
      }
      
      if (!columnNames.contains('master_device_id')) {
        await db.execute("ALTER TABLE sales ADD COLUMN master_device_id TEXT NOT NULL DEFAULT ''");
        debugPrint('Added master_device_id column to sales table');
      }
      
      if (!columnNames.contains('sync_status')) {
        await db.execute("ALTER TABLE sales ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'");
        debugPrint('Added sync_status column to sales table');
      }
      
      if (!columnNames.contains('updated_at')) {
        await db.execute("ALTER TABLE sales ADD COLUMN updated_at TEXT NOT NULL DEFAULT ''");
        debugPrint('Added updated_at column to sales table');
      }
    } catch (e) {
      debugPrint('Error ensuring sales table columns: $e');
    }
  }

  /// Ensure sale_items table has all required columns
  Future<void> ensureSaleItemsTableColumns(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(sale_items)");
      final columnNames = result.map((row) => row['name'] as String).toSet();
      
      if (!columnNames.contains('total')) {
        await db.execute('ALTER TABLE sale_items ADD COLUMN total REAL NOT NULL DEFAULT 0.0');
        await db.execute('UPDATE sale_items SET total = price * quantity');
        debugPrint('Added total column to sale_items table');
      }
    } catch (e) {
      debugPrint('Error ensuring sale_items table columns: $e');
    }
  }

  /// Insert a sale with all items
  Future<void> insertSale(Sale sale) async {
    final db = await database;
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('insertSale: Starting to save sale');
    debugPrint('  Sale ID: ${sale.id}');
    debugPrint('  Total: ${sale.total}');
    debugPrint('  Payment Method: ${sale.paymentMethod}');
    debugPrint('  Created At: ${sale.createdAt.toIso8601String()}');
    debugPrint('  Items Count: ${sale.items.length}');
    debugPrint('═══════════════════════════════════════════════════════');
    
    // Ensure sales and sale_items tables have all required columns
    await ensureSalesTableColumns(db);
    await ensureSaleItemsTableColumns(db);
    
    // Get master device ID for sync
    final master = await _devicesDao.getMaster();
    final masterDeviceId = master?.masterDeviceId ?? '';
    final now = DateTime.now().toIso8601String();
    
    // Get current device ID from SharedPreferences
    String? currentDeviceId;
    try {
      final prefs = await SharedPreferences.getInstance();
      currentDeviceId = prefs.getString('current_device_id');
      debugPrint('  Current Device ID from SharedPreferences: $currentDeviceId');
    } catch (e) {
      debugPrint('  ⚠️  Error getting current device ID: $e');
    }
    
    final finalDeviceId = currentDeviceId ?? sale.deviceId;
    debugPrint('  Final Device ID to save: $finalDeviceId');
    
    final batch = db.batch();
    
    // Prepare sale map
    final saleMap = sale.toMap(
        masterDeviceId: masterDeviceId,
        syncStatus: 'pending',
        updatedAt: now,
      deviceId: finalDeviceId,
    );
    
    debugPrint('  Sale Map Keys: ${saleMap.keys.toList()}');
    debugPrint('  Sale Map device_id: ${saleMap['device_id']}');
    debugPrint('  Sale Map created_at: ${saleMap['created_at']}');
    
    // Insert sale with sync fields and device_id
    batch.insert(
      'sales',
      saleMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Insert sale items with sync fields
    for (var item in sale.items) {
      batch.insert(
        'sale_items',
        item.toMap(
          masterDeviceId: masterDeviceId,
          syncStatus: 'pending',
          updatedAt: now,
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
    
    debugPrint('  ✓ Sale saved successfully to database');
    debugPrint('═══════════════════════════════════════════════════════');
    
    // Verify the sale was saved
    final savedSale = await getSaleById(sale.id);
    if (savedSale != null) {
      debugPrint('  ✓ Verification: Sale found in database');
      debugPrint('    Saved Total: ${savedSale.total}');
      debugPrint('    Saved Device ID: ${savedSale.deviceId}');
      debugPrint('    Saved Created At: ${savedSale.createdAt.toIso8601String()}');
    } else {
      debugPrint('  ❌ ERROR: Sale not found in database after save!');
    }
  }

  /// Get all sales
  Future<List<Sale>> getAllSales() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sales',
      orderBy: 'created_at DESC',
    );
    return Future.wait(maps.map((map) async {
      final sale = Sale.fromMap(map);
      final items = await getSaleItemsBySaleId(sale.id);
      return sale.copyWith(items: items);
    }));
  }

  /// Get sale by ID
  Future<Sale?> getSaleById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final sale = Sale.fromMap(maps.first);
    final items = await getSaleItemsBySaleId(sale.id);
    return sale.copyWith(items: items);
  }

  /// Get the total count of sales
  Future<int> getSalesCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM sales');
      if (result.isEmpty) {
        debugPrint('getSalesCount: No result returned');
        return 0;
      }
      
      final countValue = result.first['count'];
      int count = 0;
      if (countValue is int) {
        count = countValue;
      } else if (countValue is num) {
        count = countValue.toInt();
      } else {
        count = int.tryParse(countValue.toString()) ?? 0;
      }
      
      debugPrint('getSalesCount: Found $count sales in database');
      return count;
    } catch (e, stackTrace) {
      debugPrint('Error getting sales count: $e');
      debugPrint('Stack trace: $stackTrace');
      return 0;
    }
  }

  /// Get the count of sales for today
  Future<int> getTodaySalesCount() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      final todayStartStr = todayStart.toIso8601String();
      final todayEndStr = todayEnd.toIso8601String();
      
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sales WHERE created_at >= ? AND created_at < ?',
        [todayStartStr, todayEndStr],
      );
      
      if (result.isEmpty) return 0;
      
      final countValue = result.first['count'];
      if (countValue is int) {
        return countValue;
      } else if (countValue is num) {
        return countValue.toInt();
      }
      return int.tryParse(countValue.toString()) ?? 0;
    } catch (e) {
      debugPrint('Error getting today sales count: $e');
      return 0;
    }
  }

  /// Get the next invoice number
  Future<int> getNextInvoiceNumber() async {
    final count = await getTodaySalesCount();
    return count + 1;
  }

  /// Get the next order number
  Future<int> getNextOrderNumber() async {
    return await getNextInvoiceNumber();
  }

  /// Get sales by date range
  Future<List<Sale>> getSalesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    
    debugPrint('getSalesByDateRange: Querying...');
    debugPrint('  Start: ${startDate.toIso8601String()}');
    debugPrint('  End: ${endDate.toIso8601String()}');
    
    final List<Map<String, dynamic>> maps = await db.query(
      'sales',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    
    debugPrint('  Found ${maps.length} sales');
    
    return Future.wait(maps.map((map) async {
      final sale = Sale.fromMap(map);
      final items = await getSaleItemsBySaleId(sale.id);
      return sale.copyWith(items: items);
    }));
  }

  /// Get sales by device IDs and date range
  Future<List<Sale>> getSalesByDeviceIdsAndDateRange(
    List<String> deviceIds,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    
    List<Map<String, dynamic>> maps;
    
    if (deviceIds.isEmpty) {
      maps = await db.query(
        'sales',
        where: 'created_at >= ? AND created_at <= ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'created_at DESC',
      );
    } else {
      final placeholders = deviceIds.map((_) => '?').join(',');
      maps = await db.query(
        'sales',
        where: 'created_at >= ? AND created_at <= ? AND device_id IN ($placeholders)',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String(), ...deviceIds],
        orderBy: 'created_at DESC',
      );
      
      // If no matching sales found, return all sales in date range
      if (maps.isEmpty) {
        maps = await db.query(
          'sales',
          where: 'created_at >= ? AND created_at <= ?',
          whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
          orderBy: 'created_at DESC',
        );
      }
    }
    
    return Future.wait(maps.map((map) async {
      final sale = Sale.fromMap(map);
      final items = await getSaleItemsBySaleId(sale.id);
      return sale.copyWith(items: items);
    }));
  }

  /// Get sale items by sale ID
  Future<List<SaleItem>> getSaleItemsBySaleId(String saleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return maps.map((map) => SaleItem.fromMap(map)).toList();
  }

  /// Get total sales by date range
  Future<double> getTotalSalesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM sales WHERE created_at >= ? AND created_at <= ? AND (table_number IS NULL OR table_number != ?)',
      [startDate.toIso8601String(), endDate.toIso8601String(), 'hospitality'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total hospitality sales by date range
  Future<double> getTotalHospitalitySalesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM sales WHERE created_at >= ? AND created_at <= ? AND table_number = ?',
      [startDate.toIso8601String(), endDate.toIso8601String(), 'hospitality'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
