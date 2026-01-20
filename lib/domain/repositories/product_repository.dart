import '../entities/item_entity.dart';
import '../entities/category_entity.dart';

abstract class IProductRepository {
  Future<List<CategoryEntity>> getAllCategories();
  Future<List<ItemEntity>> getAllItems();
  Future<List<ItemEntity>> getItemsByCategoryId(String categoryId);
  Future<ItemEntity?> getItemById(String id);
  Future<void> updateItemStock(String itemId, double quantity, String unit);
}
