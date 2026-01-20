part of 'database_helper.dart';

extension DatabaseHelperItems on DatabaseHelper {
  // Categories CRUD
  Future<void> insertCategories(List<Category> categories) async {
    final db = await database;
    final batch = db.batch();
    
    for (var category in categories) {
      batch.insert(
        'categories',
        {
          'id': category.id,
          'name': category.name,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) {
      return Category(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
      );
    });
  }

  Future<void> deleteAllCategories() async {
    final db = await database;
    await db.delete('categories');
  }

  // SubCategories CRUD
  Future<void> insertSubCategories(List<SubCategory> subCategories) async {
    final db = await database;
    final batch = db.batch();
    
    for (var subCategory in subCategories) {
      batch.insert(
        'sub_categories',
        {
          'id': subCategory.id,
          'name': subCategory.name,
          'category_id': subCategory.categoryId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<SubCategory>> getAllSubCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sub_categories');
    return List.generate(maps.length, (i) {
      return SubCategory(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        categoryId: maps[i]['category_id'] as String,
      );
    });
  }

  Future<List<SubCategory>> getSubCategoriesByCategoryId(String categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sub_categories',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return List.generate(maps.length, (i) {
      return SubCategory(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        categoryId: maps[i]['category_id'] as String,
      );
    });
  }

  Future<void> deleteAllSubCategories() async {
    final db = await database;
    await db.delete('sub_categories');
  }

  // Items CRUD
  Future<void> insertItems(List<Item> items) async {
    final db = await database;
    final batch = db.batch();
    
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
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<void> updateItemStock(String itemId, double quantity, String unit) async {
    final db = await database;
    
    // Ensure stock columns exist before updating
    await _ensureStockColumnsExist(db);
    
    // Now update the stock
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

  Future<void> updateItemPriceAndStock(
    String itemId,
    double price,
    double quantity,
    String unit,
  ) async {
    final db = await database;
    
    // Ensure stock columns exist before updating
    await _ensureStockColumnsExist(db);
    
    // Update both price and stock
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

  Future<List<Item>> getAllItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('items');
    return maps.map((map) => Item.fromMap(map)).toList();
  }

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

  Future<List<Item>> getItemsBySubCategoryId(String subCategoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'sub_category_id = ?',
      whereArgs: [subCategoryId],
    );
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  Future<void> deleteAllItems() async {
    final db = await database;
    await db.delete('items');
  }

  // Notes CRUD
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

  Future<void> deleteAllNotes() async {
    final db = await database;
    await db.delete('notes');
  }

  // Clear all data
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
