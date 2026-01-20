part of 'database_helper.dart';

extension DatabaseHelperRawMaterials on DatabaseHelper {
  // Raw Material Categories CRUD
  Future<void> insertRawMaterialCategory(RawMaterialCategory category) async {
    final db = await database;
    await db.insert(
      'raw_material_categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RawMaterialCategory>> getAllRawMaterialCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_material_categories',
      orderBy: 'name ASC',
    );
    final categories = <RawMaterialCategory>[];
    
    for (var map in maps) {
      final category = RawMaterialCategory.fromMap(map);
      final subCategories = await getRawMaterialSubCategoriesByCategoryId(category.id);
      categories.add(category.copyWith(subCategories: subCategories));
    }
    
    return categories;
  }

  Future<void> deleteRawMaterialCategory(String id) async {
    final db = await database;
    await db.delete('raw_material_categories', where: 'id = ?', whereArgs: [id]);
  }

  // Raw Material Sub Categories CRUD
  Future<void> insertRawMaterialSubCategory(RawMaterialSubCategory subCategory) async {
    final db = await database;
    await db.insert(
      'raw_material_sub_categories',
      subCategory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RawMaterialSubCategory>> getAllRawMaterialSubCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_material_sub_categories',
      orderBy: 'name ASC',
    );
    final subCategories = <RawMaterialSubCategory>[];
    
    for (var map in maps) {
      final subCategory = RawMaterialSubCategory.fromMap(map);
      final materials = await getRawMaterialsBySubCategoryId(subCategory.id);
      subCategories.add(subCategory.copyWith(materials: materials));
    }
    
    return subCategories;
  }

  Future<List<RawMaterialSubCategory>> getRawMaterialSubCategoriesByCategoryId(String categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_material_sub_categories',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    final subCategories = <RawMaterialSubCategory>[];
    
    for (var map in maps) {
      final subCategory = RawMaterialSubCategory.fromMap(map);
      final materials = await getRawMaterialsBySubCategoryId(subCategory.id);
      subCategories.add(subCategory.copyWith(materials: materials));
    }
    
    return subCategories;
  }

  Future<void> deleteRawMaterialSubCategory(String id) async {
    final db = await database;
    await db.delete('raw_material_sub_categories', where: 'id = ?', whereArgs: [id]);
  }

