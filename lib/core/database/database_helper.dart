import 'dart:io';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/import_result.dart';
import '../utils/csv_importer.dart';

// Import all DAOs
import 'database_core.dart';
import 'categories_dao.dart';
import 'items_dao.dart';
import 'sales_dao.dart';
import 'financial_dao.dart';
import 'users_dao.dart';
import 'devices_dao.dart';
import 'pending_invoices_dao.dart';
import 'raw_materials_dao.dart';
import 'recipes_dao.dart';
import 'inventory_dao.dart';
import 'suppliers_dao.dart';

// Import models
import '../models/category.dart';
import '../models/sub_category.dart';
import '../models/item.dart';
import '../models/note.dart';
import '../models/sale.dart';
import '../models/financial_transaction.dart';
import '../models/user_profile.dart';
import '../models/user_permission.dart';
import '../models/master.dart';
import '../models/device.dart';
import '../models/raw_material.dart';
import '../models/raw_material_category.dart';
import '../models/raw_material_sub_category.dart';
import '../models/raw_material_batch.dart';
import '../models/raw_material_unit.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../models/inventory_movement.dart';
import '../models/low_stock_warning.dart';
import '../models/shift_report.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import '../models/invoice.dart';

/// Main DatabaseHelper facade class that provides backward-compatible access
/// to all database operations by delegating to specialized DAOs.
///
/// This class maintains the same API as the original monolithic DatabaseHelper
/// while internally using the new modular DAO structure.
class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Core database instance
  final DatabaseCore _core = DatabaseCore();

  // DAOs
  final CategoriesDao _categoriesDao = CategoriesDao();
  final ItemsDao _itemsDao = ItemsDao();
  final SalesDao _salesDao = SalesDao();
  final FinancialDao _financialDao = FinancialDao();
  final UsersDao _usersDao = UsersDao();
  final DevicesDao _devicesDao = DevicesDao();
  final PendingInvoicesDao _pendingInvoicesDao = PendingInvoicesDao();
  final RawMaterialsDao _rawMaterialsDao = RawMaterialsDao();
  final RecipesDao _recipesDao = RecipesDao();
  final InventoryDao _inventoryDao = InventoryDao();
  final SuppliersDao _suppliersDao = SuppliersDao();

  /// Get the database instance
  Future<Database> get database => _core.database;

  /// Initialize the database (call this before app starts)
  static Future<void> initialize() async {
    DatabaseCore.initialize();
  }

  /// Get database path
  Future<String> getDatabasePath() => _core.getDatabasePath();

  /// Close database connection
  Future<void> closeDatabase() => _core.closeDatabase();

  // ============================================================
  // Categories
  // ============================================================

  Future<void> insertCategories(List<Category> categories) =>
      _categoriesDao.insertCategories(categories);

  Future<List<Category>> getAllCategories() =>
      _categoriesDao.getAllCategories();

  Future<void> deleteAllCategories() => _categoriesDao.deleteAllCategories();

  Future<Category> createCategory(String name) =>
      _categoriesDao.createCategory(name);

  // ============================================================
  // SubCategories
  // ============================================================

  Future<void> insertSubCategories(List<SubCategory> subCategories) =>
      _categoriesDao.insertSubCategories(subCategories);

  Future<List<SubCategory>> getAllSubCategories() =>
      _categoriesDao.getAllSubCategories();

  Future<List<SubCategory>> getSubCategoriesByCategoryId(String categoryId) =>
      _categoriesDao.getSubCategoriesByCategoryId(categoryId);

  Future<void> deleteAllSubCategories() =>
      _categoriesDao.deleteAllSubCategories();

  Future<SubCategory> createSubCategory(String name, String categoryId) =>
      _categoriesDao.createSubCategory(name, categoryId);

  // ============================================================
  // Items
  // ============================================================

  Future<void> insertItems(List<Item> items) => _itemsDao.insertItems(items);

  Future<List<Item>> getAllItems() => _itemsDao.getAllItems();

  Future<Item?> getItemById(String id) => _itemsDao.getItemById(id);

  Future<List<Item>> getItemsBySubCategoryId(String subCategoryId) =>
      _itemsDao.getItemsBySubCategoryId(subCategoryId);

  Future<void> deleteAllItems() => _itemsDao.deleteAllItems();

  Future<void> updateItemStock(String itemId, double quantity, String unit) =>
      _itemsDao.updateItemStock(itemId, quantity, unit);

  Future<void> updateItemPriceAndStock(
    String itemId,
    double price,
    double quantity,
    String unit,
  ) => _itemsDao.updateItemPriceAndStock(itemId, price, quantity, unit);

  // ============================================================
  // Notes
  // ============================================================

  Future<void> insertNotes(List<Note> notes) => _itemsDao.insertNotes(notes);

  Future<List<Note>> getAllNotes() => _itemsDao.getAllNotes();

  Future<List<Note>> getNotesByItemId(String itemId) =>
      _itemsDao.getNotesByItemId(itemId);

  Future<void> deleteAllNotes() => _itemsDao.deleteAllNotes();

  Future<void> clearAllData() => _itemsDao.clearAllData();

  // ============================================================
  // JSON Import
  // ============================================================

  Future<void> importDataFromCsv({
    required String categoriesPath,
    required String subCategoriesPath,
    required String itemsPath,
  }) async {
    final importResult = await CsvImporter.importFromCsv(
      categoriesPath: categoriesPath,
      subCategoriesPath: subCategoriesPath,
      itemsPath: itemsPath,
    );
    await insertCategories(importResult.categories);
    await insertSubCategories(importResult.subCategories);
    await insertItems(importResult.items);
  }

  Future<void> importDataFromJson(String filePath) async {
    // Note: We need a way to load from JSON without ExcelImporter if we strictly remove it.
    // For now, let's just comment this out or implement a simple JSON loader.
    final jsonStr = await File(filePath).readAsString();
    final importResult = ImportResult.fromJson(json.decode(jsonStr));
    await insertCategories(importResult.categories);
    await insertSubCategories(importResult.subCategories);
    await insertItems(importResult.items);
  }

  // ============================================================
  // Sales
  // ============================================================

  Future<void> insertSale(Sale sale) => _salesDao.insertSale(sale);

  Future<List<Sale>> getAllSales() => _salesDao.getAllSales();

  Future<Sale?> getSaleById(String id) => _salesDao.getSaleById(id);

  Future<int> getSalesCount() => _salesDao.getSalesCount();

  Future<int> getTodaySalesCount() => _salesDao.getTodaySalesCount();

  Future<int> getNextInvoiceNumber() => _salesDao.getNextInvoiceNumber();

  Future<int> getNextOrderNumber() => _salesDao.getNextOrderNumber();

  Future<List<Sale>> getSalesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) => _salesDao.getSalesByDateRange(startDate, endDate);

  Future<List<Sale>> getSalesByDeviceIdsAndDateRange(
    List<String> deviceIds,
    DateTime startDate,
    DateTime endDate,
  ) => _salesDao.getSalesByDeviceIdsAndDateRange(deviceIds, startDate, endDate);

  Future<List<SaleItem>> getSaleItemsBySaleId(String saleId) =>
      _salesDao.getSaleItemsBySaleId(saleId);

  Future<double> getTotalSalesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) => _salesDao.getTotalSalesByDateRange(startDate, endDate);

  Future<double> getTotalHospitalitySalesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) => _salesDao.getTotalHospitalitySalesByDateRange(startDate, endDate);

  // ============================================================
  // Pending Invoices
  // ============================================================

  Future<void> savePendingInvoice({
    required List<String> tableNumbers,
    required List<Map<String, dynamic>> items,
    Map<String, int>? tableOrderNumbers,
    int? orderNumber,
    double discountPercentage = 0.0,
    double discountAmount = 0.0,
    double serviceCharge = 0.0,
    double deliveryTax = 0.0,
    double hospitalityTax = 0.0,
  }) => _pendingInvoicesDao.savePendingInvoice(
    tableNumbers: tableNumbers,
    items: items,
    tableOrderNumbers: tableOrderNumbers,
    orderNumber: orderNumber,
    discountPercentage: discountPercentage,
    discountAmount: discountAmount,
    serviceCharge: serviceCharge,
    deliveryTax: deliveryTax,
    hospitalityTax: hospitalityTax,
  );

  Future<Map<String, dynamic>?> getPendingInvoiceByTableNumbers(
    List<String> tableNumbers,
  ) => _pendingInvoicesDao.getPendingInvoiceByTableNumbers(tableNumbers);

  Future<List<Map<String, dynamic>>> getAllPendingInvoices() =>
      _pendingInvoicesDao.getAllPendingInvoices();

  Future<void> deletePendingInvoiceByTableNumbers(List<String> tableNumbers) =>
      _pendingInvoicesDao.deletePendingInvoiceByTableNumbers(tableNumbers);

  Future<void> deleteAllPendingInvoices() =>
      _pendingInvoicesDao.deleteAllPendingInvoices();

  // ============================================================
  // Financial Transactions
  // ============================================================

  Future<void> insertFinancialTransaction(FinancialTransaction transaction) =>
      _financialDao.insertFinancialTransaction(transaction);

  Future<List<FinancialTransaction>> getAllFinancialTransactions() =>
      _financialDao.getAllFinancialTransactions();

  Future<List<FinancialTransaction>> getFinancialTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) => _financialDao.getFinancialTransactionsByDateRange(startDate, endDate);

  Future<double> getTotalCashInByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) => _financialDao.getTotalCashInByDateRange(startDate, endDate);

  Future<double> getTotalCashOutByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) => _financialDao.getTotalCashOutByDateRange(startDate, endDate);

  // ============================================================
  // User Profiles
  // ============================================================

  Future<void> insertUserProfile(UserProfile profile, String passwordHash) =>
      _usersDao.insertUserProfile(profile, passwordHash);

  Future<UserProfile?> getUserProfile(String userId) =>
      _usersDao.getUserProfile(userId);

  Future<UserProfile?> getUserProfileByUsername(String username) =>
      _usersDao.getUserProfileByUsername(username);

  Future<String?> getUserPasswordHash(String userId) =>
      _usersDao.getUserPasswordHash(userId);

  Future<void> updateUserPassword(String userId, String newPasswordHash) =>
      _usersDao.updateUserPassword(userId, newPasswordHash);

  Future<List<UserProfile>> getAllUserProfiles() =>
      _usersDao.getAllUserProfiles();

  Future<void> updateUserRole(String userId, String role) =>
      _usersDao.updateUserRole(userId, role);

  Future<bool> adminExists() => _usersDao.adminExists();

  // ============================================================
  // User Permissions
  // ============================================================

  Future<void> insertUserPermission(UserPermission permission) =>
      _usersDao.insertUserPermission(permission);

  Future<List<UserPermission>> getUserPermissions(String userId) =>
      _usersDao.getUserPermissions(userId);

  Future<List<UserPermission>> getAllUserPermissions() =>
      _usersDao.getAllUserPermissions();

  Future<void> updateUserPermission(
    String userId,
    String permissionKey,
    bool allowed,
  ) => _usersDao.updateUserPermission(userId, permissionKey, allowed);

  Future<bool> hasPermission(String userId, String permissionKey) =>
      _usersDao.hasPermission(userId, permissionKey);

  // ============================================================
  // Masters
  // ============================================================

  Future<void> insertMaster(Master master) => _devicesDao.insertMaster(master);

  Future<Master?> getMaster() => _devicesDao.getMaster();

  Future<void> updateMasterName(String masterDeviceId, String newName) =>
      _devicesDao.updateMasterName(masterDeviceId, newName);

  // ============================================================
  // Devices
  // ============================================================

  Future<void> insertDevice(Device device) => _devicesDao.insertDevice(device);

  Future<List<Device>> getAllDevices() => _devicesDao.getAllDevices();

  Future<List<Device>> getDevicesByMasterId(String masterDeviceId) =>
      _devicesDao.getDevicesByMasterId(masterDeviceId);

  Future<Device?> getDeviceById(String deviceId) =>
      _devicesDao.getDeviceById(deviceId);

  Future<void> updateDeviceLastSeen(String deviceId) =>
      _devicesDao.updateDeviceLastSeen(deviceId);

  Future<void> deleteDevice(String deviceId) =>
      _devicesDao.deleteDevice(deviceId);

  Future<void> setDeviceAsMaster(String masterDeviceId, String deviceId) =>
      _devicesDao.setDeviceAsMaster(masterDeviceId, deviceId);

  Future<void> updateDeviceMacAddress(String deviceId, String macAddress) =>
      _devicesDao.updateDeviceMacAddress(deviceId, macAddress);

  Future<void> updateDeviceFloor(String deviceId, int? floor) =>
      _devicesDao.updateDeviceFloor(deviceId, floor);

  Future<Device?> getDeviceByMacAddress(String macAddress) =>
      _devicesDao.getDeviceByMacAddress(macAddress);

  Future<List<Device>> getDevicesByFloor(int? floor) =>
      _devicesDao.getDevicesByFloor(floor);

  // ============================================================
  // Sync
  // ============================================================

  Future<List<Map<String, dynamic>>> getPendingSyncRecords(
    String tableName,
    String masterDeviceId,
  ) => _devicesDao.getPendingSyncRecords(tableName, masterDeviceId);

  Future<void> updateSyncStatus(String tableName, String id, String status) =>
      _devicesDao.updateSyncStatus(tableName, id, status);

  // ============================================================
  // Raw Material Categories
  // ============================================================

  Future<void> insertRawMaterialCategory(RawMaterialCategory category) =>
      _rawMaterialsDao.insertRawMaterialCategory(category);

  Future<List<RawMaterialCategory>> getAllRawMaterialCategories() =>
      _rawMaterialsDao.getAllRawMaterialCategories();

  Future<void> deleteRawMaterialCategory(String id) =>
      _rawMaterialsDao.deleteRawMaterialCategory(id);

  // ============================================================
  // Raw Material SubCategories
  // ============================================================

  Future<void> insertRawMaterialSubCategory(
    RawMaterialSubCategory subCategory,
  ) => _rawMaterialsDao.insertRawMaterialSubCategory(subCategory);

  Future<List<RawMaterialSubCategory>> getAllRawMaterialSubCategories() =>
      _rawMaterialsDao.getAllRawMaterialSubCategories();

  Future<List<RawMaterialSubCategory>> getRawMaterialSubCategoriesByCategoryId(
    String categoryId,
  ) => _rawMaterialsDao.getRawMaterialSubCategoriesByCategoryId(categoryId);

  Future<void> deleteRawMaterialSubCategory(String id) =>
      _rawMaterialsDao.deleteRawMaterialSubCategory(id);

  // ============================================================
  // Raw Materials
  // ============================================================

  Future<void> insertRawMaterial(RawMaterial material) =>
      _rawMaterialsDao.insertRawMaterial(material);

  Future<void> insertRawMaterials(List<RawMaterial> materials) =>
      _rawMaterialsDao.insertRawMaterials(materials);

  Future<List<RawMaterial>> getAllRawMaterials() =>
      _rawMaterialsDao.getAllRawMaterials();

  Future<List<RawMaterial>> getRawMaterialsBySubCategoryId(
    String subCategoryId,
  ) => _rawMaterialsDao.getRawMaterialsBySubCategoryId(subCategoryId);

  Future<void> deleteAllRawMaterials() =>
      _rawMaterialsDao.deleteAllRawMaterials();

  Future<RawMaterial?> getRawMaterialById(String id) =>
      _rawMaterialsDao.getRawMaterialById(id);

  Future<void> updateRawMaterial(RawMaterial material) =>
      _rawMaterialsDao.updateRawMaterial(material);

  Future<void> deleteRawMaterial(String id) =>
      _rawMaterialsDao.deleteRawMaterial(id);

  // ============================================================
  // Raw Material Batches
  // ============================================================

  Future<void> insertRawMaterialBatch(RawMaterialBatch batch) =>
      _rawMaterialsDao.insertRawMaterialBatch(batch);

  Future<void> insertRawMaterialBatches(List<RawMaterialBatch> batches) =>
      _rawMaterialsDao.insertRawMaterialBatches(batches);

  Future<List<RawMaterialBatch>> getRawMaterialBatches(String rawMaterialId) =>
      _rawMaterialsDao.getRawMaterialBatches(rawMaterialId);

  Future<RawMaterialBatch?> getRawMaterialBatchById(String id) =>
      _rawMaterialsDao.getRawMaterialBatchById(id);

  Future<void> updateRawMaterialBatch(RawMaterialBatch batch) =>
      _rawMaterialsDao.updateRawMaterialBatch(batch);

  Future<void> deleteRawMaterialBatch(String id) =>
      _rawMaterialsDao.deleteRawMaterialBatch(id);

  // ============================================================
  // Raw Material Units
  // ============================================================

  Future<void> insertRawMaterialUnit(RawMaterialUnit unit) =>
      _rawMaterialsDao.insertRawMaterialUnit(unit);

  Future<List<RawMaterialUnit>> getRawMaterialUnits(String rawMaterialId) =>
      _rawMaterialsDao.getRawMaterialUnits(rawMaterialId);

  // ============================================================
  // Stock Management
  // ============================================================

  Future<void> addRawMaterialStock(
    String rawMaterialId,
    double quantity,
    String unit,
  ) => _rawMaterialsDao.addRawMaterialStock(rawMaterialId, quantity, unit);

  Future<double> convertToBaseUnit(
    String rawMaterialId,
    double quantity,
    String unit,
  ) => _rawMaterialsDao.convertToBaseUnit(rawMaterialId, quantity, unit);

  Future<Map<String, String>> formatStockForDisplay(String rawMaterialId) =>
      _rawMaterialsDao.formatStockForDisplay(rawMaterialId);

  Future<RawMaterial> createRawMaterial(
    String name,
    String unit,
    String subCategoryId, {
    String? baseUnit,
  }) => _rawMaterialsDao.createRawMaterial(
    name,
    unit,
    subCategoryId,
    baseUnit: baseUnit,
  );

  Future<RawMaterial> getOrCreateRawMaterial(
    String name,
    String unit,
    String subCategoryId, {
    String? baseUnit,
  }) => _rawMaterialsDao.getOrCreateRawMaterial(
    name,
    unit,
    subCategoryId,
    baseUnit: baseUnit,
  );

  // ============================================================
  // Recipes
  // ============================================================

  Future<void> insertRecipe(Recipe recipe) => _recipesDao.insertRecipe(recipe);

  Future<void> insertRecipes(List<Recipe> recipes) =>
      _recipesDao.insertRecipes(recipes);

  Future<Recipe?> getRecipeByItemId(String itemId) =>
      _recipesDao.getRecipeByItemId(itemId);

  Future<List<Recipe>> getAllRecipes() => _recipesDao.getAllRecipes();

  Future<void> updateRecipe(Recipe recipe) => _recipesDao.updateRecipe(recipe);

  Future<void> deleteRecipe(String id) => _recipesDao.deleteRecipe(id);

  // ============================================================
  // Recipe Ingredients
  // ============================================================

  Future<void> insertRecipeIngredient(RecipeIngredient ingredient) =>
      _recipesDao.insertRecipeIngredient(ingredient);

  Future<void> insertRecipeIngredients(List<RecipeIngredient> ingredients) =>
      _recipesDao.insertRecipeIngredients(ingredients);

  Future<List<RecipeIngredient>> getRecipeIngredients(String recipeId) =>
      _recipesDao.getRecipeIngredients(recipeId);

  Future<void> updateRecipeIngredient(RecipeIngredient ingredient) =>
      _recipesDao.updateRecipeIngredient(ingredient);

  Future<void> deleteRecipeIngredient(String id) =>
      _recipesDao.deleteRecipeIngredient(id);

  Future<RecipeIngredient?> getRecipeIngredientById(String id) =>
      _recipesDao.getRecipeIngredientById(id);

  // ============================================================
  // Inventory
  // ============================================================

  Future<void> insertInventoryMovement(InventoryMovement movement) =>
      _inventoryDao.insertInventoryMovement(movement);

  Future<List<InventoryMovement>> getInventoryMovementsByItemId(
    String itemId, {
    DateTime? startDate,
    DateTime? endDate,
  }) => _inventoryDao.getInventoryMovementsByItemId(
    itemId,
    startDate: startDate,
    endDate: endDate,
  );

  Future<List<InventoryMovement>> getInventoryMovementsByType(
    String movementType, {
    DateTime? startDate,
    DateTime? endDate,
  }) => _inventoryDao.getInventoryMovementsByType(
    movementType,
    startDate: startDate,
    endDate: endDate,
  );

  Future<List<LowStockWarning>> deductInventoryForSale(
    String itemId,
    int quantity,
  ) => _inventoryDao.deductInventoryForSale(itemId, quantity);

  Future<List<LowStockWarning>> calculateAndDeductStock(
    List<Map<String, dynamic>> invoiceItems,
  ) => _inventoryDao.calculateAndDeductStock(invoiceItems);

  // ============================================================
  // Shift Reports
  // ============================================================

  Future<void> insertShiftReport(ShiftReport report) =>
      _inventoryDao.insertShiftReport(report);

  Future<List<ShiftReport>> getShiftReportsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? floorId,
  }) => _inventoryDao.getShiftReportsByDateRange(
    startDate,
    endDate,
    floorId: floorId,
  );

  Future<ShiftReport?> getShiftReportById(String id) =>
      _inventoryDao.getShiftReportById(id);

  // ============================================================
  // Invoices
  // ============================================================

  Future<void> insertInvoice(Invoice invoice) =>
      _inventoryDao.insertInvoice(invoice);

  Future<Map<String, dynamic>> createInvoice({
    required DateTime date,
    required double totalAmount,
    required List<Map<String, dynamic>> invoiceItems,
  }) => _inventoryDao.createInvoice(
    date: date,
    totalAmount: totalAmount,
    invoiceItems: invoiceItems,
  );

  // ============================================================
  // Suppliers
  // ============================================================

  Future<void> insertSupplier(Supplier supplier) =>
      _suppliersDao.insertSupplier(supplier);

  Future<List<Supplier>> getAllSuppliers() => _suppliersDao.getAllSuppliers();

  Future<Supplier?> getSupplierById(String id) =>
      _suppliersDao.getSupplierById(id);

  // ============================================================
  // Purchases
  // ============================================================

  Future<String> getNextPurchaseInvoiceNumber() =>
      _suppliersDao.getNextPurchaseInvoiceNumber();

  Future<void> insertPurchase(Purchase purchase) =>
      _suppliersDao.insertPurchase(purchase);

  Future<List<Purchase>> getPurchasesBySupplierId(
    String supplierId, {
    DateTime? startDate,
    DateTime? endDate,
  }) => _suppliersDao.getPurchasesBySupplierId(
    supplierId,
    startDate: startDate,
    endDate: endDate,
  );

  Future<List<PurchaseItem>> getPurchaseItemsByPurchaseId(String purchaseId) =>
      _suppliersDao.getPurchaseItemsByPurchaseId(purchaseId);

  Future<List<Purchase>> getAllPurchases({
    DateTime? startDate,
    DateTime? endDate,
  }) => _suppliersDao.getAllPurchases(startDate: startDate, endDate: endDate);
}
