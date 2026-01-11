import 'recipe_ingredient.dart';

class Recipe {
  final String id;
  final String itemId; // The product/item this recipe is for
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RecipeIngredient> ingredients;

  const Recipe({
    required this.id,
    required this.itemId,
    required this.createdAt,
    required this.updatedAt,
    this.ingredients = const [],
  });

  Recipe copyWith({
    String? id,
    String? itemId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RecipeIngredient>? ingredients,
  }) {
    return Recipe(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ingredients: ingredients ?? this.ingredients,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id']?.toString() ?? '',
      itemId: map['item_id']?.toString() ?? '',
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
      ingredients: const [],
    );
  }
}

