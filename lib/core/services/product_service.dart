import 'package:flutter/foundation.dart' hide Category;
import 'dart:io';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../models/item.dart';
import '../models/note.dart';
import '../database/database_helper.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Category> _categories = [];
  List<SubCategory> _subCategories = [];
  List<Item> _items = [];
  List<Note> _notes = [];

  bool _isInitialized = false;

  // Getters
  List<Category> get categories => _categories;
  List<SubCategory> get subCategories => _subCategories;
  List<Item> get items => _items;
  List<Note> get notes => _notes;

  // Initialize and load data from database
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Access database to trigger lazy initialization
    await _dbHelper.database;

    // Silent Auto-Sync from CSV project folder
    await autoSyncCsv();

    await loadFromDatabase();
    _isInitialized = true;
  }

  /// Automatically import from project 'items' folder if files exist
  Future<void> autoSyncCsv() async {
    try {
      const categoriesPath = 'items/categories_import.csv';
      const subCategoriesPath = 'items/sub_categories_import.csv';
      const itemsPath = 'items/items_import.csv';

      if (File(categoriesPath).existsSync() &&
          File(subCategoriesPath).existsSync() &&
          File(itemsPath).existsSync()) {
        debugPrint('ProductService: Auto-syncing CSV data...');
        await _dbHelper.importDataFromCsv(
          categoriesPath: categoriesPath,
          subCategoriesPath: subCategoriesPath,
          itemsPath: itemsPath,
        );
      }
    } catch (e) {
      debugPrint('ProductService: Silent auto-sync error: $e');
    }
  }

  // Reload data from database (useful after updates)
  Future<void> reloadFromDatabase() async {
    await loadFromDatabase();
  }

  Future<void> loadFromDatabase() async {
    try {
      _categories = await _dbHelper.getAllCategories();
      _subCategories = await _dbHelper.getAllSubCategories();
      _items = await _dbHelper.getAllItems();
      _notes = await _dbHelper.getAllNotes();

      // Ensure all items have valid stockQuantity and stockUnit
      _items = _items.map((item) {
        double stockQty;
        String stockUnit;
        try {
          stockQty = item.stockQuantity;
          stockUnit = item.stockUnit;
        } catch (e) {
          // If stockQuantity or stockUnit is null or invalid, use defaults
          stockQty = 0.0;
          stockUnit = 'number';
        }
        // Only recreate if values are invalid
        if (stockQty != item.stockQuantity || stockUnit != item.stockUnit) {
          return item.copyWith(stockQuantity: stockQty, stockUnit: stockUnit);
        }
        return item;
      }).toList();

      // Link notes to items
      _linkNotesToItems();
    } catch (e) {
      debugPrint('Error loading from database: $e');
      // If database doesn't exist or error occurs, start with empty lists
      _categories = [];
      _subCategories = [];
      _items = [];
      _notes = [];
    }
  }

  // Load sample data
  void loadSampleData() {
    _categories = [
      Category(
        id: '1',
        name: 'Beverages',
        subCategories: [
          SubCategory(
            id: '1',
            name: 'Hot Drinks',
            categoryId: '1',
            items: [
              Item(
                id: '1',
                name: 'Coffee',
                subCategoryId: '1',
                price: 4.99,
                hasNotes: true,
                stockQuantity: 0.0,
                stockUnit: 'number',
                notes: [
                  Note(id: '1', itemId: '1', text: 'Extra sugar'),
                  Note(id: '2', itemId: '1', text: 'No milk'),
                ],
              ),
              Item(
                id: '2',
                name: 'Tea',
                subCategoryId: '1',
                price: 3.99,
                hasNotes: false,
                stockQuantity: 0.0,
                stockUnit: 'number',
              ),
            ],
          ),
          SubCategory(
            id: '2',
            name: 'Cold Drinks',
            categoryId: '1',
            items: [
              Item(
                id: '3',
                name: 'Juice',
                subCategoryId: '2',
                price: 3.49,
                hasNotes: false,
                stockQuantity: 0.0,
                stockUnit: 'number',
              ),
              Item(
                id: '4',
                name: 'Water',
                subCategoryId: '2',
                price: 1.99,
                hasNotes: false,
                stockQuantity: 0.0,
                stockUnit: 'number',
              ),
            ],
          ),
        ],
      ),
      Category(
        id: '2',
        name: 'Food',
        subCategories: [
          SubCategory(
            id: '3',
            name: 'Fast Food',
            categoryId: '2',
            items: [
              Item(
                id: '5',
                name: 'Burger',
                subCategoryId: '3',
                price: 9.99,
                hasNotes: true,
                stockQuantity: 0.0,
                stockUnit: 'number',
                notes: [
                  Note(id: '3', itemId: '5', text: 'No pickles'),
                  Note(id: '4', itemId: '5', text: 'Extra cheese'),
                ],
              ),
              Item(
                id: '6',
                name: 'Pizza',
                subCategoryId: '3',
                price: 12.99,
                hasNotes: false,
                stockQuantity: 0.0,
                stockUnit: 'number',
              ),
            ],
          ),
        ],
      ),
    ];

    // Flatten subcategories and items
    _subCategories = _categories
        .expand((cat) => cat.subCategories)
        .toList()
        .cast<SubCategory>();

    _items = _subCategories.expand((sub) => sub.items).toList().cast<Item>();

    _notes = _items.expand((item) => item.notes).toList();
  }

  // Get subcategories by category ID
  List<SubCategory> getSubCategoriesByCategoryId(String categoryId) {
    return _subCategories.where((sub) => sub.categoryId == categoryId).toList();
  }

  // Get items by subcategory ID
  List<Item> getItemsBySubCategoryId(String subCategoryId) {
    return _items.where((item) => item.subCategoryId == subCategoryId).toList();
  }

  // Get notes by item ID
  List<Note> getNotesByItemId(String itemId) {
    return _notes.where((note) => note.itemId == itemId).toList();
  }

  // Import from Excel and save to database
  Future<void> importCategories(List<Category> categories) async {
    _categories = categories;
    // Save to database
    await _dbHelper.insertCategories(categories);
    // Update flattened data, but preserve imported subcategories
    _updateFlattenedData();
  }

  Future<void> importSubCategories(List<SubCategory> subCategories) async {
    _subCategories = subCategories;
    // Save to database
    await _dbHelper.insertSubCategories(subCategories);
    // Don't call _updateFlattenedData() here as it would overwrite imported subcategories
    // Just update items if needed
    _linkNotesToItems();
  }

  Future<void> importItems(List<Item> items) async {
    _items = items;
    // Save to database
    await _dbHelper.insertItems(items);
    _linkNotesToItems();
    _updateFlattenedData();
  }

  Future<void> importNotes(List<Note> notes) async {
    _notes = notes;
    // Save to database
    await _dbHelper.insertNotes(notes);
    _linkNotesToItems();
  }

  void _linkNotesToItems() {
    // Link notes to items based on itemId
    _items = _items.map((item) {
      final itemNotes = _notes.where((note) => note.itemId == item.id).toList();
      // Ensure stockQuantity and stockUnit have valid values
      double stockQty;
      String stockUnit;
      try {
        stockQty = item.stockQuantity;
        stockUnit = item.stockUnit;
      } catch (e) {
        // If stockQuantity or stockUnit is null or invalid, use defaults
        stockQty = 0.0;
        stockUnit = 'number';
      }
      return item.copyWith(
        hasNotes: itemNotes.isNotEmpty,
        notes: itemNotes,
        // Ensure stockQuantity and stockUnit are preserved or set to defaults
        stockQuantity: stockQty,
        stockUnit: stockUnit,
      );
    }).toList();
  }

  void _updateFlattenedData() {
    // Get subcategories from categories
    final categorySubCategories = _categories
        .expand((cat) => cat.subCategories)
        .toList();

    // Merge imported subcategories with category subcategories
    // Imported subcategories take precedence (by ID)
    final subCategoryMap = <String, SubCategory>{};

    // First add category subcategories
    for (var sub in categorySubCategories) {
      subCategoryMap[sub.id] = sub;
    }

    // Then add/override with imported subcategories (preserve imported ones)
    for (var sub in _subCategories) {
      subCategoryMap[sub.id] = sub;
    }

    // Update subcategories with merged list
    _subCategories = subCategoryMap.values.toList();

    // If items were imported directly, keep them
    // Otherwise, get items from subcategories
    if (_items.isEmpty) {
      _items = _subCategories.expand((sub) => sub.items).map((item) {
        // Ensure all items have stockQuantity and stockUnit
        double stockQty;
        String stockUnit;
        try {
          stockQty = item.stockQuantity;
          stockUnit = item.stockUnit;
        } catch (e) {
          // If stockQuantity or stockUnit is null or invalid, use defaults
          stockQty = 0.0;
          stockUnit = 'number';
        }
        return item.copyWith(stockQuantity: stockQty, stockUnit: stockUnit);
      }).toList();
    }

    // Link notes to items after updating
    _linkNotesToItems();
  }
}
