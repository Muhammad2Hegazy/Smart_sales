part of 'database_helper.dart';

extension DatabaseHelperSales on DatabaseHelper {
  // Sales CRUD
  Future<void> insertSale(Sale sale) async {
    final db = await database;
    
    print('═══════════════════════════════════════════════════════');
    print('insertSale: Starting to save sale');
    print('  Sale ID: ${sale.id}');
    print('  Total: ${sale.total}');
    print('  Payment Method: ${sale.paymentMethod}');
    print('  Created At: ${sale.createdAt.toIso8601String()}');
    print('  Items Count: ${sale.items.length}');
    print('═══════════════════════════════════════════════════════');
    
    // Ensure sales table has all required columns
    await _ensureSalesTableColumns(db);
    
    // Get master device ID for sync
    final master = await getMaster();
    final masterDeviceId = master?.masterDeviceId ?? '';
    final now = DateTime.now().toIso8601String();
    
    // Get current device ID from SharedPreferences
    String? currentDeviceId;
    try {
      final prefs = await SharedPreferences.getInstance();
      currentDeviceId = prefs.getString('current_device_id');
      print('  Current Device ID from SharedPreferences: $currentDeviceId');
    } catch (e) {
      print('  ⚠️  Error getting current device ID: $e');
    }
    
    final finalDeviceId = currentDeviceId ?? sale.deviceId;
    print('  Final Device ID to save: $finalDeviceId');
    
    final batch = db.batch();
    
    // Prepare sale map
    final saleMap = sale.toMap(
        masterDeviceId: masterDeviceId,
        syncStatus: 'pending', // Mark as pending for sync
        updatedAt: now,
      deviceId: finalDeviceId,
    );
    
    print('  Sale Map Keys: ${saleMap.keys.toList()}');
    print('  Sale Map device_id: ${saleMap['device_id']}');
    print('  Sale Map created_at: ${saleMap['created_at']}');
    
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
          syncStatus: 'pending', // Mark as pending for sync
          updatedAt: now,
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
    
    print('  ✓ Sale saved successfully to database');
    print('═══════════════════════════════════════════════════════');
    
    // Verify the sale was saved
    final savedSale = await getSaleById(sale.id);
    if (savedSale != null) {
      print('  ✓ Verification: Sale found in database');
      print('    Saved Total: ${savedSale.total}');
      print('    Saved Device ID: ${savedSale.deviceId}');
      print('    Saved Created At: ${savedSale.createdAt.toIso8601String()}');
    } else {
      print('  ❌ ERROR: Sale not found in database after save!');
    }
  }

  Future<List<Sale>> getAllSales() async {
    final db = await database;
    final List<Map<String, dynamic>> saleMaps = await db.query('sales', orderBy: 'created_at DESC');
    
    final List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final sale = Sale.fromMap(saleMap);
      final items = await getSaleItemsBySaleId(sale.id);
      sales.add(sale.copyWith(items: items));
    }
    
