class RecipeIngredient {
  final String id;
  final String recipeId;
  final String rawMaterialId;
  final double quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.rawMaterialId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'raw_material_id': rawMaterialId,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      id: map['id']?.toString() ?? '',
      recipeId: map['recipe_id']?.toString() ?? '',
      rawMaterialId: map['raw_material_id']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  RecipeIngredient copyWith({
    String? id,
    String? recipeId,
    String? rawMaterialId,
    double? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecipeIngredient(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      rawMaterialId: rawMaterialId ?? this.rawMaterialId,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

