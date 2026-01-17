import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import '../utils/csv_importer.dart';

/// Database migrations helper containing schema creation and upgrade logic
class MigrationsHelper {
  static const int currentVersion = 31;

  /// Create all tables for a fresh database
  static Future<void> onCreate(Database db, int version) async {
    debugPrint('Creating database with version $version');

    // User profiles table
    await db.execute('''
      CREATE TABLE user_profiles (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL DEFAULT 'cashier',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Passwords table
    await db.execute('''
      CREATE TABLE passwords (
        user_id TEXT PRIMARY KEY,
        password_hash TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE
      )
    ''');

    // Masters table
    await db.execute('''
      CREATE TABLE masters (
        master_device_id TEXT PRIMARY KEY,
        master_name TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Devices table
    await db.execute('''
      CREATE TABLE devices (
        device_id TEXT PRIMARY KEY,
        device_name TEXT NOT NULL,
        master_device_id TEXT NOT NULL,
        is_master INTEGER NOT NULL DEFAULT 0,
        last_seen_at TEXT NOT NULL,
        mac_address TEXT,
        floor INTEGER,
        FOREIGN KEY (master_device_id) REFERENCES masters(master_device_id) ON DELETE CASCADE
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        master_device_id TEXT NOT NULL DEFAULT '',
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL DEFAULT ''
      )
    ''');

    // SubCategories table
    await db.execute('''
      CREATE TABLE sub_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        master_device_id TEXT NOT NULL DEFAULT '',
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    // Items table
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sub_category_id TEXT NOT NULL,
        price REAL NOT NULL,
        has_notes INTEGER NOT NULL DEFAULT 0,
        image_url TEXT,
        stock_quantity REAL NOT NULL DEFAULT 0,
        stock_unit TEXT NOT NULL DEFAULT 'number',
        conversion_rate REAL,
        is_pos_only INTEGER NOT NULL DEFAULT 0,
        master_device_id TEXT NOT NULL DEFAULT '',
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (sub_category_id) REFERENCES sub_categories(id) ON DELETE CASCADE
      )
    ''');

    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        text TEXT NOT NULL,
        master_device_id TEXT NOT NULL DEFAULT '',
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
      )
    ''');

    // Sales table
    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        table_number TEXT,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        created_at TEXT NOT NULL,
        discount_percentage REAL NOT NULL DEFAULT 0.0,
        discount_amount REAL NOT NULL DEFAULT 0.0,
        service_charge REAL NOT NULL DEFAULT 0.0,
        delivery_tax REAL NOT NULL DEFAULT 0.0,
        hospitality_tax REAL NOT NULL DEFAULT 0.0,
        device_id TEXT,
        master_device_id TEXT NOT NULL DEFAULT '',
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Sale items table
    await db.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        total REAL NOT NULL,
        master_device_id TEXT NOT NULL DEFAULT '',
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
      )
    ''');

    // Financial transactions table
    await db.execute('''
      CREATE TABLE financial_transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        created_at TEXT NOT NULL,
        master_device_id TEXT NOT NULL DEFAULT '',
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Pending invoices table
    await db.execute('''
      CREATE TABLE pending_invoices (
        id TEXT PRIMARY KEY,
        table_numbers TEXT NOT NULL,
        items TEXT NOT NULL,
        order_number TEXT,
        table_order_numbers TEXT,
        discount_percentage REAL NOT NULL DEFAULT 0.0,
        discount_amount REAL NOT NULL DEFAULT 0.0,
        service_charge REAL NOT NULL DEFAULT 0.0,
        delivery_tax REAL NOT NULL DEFAULT 0.0,
        hospitality_tax REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        master_device_id TEXT NOT NULL DEFAULT ''
      )
    ''');

    // User permissions table
    await db.execute('''
      CREATE TABLE user_permissions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        permission_key TEXT NOT NULL,
        allowed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE,
        UNIQUE(user_id, permission_key)
      )
    ''');

    // Raw material categories table
    await db.execute('''
      CREATE TABLE raw_material_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Raw material sub categories table
    await db.execute('''
      CREATE TABLE raw_material_sub_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES raw_material_categories(id) ON DELETE CASCADE
      )
    ''');

    // Raw materials table
    await db.execute('''
      CREATE TABLE raw_materials (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sub_category_id TEXT,
        unit TEXT NOT NULL DEFAULT 'number',
        base_unit TEXT,
        stock_quantity REAL NOT NULL DEFAULT 0,
        minimum_stock REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (sub_category_id) REFERENCES raw_material_sub_categories(id) ON DELETE SET NULL
      )
    ''');

    // Raw material units table
    await db.execute('''
      CREATE TABLE raw_material_units (
        id TEXT PRIMARY KEY,
        raw_material_id TEXT NOT NULL,
        unit_name TEXT NOT NULL,
        conversion_rate REAL NOT NULL,
        FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id) ON DELETE CASCADE
      )
    ''');

    // Raw material batches table
    await db.execute('''
      CREATE TABLE raw_material_batches (
        id TEXT PRIMARY KEY,
        raw_material_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        price REAL,
        expiry_date TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id) ON DELETE CASCADE
      )
    ''');

    // Recipes table
    await db.execute('''
      CREATE TABLE recipes (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        name TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
      )
    ''');

    // Recipe ingredients table
    await db.execute('''
      CREATE TABLE recipe_ingredients (
        id TEXT PRIMARY KEY,
        recipe_id TEXT NOT NULL,
        raw_material_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
        FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id) ON DELETE CASCADE
      )
    ''');

    // Invoices table
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Invoice items table
    await db.execute('''
      CREATE TABLE invoice_items (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
      )
    ''');

    // Shift reports table
    await db.execute('''
      CREATE TABLE shift_reports (
        id TEXT PRIMARY KEY,
        shift_id TEXT NOT NULL,
        shift_start TEXT NOT NULL,
        shift_end TEXT NOT NULL,
        floor_id INTEGER,
        device_id TEXT,
        total_sales REAL NOT NULL DEFAULT 0.0,
        cash_total REAL NOT NULL DEFAULT 0.0,
        visa_total REAL NOT NULL DEFAULT 0.0,
        orders_count INTEGER NOT NULL DEFAULT 0,
        discounts REAL NOT NULL DEFAULT 0.0,
        service REAL NOT NULL DEFAULT 0.0,
        tax REAL NOT NULL DEFAULT 0.0,
        cash_in REAL NOT NULL DEFAULT 0.0,
        cash_out REAL NOT NULL DEFAULT 0.0,
        report_data TEXT,
        created_at TEXT NOT NULL,
        master_device_id TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Inventory movements table
    await db.execute('''
      CREATE TABLE inventory_movements (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        movement_type TEXT NOT NULL,
        quantity REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES raw_materials(id) ON DELETE CASCADE
      )
    ''');

    // Suppliers table
    await db.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        contact_person TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        balance REAL DEFAULT 0.0,
        created_at TEXT NOT NULL
      )
    ''');

    // Purchases table
    await db.execute('''
      CREATE TABLE purchases (
        id TEXT PRIMARY KEY,
        invoice_number TEXT,
        supplier_id TEXT NOT NULL,
        supplier_invoice_number TEXT,
        purchase_date TEXT NOT NULL,
        payment_type TEXT NOT NULL DEFAULT 'cash',
        total_amount REAL NOT NULL,
        paid_amount REAL NOT NULL DEFAULT 0.0,
        discount_amount REAL DEFAULT 0.0,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE
      )
    ''');

    // Purchase items table
    await db.execute('''
      CREATE TABLE purchase_items (
        id TEXT PRIMARY KEY,
        purchase_id TEXT NOT NULL,
        raw_material_id TEXT NOT NULL,
        raw_material_name TEXT NOT NULL,
        unit TEXT NOT NULL DEFAULT 'number',
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0.0,
        total REAL NOT NULL,
        FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);

    // Create default admin user
    await _createDefaultAdminUser(db);

    debugPrint('Database created successfully');
  }

  /// Create indexes for better query performance
  static Future<void> _createIndexes(Database db) async {
    // Categories indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name)',
    );

    // SubCategories indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sub_categories_category_id ON sub_categories(category_id)',
    );

    // Items indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_items_sub_category_id ON items(sub_category_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_items_name ON items(name)',
    );

    // Notes indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_item_id ON notes(item_id)',
    );

    // Sales indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_device_id ON sales(device_id)',
    );

    // Sale items indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items(sale_id)',
    );

    // Financial transactions indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_financial_transactions_created_at ON financial_transactions(created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_financial_transactions_type ON financial_transactions(type)',
    );

    // Pending invoices indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pending_invoices_table_numbers ON pending_invoices(table_numbers)',
    );

    // Raw materials indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_raw_materials_sub_category_id ON raw_materials(sub_category_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_raw_material_batches_raw_material_id ON raw_material_batches(raw_material_id)',
    );

    // Recipes indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recipes_item_id ON recipes(item_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id)',
    );

    // Devices indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_devices_master_device_id ON devices(master_device_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_devices_mac_address ON devices(mac_address)',
    );

    // Suppliers and purchases indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_purchases_supplier_id ON purchases(supplier_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id ON purchase_items(purchase_id)',
    );

    // User permissions indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_user_permissions_user_id ON user_permissions(user_id)',
    );
  }

  /// Create default admin user
  static Future<void> _createDefaultAdminUser(Database db) async {
    try {
      final existing = await db.query(
        'user_profiles',
        where: 'username = ?',
        whereArgs: ['admin'],
      );

      if (existing.isEmpty) {
        final adminId = const Uuid().v4();

        await db.insert('user_profiles', {
          'id': adminId,
          'username': 'admin',
          'role': 'admin',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        final passwordBytes = utf8.encode('mohamed2003');
        final passwordHash = sha256.convert(passwordBytes).toString();

        await db.insert('passwords', {
          'user_id': adminId,
          'password_hash': passwordHash,
        });

        debugPrint('Default admin user created');
      }
    } catch (e) {
      debugPrint('Error creating default admin user: $e');
    }
  }

  /// Upgrade database from old version to new version
  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');

    // Run migrations for each version
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      await _runMigration(db, version);
    }

    debugPrint('Database upgrade complete');
  }

  /// Handle database opening to ensure schema is correct and initial data exists
  static Future<void> onOpen(Database db) async {
    debugPrint('Database onOpen - ensuring schema consistency');

    // Ensure updated_at exists in user_profiles
    await addColumnIfNotExists(
      db,
      'user_profiles',
      'updated_at',
      'TEXT DEFAULT ""',
    );

    // Ensure default admin user exists
    await _createDefaultAdminUser(db);

    // Auto-import categories, subcategories, and items from the project folder
    await _performAutoImport(db);
  }

  /// Automatically import data from CSV files in the project's 'items' folder
  static Future<void> _performAutoImport(Database db) async {
    try {
      final itemsDir = Directory('items');
      if (!itemsDir.existsSync()) {
        debugPrint('Auto-import: "items" folder not found');
        return;
      }

      final categoriesPath = p.join('items', 'categories_import.csv');
      final subCategoriesPath = p.join('items', 'sub_categories_import.csv');
      final itemsPath = p.join('items', 'items_import.csv');

      if (!File(categoriesPath).existsSync() ||
          !File(subCategoriesPath).existsSync() ||
          !File(itemsPath).existsSync()) {
        debugPrint('Auto-import: Some CSV files are missing in "items" folder');
        return;
      }

      debugPrint('Auto-import: CSV files found, starting import...');

      final result = await CsvImporter.importFromCsv(
        categoriesPath: categoriesPath,
        subCategoriesPath: subCategoriesPath,
        itemsPath: itemsPath,
      );

      final batch = db.batch();

      // Get master device ID if exists
      final masters = await db.query('masters');
      final masterDeviceId = masters.isNotEmpty
          ? masters.first['master_device_id'] as String
          : '';
      final now = DateTime.now().toIso8601String();

      // 1. Categories
      for (var cat in result.categories) {
        batch.insert('categories', {
          'id': cat.id,
          'name': cat.name,
          'master_device_id': masterDeviceId,
          'sync_status': 'pending',
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 2. Subcategories
      for (var sub in result.subCategories) {
        batch.insert('sub_categories', {
          'id': sub.id,
          'category_id': sub.categoryId,
          'name': sub.name,
          'master_device_id': masterDeviceId,
          'sync_status': 'pending',
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 3. Items
      for (var item in result.items) {
        batch.insert('items', {
          'id': item.id,
          'name': item.name,
          'sub_category_id': item.subCategoryId,
          'price': item.price,
          'has_notes':
              0, // Using 0 for now as notes are not imported from CSV yet
          'stock_quantity': 0.0,
          'stock_unit': item.stockUnit,
          'is_pos_only': item.isPosOnly ? 1 : 0,
          'master_device_id': masterDeviceId,
          'sync_status': 'pending',
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
      debugPrint(
        'Auto-import: Successfully imported ${result.categories.length} categories, ${result.subCategories.length} subcategories, and ${result.items.length} items.',
      );
    } catch (e) {
      debugPrint('Auto-import error: $e');
    }
  }

  /// Run migration for a specific version
  static Future<void> _runMigration(Database db, int version) async {
    debugPrint('Running migration for version $version');

    try {
      switch (version) {
        case 2:
          await _migrationV2(db);
          break;
        case 3:
          await _migrationV3(db);
          break;
        // Add more version migrations as needed
        default:
          debugPrint('No migration needed for version $version');
      }
    } catch (e) {
      debugPrint('Error in migration v$version: $e');
    }
  }

  /// Migration for version 2
  static Future<void> _migrationV2(Database db) async {
    // Add sales and sale_items tables if they don't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id TEXT PRIMARY KEY,
        table_number TEXT,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS financial_transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items(sale_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at)',
    );
  }

  /// Migration for version 3
  static Future<void> _migrationV3(Database db) async {
    // Add stock columns to items table
    try {
      final result = await db.rawQuery("PRAGMA table_info(items)");
      final hasStockQuantity = result.any(
        (row) => row['name'] == 'stock_quantity',
      );
      final hasStockUnit = result.any((row) => row['name'] == 'stock_unit');

      if (!hasStockQuantity) {
        await db.execute(
          'ALTER TABLE items ADD COLUMN stock_quantity REAL DEFAULT 0',
        );
      }
      if (!hasStockUnit) {
        await db.execute(
          "ALTER TABLE items ADD COLUMN stock_unit TEXT DEFAULT 'number'",
        );
      }
    } catch (e) {
      debugPrint('Error in migration v3: $e');
    }
  }

  /// Helper to safely add a column if it doesn't exist
  static Future<void> addColumnIfNotExists(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info($table)");
      final hasColumn = result.any((row) => row['name'] == column);

      if (!hasColumn) {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
        debugPrint('Added column $column to $table');
      }
    } catch (e) {
      debugPrint('Error adding column $column to $table: $e');
    }
  }

  /// Helper to safely create a table if it doesn't exist
  static Future<void> createTableIfNotExists(
    Database db,
    String tableName,
    String createStatement,
  ) async {
    try {
      await db.execute(createStatement);
      debugPrint('Ensured table $tableName exists');
    } catch (e) {
      debugPrint('Error creating table $tableName: $e');
    }
  }
}
