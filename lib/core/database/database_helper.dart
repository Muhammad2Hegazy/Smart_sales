import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../models/item.dart';
import '../models/note.dart';
import '../models/sale.dart';
import '../models/financial_transaction.dart';
import '../models/master.dart';
import '../models/device.dart';
import '../models/user_profile.dart';
import '../models/user_permission.dart';
import '../models/raw_material.dart';
import '../models/raw_material_batch.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Initialize database for Windows
  static Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await _getDatabasePath();
    
    // Ensure the directory exists
    final dbFile = File(dbPath);
    final dbDirectory = dbFile.parent;
    if (!await dbDirectory.exists()) {
      await dbDirectory.create(recursive: true);
    }
    
    return await openDatabase(
      dbPath,
      version: 18, // Incremented for recipes and recipe ingredients
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<String> _getDatabasePath() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Use getApplicationSupportDirectory for better reliability (not synced by OneDrive)
      final directory = await getApplicationSupportDirectory();
      return join(directory.path, 'smart_sales.db');
    } else {
      final databasesPath = await getDatabasesPath();
      return join(databasesPath, 'smart_sales.db');
    }
  }

  /// Get the database file path (public method for backup/restore)
  Future<String> getDatabasePath() async {
    return await _getDatabasePath();
  }

  /// Close the database connection (public method for backup/restore)
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // User profiles table - stores user information (local auth)
    await db.execute('''
      CREATE TABLE user_profiles (
        user_id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL DEFAULT 'cashier',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // Ensure developer device is registered after tables are created
    Future.microtask(() => _ensureDeveloperDeviceRegistered());

    // User passwords table - stores hashed passwords (local auth)
    await db.execute('''
      CREATE TABLE user_passwords (
        user_id TEXT PRIMARY KEY,
        password_hash TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles(user_id) ON DELETE CASCADE
      )
    ''');

    // Masters table - stores master device information
    await db.execute('''
      CREATE TABLE masters (
        master_device_id TEXT PRIMARY KEY,
        master_name TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles(user_id) ON DELETE CASCADE
      )
    ''');

    // Devices table - stores all devices (master and slaves)
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
    
    // Ensure developer device is registered after tables are created
    // Note: This will be called asynchronously after database is ready
    Future.microtask(() async {
      try {
        await _ensureDeveloperDeviceRegistered();
      } catch (e) {
        debugPrint('Error ensuring developer device in onCreate: $e');
      }
    });

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        master_device_id TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL,
        FOREIGN KEY (master_device_id) REFERENCES masters(master_device_id) ON DELETE CASCADE
      )
    ''');

    // SubCategories table
    await db.execute('''
      CREATE TABLE sub_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        master_device_id TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
        FOREIGN KEY (master_device_id) REFERENCES masters(master_device_id) ON DELETE CASCADE
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
        master_device_id TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL,
        FOREIGN KEY (sub_category_id) REFERENCES sub_categories(id) ON DELETE CASCADE,
        FOREIGN KEY (master_device_id) REFERENCES masters(master_device_id) ON DELETE CASCADE
      )
    ''');

    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        text TEXT NOT NULL,
        master_device_id TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
        FOREIGN KEY (master_device_id) REFERENCES masters(master_device_id) ON DELETE CASCADE
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
        master_device_id TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL,
        FOREIGN KEY (master_device_id) REFERENCES masters(master_device_id) ON DELETE CASCADE
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
        master_device_id TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
        FOREIGN KEY (master_device_id) REFERENCES masters(master_device_id) ON DELETE CASCADE
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
        master_device_id TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL,
        FOREIGN KEY (master_device_id) REFERENCES masters(master_device_id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_devices_master_device_id ON devices(master_device_id)');
    await db.execute('CREATE INDEX idx_categories_master_device_id ON categories(master_device_id)');
    await db.execute('CREATE INDEX idx_categories_sync_status ON categories(sync_status)');
    await db.execute('CREATE INDEX idx_sub_categories_category_id ON sub_categories(category_id)');
    await db.execute('CREATE INDEX idx_sub_categories_master_device_id ON sub_categories(master_device_id)');
    await db.execute('CREATE INDEX idx_sub_categories_sync_status ON sub_categories(sync_status)');
    await db.execute('CREATE INDEX idx_items_sub_category_id ON items(sub_category_id)');
    await db.execute('CREATE INDEX idx_items_master_device_id ON items(master_device_id)');
    await db.execute('CREATE INDEX idx_items_sync_status ON items(sync_status)');
    await db.execute('CREATE INDEX idx_notes_item_id ON notes(item_id)');
    await db.execute('CREATE INDEX idx_notes_master_device_id ON notes(master_device_id)');
    await db.execute('CREATE INDEX idx_notes_sync_status ON notes(sync_status)');
    await db.execute('CREATE INDEX idx_sale_items_sale_id ON sale_items(sale_id)');
    await db.execute('CREATE INDEX idx_sale_items_master_device_id ON sale_items(master_device_id)');
    await db.execute('CREATE INDEX idx_sale_items_sync_status ON sale_items(sync_status)');
    await db.execute('CREATE INDEX idx_sales_created_at ON sales(created_at)');
    await db.execute('CREATE INDEX idx_sales_master_device_id ON sales(master_device_id)');
    await db.execute('CREATE INDEX idx_sales_sync_status ON sales(sync_status)');
    await db.execute('CREATE INDEX idx_financial_transactions_created_at ON financial_transactions(created_at)');
    await db.execute('CREATE INDEX idx_financial_transactions_type ON financial_transactions(type)');
    await db.execute('CREATE INDEX idx_financial_transactions_master_device_id ON financial_transactions(master_device_id)');
    await db.execute('CREATE INDEX idx_financial_transactions_sync_status ON financial_transactions(sync_status)');
    
    // User permissions table - stores user permissions
    await db.execute('''
      CREATE TABLE user_permissions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        permission_key TEXT NOT NULL,
        allowed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles(user_id) ON DELETE CASCADE,
        UNIQUE(user_id, permission_key)
      )
    ''');

    // Raw materials table
    await db.execute('''
      CREATE TABLE raw_materials (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        unit TEXT NOT NULL DEFAULT 'number',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Raw material batches table
    await db.execute('''
      CREATE TABLE raw_material_batches (
        id TEXT PRIMARY KEY,
        raw_material_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        expiry_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for raw materials
    await db.execute('CREATE INDEX idx_raw_material_batches_raw_material_id ON raw_material_batches(raw_material_id)');
    await db.execute('CREATE INDEX idx_raw_material_batches_expiry_date ON raw_material_batches(expiry_date)');

    // Recipes table
    await db.execute('''
      CREATE TABLE recipes (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
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
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
        FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for recipes
    await db.execute('CREATE INDEX idx_recipes_item_id ON recipes(item_id)');
    await db.execute('CREATE INDEX idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id)');
    await db.execute('CREATE INDEX idx_recipe_ingredients_raw_material_id ON recipe_ingredients(raw_material_id)');

    // Create indexes for user tables
    await db.execute('CREATE INDEX idx_user_profiles_username ON user_profiles(username)');
    await db.execute('CREATE INDEX idx_user_profiles_role ON user_profiles(role)');
    await db.execute('CREATE INDEX idx_user_permissions_user_id ON user_permissions(user_id)');
    await db.execute('CREATE INDEX idx_user_permissions_key ON user_permissions(permission_key)');
    
    // Create default admin user
    await _createDefaultAdminUser(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add sales table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales (
          id TEXT PRIMARY KEY,
          table_number TEXT,
          total REAL NOT NULL,
          payment_method TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      // Add sale items table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sale_items (
          id TEXT PRIMARY KEY,
          sale_id TEXT NOT NULL,
          item_id TEXT NOT NULL,
          item_name TEXT NOT NULL,
          price REAL NOT NULL,
          quantity INTEGER NOT NULL,
          total REAL NOT NULL,
          FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
        )
      ''');

      // Add financial transactions table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS financial_transactions (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      // Create indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items(sale_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_financial_transactions_created_at ON financial_transactions(created_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_financial_transactions_type ON financial_transactions(type)');
    }
    
    if (oldVersion < 3) {
      // Add stock fields to items table
      await _ensureStockColumnsExist(db);
    }
    
    if (oldVersion < 4) {
      // Add conversion_rate column to items table
      try {
        final result = await db.rawQuery("PRAGMA table_info(items)");
        final hasConversionRate = result.any((row) => row['name'] == 'conversion_rate');
        
        if (!hasConversionRate) {
          await db.execute('ALTER TABLE items ADD COLUMN conversion_rate REAL');
        }
      } catch (e) {
        debugPrint('Error adding conversion_rate column: $e');
        try {
          await db.execute('ALTER TABLE items ADD COLUMN conversion_rate REAL');
        } catch (e2) {
          debugPrint('Error adding conversion_rate: $e2');
        }
      }
    }
    
    if (oldVersion < 5) {
      // Add is_pos_only column to items table
      try {
        final result = await db.rawQuery("PRAGMA table_info(items)");
        final hasIsPosOnly = result.any((row) => row['name'] == 'is_pos_only');
        
        if (!hasIsPosOnly) {
          await db.execute('ALTER TABLE items ADD COLUMN is_pos_only INTEGER NOT NULL DEFAULT 0');
        }
      } catch (e) {
        debugPrint('Error adding is_pos_only column: $e');
        try {
          await db.execute('ALTER TABLE items ADD COLUMN is_pos_only INTEGER NOT NULL DEFAULT 0');
        } catch (e2) {
          debugPrint('Error adding is_pos_only: $e2');
        }
      }
    }
    
    if (oldVersion < 6) {
      // Add master-device sync support
      await _addMasterDeviceSyncSupport(db);
    }
    
    if (oldVersion < 7) {
      // Add userId to masters table
      await _addUserIdToMasters(db);
    }
    
    if (oldVersion < 8) {
      // Add local auth support (user_profiles and passwords)
      await _addLocalAuthSupport(db);
    }
    
    if (oldVersion < 9) {
      // Add user permissions table
      await _addUserPermissionsSupport(db);
    }
    
    if (oldVersion < 10) {
      // Remove role CHECK constraint to allow custom roles
      await _updateRoleConstraint(db);
    }
    
    if (oldVersion < 11) {
      // Add discount and service charge columns to sales table
      await _addDiscountAndServiceChargeToSales(db);
    }
    
    if (oldVersion < 12) {
      // Add delivery tax column to sales table
      await _addDeliveryTaxToSales(db);
    }
    
    if (oldVersion < 13) {
      // Add hospitality tax column to sales table
      await _addHospitalityTaxToSales(db);
    }
    
    if (oldVersion < 14) {
      // Add mac_address column to devices table
      await _addMacAddressToDevices(db);
    }
    
    if (oldVersion < 15) {
      // Add floor column to devices table
      await _addFloorToDevices(db);
    }
    
    if (oldVersion < 16) {
      // Add device_id column to sales table
      await _addDeviceIdToSales(db);
    }
    
    if (oldVersion < 17) {
      // Add raw materials tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS raw_materials (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          unit TEXT NOT NULL DEFAULT 'number',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS raw_material_batches (
          id TEXT PRIMARY KEY,
          raw_material_id TEXT NOT NULL,
          quantity REAL NOT NULL,
          expiry_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_raw_material_batches_raw_material_id ON raw_material_batches(raw_material_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_raw_material_batches_expiry_date ON raw_material_batches(expiry_date)');
    }
    
    if (oldVersion < 18) {
      // Add recipes tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recipes (
          id TEXT PRIMARY KEY,
          item_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recipe_ingredients (
          id TEXT PRIMARY KEY,
          recipe_id TEXT NOT NULL,
          raw_material_id TEXT NOT NULL,
          quantity REAL NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
          FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_recipes_item_id ON recipes(item_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_raw_material_id ON recipe_ingredients(raw_material_id)');
    }
  }
  
  /// Add mac_address column to devices table
  Future<void> _addMacAddressToDevices(Database db) async {
    try {
      // Check if column already exists
      final result = await db.rawQuery("PRAGMA table_info(devices)");
      final hasMacAddress = result.any((row) => row['name'] == 'mac_address');
      
      if (!hasMacAddress) {
        await db.execute('ALTER TABLE devices ADD COLUMN mac_address TEXT');
      }
    } catch (e) {
      debugPrint('Error adding mac_address column: $e');
      try {
        await db.execute('ALTER TABLE devices ADD COLUMN mac_address TEXT');
      } catch (e2) {
        debugPrint('Error adding mac_address: $e2');
      }
    }
    
    // Ensure developer device is registered after migration
    Future.microtask(() async {
      try {
        await _ensureDeveloperDeviceRegistered();
      } catch (e) {
        debugPrint('Error ensuring developer device in migration: $e');
      }
    });
  }
  
  /// Add device_id column to sales table
  Future<void> _addDeviceIdToSales(Database db) async {
    try {
      // Check if column already exists
      final result = await db.rawQuery("PRAGMA table_info(sales)");
      final hasDeviceId = result.any((row) => row['name'] == 'device_id');
      
      if (!hasDeviceId) {
        await db.execute('ALTER TABLE sales ADD COLUMN device_id TEXT');
      }
    } catch (e) {
      debugPrint('Error adding device_id column to sales: $e');
      try {
        await db.execute('ALTER TABLE sales ADD COLUMN device_id TEXT');
      } catch (e2) {
        debugPrint('Error adding device_id to sales: $e2');
      }
    }
  }
  
  /// Add floor column to devices table
  Future<void> _addFloorToDevices(Database db) async {
    try {
      // Check if column already exists
      final result = await db.rawQuery("PRAGMA table_info(devices)");
      final hasFloor = result.any((row) => row['name'] == 'floor');
      
      if (!hasFloor) {
        await db.execute('ALTER TABLE devices ADD COLUMN floor INTEGER');
      }
    } catch (e) {
      debugPrint('Error adding floor column: $e');
      try {
        await db.execute('ALTER TABLE devices ADD COLUMN floor INTEGER');
      } catch (e2) {
        debugPrint('Error adding floor: $e2');
      }
    }
  }
  
  /// Add discount and service charge columns to sales table
  Future<void> _addDiscountAndServiceChargeToSales(Database db) async {
    try {
      // Check if columns already exist
      final result = await db.rawQuery("PRAGMA table_info(sales)");
      final hasDiscountPercentage = result.any((row) => row['name'] == 'discount_percentage');
      final hasDiscountAmount = result.any((row) => row['name'] == 'discount_amount');
      final hasServiceCharge = result.any((row) => row['name'] == 'service_charge');
      
      if (!hasDiscountPercentage) {
        await db.execute('ALTER TABLE sales ADD COLUMN discount_percentage REAL NOT NULL DEFAULT 0.0');
      }
      if (!hasDiscountAmount) {
        await db.execute('ALTER TABLE sales ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0.0');
      }
      if (!hasServiceCharge) {
        await db.execute('ALTER TABLE sales ADD COLUMN service_charge REAL NOT NULL DEFAULT 0.0');
      }
    } catch (e) {
      debugPrint('Error adding discount/service charge columns: $e');
      // Try individual column additions
      try {
        await db.execute('ALTER TABLE sales ADD COLUMN discount_percentage REAL NOT NULL DEFAULT 0.0');
      } catch (e2) {
        debugPrint('Error adding discount_percentage: $e2');
      }
      try {
        await db.execute('ALTER TABLE sales ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0.0');
      } catch (e2) {
        debugPrint('Error adding discount_amount: $e2');
      }
      try {
        await db.execute('ALTER TABLE sales ADD COLUMN service_charge REAL NOT NULL DEFAULT 0.0');
      } catch (e2) {
        debugPrint('Error adding service_charge: $e2');
      }
    }
  }
  
  /// Add delivery tax column to sales table
  Future<void> _addDeliveryTaxToSales(Database db) async {
    try {
      // Check if column already exists
      final result = await db.rawQuery("PRAGMA table_info(sales)");
      final hasDeliveryTax = result.any((row) => row['name'] == 'delivery_tax');
      
      if (!hasDeliveryTax) {
        await db.execute('ALTER TABLE sales ADD COLUMN delivery_tax REAL NOT NULL DEFAULT 0.0');
      }
    } catch (e) {
      debugPrint('Error adding delivery_tax column: $e');
      try {
        await db.execute('ALTER TABLE sales ADD COLUMN delivery_tax REAL NOT NULL DEFAULT 0.0');
      } catch (e2) {
        debugPrint('Error adding delivery_tax: $e2');
      }
    }
  }
  
  /// Add hospitality tax column to sales table
  Future<void> _addHospitalityTaxToSales(Database db) async {
    try {
      // Check if column already exists
      final result = await db.rawQuery("PRAGMA table_info(sales)");
      final hasHospitalityTax = result.any((row) => row['name'] == 'hospitality_tax');
      
      if (!hasHospitalityTax) {
        await db.execute('ALTER TABLE sales ADD COLUMN hospitality_tax REAL NOT NULL DEFAULT 0.0');
      }
    } catch (e) {
      debugPrint('Error adding hospitality_tax column: $e');
      try {
        await db.execute('ALTER TABLE sales ADD COLUMN hospitality_tax REAL NOT NULL DEFAULT 0.0');
      } catch (e2) {
        debugPrint('Error adding hospitality_tax: $e2');
      }
    }
  }

  /// Ensure sales table has all required columns (called before insert/update operations)
  Future<void> _ensureSalesTableColumns(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(sales)");
      final columnNames = result.map((row) => row['name'] as String).toSet();
      
      // Check and add missing columns
      if (!columnNames.contains('discount_percentage')) {
        await db.execute('ALTER TABLE sales ADD COLUMN discount_percentage REAL NOT NULL DEFAULT 0.0');
        debugPrint('Added discount_percentage column to sales table');
      }
      
      if (!columnNames.contains('discount_amount')) {
        await db.execute('ALTER TABLE sales ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0.0');
        debugPrint('Added discount_amount column to sales table');
      }
      
      if (!columnNames.contains('service_charge')) {
        await db.execute('ALTER TABLE sales ADD COLUMN service_charge REAL NOT NULL DEFAULT 0.0');
        debugPrint('Added service_charge column to sales table');
      }
      
      if (!columnNames.contains('delivery_tax')) {
        await db.execute('ALTER TABLE sales ADD COLUMN delivery_tax REAL NOT NULL DEFAULT 0.0');
        debugPrint('Added delivery_tax column to sales table');
      }
      
      if (!columnNames.contains('hospitality_tax')) {
        await db.execute('ALTER TABLE sales ADD COLUMN hospitality_tax REAL NOT NULL DEFAULT 0.0');
        debugPrint('Added hospitality_tax column to sales table');
      }
      
      if (!columnNames.contains('device_id')) {
        await db.execute('ALTER TABLE sales ADD COLUMN device_id TEXT');
        debugPrint('Added device_id column to sales table');
      }
      
      if (!columnNames.contains('master_device_id')) {
        await db.execute('ALTER TABLE sales ADD COLUMN master_device_id TEXT NOT NULL DEFAULT \'\'');
        debugPrint('Added master_device_id column to sales table');
      }
      
      if (!columnNames.contains('sync_status')) {
        await db.execute('ALTER TABLE sales ADD COLUMN sync_status TEXT NOT NULL DEFAULT \'pending\'');
        debugPrint('Added sync_status column to sales table');
      }
      
      if (!columnNames.contains('updated_at')) {
        await db.execute('ALTER TABLE sales ADD COLUMN updated_at TEXT NOT NULL DEFAULT \'\'');
        debugPrint('Added updated_at column to sales table');
      }
    } catch (e) {
      debugPrint('Error ensuring sales table columns: $e');
    }
  }

  /// Update role constraint to allow custom roles
  Future<void> _updateRoleConstraint(Database db) async {
    try {
      // SQLite doesn't support ALTER TABLE to modify CHECK constraints
      // We need to recreate the table without the constraint
      // First, create a backup of existing data
      final existingData = await db.query('user_profiles');
      
      // Drop the old table
      await db.execute('DROP TABLE IF EXISTS user_profiles_backup');
      
      // Create backup table
      await db.execute('''
        CREATE TABLE user_profiles_backup AS SELECT * FROM user_profiles
      ''');
      
      // Drop original table
      await db.execute('DROP TABLE user_profiles');
      
      // Recreate table without CHECK constraint
      await db.execute('''
        CREATE TABLE user_profiles (
          user_id TEXT PRIMARY KEY,
          username TEXT NOT NULL UNIQUE,
          role TEXT NOT NULL DEFAULT 'cashier',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      
      // Restore data
      if (existingData.isNotEmpty) {
        final batch = db.batch();
        for (final row in existingData) {
          batch.insert('user_profiles', row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      }
      
      // Drop backup table
      await db.execute('DROP TABLE IF EXISTS user_profiles_backup');
      
      // Recreate indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON user_profiles(username)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role)');
    } catch (e) {
      debugPrint('Error updating role constraint: $e');
      // If migration fails, try to restore from backup
      try {
        final backupData = await db.query('user_profiles_backup');
        if (backupData.isNotEmpty) {
          await db.execute('DROP TABLE IF EXISTS user_profiles');
          await db.execute('''
            CREATE TABLE user_profiles AS SELECT * FROM user_profiles_backup
          ''');
        }
      } catch (e2) {
        debugPrint('Error restoring from backup: $e2');
      }
    }
  }

  /// Add userId column to masters table
  Future<void> _addUserIdToMasters(Database db) async {
    try {
      // Check if user_id column exists
      final result = await db.rawQuery("PRAGMA table_info(masters)");
      final hasUserId = result.any((row) => row['name'] == 'user_id');

      if (!hasUserId) {
        // Add user_id column
        await db.execute('ALTER TABLE masters ADD COLUMN user_id TEXT');
        // For existing records, set a default userId (will be updated on next login)
        await db.execute('UPDATE masters SET user_id = \'\' WHERE user_id IS NULL');
      }
    } catch (e) {
      debugPrint('Error adding user_id to masters: $e');
    }
  }

  /// Add local auth support (user_profiles and passwords tables)
  Future<void> _addLocalAuthSupport(Database db) async {
    try {
      // Create user_profiles table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profiles (
          user_id TEXT PRIMARY KEY,
          username TEXT NOT NULL UNIQUE,
          role TEXT NOT NULL DEFAULT 'cashier',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create user_passwords table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_passwords (
          user_id TEXT PRIMARY KEY,
          password_hash TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES user_profiles(user_id) ON DELETE CASCADE
        )
      ''');

      // Create indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON user_profiles(username)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role)');
      
      // Create default admin user if no users exist
      await _createDefaultAdminUser(db);
    } catch (e) {
      debugPrint('Error adding local auth support: $e');
      rethrow;
    }
  }

  /// Create default admin user (username: admin, password: mohamed2003)
  Future<void> _createDefaultAdminUser(Database db) async {
    try {
      // Check if any users exist
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM user_profiles');
      final count = result.first['count'] as int? ?? 0;
      
      if (count == 0) {
        // No users exist, create default admin
        final adminUserId = const Uuid().v4();
        final now = DateTime.now().toIso8601String();
        
        // Hash password: mohamed2003
        final passwordBytes = utf8.encode('mohamed2003');
        final passwordHash = sha256.convert(passwordBytes).toString();
        
        // Insert admin user profile
        await db.insert(
          'user_profiles',
          {
            'user_id': adminUserId,
            'username': 'admin',
            'role': 'admin',
            'created_at': now,
            'updated_at': now,
          },
        );
        
        // Insert admin password hash
        await db.insert(
          'user_passwords',
          {
            'user_id': adminUserId,
            'password_hash': passwordHash,
          },
        );
        
        debugPrint('Default admin user created: username=admin, password=mohamed2003');
      }
    } catch (e) {
      debugPrint('Error creating default admin user: $e');
      // Don't rethrow - this is not critical for migration
    }
  }

  /// Add user permissions support
  Future<void> _addUserPermissionsSupport(Database db) async {
    try {
      // Create user_permissions table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_permissions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          permission_key TEXT NOT NULL,
          allowed INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES user_profiles(user_id) ON DELETE CASCADE,
          UNIQUE(user_id, permission_key)
        )
      ''');

      // Create indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_user_permissions_user_id ON user_permissions(user_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_user_permissions_key ON user_permissions(permission_key)');
    } catch (e) {
      debugPrint('Error adding user permissions support: $e');
      rethrow;
    }
  }

  /// Add master-device sync support to existing database
  Future<void> _addMasterDeviceSyncSupport(Database db) async {
    // Create masters table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS masters (
        master_device_id TEXT PRIMARY KEY,
        master_name TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Create devices table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS devices (
        device_id TEXT PRIMARY KEY,
        device_name TEXT NOT NULL,
        master_device_id TEXT NOT NULL,
        is_master INTEGER NOT NULL DEFAULT 0,
        last_seen_at TEXT NOT NULL,
        FOREIGN KEY (master_device_id) REFERENCES masters(master_device_id) ON DELETE CASCADE
      )
    ''');

    // Add master_device_id, sync_status, and updated_at to all existing tables
    final tables = [
      'categories',
      'sub_categories',
      'items',
      'notes',
      'sales',
      'sale_items',
      'financial_transactions',
    ];

    for (final table in tables) {
      try {
        // Check if columns exist
        final result = await db.rawQuery("PRAGMA table_info($table)");
        final hasMasterDeviceId = result.any((row) => row['name'] == 'master_device_id');
        final hasSyncStatus = result.any((row) => row['name'] == 'sync_status');
        final hasUpdatedAt = result.any((row) => row['name'] == 'updated_at');

        if (!hasMasterDeviceId) {
          await db.execute('ALTER TABLE $table ADD COLUMN master_device_id TEXT');
        }
        if (!hasSyncStatus) {
          await db.execute('ALTER TABLE $table ADD COLUMN sync_status TEXT NOT NULL DEFAULT \'pending\'');
        }
        if (!hasUpdatedAt) {
          await db.execute('ALTER TABLE $table ADD COLUMN updated_at TEXT NOT NULL DEFAULT \'${DateTime.now().toIso8601String()}\'');
        }

        // Update existing records to have default master_device_id if null
        // This will be set when master is initialized
        await db.execute('UPDATE $table SET sync_status = \'pending\' WHERE sync_status IS NULL');
        await db.execute('UPDATE $table SET updated_at = datetime(\'now\') WHERE updated_at IS NULL');
      } catch (e) {
        debugPrint('Error adding sync columns to $table: $e');
      }
    }

    // Create indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_devices_master_device_id ON devices(master_device_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_master_device_id ON categories(master_device_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_sync_status ON categories(sync_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sub_categories_master_device_id ON sub_categories(master_device_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sub_categories_sync_status ON sub_categories(sync_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_items_master_device_id ON items(master_device_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_items_sync_status ON items(sync_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_master_device_id ON notes(master_device_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_sync_status ON notes(sync_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_master_device_id ON sale_items(master_device_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_sync_status ON sale_items(sync_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_master_device_id ON sales(master_device_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_sync_status ON sales(sync_status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_financial_transactions_master_device_id ON financial_transactions(master_device_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_financial_transactions_sync_status ON financial_transactions(sync_status)');
  }

  // Categories CRUD
  Future<void> insertCategories(List<Category> categories) async {
    final db = await database;
    final batch = db.batch();
    
    for (var category in categories) {
      batch.insert(
        'categories',
        {
          'id': category.id,
          'name': category.name,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) {
      return Category(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
      );
    });
  }

  Future<void> deleteAllCategories() async {
    final db = await database;
    await db.delete('categories');
  }

  // SubCategories CRUD
  Future<void> insertSubCategories(List<SubCategory> subCategories) async {
    final db = await database;
    final batch = db.batch();
    
    for (var subCategory in subCategories) {
      batch.insert(
        'sub_categories',
        {
          'id': subCategory.id,
          'name': subCategory.name,
          'category_id': subCategory.categoryId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<SubCategory>> getAllSubCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sub_categories');
    return List.generate(maps.length, (i) {
      return SubCategory(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        categoryId: maps[i]['category_id'] as String,
      );
    });
  }

  Future<List<SubCategory>> getSubCategoriesByCategoryId(String categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sub_categories',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return List.generate(maps.length, (i) {
      return SubCategory(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        categoryId: maps[i]['category_id'] as String,
      );
    });
  }

  Future<void> deleteAllSubCategories() async {
    final db = await database;
    await db.delete('sub_categories');
  }

  // Items CRUD
  Future<void> insertItems(List<Item> items) async {
    final db = await database;
    final batch = db.batch();
    
    for (var item in items) {
      batch.insert(
        'items',
        {
          'id': item.id,
          'name': item.name,
          'sub_category_id': item.subCategoryId,
          'price': item.price,
          'has_notes': item.hasNotes ? 1 : 0,
          'image_url': item.imageUrl,
          'stock_quantity': item.stockQuantity,
          'stock_unit': item.stockUnit,
          'conversion_rate': item.conversionRate,
          'is_pos_only': item.isPosOnly ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }
  
  Future<void> _ensureStockColumnsExist(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(items)");
      final hasStockQuantity = result.any((row) => row['name'] == 'stock_quantity');
      final hasStockUnit = result.any((row) => row['name'] == 'stock_unit');
      
      if (!hasStockQuantity) {
        await db.execute('ALTER TABLE items ADD COLUMN stock_quantity REAL');
        await db.execute('UPDATE items SET stock_quantity = 0.0 WHERE stock_quantity IS NULL');
        debugPrint('Added stock_quantity column to items table');
      }
      
      if (!hasStockUnit) {
        await db.execute('ALTER TABLE items ADD COLUMN stock_unit TEXT');
        await db.execute('UPDATE items SET stock_unit = \'number\' WHERE stock_unit IS NULL');
        debugPrint('Added stock_unit column to items table');
      }
    } catch (e) {
      debugPrint('Error ensuring stock columns exist: $e');
      // Try to add columns anyway
      try {
        await db.execute('ALTER TABLE items ADD COLUMN stock_quantity REAL');
        await db.execute('UPDATE items SET stock_quantity = 0.0 WHERE stock_quantity IS NULL');
      } catch (e2) {
        // Column might already exist, ignore
        debugPrint('stock_quantity column might already exist: $e2');
      }
      try {
        await db.execute('ALTER TABLE items ADD COLUMN stock_unit TEXT');
        await db.execute('UPDATE items SET stock_unit = \'number\' WHERE stock_unit IS NULL');
      } catch (e2) {
        // Column might already exist, ignore
        debugPrint('stock_unit column might already exist: $e2');
      }
    }
  }

  Future<void> updateItemStock(String itemId, double quantity, String unit) async {
    final db = await database;
    
    // Ensure stock columns exist before updating
    await _ensureStockColumnsExist(db);
    
    // Now update the stock
    await db.update(
      'items',
      {
        'stock_quantity': quantity,
        'stock_unit': unit,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> updateItemPriceAndStock(
    String itemId,
    double price,
    double quantity,
    String unit,
  ) async {
    final db = await database;
    
    // Ensure stock columns exist before updating
    await _ensureStockColumnsExist(db);
    
    // Update both price and stock
    await db.update(
      'items',
      {
        'price': price,
        'stock_quantity': quantity,
        'stock_unit': unit,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<List<Item>> getAllItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('items');
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  Future<List<Item>> getItemsBySubCategoryId(String subCategoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'sub_category_id = ?',
      whereArgs: [subCategoryId],
    );
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  Future<void> deleteAllItems() async {
    final db = await database;
    await db.delete('items');
  }

  // Notes CRUD
  Future<void> insertNotes(List<Note> notes) async {
    final db = await database;
    final batch = db.batch();
    
    for (var note in notes) {
      batch.insert(
        'notes',
        {
          'id': note.id,
          'item_id': note.itemId,
          'text': note.text,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes');
    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i]['id'] as String,
        itemId: maps[i]['item_id'] as String,
        text: maps[i]['text'] as String,
      );
    });
  }

  Future<List<Note>> getNotesByItemId(String itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i]['id'] as String,
        itemId: maps[i]['item_id'] as String,
        text: maps[i]['text'] as String,
      );
    });
  }

  Future<void> deleteAllNotes() async {
    final db = await database;
    await db.delete('notes');
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    final batch = db.batch();
    batch.delete('notes');
    batch.delete('items');
    batch.delete('sub_categories');
    batch.delete('categories');
    await batch.commit(noResult: true);
  }

  // Sales CRUD
  Future<void> insertSale(Sale sale) async {
    final db = await database;
    
    // Ensure sales table has all required columns
    await _ensureSalesTableColumns(db);
    
    // Get master device ID for sync
    final master = await getMaster();
    final masterDeviceId = master?.masterDeviceId ?? '';
    final now = DateTime.now().toIso8601String();
    
    // Get current device ID from SharedPreferences
    String? currentDeviceId;
    try {
      final prefs = await SharedPreferences.getInstance();
      currentDeviceId = prefs.getString('current_device_id');
    } catch (e) {
      debugPrint('Error getting current device ID: $e');
    }
    
    final batch = db.batch();
    
    // Insert sale with sync fields and device_id
    batch.insert(
      'sales',
      sale.toMap(
        masterDeviceId: masterDeviceId,
        syncStatus: 'pending', // Mark as pending for sync
        updatedAt: now,
        deviceId: currentDeviceId ?? sale.deviceId,
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Insert sale items with sync fields
    for (var item in sale.items) {
      batch.insert(
        'sale_items',
        item.toMap(
          masterDeviceId: masterDeviceId,
          syncStatus: 'pending', // Mark as pending for sync
          updatedAt: now,
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<Sale>> getAllSales() async {
    final db = await database;
    final List<Map<String, dynamic>> saleMaps = await db.query('sales', orderBy: 'created_at DESC');
    
    final List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final sale = Sale.fromMap(saleMap);
      final items = await getSaleItemsBySaleId(sale.id);
      sales.add(sale.copyWith(items: items));
    }
    
    return sales;
  }

  Future<Sale?> getSaleById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final sale = Sale.fromMap(maps.first);
    final items = await getSaleItemsBySaleId(sale.id);
    return sale.copyWith(items: items);
  }

  /// Get the total count of sales (for invoice numbering)
  Future<int> getSalesCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM sales');
      if (result.isEmpty) {
        debugPrint('getSalesCount: No result returned');
        return 0;
      }
      
      // Handle different return types from SQLite
      final countValue = result.first['count'];
      int count = 0;
      if (countValue is int) {
        count = countValue;
      } else if (countValue is num) {
        count = countValue.toInt();
      } else {
        count = int.tryParse(countValue.toString()) ?? 0;
      }
      
      debugPrint('getSalesCount: Found $count sales in database (raw value: $countValue, type: ${countValue.runtimeType})');
      return count;
    } catch (e, stackTrace) {
      debugPrint('Error getting sales count: $e');
      debugPrint('Stack trace: $stackTrace');
      return 0;
    }
  }

  /// Get the count of sales for today (for daily invoice numbering)
  Future<int> getTodaySalesCount() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      final todayStartStr = todayStart.toIso8601String();
      final todayEndStr = todayEnd.toIso8601String();
      
      debugPrint('getTodaySalesCount: Querying sales from $todayStartStr to $todayEndStr');
      
      // First, let's see all sales to debug
      final allSales = await db.query('sales', columns: ['id', 'created_at'], limit: 5);
      debugPrint('getTodaySalesCount: Sample sales in DB:');
      for (var sale in allSales) {
        debugPrint('  - Sale ID: ${sale['id']}, created_at: ${sale['created_at']}');
      }
      
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sales WHERE created_at >= ? AND created_at < ?',
        [todayStartStr, todayEndStr],
      );
      
      if (result.isEmpty) {
        debugPrint('getTodaySalesCount: No result returned');
        return 0;
      }
      
      // Handle different return types from SQLite
      final countValue = result.first['count'];
      int count = 0;
      if (countValue is int) {
        count = countValue;
      } else if (countValue is num) {
        count = countValue.toInt();
      } else {
        count = int.tryParse(countValue.toString()) ?? 0;
      }
      
      debugPrint('getTodaySalesCount: Found $count sales today (from $todayStartStr to $todayEndStr)');
      
      // Also try a simpler query using DATE() function if available
      try {
        final dateResult = await db.rawQuery(
          "SELECT COUNT(*) as count FROM sales WHERE DATE(created_at) = DATE('now')",
        );
        if (dateResult.isNotEmpty) {
          final dateCountValue = dateResult.first['count'];
          int dateCount = 0;
          if (dateCountValue is int) {
            dateCount = dateCountValue;
          } else if (dateCountValue is num) {
            dateCount = dateCountValue.toInt();
          } else {
            dateCount = int.tryParse(dateCountValue.toString()) ?? 0;
          }
          debugPrint('getTodaySalesCount: Alternative query (DATE function) found $dateCount sales');
          // Use the alternative if it gives a different result
          if (dateCount != count) {
            debugPrint('getTodaySalesCount: Using alternative count: $dateCount');
            return dateCount;
          }
        }
      } catch (e) {
        debugPrint('getTodaySalesCount: Alternative query failed (may not support DATE function): $e');
      }
      
      return count;
    } catch (e, stackTrace) {
      debugPrint('Error getting today sales count: $e');
      debugPrint('Stack trace: $stackTrace');
      return 0;
    }
  }

  /// Get the next invoice number (today's count + 1)
  Future<int> getNextInvoiceNumber() async {
    final count = await getTodaySalesCount();
    final nextNumber = count + 1;
    debugPrint('getNextInvoiceNumber: Today count=$count, Next number=$nextNumber');
    return nextNumber;
  }

  /// Get the next order number (today's count + 1)
  /// This is the same as invoice number since each sale is both an order and an invoice
  Future<int> getNextOrderNumber() async {
    return await getNextInvoiceNumber();
  }

  Future<List<Sale>> getSalesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> saleMaps = await db.query(
      'sales',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    
    final List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final sale = Sale.fromMap(saleMap);
      final items = await getSaleItemsBySaleId(sale.id);
      sales.add(sale.copyWith(items: items));
    }
    
    return sales;
  }

  /// Get sales by device IDs and date range
  Future<List<Sale>> getSalesByDeviceIdsAndDateRange(
    List<String> deviceIds,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (deviceIds.isEmpty) {
      return [];
    }
    
    final db = await database;
    final placeholders = deviceIds.map((_) => '?').join(',');
    final List<Map<String, dynamic>> saleMaps = await db.query(
      'sales',
      where: 'device_id IN ($placeholders) AND created_at >= ? AND created_at <= ?',
      whereArgs: [...deviceIds, startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    
    final List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final sale = Sale.fromMap(saleMap);
      final items = await getSaleItemsBySaleId(sale.id);
      sales.add(sale.copyWith(items: items));
    }
    
    return sales;
  }

  Future<List<SaleItem>> getSaleItemsBySaleId(String saleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return maps.map((map) => SaleItem.fromMap(map)).toList();
  }

  Future<double> getTotalSalesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    // Exclude hospitality sales from profit calculation (they are treated as losses)
    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM sales WHERE created_at >= ? AND created_at <= ? AND (table_number IS NULL OR table_number != ?)',
      [startDate.toIso8601String(), endDate.toIso8601String(), 'hospitality'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total hospitality sales (to be treated as losses in profit/loss calculation)
  Future<double> getTotalHospitalitySalesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM sales WHERE created_at >= ? AND created_at <= ? AND table_number = ?',
      [startDate.toIso8601String(), endDate.toIso8601String(), 'hospitality'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Financial Transactions CRUD
  Future<void> insertFinancialTransaction(FinancialTransaction transaction) async {
    final db = await database;
    
    // Get master device ID for sync
    final master = await getMaster();
    final masterDeviceId = master?.masterDeviceId ?? '';
    final now = DateTime.now().toIso8601String();
    
    await db.insert(
      'financial_transactions',
      transaction.toMap(
        masterDeviceId: masterDeviceId,
        syncStatus: 'pending', // Mark as pending for sync
        updatedAt: now,
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FinancialTransaction>> getAllFinancialTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'financial_transactions',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => FinancialTransaction.fromMap(map)).toList();
  }

  Future<List<FinancialTransaction>> getFinancialTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'financial_transactions',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => FinancialTransaction.fromMap(map)).toList();
  }

  Future<double> getTotalCashInByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM financial_transactions WHERE type = ? AND created_at >= ? AND created_at <= ?',
      ['cash_in', startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalCashOutByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM financial_transactions WHERE type = ? AND created_at >= ? AND created_at <= ?',
      ['cash_out', startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // User Profiles CRUD (Local Auth)
  Future<void> insertUserProfile(UserProfile profile, String passwordHash) async {
    final db = await database;
    final batch = db.batch();
    
    // Insert user profile
    batch.insert(
      'user_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Insert password hash
    batch.insert(
      'user_passwords',
      {
        'user_id': profile.userId,
        'password_hash': passwordHash,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    await batch.commit(noResult: true);
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  Future<UserProfile?> getUserProfileByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  Future<String?> getUserPasswordHash(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_passwords',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['password_hash'] as String?;
  }

  Future<void> updateUserPassword(String userId, String newPasswordHash) async {
    final db = await database;
    // Check if password entry exists
    final existing = await db.query(
      'user_passwords',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    
    if (existing.isEmpty) {
      // Insert new password entry
      await db.insert(
        'user_passwords',
        {
          'user_id': userId,
          'password_hash': newPasswordHash,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    } else {
      // Update existing password
      await db.update(
        'user_passwords',
        {
          'password_hash': newPasswordHash,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  Future<List<UserProfile>> getAllUserProfiles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => UserProfile.fromMap(map)).toList();
  }

  Future<void> updateUserRole(String userId, String role) async {
    final db = await database;
    await db.update(
      'user_profiles',
      {
        'role': role,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // User Permissions CRUD
  Future<void> insertUserPermission(UserPermission permission) async {
    final db = await database;
    await db.insert(
      'user_permissions',
      {
        'id': permission.id,
        'user_id': permission.userId,
        'permission_key': permission.permissionKey,
        'allowed': permission.allowed ? 1 : 0,
        'created_at': permission.createdAt.toIso8601String(),
        'updated_at': permission.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<UserPermission>> getUserPermissions(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_permissions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'permission_key',
    );
    return maps.map((map) => UserPermission(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      permissionKey: map['permission_key'] as String,
      allowed: (map['allowed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    )).toList();
  }

  Future<List<UserPermission>> getAllUserPermissions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_permissions',
      orderBy: 'user_id, permission_key',
    );
    return maps.map((map) => UserPermission(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      permissionKey: map['permission_key'] as String,
      allowed: (map['allowed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    )).toList();
  }

  Future<void> updateUserPermission(String userId, String permissionKey, bool allowed) async {
    final db = await database;
    final uuid = const Uuid();
    final now = DateTime.now();
    
    // Check if permission exists
    final existing = await db.query(
      'user_permissions',
      where: 'user_id = ? AND permission_key = ?',
      whereArgs: [userId, permissionKey],
      limit: 1,
    );
    
    if (existing.isEmpty) {
      // Insert new permission
      await db.insert(
        'user_permissions',
        {
          'id': uuid.v4(),
          'user_id': userId,
          'permission_key': permissionKey,
          'allowed': allowed ? 1 : 0,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      );
    } else {
      // Update existing permission
      await db.update(
        'user_permissions',
        {
          'allowed': allowed ? 1 : 0,
          'updated_at': now.toIso8601String(),
        },
        where: 'user_id = ? AND permission_key = ?',
        whereArgs: [userId, permissionKey],
      );
    }
  }

  Future<bool> hasPermission(String userId, String permissionKey) async {
    final db = await database;
    
    // First check if user is admin - admins have all permissions by default
    final profile = await getUserProfile(userId);
    if (profile?.isAdmin == true) {
      return true;
    }
    
    // Check permission in database
    final maps = await db.query(
      'user_permissions',
      where: 'user_id = ? AND permission_key = ? AND allowed = ?',
      whereArgs: [userId, permissionKey, 1],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<bool> adminExists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      where: 'role = ?',
      whereArgs: ['admin'],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  // Masters CRUD
  Future<void> insertMaster(Master master) async {
    final db = await database;
    await db.insert(
      'masters',
      master.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Master?> getMaster() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('masters', limit: 1);
    if (maps.isEmpty) return null;
    return Master.fromMap(maps.first);
  }

  Future<void> updateMasterName(String masterDeviceId, String newName) async {
    final db = await database;
    await db.update(
      'masters',
      {'master_name': newName},
      where: 'master_device_id = ?',
      whereArgs: [masterDeviceId],
    );
  }

  // Devices CRUD
  Future<void> insertDevice(Device device) async {
    final db = await database;
    await db.insert(
      'devices',
      device.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Device>> getAllDevices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('devices');
    return maps.map((map) => Device.fromMap(map)).toList();
  }

  Future<List<Device>> getDevicesByMasterId(String masterDeviceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where: 'master_device_id = ?',
      whereArgs: [masterDeviceId],
    );
    return maps.map((map) => Device.fromMap(map)).toList();
  }

  Future<Device?> getDeviceById(String deviceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where: 'device_id = ?',
      whereArgs: [deviceId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Device.fromMap(maps.first);
  }

  Future<void> updateDeviceLastSeen(String deviceId) async {
    final db = await database;
    await db.update(
      'devices',
      {'last_seen_at': DateTime.now().toIso8601String()},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  Future<void> deleteDevice(String deviceId) async {
    final db = await database;
    await db.delete(
      'devices',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  Future<void> setDeviceAsMaster(String masterDeviceId, String deviceId) async {
    final db = await database;
    // First, set all devices in this master group to not master
    await db.update(
      'devices',
      {'is_master': 0},
      where: 'master_device_id = ?',
      whereArgs: [masterDeviceId],
    );
    // Then set the selected device as master
    await db.update(
      'devices',
      {'is_master': 1},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  Future<void> updateDeviceMacAddress(String deviceId, String macAddress) async {
    final db = await database;
    await db.update(
      'devices',
      {'mac_address': macAddress},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  Future<void> updateDeviceFloor(String deviceId, int? floor) async {
    final db = await database;
    await db.update(
      'devices',
      {'floor': floor},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  Future<Device?> getDeviceByMacAddress(String macAddress) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where: 'mac_address = ?',
      whereArgs: [macAddress],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Device.fromMap(maps.first);
  }

  /// Get devices by floor
  Future<List<Device>> getDevicesByFloor(int? floor) async {
    final db = await database;
    if (floor == null) {
      // Get devices with no floor assigned
      final List<Map<String, dynamic>> maps = await db.query(
        'devices',
        where: 'floor IS NULL',
      );
      return maps.map((map) => Device.fromMap(map)).toList();
    } else {
      final List<Map<String, dynamic>> maps = await db.query(
        'devices',
        where: 'floor = ?',
        whereArgs: [floor],
      );
      return maps.map((map) => Device.fromMap(map)).toList();
    }
  }

  /// Ensure developer device is always registered
  /// Developer MAC: E0:0A:F6:C3:BA:FF
  Future<void> _ensureDeveloperDeviceRegistered() async {
    try {
      const developerMacAddress = 'E0:0A:F6:C3:BA:FF';
      
      // Check if developer device already exists
      final existingDevice = await getDeviceByMacAddress(developerMacAddress);
      if (existingDevice != null) {
        return; // Already registered
      }

      // Get or create master
      final master = await getMaster();
      String masterDeviceId;
      
      if (master == null) {
        // Create a temporary master for developer device
        // This will be updated when a user logs in
        masterDeviceId = DateTime.now().millisecondsSinceEpoch.toString();
        final newMaster = Master(
          masterDeviceId: masterDeviceId,
          masterName: 'Master Device',
          userId: 'developer',
          createdAt: DateTime.now(),
        );
        await insertMaster(newMaster);
      } else {
        masterDeviceId = master.masterDeviceId;
      }
      
      // Register developer device
      final device = Device(
        deviceId: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceName: 'DEV',
        masterDeviceId: masterDeviceId,
        isMaster: false,
        lastSeenAt: DateTime.now(),
        macAddress: developerMacAddress,
      );
      await insertDevice(device);
      debugPrint('Developer device registered: $developerMacAddress');
    } catch (e) {
      debugPrint('Error ensuring developer device registered: $e');
    }
  }

  // Sync status helpers
  Future<List<Map<String, dynamic>>> getPendingSyncRecords(String tableName, String masterDeviceId) async {
    final db = await database;
    return await db.query(
      tableName,
      where: 'master_device_id = ? AND sync_status = ?',
      whereArgs: [masterDeviceId, 'pending'],
    );
  }

  Future<void> updateSyncStatus(String tableName, String id, String status) async {
    final db = await database;
    await db.update(
      tableName,
      {
        'sync_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
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
    
    // Update raw material updated_at
    await db.update(
      'raw_materials',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [batch.rawMaterialId],
    );
  }

  Future<void> deleteRawMaterialBatch(String id) async {
    final db = await database;
    // Get batch to update raw material
    final batch = await getRawMaterialBatchById(id);
    await db.delete('raw_material_batches', where: 'id = ?', whereArgs: [id]);
    
    if (batch != null) {
      // Update raw material updated_at
      await db.update(
        'raw_materials',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [batch.rawMaterialId],
      );
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
  Future<void> deductInventoryForSale(String itemId, int quantity) async {
    debugPrint('deductInventoryForSale called: itemId=$itemId, quantity=$quantity');
    final recipe = await getRecipeByItemId(itemId);
    if (recipe == null || recipe.ingredients.isEmpty) {
      // No recipe found, nothing to deduct
      debugPrint('No recipe found for itemId=$itemId or recipe has no ingredients');
      return;
    }
    
    debugPrint('Recipe found for itemId=$itemId with ${recipe.ingredients.length} ingredients');
    
    // For each ingredient in the recipe, deduct the required quantity
    for (var ingredient in recipe.ingredients) {
      final requiredQuantity = ingredient.quantity * quantity;
      debugPrint('Processing ingredient: rawMaterialId=${ingredient.rawMaterialId}, quantityPerUnit=${ingredient.quantity}, totalRequired=$requiredQuantity');
      
      // Get all batches for this raw material, ordered by expiry date (FIFO)
      final batches = await getRawMaterialBatches(ingredient.rawMaterialId);
      debugPrint('Found ${batches.length} batches for raw material ${ingredient.rawMaterialId}');
      batches.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      
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
    }
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