  // Raw Materials CRUD
  Future<void> insertRawMaterial(RawMaterial material) async {
    final db = await database;
    await db.insert(
      'raw_materials',
      material.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertRawMaterials(List<RawMaterial> materials) async {
    final db = await database;
    final batch = db.batch();
    for (var material in materials) {
      batch.insert(
        'raw_materials',
        material.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<RawMaterial>> getAllRawMaterials() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('raw_materials', orderBy: 'name ASC');
    final materials = <RawMaterial>[];
    
    // Load batches for each material
    for (var map in maps) {
      final material = RawMaterial.fromMap(map);
      final batches = await getRawMaterialBatches(material.id);
      materials.add(material.copyWith(batches: batches));
    }
    
    return materials;
  }

  Future<List<RawMaterial>> getRawMaterialsBySubCategoryId(String subCategoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_materials',
      where: 'sub_category_id = ?',
      whereArgs: [subCategoryId],
      orderBy: 'name ASC',
    );
    final materials = <RawMaterial>[];
    
    // Load batches for each material
    for (var map in maps) {
      final material = RawMaterial.fromMap(map);
      final batches = await getRawMaterialBatches(material.id);
      materials.add(material.copyWith(batches: batches));
    }
    
    return materials;
  }

  Future<void> deleteAllRawMaterials() async {
    final db = await database;
    await db.delete('raw_material_batches');
    await db.delete('raw_materials');
    await db.delete('raw_material_sub_categories');
    await db.delete('raw_material_categories');
  }

  Future<RawMaterial?> getRawMaterialById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_materials',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final material = RawMaterial.fromMap(maps.first);
    final batches = await getRawMaterialBatches(id);
    return material.copyWith(batches: batches);
  }

  Future<void> updateRawMaterial(RawMaterial material) async {
    final db = await database;
    await db.update(
      'raw_materials',
      material.toMap(),
      where: 'id = ?',
      whereArgs: [material.id],
    );
  }

  Future<void> deleteRawMaterial(String id) async {
    final db = await database;
    // Batches will be deleted automatically due to CASCADE
    await db.delete('raw_materials', where: 'id = ?', whereArgs: [id]);
  }

  // Raw Material Batches CRUD
  Future<void> insertRawMaterialBatch(RawMaterialBatch batch) async {
    final db = await database;
    await db.insert(
      'raw_material_batches',
      batch.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Recalculate stock quantity from all batches
    await _recalculateStockQuantity(batch.rawMaterialId);
    
    // Update raw material updated_at
    await db.update(
      'raw_materials',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [batch.rawMaterialId],
    );
  }

  Future<void> insertRawMaterialBatches(List<RawMaterialBatch> batches) async {
    final db = await database;
    final batch = db.batch();
    for (var batchItem in batches) {
      batch.insert(
        'raw_material_batches',
        batchItem.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<RawMaterialBatch>> getRawMaterialBatches(String rawMaterialId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_material_batches',
      where: 'raw_material_id = ?',
      whereArgs: [rawMaterialId],
      orderBy: 'expiry_date ASC',
    );
    return maps.map((map) => RawMaterialBatch.fromMap(map)).toList();
  }

  Future<RawMaterialBatch?> getRawMaterialBatchById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_material_batches',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RawMaterialBatch.fromMap(maps.first);
  }

  Future<void> updateRawMaterialBatch(RawMaterialBatch batch) async {
    final db = await database;
    await db.update(
      'raw_material_batches',
      batch.toMap(),
      where: 'id = ?',
      whereArgs: [batch.id],
    );
    
    // Recalculate stock quantity from all batches
    await _recalculateStockQuantity(batch.rawMaterialId);
    
    // Update raw material updated_at
    await db.update(
      'raw_materials',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [batch.rawMaterialId],
    );
  }

  /// Recalculate stock quantity from all batches
  Future<void> _recalculateStockQuantity(String rawMaterialId) async {
    final db = await database;
    final batches = await getRawMaterialBatches(rawMaterialId);
    final totalQuantity = batches.fold<double>(0.0, (sum, batch) => sum + batch.quantity);
    
    await db.update(
      'raw_materials',
      {
        'stock_quantity': totalQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [rawMaterialId],
    );
  }

  Future<void> deleteRawMaterialBatch(String id) async {
    final db = await database;
    // Get batch to update raw material
    final batch = await getRawMaterialBatchById(id);
    if (batch != null) {
      await db.delete('raw_material_batches', where: 'id = ?', whereArgs: [id]);
    
      // Recalculate stock quantity from all remaining batches
      await _recalculateStockQuantity(batch.rawMaterialId);
      
      // Update raw material updated_at
      await db.update(
        'raw_materials',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [batch.rawMaterialId],
      );
    } else {
      await db.delete('raw_material_batches', where: 'id = ?', whereArgs: [id]);
    }
  }

  // Recipes CRUD
  Future<void> insertRecipe(Recipe recipe) async {
    final db = await database;
    await db.insert(
      'recipes',
      recipe.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertRecipes(List<Recipe> recipes) async {
    final db = await database;
    final batch = db.batch();
    for (var recipe in recipes) {
      batch.insert(
        'recipes',
        recipe.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<Recipe?> getRecipeByItemId(String itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: 'item_id = ?',
      whereArgs: [itemId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final recipe = Recipe.fromMap(maps.first);
    final ingredients = await getRecipeIngredients(recipe.id);
    return recipe.copyWith(ingredients: ingredients);
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('recipes');
    final recipes = <Recipe>[];
    
    for (var map in maps) {
      final recipe = Recipe.fromMap(map);
      final ingredients = await getRecipeIngredients(recipe.id);
      recipes.add(recipe.copyWith(ingredients: ingredients));
    }
    
    return recipes;
  }

  Future<void> updateRecipe(Recipe recipe) async {
    final db = await database;
    await db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<void> deleteRecipe(String id) async {
    final db = await database;
    // Ingredients will be deleted automatically due to CASCADE
    await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  // Recipe Ingredients CRUD
  Future<void> insertRecipeIngredient(RecipeIngredient ingredient) async {
    final db = await database;
    await db.insert(
      'recipe_ingredients',
      ingredient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Update recipe updated_at
    await db.update(
      'recipes',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [ingredient.recipeId],
    );
  }

  Future<void> insertRecipeIngredients(List<RecipeIngredient> ingredients) async {
    final db = await database;
    final batch = db.batch();
    for (var ingredient in ingredients) {
      batch.insert(
        'recipe_ingredients',
        ingredient.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<RecipeIngredient>> getRecipeIngredients(String recipeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipe_ingredients',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
    return maps.map((map) => RecipeIngredient.fromMap(map)).toList();
  }

  Future<void> updateRecipeIngredient(RecipeIngredient ingredient) async {
    final db = await database;
    await db.update(
      'recipe_ingredients',
      ingredient.toMap(),
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );
    
    // Update recipe updated_at
    await db.update(
      'recipes',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [ingredient.recipeId],
    );
  }

  Future<void> deleteRecipeIngredient(String id) async {
    final db = await database;
    // Get ingredient to update recipe
    final ingredient = await getRecipeIngredientById(id);
    await db.delete('recipe_ingredients', where: 'id = ?', whereArgs: [id]);
    
    if (ingredient != null) {
      // Update recipe updated_at
      await db.update(
        'recipes',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [ingredient.recipeId],
      );
    }
  }

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

  // Inventory deduction methods
  /// Deduct raw materials from inventory based on recipe when item is sold
  /// Returns list of low stock warnings if any raw materials are running low
  Future<List<LowStockWarning>> deductInventoryForSale(String itemId, int quantity) async {
    // Convert int to double for calculations
    final quantityDouble = quantity.toDouble();
    final warnings = <LowStockWarning>[];
    debugPrint('deductInventoryForSale called: itemId=$itemId, quantity=$quantity');
    final recipe = await getRecipeByItemId(itemId);
    if (recipe == null || recipe.ingredients.isEmpty) {
      // No recipe found, nothing to deduct
      debugPrint('No recipe found for itemId=$itemId or recipe has no ingredients');
      return warnings;
    }
    
    debugPrint('Recipe found for itemId=$itemId with ${recipe.ingredients.length} ingredients');
    
    // For each ingredient in the recipe, deduct the required quantity
    for (var ingredient in recipe.ingredients) {
      final requiredQuantity = ingredient.quantity * quantityDouble;
      debugPrint('Processing ingredient: rawMaterialId=${ingredient.rawMaterialId}, quantityPerUnit=${ingredient.quantity}, totalRequired=$requiredQuantity');
      
      // Get all batches for this raw material, ordered by expiry date (FIFO)
      final batches = await getRawMaterialBatches(ingredient.rawMaterialId);
      debugPrint('Found ${batches.length} batches for raw material ${ingredient.rawMaterialId}');
      batches.sort((a, b) {
        if (a.expiryDate == null && b.expiryDate == null) return 0;
        if (a.expiryDate == null) return 1; // nulls go to end
        if (b.expiryDate == null) return -1; // nulls go to end
        return a.expiryDate!.compareTo(b.expiryDate!);
      });
      
      double remainingToDeduct = requiredQuantity;
      double totalDeducted = 0.0;
      
      for (var batch in batches) {
        if (remainingToDeduct <= 0) break;
        
        if (batch.quantity > 0) {
          final toDeduct = remainingToDeduct > batch.quantity 
              ? batch.quantity 
              : remainingToDeduct;
          
          debugPrint('Deducting $toDeduct from batch ${batch.id} (current quantity: ${batch.quantity})');
          
          final newQuantity = batch.quantity - toDeduct;
          
          if (newQuantity <= 0) {
            // Delete batch if quantity becomes zero or negative
            debugPrint('Deleting batch ${batch.id} (quantity would be $newQuantity)');
            await deleteRawMaterialBatch(batch.id);
          } else {
            // Update batch with new quantity
            final updatedBatch = batch.copyWith(
              quantity: newQuantity,
              updatedAt: DateTime.now(),
            );
            debugPrint('Updating batch ${batch.id} to quantity $newQuantity');
            await updateRawMaterialBatch(updatedBatch);
          }
          
          totalDeducted += toDeduct;
          remainingToDeduct -= toDeduct;
        }
      }
      
      debugPrint('Total deducted: $totalDeducted, Remaining: $remainingToDeduct');
      
      // If we couldn't deduct all required quantity, log a warning
      if (remainingToDeduct > 0) {
        debugPrint('Warning: Could not deduct full quantity for raw material ${ingredient.rawMaterialId}. Required: $requiredQuantity, Deducted: ${requiredQuantity - remainingToDeduct}');
      } else {
        debugPrint('Successfully deducted $totalDeducted for raw material ${ingredient.rawMaterialId}');
      }
      
      // Check for low stock after deduction
      final rawMaterial = await getRawMaterialById(ingredient.rawMaterialId);
      if (rawMaterial != null) {
        final warning = _checkLowStock(
          rawMaterial: rawMaterial,
          requiredQuantity: requiredQuantity,
        );
        if (warning != null) {
          warnings.add(warning);
        }
      }
    }
    
    return warnings;
  }

  /// Check if raw material stock is low and return warning if needed
  LowStockWarning? _checkLowStock({
    required RawMaterial rawMaterial,
    required double requiredQuantity,
  }) {
    final currentQuantity = rawMaterial.totalQuantity;
    
    // Calculate percentage remaining (assuming we need at least 10x the required quantity for safety)
    final minimumSafeQuantity = requiredQuantity * 10;
    final percentageRemaining = minimumSafeQuantity > 0 
        ? (currentQuantity / minimumSafeQuantity) * 100 
        : 0.0;
    
    // Show warning if stock is below 25% of safe minimum
    if (currentQuantity <= 0 || percentageRemaining < 25) {
      return LowStockWarning(
        rawMaterialId: rawMaterial.id,
        rawMaterialName: rawMaterial.name,
        currentQuantity: currentQuantity,
        requiredQuantity: requiredQuantity,
        unit: rawMaterial.unit,
        percentageRemaining: percentageRemaining.clamp(0.0, 100.0),
      );
    }
    
    return null;
  }

  // ============================================
  // Restaurant Inventory Management Functions
  // ============================================

  /// Convert quantity from input unit to base unit
  /// Returns converted quantity in base unit
  Future<double> convertToBaseUnit(String rawMaterialId, double quantity, String unit) async {
    final db = await database;
    
    // Get raw material
    final material = await getRawMaterialById(rawMaterialId);
    if (material == null) {
      throw Exception('Raw material not found: $rawMaterialId');
    }
    
    // If unit is already base unit, return as is
    if (unit.toLowerCase() == material.baseUnit.toLowerCase()) {
      return quantity;
    }
    
    // Get conversion factor from raw_material_units table
    final unitMaps = await db.query(
      'raw_material_units',
      where: 'raw_material_id = ? AND unit = ?',
      whereArgs: [rawMaterialId, unit.toLowerCase()],
      limit: 1,
    );
    
    if (unitMaps.isNotEmpty) {
      final conversionFactor = (unitMaps.first['conversion_factor_to_base'] as num).toDouble();
      return quantity * conversionFactor;
    }
    
    // Default conversions for common units
    final baseUnit = material.baseUnit.toLowerCase();
    final inputUnit = unit.toLowerCase();
    
    // Weight conversions (gram is base)
    if (baseUnit == 'gram') {
      if (inputUnit == 'kilogram' || inputUnit == 'kg' || inputUnit == 'كيلو') {
        return quantity * 1000.0; // 1 kg = 1000 grams
      }
      if (inputUnit == 'gram' || inputUnit == 'g' || inputUnit == 'جرام') {
        return quantity;
      }
    }
    
    // Volume conversions (ml is base)
    if (baseUnit == 'ml') {
      if (inputUnit == 'liter' || inputUnit == 'l' || inputUnit == 'لتر') {
        return quantity * 1000.0; // 1 L = 1000 ml
      }
      if (inputUnit == 'ml' || inputUnit == 'مل') {
        return quantity;
      }
    }
    
    // Piece has no conversion (1:1)
    if (baseUnit == 'piece' && (inputUnit == 'piece' || inputUnit == 'قطعة')) {
      return quantity;
    }
    
    // Carton conversions (carton is base)
    if (baseUnit == 'carton') {
      if (inputUnit == 'carton' || inputUnit == 'كرتونة') {
        return quantity;
      }
      if (inputUnit == 'bottle' || inputUnit == 'زجاجة') {
        // Default: 1 bottle = 1/20 carton
        return quantity / 20.0;
      }
    }
    
    // Packet conversions (packet is base, 1 packet = 10kg = 10000g)
    if (baseUnit == 'packet') {
      if (inputUnit == 'packet' || inputUnit == 'باكيت') {
        return quantity;
      }
      if (inputUnit == 'kilogram' || inputUnit == 'kg' || inputUnit == 'كيلو') {
        // 1 packet = 10kg, so 1 kg = 0.1 packet
        return quantity * 0.1;
      }
      if (inputUnit == 'gram' || inputUnit == 'g' || inputUnit == 'جرام') {
        // 1 packet = 10000g, so 1g = 0.0001 packet
        return quantity * 0.0001;
      }
    }
    
    // Jar conversions (jar is base, 1:1)
    if (baseUnit == 'jar') {
      if (inputUnit == 'jar' || inputUnit == 'جرة') {
        return quantity;
      }
    }
    
    throw Exception('Invalid unit conversion: $unit to $baseUnit');
  }

  /// Add raw material to stock
  /// Accepts quantity + unit, converts to base unit, increases stock_quantity
  Future<void> addRawMaterialStock(String rawMaterialId, double quantity, String unit) async {
    final db = await database;
    
    // Convert to base unit
    final quantityInBaseUnit = await convertToBaseUnit(rawMaterialId, quantity, unit);
    
    // Get current stock
    final material = await getRawMaterialById(rawMaterialId);
    if (material == null) {
      throw Exception('Raw material not found: $rawMaterialId');
    }
    
    // Update stock quantity
    final newStockQuantity = material.stockQuantity + quantityInBaseUnit;
    
    await db.update(
      'raw_materials',
      {
        'stock_quantity': newStockQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [rawMaterialId],
    );
    
    debugPrint('Added $quantity $unit ($quantityInBaseUnit ${material.baseUnit}) to ${material.name}. New stock: $newStockQuantity');
  }

  /// Calculate and deduct stock for invoice items
  /// Returns list of low stock warnings
  Future<List<String>> calculateAndDeductStock(List<Map<String, dynamic>> invoiceItems) async {
    final db = await database;
    final warnings = <String>[];
    
    // First, validate all stock is sufficient
    for (var invoiceItem in invoiceItems) {
      final itemId = invoiceItem['item_id'] as String;
      final quantitySold = (invoiceItem['quantity_sold'] as num).toDouble();
      
      // Get recipe for this item
      final recipe = await getRecipeByItemId(itemId);
      if (recipe == null) {
        continue; // Item has no recipe, skip
      }
      
      // For each ingredient in recipe
      for (var ingredient in recipe.ingredients) {
        final rawMaterialId = ingredient.rawMaterialId;
        final quantityRequiredPerItem = ingredient.quantityRequiredInBaseUnit;
        final totalQuantityRequired = quantityRequiredPerItem * quantitySold;
        
        // Get current stock
        final material = await getRawMaterialById(rawMaterialId);
        if (material == null) {
          throw Exception('Raw material not found: $rawMaterialId');
        }
        
        // Check if stock is sufficient
        if (material.stockQuantity < totalQuantityRequired) {
          throw Exception(
            'Insufficient stock for ${material.name}. '
            'Required: $totalQuantityRequired ${material.baseUnit}, '
            'Available: ${material.stockQuantity} ${material.baseUnit}'
          );
        }
      }
    }
    
    // All stock validated, now deduct
    for (var invoiceItem in invoiceItems) {
      final itemId = invoiceItem['item_id'] as String;
      final quantitySold = (invoiceItem['quantity_sold'] as num).toDouble();
      
      // Get recipe for this item
      final recipe = await getRecipeByItemId(itemId);
      if (recipe == null) {
        continue; // Item has no recipe, skip
      }
      
      // For each ingredient in recipe
      for (var ingredient in recipe.ingredients) {
        final rawMaterialId = ingredient.rawMaterialId;
        final quantityRequiredPerItem = ingredient.quantityRequiredInBaseUnit;
        final totalQuantityRequired = quantityRequiredPerItem * quantitySold;
        
        // Get current stock
        final material = await getRawMaterialById(rawMaterialId);
        if (material == null) {
          continue;
        }
        
        // Deduct from stock
        final newStockQuantity = material.stockQuantity - totalQuantityRequired;
        
        await db.update(
          'raw_materials',
          {
            'stock_quantity': newStockQuantity,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [rawMaterialId],
        );
        
        // Check for low stock alert
        if (newStockQuantity <= material.minimumAlertQuantity) {
          warnings.add('⚠️ Raw material ${material.name} is running low. '
                      'Current: $newStockQuantity ${material.baseUnit}, '
                      'Minimum: ${material.minimumAlertQuantity} ${material.baseUnit}');
        }
      }
    }
    
    return warnings;
  }

  /// Create invoice and process stock deduction
  /// Returns invoice ID and list of warnings
  Future<Map<String, dynamic>> createInvoice({
    required DateTime date,
    required double totalAmount,
    required List<Map<String, dynamic>> invoiceItems,
  }) async {
    final db = await database;
    final uuid = const Uuid();
    final now = DateTime.now();
    
    // Validate and deduct stock
    final warnings = await calculateAndDeductStock(invoiceItems);
    
    // Create invoice
    final invoiceId = uuid.v4();
    await db.insert('invoices', {
      'id': invoiceId,
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    
    // Create invoice items
    for (var item in invoiceItems) {
      await db.insert('invoice_items', {
        'id': uuid.v4(),
        'invoice_id': invoiceId,
        'item_id': item['item_id'] as String,
        'quantity_sold': item['quantity_sold'] as num,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }
    
    return {
      'invoice_id': invoiceId,
      'warnings': warnings,
    };
  }

  // Raw Material Units CRUD
  Future<void> insertRawMaterialUnit(RawMaterialUnit unit) async {
    final db = await database;
    await db.insert(
      'raw_material_units',
      unit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RawMaterialUnit>> getRawMaterialUnits(String rawMaterialId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_material_units',
      where: 'raw_material_id = ?',
      whereArgs: [rawMaterialId],
    );
    return maps.map((map) => RawMaterialUnit.fromMap(map)).toList();
  }

  // Invoices CRUD
  Future<void> insertInvoice(Invoice invoice) async {
    final db = await database;
    await db.insert(
      'invoices',
      invoice.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      orderBy: 'date DESC',
    );
    final invoices = <Invoice>[];
    
    for (var map in maps) {
      final invoice = Invoice.fromMap(map);
      final items = await getInvoiceItemsByInvoiceId(invoice.id);
      invoices.add(invoice.copyWith(items: items));
    }
    
    return invoices;
  }

  Future<List<InvoiceItem>> getInvoiceItemsByInvoiceId(String invoiceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return maps.map((map) => InvoiceItem.fromMap(map)).toList();
  }
}
