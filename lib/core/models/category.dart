import 'sub_category.dart';

class Category {
  final String id;
  final String name;
  final List<SubCategory> subCategories;

  const Category({
    required this.id,
    required this.name,
    this.subCategories = const [],
  });

  Category copyWith({
    String? id,
    String? name,
    List<SubCategory>? subCategories,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      subCategories: subCategories ?? this.subCategories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
    );
  }
}

