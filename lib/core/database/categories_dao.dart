import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'base_dao.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import 'devices_dao.dart';

/// Data Access Object for Category and SubCategory operations
class CategoriesDao extends BaseDao {
  final DevicesDao _devicesDao = DevicesDao();

  // ============ Categories ============

  /// Insert multiple categories
  Future<void> insertCategories(List<Category> categories) async {
    final db = await database;
    final batch = db.batch();
    
    final master = await _devicesDao.getMaster();
    final masterDeviceId = master?.masterDeviceId ?? '';
    final now = DateTime.now().toIso8601String();
    
    for (var category in categories) {
      batch.insert(
        'categories',
        {
          'id': category.id,
          'name': category.name,
          'master_device_id': masterDeviceId,
          'sync_status': 'pending',
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// Get all categories
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

  /// Delete all categories
  Future<void> deleteAllCategories() async {
    final db = await database;
    await db.delete('categories');
  }

  /// Create a new category
  Future<Category> createCategory(String name) async {
    final db = await database;
    final id = const Uuid().v4();
    await db.insert('categories', {
      'id': id,
      'name': name,
    });
    return Category(id: id, name: name);
  }

  /// Get category ID by name
  Future<String?> getCategoryId(String name) async {
    final db = await database;
    final result = await db.query(
      'raw_material_categories',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (result.isNotEmpty) {
      return result.first['id'] as String;
    }
    return null;
  }

  // ============ SubCategories ============

  /// Insert multiple subcategories
  Future<void> insertSubCategories(List<SubCategory> subCategories) async {
    final db = await database;
    final batch = db.batch();
    
    final master = await _devicesDao.getMaster();
    final masterDeviceId = master?.masterDeviceId ?? '';
    final now = DateTime.now().toIso8601String();
    
    for (var subCategory in subCategories) {
      batch.insert(
        'sub_categories',
        {
          'id': subCategory.id,
          'name': subCategory.name,
          'category_id': subCategory.categoryId,
          'master_device_id': masterDeviceId,
          'sync_status': 'pending',
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// Get all subcategories
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

  /// Get subcategories by category ID
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

  /// Delete all subcategories
  Future<void> deleteAllSubCategories() async {
    final db = await database;
    await db.delete('sub_categories');
  }

  /// Create a new subcategory
  Future<SubCategory> createSubCategory(String name, String categoryId) async {
    final db = await database;
    final id = const Uuid().v4();
    await db.insert('sub_categories', {
      'id': id,
      'name': name,
      'category_id': categoryId,
    });
    return SubCategory(id: id, name: name, categoryId: categoryId);
  }
}
