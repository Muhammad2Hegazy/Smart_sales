import 'item.dart';

class SubCategory {
  final String id;
  final String name;
  final String categoryId;
  final List<Item> items;

  const SubCategory({
    required this.id,
    required this.name,
    required this.categoryId,
    this.items = const [],
  });

  SubCategory copyWith({
    String? id,
    String? name,
    String? categoryId,
    List<Item>? items,
  }) {
    return SubCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
    };
  }

  factory SubCategory.fromMap(Map<String, dynamic> map) {
    return SubCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      categoryId: map['category_id'] as String? ?? map['categoryId'] as String,
    );
  }
}

