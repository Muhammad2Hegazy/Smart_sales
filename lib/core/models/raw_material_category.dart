import 'raw_material_sub_category.dart';

class RawMaterialCategory {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RawMaterialSubCategory> subCategories;

  const RawMaterialCategory({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.subCategories = const [],
  });

  RawMaterialCategory copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RawMaterialSubCategory>? subCategories,
  }) {
    return RawMaterialCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subCategories: subCategories ?? this.subCategories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RawMaterialCategory.fromMap(Map<String, dynamic> map) {
    return RawMaterialCategory(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
      subCategories: const [],
    );
  }
}

