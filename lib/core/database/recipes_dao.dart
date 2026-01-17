import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'base_dao.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';

/// Data Access Object for Recipe and RecipeIngredient operations
class RecipesDao extends BaseDao {

  // ============ Recipes ============

  /// Insert a recipe
  Future<void> insertRecipe(Recipe recipe) async {
    final db = await database;
    await db.insert(
      'recipes',
      recipe.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple recipes
  Future<void> insertRecipes(List<Recipe> recipes) async {
    final db = await database;
    final batch = db.batch();
    for (var recipe in recipes) {
      batch.insert('recipes', recipe.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Get recipe by item ID
  Future<Recipe?> getRecipeByItemId(String itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: 'item_id = ?',
      whereArgs: [itemId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Recipe.fromMap(maps.first);
  }

  /// Get all recipes
  Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('recipes');
    return maps.map((map) => Recipe.fromMap(map)).toList();
  }

  /// Update a recipe
  Future<void> updateRecipe(Recipe recipe) async {
    final db = await database;
    await db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  /// Delete a recipe
  Future<void> deleteRecipe(String id) async {
    final db = await database;
    await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Recipe Ingredients ============

  /// Insert a recipe ingredient
  Future<void> insertRecipeIngredient(RecipeIngredient ingredient) async {
    final db = await database;
    await db.insert(
      'recipe_ingredients',
      ingredient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple recipe ingredients
  Future<void> insertRecipeIngredients(List<RecipeIngredient> ingredients) async {
    final db = await database;
    final batch = db.batch();
    for (var ingredient in ingredients) {
      batch.insert('recipe_ingredients', ingredient.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Get recipe ingredients by recipe ID
  Future<List<RecipeIngredient>> getRecipeIngredients(String recipeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipe_ingredients',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
    return maps.map((map) => RecipeIngredient.fromMap(map)).toList();
  }

  /// Update a recipe ingredient
  Future<void> updateRecipeIngredient(RecipeIngredient ingredient) async {
    final db = await database;
    await db.update(
      'recipe_ingredients',
      ingredient.toMap(),
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );
  }

  /// Delete a recipe ingredient
  Future<void> deleteRecipeIngredient(String id) async {
    final db = await database;
    await db.delete('recipe_ingredients', where: 'id = ?', whereArgs: [id]);
  }

  /// Get recipe ingredient by ID
  Future<RecipeIngredient?> getRecipeIngredientById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipe_ingredients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RecipeIngredient.fromMap(maps.first);
  }
}