    return sales;
  }

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

  /// Get the total count of sales (for invoice numbering)
  Future<int> getSalesCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM sales');
      if (result.isEmpty) {
        print('getSalesCount: No result returned');
        return 0;
      }
      
      // Handle different return types from SQLite
      final countValue = result.first['count'];
      int count = 0;
      if (countValue is int) {
        count = countValue;
      } else if (countValue is num) {
        count = countValue.toInt();
      } else {
        count = int.tryParse(countValue.toString()) ?? 0;
      }
      
      print('getSalesCount: Found $count sales in database (raw value: $countValue, type: ${countValue.runtimeType})');
      return count;
    } catch (e, stackTrace) {
      print('Error getting sales count: $e');
      print('Stack trace: $stackTrace');
      return 0;
    }
  }

  /// Get the count of sales for today (for daily invoice numbering)
  Future<int> getTodaySalesCount() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      final todayStartStr = todayStart.toIso8601String();
      final todayEndStr = todayEnd.toIso8601String();
      
      print('getTodaySalesCount: Querying sales from $todayStartStr to $todayEndStr');
      
      // First, let's see all sales to debug
      final allSales = await db.query('sales', columns: ['id', 'created_at'], limit: 5);
      print('getTodaySalesCount: Sample sales in DB:');
      for (var sale in allSales) {
        print('  - Sale ID: ${sale['id']}, created_at: ${sale['created_at']}');
      }
      
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sales WHERE created_at >= ? AND created_at < ?',
        [todayStartStr, todayEndStr],
      );
      
      if (result.isEmpty) {
        print('getTodaySalesCount: No result returned');
        return 0;
      }
      
      // Handle different return types from SQLite
      final countValue = result.first['count'];
      int count = 0;
      if (countValue is int) {
        count = countValue;
      } else if (countValue is num) {
        count = countValue.toInt();
      } else {
        count = int.tryParse(countValue.toString()) ?? 0;
      }
      
      print('getTodaySalesCount: Found $count sales today (from $todayStartStr to $todayEndStr)');
      
      // Also try a simpler query using DATE() function if available
      try {
        final dateResult = await db.rawQuery(
          "SELECT COUNT(*) as count FROM sales WHERE DATE(created_at) = DATE('now')",
        );
        if (dateResult.isNotEmpty) {
          final dateCountValue = dateResult.first['count'];
          int dateCount = 0;
          if (dateCountValue is int) {
            dateCount = dateCountValue;
          } else if (dateCountValue is num) {
            dateCount = dateCountValue.toInt();
          } else {
            dateCount = int.tryParse(dateCountValue.toString()) ?? 0;
          }
          print('getTodaySalesCount: Alternative query (DATE function) found $dateCount sales');
          // Use the alternative if it gives a different result
          if (dateCount != count) {
            print('getTodaySalesCount: Using alternative count: $dateCount');
            return dateCount;
          }
        }
      } catch (e) {
        print('getTodaySalesCount: Alternative query failed (may not support DATE function): $e');
      }
      
      return count;
    } catch (e, stackTrace) {
      print('Error getting today sales count: $e');
      print('Stack trace: $stackTrace');
      return 0;
    }
  }

  /// Get the next invoice number (today's count + 1)
  Future<int> getNextInvoiceNumber() async {
    final count = await getTodaySalesCount();
    final nextNumber = count + 1;
    print('getNextInvoiceNumber: Today count=$count, Next number=$nextNumber');
    return nextNumber;
  }

  /// Get the next order number (today's count + 1)
  /// This is the same as invoice number since each sale is both an order and an invoice
  Future<int> getNextOrderNumber() async {
    return await getNextInvoiceNumber();
  }

  Future<List<Sale>> getSalesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    
    print('═══════════════════════════════════════════════════════');
    print('getSalesByDateRange: Querying sales');
    print('  Start Date: ${startDate.toIso8601String()}');
    print('  End Date: ${endDate.toIso8601String()}');
    
    // First, let's check total sales count
    final totalCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM sales');
    final totalCount = (totalCountResult.first['count'] as num?)?.toInt() ?? 0;
    print('  Total sales in database: $totalCount');
    
    // Get all sales to see what we have
    final allSalesMaps = await db.query('sales', limit: 5, orderBy: 'created_at DESC');
    print('  Sample of all sales (last 5):');
    for (var saleMap in allSalesMaps) {
      print('    - ID: ${saleMap['id']}, Total: ${saleMap['total']}, Created: ${saleMap['created_at']}, Device: ${saleMap['device_id']}');
    }
    
    final List<Map<String, dynamic>> saleMaps = await db.query(
      'sales',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    
    print('  Found ${saleMaps.length} sales in date range');
    
    if (saleMaps.isEmpty) {
      print('  ⚠️  WARNING: No sales found in date range!');
      print('  Checking if any sales exist outside this range...');
      final beforeCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sales WHERE created_at < ?',
        [startDate.toIso8601String()],
      );
      final afterCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sales WHERE created_at > ?',
        [endDate.toIso8601String()],
      );
      print('    Sales before range: ${(beforeCount.first['count'] as num?)?.toInt() ?? 0}');
      print('    Sales after range: ${(afterCount.first['count'] as num?)?.toInt() ?? 0}');
    }
    
    final List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final sale = Sale.fromMap(saleMap);
      final items = await getSaleItemsBySaleId(sale.id);
      sales.add(sale.copyWith(items: items));
    }
    
    print('  Returning ${sales.length} sales with items');
    print('═══════════════════════════════════════════════════════');
    
    return sales;
  }

  /// Get sales by device IDs and date range
  /// If deviceIds is empty, returns all sales in date range (including those without device_id)
  /// IMPORTANT: If deviceIds is provided but no matching sales found, returns ALL sales in date range
  /// This ensures reports show all sales even if device_id doesn't match
  Future<List<Sale>> getSalesByDeviceIdsAndDateRange(
    List<String> deviceIds,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    
    print('═══════════════════════════════════════════════════════');
    print('getSalesByDeviceIdsAndDateRange: Querying sales');
    print('  Device IDs: $deviceIds (count: ${deviceIds.length})');
    print('  Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
    
    // If deviceIds is empty, get all sales in date range (including null device_id)
    if (deviceIds.isEmpty) {
      print('  No device IDs provided, getting all sales in date range');
      return await getSalesByDateRange(startDate, endDate);
    }
    
    // First, try to get sales for the specified device IDs
    final placeholders = deviceIds.map((_) => '?').join(',');
    final List<Map<String, dynamic>> saleMaps = await db.query(
      'sales',
      where: '(device_id IN ($placeholders) OR device_id IS NULL) AND created_at >= ? AND created_at <= ?',
      whereArgs: [...deviceIds, startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    
    print('  Found ${saleMaps.length} sales matching device IDs');
    
    // If no sales found with device IDs, get ALL sales in date range
    // This handles the case where device_id format doesn't match
    if (saleMaps.isEmpty) {
      print('  ⚠️  No sales found with device IDs, getting ALL sales in date range');
      print('  This ensures reports show all sales even if device_id format differs');
      return await getSalesByDateRange(startDate, endDate);
    }
    
    final List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final sale = Sale.fromMap(saleMap);
      final items = await getSaleItemsBySaleId(sale.id);
      sales.add(sale.copyWith(items: items));
    }
    
    print('  Returning ${sales.length} sales with items');
    print('═══════════════════════════════════════════════════════');
    
    return sales;
  }

  Future<List<SaleItem>> getSaleItemsBySaleId(String saleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return maps.map((map) => SaleItem.fromMap(map)).toList();
  }

  Future<double> getTotalSalesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    // Exclude hospitality sales from profit calculation (they are treated as losses)
    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM sales WHERE created_at >= ? AND created_at <= ? AND (table_number IS NULL OR table_number != ?)',
      [startDate.toIso8601String(), endDate.toIso8601String(), 'hospitality'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total hospitality sales (to be treated as losses in profit/loss calculation)
  Future<double> getTotalHospitalitySalesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM sales WHERE created_at >= ? AND created_at <= ? AND table_number = ?',
      [startDate.toIso8601String(), endDate.toIso8601String(), 'hospitality'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
