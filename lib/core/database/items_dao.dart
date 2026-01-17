import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'base_dao.dart';
import '../models/item.dart';
import '../models/note.dart';
import 'devices_dao.dart';

/// Data Access Object for Item and Note operations
class ItemsDao extends BaseDao {
  final DevicesDao _devicesDao = DevicesDao();

  // ============ Items ============

  /// Insert multiple items
  Future<void> insertItems(List<Item> items) async {
    final db = await database;
    final batch = db.batch();
    
    final master = await _devicesDao.getMaster();
    final masterDeviceId = master?.masterDeviceId ?? '';
    final now = DateTime.now().toIso8601String();
    
    for (var item in items) {
      batch.insert(
        'items',
        {
          'id': item.id,
          'name': item.name,
          'sub_category_id': item.subCategoryId,
          'price': item.price,
          'has_notes': item.hasNotes ? 1 : 0,
          'image_url': item.imageUrl,
          'stock_quantity': item.stockQuantity,
          'stock_unit': item.stockUnit,
          'conversion_rate': item.conversionRate,
          'is_pos_only': item.isPosOnly ? 1 : 0,
          'master_device_id': masterDeviceId,
          'sync_status': 'pending',
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// Ensure stock columns exist in items table
  Future<void> ensureStockColumnsExist(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(items)");
      final hasStockQuantity = result.any((row) => row['name'] == 'stock_quantity');
      final hasStockUnit = result.any((row) => row['name'] == 'stock_unit');
      
      if (!hasStockQuantity) {
        await db.execute('ALTER TABLE items ADD COLUMN stock_quantity REAL DEFAULT 0');
      }
      if (!hasStockUnit) {
        await db.execute("ALTER TABLE items ADD COLUMN stock_unit TEXT DEFAULT 'number'");
      }
    } catch (e) {
      debugPrint('Error ensuring stock columns exist: $e');
    }
  }

  /// Update item stock
  Future<void> updateItemStock(String itemId, double quantity, String unit) async {
    final db = await database;
    await db.update(
      'items',
      {
        'stock_quantity': quantity,
        'stock_unit': unit,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  /// Update item price and stock
  Future<void> updateItemPriceAndStock(
    String itemId,
    double price,
    double quantity,
    String unit,
  ) async {
    final db = await database;
    await db.update(
      'items',
      {
        'price': price,
        'stock_quantity': quantity,
        'stock_unit': unit,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  /// Get all items
  Future<List<Item>> getAllItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('items');
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  /// Get item by ID
  Future<Item?> getItemById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Item.fromMap(maps.first);
  }

  /// Get items by subcategory ID
  Future<List<Item>> getItemsBySubCategoryId(String subCategoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'sub_category_id = ?',
      whereArgs: [subCategoryId],
    );
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  /// Delete all items
  Future<void> deleteAllItems() async {
    final db = await database;
    await db.delete('items');
  }

  // ============ Notes ============

  /// Insert multiple notes
  Future<void> insertNotes(List<Note> notes) async {
    final db = await database;
    final batch = db.batch();
    
    for (var note in notes) {
      batch.insert(
        'notes',
        {
          'id': note.id,
          'item_id': note.itemId,
          'text': note.text,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// Get all notes
  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes');
    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i]['id'] as String,
        itemId: maps[i]['item_id'] as String,
        text: maps[i]['text'] as String,
      );
    });
  }

  /// Get notes by item ID
  Future<List<Note>> getNotesByItemId(String itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i]['id'] as String,
        itemId: maps[i]['item_id'] as String,
        text: maps[i]['text'] as String,
      );
    });
  }

  /// Delete all notes
  Future<void> deleteAllNotes() async {
    final db = await database;
    await db.delete('notes');
  }

  /// Clear all data (notes, items, subcategories, categories)
  Future<void> clearAllData() async {
    final db = await database;
    final batch = db.batch();
    batch.delete('notes');
    batch.delete('items');
    batch.delete('sub_categories');
    batch.delete('categories');
    await batch.commit(noResult: true);
  }
}
