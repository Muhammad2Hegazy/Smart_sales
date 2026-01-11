import 'raw_material.dart';

class RawMaterialSubCategory {
  final String id;
  final String name;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RawMaterial> materials;

  const RawMaterialSubCategory({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.materials = const [],
  });

  RawMaterialSubCategory copyWith({
    String? id,
    String? name,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RawMaterial>? materials,
  }) {
    return RawMaterialSubCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      materials: materials ?? this.materials,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RawMaterialSubCategory.fromMap(Map<String, dynamic> map) {
    return RawMaterialSubCategory(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
      materials: const [],
    );
  }
}

