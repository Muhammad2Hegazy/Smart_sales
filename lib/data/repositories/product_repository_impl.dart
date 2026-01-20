import '../../domain/entities/item_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../../core/database/database_helper.dart';

class ProductRepositoryImpl implements IProductRepository {
  final DatabaseHelper _dbHelper;

  ProductRepositoryImpl(this._dbHelper);

  @override
  Future<List<CategoryEntity>> getAllCategories() async {
    final categories = await _dbHelper.getAllCategories();
    return categories.map((c) => CategoryEntity(
      id: c.id,
      name: c.name,
    )).toList();
  }

  @override
  Future<List<ItemEntity>> getAllItems() async {
    final items = await _dbHelper.getAllItems();
    return items.map((i) => ItemEntity(
      id: i.id,
      name: i.name,
      subCategoryId: i.subCategoryId,
      price: i.price,
      imageUrl: i.imageUrl,
      stockQuantity: i.stockQuantity,
      stockUnit: i.stockUnit,
      conversionRate: i.conversionRate,
      isPosOnly: i.isPosOnly,
    )).toList();
  }

  @override
  Future<List<ItemEntity>> getItemsByCategoryId(String categoryId) async {
    // Current DB schema uses subcategories.
    // This is a simplified implementation for the demonstration of the pattern.
    final items = await _dbHelper.getAllItems();
    return items.map((i) => ItemEntity(
      id: i.id,
      name: i.name,
      subCategoryId: i.subCategoryId,
      price: i.price,
      imageUrl: i.imageUrl,
      stockQuantity: i.stockQuantity,
      stockUnit: i.stockUnit,
      conversionRate: i.conversionRate,
      isPosOnly: i.isPosOnly,
    )).toList();
  }

  @override
  Future<ItemEntity?> getItemById(String id) async {
    final item = await _dbHelper.getItemById(id);
    if (item == null) return null;
    return ItemEntity(
      id: item.id,
      name: item.name,
      subCategoryId: item.subCategoryId,
      price: item.price,
      imageUrl: item.imageUrl,
      stockQuantity: item.stockQuantity,
      stockUnit: item.stockUnit,
      conversionRate: item.conversionRate,
      isPosOnly: item.isPosOnly,
    );
  }

  @override
  Future<void> updateItemStock(String itemId, double quantity, String unit) async {
    await _dbHelper.updateItemStock(itemId, quantity, unit);
  }
}
