import 'category.dart';
import 'sub_category.dart';
import 'item.dart';

/// Result of importing items with categories and subcategories
class ImportResult {
  final List<Category> categories;
  final List<SubCategory> subCategories;
  final List<Item> items;

  ImportResult({
    required this.categories,
    required this.subCategories,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((e) => e.toMap()).toList(),
      'subCategories': subCategories.map((e) => e.toMap()).toList(),
      'items': items.map((e) => e.toMap()).toList(),
    };
  }

  factory ImportResult.fromJson(Map<String, dynamic> json) {
    return ImportResult(
      categories: (json['categories'] as List)
          .map((e) => Category.fromMap(e as Map<String, dynamic>))
          .toList(),
      subCategories: (json['subCategories'] as List)
          .map((e) => SubCategory.fromMap(e as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List)
          .map((e) => Item.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
