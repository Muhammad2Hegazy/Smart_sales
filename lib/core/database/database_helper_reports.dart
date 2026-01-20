part of 'database_helper.dart';

extension DatabaseHelperReports on DatabaseHelper {
  // Shift Reports CRUD
  Future<void> insertShiftReport(ShiftReport report) async {
    final db = await database;
    await db.insert(
      'shift_reports',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ShiftReport>> getAllShiftReports({
    DateTime? startDate,
    DateTime? endDate,
    int? floorId,
  }) async {
    final db = await database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause += ' AND created_at >= ? AND created_at <= ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    if (floorId != null) {
      whereClause += ' AND floor_id = ?';
      whereArgs.add(floorId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'shift_reports',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'shift_start DESC',
    );
    return maps.map((map) => ShiftReport.fromMap(map)).toList();
  }

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

  // Inventory Movements CRUD
  Future<void> insertInventoryMovement(InventoryMovement movement) async {
    final db = await database;
    
    await db.insert(
      'inventory_movements',
      movement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<InventoryMovement>> getInventoryMovementsByItemId(
    String itemId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = 'item_id = ?';
    List<dynamic> whereArgs = [itemId];

    if (startDate != null && endDate != null) {
      whereClause += ' AND created_at >= ? AND created_at <= ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'inventory_movements',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => InventoryMovement.fromMap(map)).toList();
  }

  Future<List<InventoryMovement>> getInventoryMovementsByType(
    String movementType, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = 'movement_type = ?';
    List<dynamic> whereArgs = [movementType];

    if (startDate != null && endDate != null) {
      whereClause += ' AND created_at >= ? AND created_at <= ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'inventory_movements',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => InventoryMovement.fromMap(map)).toList();
  }

  // Suppliers CRUD
  Future<void> insertSupplier(Supplier supplier) async {
    final db = await database;
    await db.insert(
      'suppliers',
      supplier.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Supplier>> getAllSuppliers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'suppliers',
      orderBy: 'name ASC',
    );
    return maps.map((map) => Supplier.fromMap(map)).toList();
  }

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

  /// Get the next purchase invoice number (today's count + 1)
  Future<String> getNextPurchaseInvoiceNumber() async {
    try {
      final db = await database;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM purchases WHERE purchase_date >= ? AND purchase_date < ?',
        [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      );
      
      final countValue = result.first['count'];
      int count = 0;
      if (countValue is int) {
        count = countValue;
      } else if (countValue is num) {
        count = countValue.toInt();
      } else {
        count = int.tryParse(countValue.toString()) ?? 0;
      }
      
      final nextNumber = count + 1;
      final dateStr = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
      return 'PUR-$dateStr-${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      debugPrint('Error getting next purchase invoice number: $e');
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      return 'PUR-$dateStr-0001';
    }
  }

  // Purchases CRUD
  Future<void> insertPurchase(Purchase purchase) async {
    final db = await database;
    
    final batch = db.batch();
    
    // Insert purchase
    batch.insert(
      'purchases',
      purchase.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Insert purchase items
    for (var item in purchase.items) {
      batch.insert(
        'purchase_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<Purchase>> getPurchasesBySupplierId(
    String supplierId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = 'supplier_id = ?';
    List<dynamic> whereArgs = [supplierId];

    if (startDate != null && endDate != null) {
      whereClause += ' AND purchase_date >= ? AND purchase_date <= ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'purchases',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'purchase_date DESC',
    );
    
    final List<Purchase> purchases = [];
    for (var map in maps) {
      final purchase = Purchase.fromMap(map);
      final items = await getPurchaseItemsByPurchaseId(purchase.id);
      purchases.add(purchase.copyWith(items: items));
    }
    
    return purchases;
  }

  Future<List<PurchaseItem>> getPurchaseItemsByPurchaseId(String purchaseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'purchase_items',
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
    return maps.map((map) => PurchaseItem.fromMap(map)).toList();
  }

  Future<List<Purchase>> getAllPurchases({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause += ' AND purchase_date >= ? AND purchase_date <= ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'purchases',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'purchase_date DESC',
    );
    
    final List<Purchase> purchases = [];
    for (var map in maps) {
      final purchase = Purchase.fromMap(map);
      final items = await getPurchaseItemsByPurchaseId(purchase.id);
      purchases.add(purchase.copyWith(items: items));
    }
    
    return purchases;
  }
}
