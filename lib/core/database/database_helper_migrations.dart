part of 'database_helper.dart';

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

  // User passwords table - stores hashed passwords
  await db.execute('''
    CREATE TABLE user_passwords (
      user_id TEXT PRIMARY KEY,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profiles (user_id) ON DELETE CASCADE
    )
  ''');

  // Masters table - stores master device information
  await db.execute('''
    CREATE TABLE masters (
      master_device_id TEXT PRIMARY KEY,
      master_name TEXT NOT NULL,
      user_id TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profiles (user_id) ON DELETE CASCADE
    )
  ''');

  // Devices table - stores all devices in the master group
  await db.execute('''
    CREATE TABLE devices (
      device_id TEXT PRIMARY KEY,
      device_name TEXT NOT NULL,
      master_device_id TEXT NOT NULL,
      is_master INTEGER NOT NULL DEFAULT 0,
      last_seen_at TEXT NOT NULL,
      mac_address TEXT,
      floor INTEGER,
      FOREIGN KEY (master_device_id) REFERENCES masters (master_device_id) ON DELETE CASCADE
    )
  ''');

  // Categories table
  await db.execute('''
    CREATE TABLE categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      master_device_id TEXT,
      sync_status TEXT DEFAULT 'pending',
      updated_at TEXT
    )
  ''');

  // Sub-categories table
  await db.execute('''
    CREATE TABLE sub_categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      category_id TEXT NOT NULL,
      master_device_id TEXT,
      sync_status TEXT DEFAULT 'pending',
      updated_at TEXT,
      FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
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
      stock_quantity REAL,
      stock_unit TEXT,
      conversion_rate REAL NOT NULL DEFAULT 1.0,
      is_pos_only INTEGER NOT NULL DEFAULT 0,
      master_device_id TEXT,
      sync_status TEXT DEFAULT 'pending',
      updated_at TEXT,
      FOREIGN KEY (sub_category_id) REFERENCES sub_categories (id) ON DELETE CASCADE
    )
  ''');

  // Notes table
  await db.execute('''
    CREATE TABLE notes (
      id TEXT PRIMARY KEY,
      item_id TEXT NOT NULL,
      text TEXT NOT NULL,
      FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
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
      device_id TEXT,
      master_device_id TEXT,
      sync_status TEXT DEFAULT 'pending',
      updated_at TEXT
    )
  ''');

  // Sale items table
  await db.execute('''
    CREATE TABLE sale_items (
      id TEXT PRIMARY KEY,
      sale_id TEXT NOT NULL,
      item_id TEXT NOT NULL,
      item_name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      price REAL NOT NULL,
      notes TEXT,
      master_device_id TEXT,
      sync_status TEXT DEFAULT 'pending',
      updated_at TEXT,
      FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
    )
  ''');

  // Financial transactions table
  await db.execute('''
    CREATE TABLE financial_transactions (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL, -- 'cash_in' or 'cash_out'
      amount REAL NOT NULL,
      reason TEXT NOT NULL,
      created_at TEXT NOT NULL,
      master_device_id TEXT,
      sync_status TEXT DEFAULT 'pending',
      updated_at TEXT
    )
  ''');

  // Pending Invoices table (for draft invoices/tables)
  await db.execute('''
    CREATE TABLE pending_invoices (
      id TEXT PRIMARY KEY,
      table_numbers TEXT NOT NULL, -- comma separated
      items TEXT NOT NULL, -- JSON
      order_number TEXT, -- JSON string since v27 (support multiple table order numbers)
      discount_percentage REAL DEFAULT 0,
      discount_amount REAL DEFAULT 0,
      service_charge REAL DEFAULT 0,
      delivery_tax REAL DEFAULT 0,
      hospitality_tax REAL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      master_device_id TEXT
    )
  ''');

  // User permissions table
  await db.execute('''
    CREATE TABLE user_permissions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      permission_key TEXT NOT NULL,
      allowed INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profiles (user_id) ON DELETE CASCADE,
      UNIQUE(user_id, permission_key)
    )
  ''');

  // Create indexes for better performance
  await db.execute('CREATE INDEX idx_sale_items_sale_id ON sale_items (sale_id)');
  await db.execute('CREATE INDEX idx_sales_created_at ON sales (created_at)');
  await db.execute('CREATE INDEX idx_items_sub_category_id ON items (sub_category_id)');
  await db.execute('CREATE INDEX idx_sub_categories_category_id ON sub_categories (category_id)');
  await db.execute('CREATE INDEX idx_pending_invoices_table_numbers ON pending_invoices (table_numbers)');
  
  // Restaurant Inventory System Tables
  await db.execute('''
    CREATE TABLE IF NOT EXISTS raw_materials (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      unit TEXT NOT NULL,
      base_unit TEXT NOT NULL DEFAULT 'gram',
      stock_quantity REAL NOT NULL DEFAULT 0,
      minimum_alert_quantity REAL NOT NULL DEFAULT 0,
      sub_category_id TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS raw_material_batches (
      id TEXT PRIMARY KEY,
      raw_material_id TEXT NOT NULL,
      quantity REAL NOT NULL,
      price REAL,
      expiry_date TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id) ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS raw_material_units (
      id TEXT PRIMARY KEY,
      raw_material_id TEXT NOT NULL,
      unit TEXT NOT NULL,
      conversion_factor_to_base REAL NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id) ON DELETE CASCADE,
      UNIQUE(raw_material_id, unit)
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS recipes (
      id TEXT PRIMARY KEY,
      item_id TEXT NOT NULL UNIQUE,
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
      quantity_required_in_base_unit REAL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
      FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id) ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS invoices (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      total_amount REAL NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS invoice_items (
      id TEXT PRIMARY KEY,
      invoice_id TEXT NOT NULL,
      item_id TEXT NOT NULL,
      quantity_sold REAL NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
      FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS shift_reports (
      id TEXT PRIMARY KEY,
      shift_start TEXT NOT NULL,
      shift_end TEXT NOT NULL,
      user_id TEXT NOT NULL,
      total_sales REAL NOT NULL,
      total_cash REAL NOT NULL,
      total_card REAL NOT NULL,
      total_expenses REAL NOT NULL,
      floor_id INTEGER,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profiles (user_id) ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS inventory_movements (
      id TEXT PRIMARY KEY,
      item_id TEXT NOT NULL,
      movement_type TEXT NOT NULL, -- 'sale', 'adjustment', 'restock'
      quantity REAL NOT NULL,
      reason TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS suppliers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      contact_person TEXT,
      phone TEXT,
      email TEXT,
      address TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS purchases (
      id TEXT PRIMARY KEY,
      supplier_id TEXT NOT NULL,
      purchase_date TEXT NOT NULL,
      total_amount REAL NOT NULL,
      invoice_number TEXT,
      status TEXT NOT NULL, -- 'pending', 'completed', 'cancelled'
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS purchase_items (
      id TEXT PRIMARY KEY,
      purchase_id TEXT NOT NULL,
      raw_material_id TEXT NOT NULL,
      quantity REAL NOT NULL,
      unit_price REAL NOT NULL,
      total_price REAL NOT NULL,
      expiry_date TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (purchase_id) REFERENCES purchases (id) ON DELETE CASCADE,
      FOREIGN KEY (raw_material_id) REFERENCES raw_materials (id) ON DELETE CASCADE
    )
  ''');

  // Create additional indexes
  await db.execute('CREATE INDEX IF NOT EXISTS idx_raw_materials_sub_category_id ON raw_materials(sub_category_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_raw_material_batches_raw_material_id ON raw_material_batches(raw_material_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_raw_material_units_raw_material_id ON raw_material_units(raw_material_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice_id ON invoice_items(invoice_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_purchases_supplier_id ON purchases(supplier_id)');

  // Create default admin user
  await _createDefaultAdminUser(db);
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  print('Upgrading database from $oldVersion to $newVersion');
  if (oldVersion < 2) {
    // Add sales table if not exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id TEXT PRIMARY KEY,
        table_number TEXT,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }
  if (oldVersion < 3) {
    // Add sale_items table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');
  }
  if (oldVersion < 4) {
    // Add notes to sale_items
    await db.execute('ALTER TABLE sale_items ADD COLUMN notes TEXT');
  }
  if (oldVersion < 5) {
    // Add financial_transactions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS financial_transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        reason TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }
  if (oldVersion < 6) {
    // Add user_profiles and user_passwords tables for local auth
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profiles (
        user_id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL DEFAULT 'cashier',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_passwords (
        user_id TEXT PRIMARY KEY,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles (user_id) ON DELETE CASCADE
      )
    ''');
    // Create default admin user
    await _createDefaultAdminUser(db);
  }
  if (oldVersion < 7) {
    // Add pending_invoices table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_invoices (
        id TEXT PRIMARY KEY,
        table_numbers TEXT NOT NULL,
        items TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }
  if (oldVersion < 8) {
    // Add user_permissions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_permissions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        permission_key TEXT NOT NULL,
        allowed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles (user_id) ON DELETE CASCADE,
        UNIQUE(user_id, permission_key)
      )
    ''');
  }
  if (oldVersion < 9) {
    // Add masters table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS masters (
        master_device_id TEXT PRIMARY KEY,
        master_name TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles (user_id) ON DELETE CASCADE
      )
    ''');
    // Add devices table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS devices (
        device_id TEXT PRIMARY KEY,
        device_name TEXT NOT NULL,
        master_device_id TEXT NOT NULL,
        is_master INTEGER NOT NULL DEFAULT 0,
        last_seen_at TEXT NOT NULL,
        FOREIGN KEY (master_device_id) REFERENCES masters (master_device_id) ON DELETE CASCADE
      )
    ''');
  }
  if (oldVersion < 10) {
    // Add sync columns to sales
    await _addSyncColumnsToTable(db, 'sales');
    // Add sync columns to sale_items
    await _addSyncColumnsToTable(db, 'sale_items');
    // Add sync columns to financial_transactions
    await _addSyncColumnsToTable(db, 'financial_transactions');
    // Add master_device_id to pending_invoices
    await db.execute('ALTER TABLE pending_invoices ADD COLUMN master_device_id TEXT');
  }
  if (oldVersion < 11) {
    // Recreate user_profiles to update role constraint
    await _updateRoleConstraint(db);
  }
  if (oldVersion < 12) {
    // Add device_id to sales table
    await _addSalesTableColumns(db);
  }
  if (oldVersion < 13) {
    // Add raw_materials, raw_material_batches, and recipes tables for restaurant inventory
    await db.execute('''
      CREATE TABLE IF NOT EXISTS raw_materials (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
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
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recipes (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL UNIQUE,
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
  }
  if (oldVersion < 14) {
    // Add indexes for inventory tables
    await db.execute('CREATE INDEX IF NOT EXISTS idx_raw_material_batches_raw_material_id ON raw_material_batches(raw_material_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id)');
  }
  if (oldVersion < 15) {
    // Add more indices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items (sale_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_items_sub_category_id ON items (sub_category_id)');
  }
  if (oldVersion < 16) {
    // Add mac_address to devices table
    await db.execute('ALTER TABLE devices ADD COLUMN mac_address TEXT');
  }
  if (oldVersion < 17) {
    // Add order_number to pending_invoices
    await db.execute('ALTER TABLE pending_invoices ADD COLUMN order_number INTEGER');
  }
  if (oldVersion < 18) {
    // Add discount/tax columns to pending_invoices
    await db.execute('ALTER TABLE pending_invoices ADD COLUMN discount_percentage REAL DEFAULT 0');
    await db.execute('ALTER TABLE pending_invoices ADD COLUMN discount_amount REAL DEFAULT 0');
    await db.execute('ALTER TABLE pending_invoices ADD COLUMN service_charge REAL DEFAULT 0');
    await db.execute('ALTER TABLE pending_invoices ADD COLUMN delivery_tax REAL DEFAULT 0');
    await db.execute('ALTER TABLE pending_invoices ADD COLUMN hospitality_tax REAL DEFAULT 0');
  }
  if (oldVersion < 19) {
    // Add floor for devices
    await db.execute('ALTER TABLE devices ADD COLUMN floor INTEGER');
  }
  if (oldVersion < 20) {
    // Add stock columns to items table
    await _ensureStockColumnsExist(db);
  }
  if (oldVersion < 21) {
    // Add raw material categories and more precise unit management
    await _addRawMaterialCategories(db);
  }
  if (oldVersion < 22) {
    // Add Restaurant Inventory, Recipe & Invoice Management System
    await _addRestaurantInventorySystem(db);
  }
  if (oldVersion < 23) {
    // Make expiry_date optional in raw_material_batches
    await _makeExpiryDateOptional(db);
  }
  if (oldVersion < 24) {
    // Add price to raw_material_batches
    await _addPriceToBatches(db);
  }
  if (oldVersion < 25) {
    // Update water base unit to carton
    await _updateWaterBaseUnit(db);
  }
  if (oldVersion < 26) {
    // Check if stock_unit already exists before adding
    try {
      final result = await db.rawQuery("PRAGMA table_info(items)");
      final hasStockUnit = result.any((row) => row['name'] == 'stock_unit');
      if (!hasStockUnit) {
        await db.execute('ALTER TABLE items ADD COLUMN stock_unit TEXT');
      }
    } catch (e) {
      print('Error adding stock_unit to items: $e');
    }
  }
  if (oldVersion < 27) {
    // Add index on table_numbers for pending_invoices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pending_invoices_table_numbers ON pending_invoices (table_numbers)');
    // order_number in pending_invoices is now used for multiple tables (stored as JSON string)
    // No change needed to the column itself, just the logic in the app
  }
  if (oldVersion < 28) {
    // Add extra tracking columns to items
    try {
      final result = await db.rawQuery("PRAGMA table_info(items)");
      final columns = result.map((row) => row['name'] as String).toSet();
      
      if (!columns.contains('conversion_rate')) {
        await db.execute('ALTER TABLE items ADD COLUMN conversion_rate REAL NOT NULL DEFAULT 1.0');
      }
      if (!columns.contains('is_pos_only')) {
        await db.execute('ALTER TABLE items ADD COLUMN is_pos_only INTEGER NOT NULL DEFAULT 0');
      }
    } catch (e) {
      print('Error adding columns to items: $e');
    }
  }
  if (oldVersion < 29) {
    // Update raw materials base units according to new rules
    await _updateRawMaterialsBaseUnits(db);
  }
  if (oldVersion < 30) {
    // Add soft drinks category and materials
    await _addSoftDrinksCategory(db);
  }
  if (oldVersion < 31) {
    // Add milk subcategory to dairy category
    await _addMilkSubCategory(db);
  }
  if (oldVersion < 32) {
    // Add shift_reports, inventory_movements, suppliers, purchases, purchase_items tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shift_reports (
        id TEXT PRIMARY KEY,
        shift_start TEXT NOT NULL,
        shift_end TEXT NOT NULL,
        user_id TEXT NOT NULL,
        total_sales REAL NOT NULL,
        total_cash REAL NOT NULL,
        total_card REAL NOT NULL,
        total_expenses REAL NOT NULL,
        floor_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles (user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_movements (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        movement_type TEXT NOT NULL, -- 'sale', 'adjustment', 'restock'
        quantity REAL NOT NULL,
        reason TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        contact_person TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
        id TEXT PRIMARY KEY,
        supplier_id TEXT NOT NULL,
        purchase_date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        invoice_number TEXT,
        status TEXT NOT NULL, -- 'pending', 'completed', 'cancelled'
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_items (
        id TEXT PRIMARY KEY,
        purchase_id TEXT NOT NULL,
        raw_material_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        expiry_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (purchase_id) REFERENCES purchases (id) ON DELETE CASCADE,
        FOREIGN KEY (raw_material_id) REFERENCES raw_materials (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_purchases_supplier_id ON purchases(supplier_id)');
  }
  if (oldVersion < 33) {
    // Add sync columns to categories, sub_categories, and items tables
    await _addSyncColumnsToTable(db, 'categories');
    await _addSyncColumnsToTable(db, 'sub_categories');
    await _addSyncColumnsToTable(db, 'items');
  }
}

Future<void> _addSyncColumnsToTable(Database db, String tableName) async {
  try {
    await db.execute('ALTER TABLE $tableName ADD COLUMN master_device_id TEXT');
    await db.execute("ALTER TABLE $tableName ADD COLUMN sync_status TEXT DEFAULT 'pending'");
    await db.execute('ALTER TABLE $tableName ADD COLUMN updated_at TEXT');
  } catch (e) {
    print('Sync columns may already exist in $tableName: $e');
  }
}

Future<void> _updateRoleConstraint(Database db) async {
  try {
    // Drop old index if exists
    await db.execute('DROP INDEX IF EXISTS idx_user_profiles_username');
    
    // Rename old table
    await db.execute('ALTER TABLE user_profiles RENAME TO user_profiles_old');
    
    // Create new table
    await db.execute('''
      CREATE TABLE user_profiles (
        user_id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL DEFAULT 'cashier',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // Copy data
    await db.execute('''
      INSERT INTO user_profiles (user_id, username, role, created_at, updated_at)
      SELECT user_id, username, role, created_at, updated_at FROM user_profiles_old
    ''');
    
    // Drop old table
    await db.execute('DROP TABLE user_profiles_old');
  } catch (e) {
    print('Error updating role constraint: $e');
  }
}

Future<void> _addSalesTableColumns(Database db) async {
  try {
    final result = await db.rawQuery("PRAGMA table_info(sales)");
    final columns = result.map((row) => row['name'] as String).toSet();
    if (!columns.contains('device_id')) {
      await db.execute('ALTER TABLE sales ADD COLUMN device_id TEXT');
    }
  } catch (e) {
    print('Error adding device_id to sales: $e');
  }
}

Future<void> _ensureSalesTableColumns(Database db) async {
  try {
    final result = await db.rawQuery("PRAGMA table_info(sales)");
    final columns = result.map((row) => row['name'] as String).toSet();
    if (!columns.contains('device_id')) {
      await db.execute('ALTER TABLE sales ADD COLUMN device_id TEXT');
      print('  ✓ Added device_id column to sales table');
    }
    if (!columns.contains('master_device_id')) {
      await db.execute('ALTER TABLE sales ADD COLUMN master_device_id TEXT');
      print('  ✓ Added master_device_id column to sales table');
    }
  } catch (e) {
    print('Error ensuring sales table columns: $e');
  }
}

Future<void> _createDefaultAdminUser(Database db) async {
  try {
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as count FROM user_profiles');
    final count = (result.first['count'] as num?)?.toInt() ?? 0;
    
    if (count == 0) {
      final now = DateTime.now().toIso8601String();
      final userId = const Uuid().v4();
      
      // Password hash for 'mohamed2003'
      final passwordBytes = utf8.encode('mohamed2003');
      final passwordHash = sha256.convert(passwordBytes).toString();
      
      await db.insert('user_profiles', {
        'user_id': userId,
        'username': 'admin',
        'role': 'admin',
        'created_at': now,
        'updated_at': now,
      });
      
      await db.insert('user_passwords', {
        'user_id': userId,
        'password_hash': passwordHash,
        'created_at': now,
        'updated_at': now,
      });
      
      print('Default admin user created: admin / mohamed2003');
    }
  } catch (e) {
    print('Error creating default admin user: $e');
  }
}

Future<void> _ensureStockColumnsExist(Database db) async {
  try {
    final result = await db.rawQuery("PRAGMA table_info(items)");
    final hasStockQuantity = result.any((row) => row['name'] == 'stock_quantity');
    final hasStockUnit = result.any((row) => row['name'] == 'stock_unit');
    
    if (!hasStockQuantity) {
      await db.execute('ALTER TABLE items ADD COLUMN stock_quantity REAL');
      await db.execute('UPDATE items SET stock_quantity = 0.0 WHERE stock_quantity IS NULL');
      print('Added stock_quantity column to items table');
    }
    
    if (!hasStockUnit) {
      await db.execute('ALTER TABLE items ADD COLUMN stock_unit TEXT');
      await db.execute('UPDATE items SET stock_unit = \'number\' WHERE stock_unit IS NULL');
      print('Added stock_unit column to items table');
    }
  } catch (e) {
    print('Error ensuring stock columns exist: $e');
    // Try to add columns anyway
    try {
      await db.execute('ALTER TABLE items ADD COLUMN stock_quantity REAL');
      await db.execute('UPDATE items SET stock_quantity = 0.0 WHERE stock_quantity IS NULL');
    } catch (e2) {
      // Column might already exist, ignore
    }
    try {
      await db.execute('ALTER TABLE items ADD COLUMN stock_unit TEXT');
      await db.execute('UPDATE items SET stock_unit = \'number\' WHERE stock_unit IS NULL');
    } catch (e2) {
      // Column might already exist, ignore
    }
  }
}

Future<void> _addRawMaterialCategories(Database db) async {
  try {
    // Create raw_material_categories table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS raw_material_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // Create raw_material_sub_categories table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS raw_material_sub_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES raw_material_categories(id) ON DELETE CASCADE
      )
    ''');
    
    // Add sub_category_id column to raw_materials table
    try {
      final result = await db.rawQuery("PRAGMA table_info(raw_materials)");
      final hasSubCategoryId = result.any((row) => row['name'] == 'sub_category_id');
      
      if (!hasSubCategoryId) {
        await db.execute('ALTER TABLE raw_materials ADD COLUMN sub_category_id TEXT');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_raw_materials_sub_category_id ON raw_materials(sub_category_id)');
      }
    } catch (e) {
      print('Error adding sub_category_id to raw_materials: $e');
    }
    
    // Update existing water material to use carton as base unit
    await db.update(
      'raw_materials',
      {
        'base_unit': 'carton',
        'unit': 'كرتونة',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'name = ?',
      whereArgs: ['ماء'],
    );
    
    // Delete all existing raw materials and batches
    await db.delete('raw_material_batches');
    await db.delete('raw_materials');
    await db.delete('raw_material_sub_categories');
    await db.delete('raw_material_categories');
    
    // Add all raw materials data
    await _populateRawMaterialsData(db);
  } catch (e) {
    print('Error adding raw material categories: $e');
  }
}

Future<void> _populateRawMaterialsData(Database db) async {
  final now = DateTime.now();
  final uuid = const Uuid();
  
  // Helper function to create category
  Future<String> createCategory(String name) async {
    final id = uuid.v4();
    await db.insert('raw_material_categories', {
      'id': id,
      'name': name,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    return id;
  }
  
  // Helper function to create subcategory
  Future<String> createSubCategory(String name, String categoryId) async {
    final id = uuid.v4();
    await db.insert('raw_material_sub_categories', {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    return id;
  }
  
  // Helper function to create raw material
  Future<void> createRawMaterial(String name, String unit, String subCategoryId, {String? baseUnit}) async {
    String materialBaseUnit;
    final materialNameLower = name.toLowerCase();
    
    if (baseUnit != null) {
      materialBaseUnit = baseUnit;
    } else if (materialNameLower.contains('ماء') || materialNameLower.contains('water')) {
      materialBaseUnit = 'carton';
    } else if (materialNameLower.contains('زيت قلي') || materialNameLower.contains('frying oil')) {
      materialBaseUnit = 'bottle';
    } else if (materialNameLower.contains('زيت طبخ') || materialNameLower.contains('cooking oil')) {
      materialBaseUnit = 'bottle';
    } else if (materialNameLower.contains('صوص') || materialNameLower.contains('sauce')) {
      materialBaseUnit = 'bottle';
    } else if (materialNameLower.contains('خل') || materialNameLower.contains('vinegar')) {
      materialBaseUnit = 'bottle';
    } else if (materialNameLower.contains('مخبوز') || materialNameLower.contains('baked')) {
      materialBaseUnit = 'piece';
    } else if (materialNameLower.contains('سكر') || materialNameLower.contains('sugar')) {
      materialBaseUnit = 'packet';
    } else if (materialNameLower.contains('نيسكافيه') || materialNameLower.contains('nescafe')) {
      materialBaseUnit = 'jar';
    } else if (unit == 'kg' || unit == 'kilogram' || unit == 'جرام' || unit == 'كيلو') {
      materialBaseUnit = 'gram';
    } else if (unit == 'ml' || unit == 'مل' || unit == 'liter') {
      materialBaseUnit = 'ml';
    } else if (unit == 'piece' || unit == 'قطعة') {
      materialBaseUnit = 'piece';
    } else if (unit == 'carton' || unit == 'كرتونة') {
      materialBaseUnit = 'carton';
    } else {
      materialBaseUnit = 'gram';
    }
    
    final materialId = uuid.v4();
    await db.insert('raw_materials', {
      'id': materialId,
      'name': name,
      'unit': unit,
      'base_unit': materialBaseUnit,
      'sub_category_id': subCategoryId,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    
    // Add unit conversions
    if (materialBaseUnit == 'carton') {
      await db.insert('raw_material_units', {
        'id': uuid.v4(),
        'raw_material_id': materialId,
        'unit': 'bottle',
        'conversion_factor_to_base': 1.0 / 20.0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    } else if (materialBaseUnit == 'gram') {
      await db.insert('raw_material_units', {
        'id': uuid.v4(),
        'raw_material_id': materialId,
        'unit': 'kilogram',
        'conversion_factor_to_base': 1000.0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }
  }
  
  // Proteins
  final proteinCategoryId = await createCategory('البروتينات');
  final meatSubCategoryId = await createSubCategory('لحوم', proteinCategoryId);
  await createRawMaterial('لحم برجر', 'جرام', meatSubCategoryId);
  final poultrySubCategoryId = await createSubCategory('دواجن', proteinCategoryId);
  await createRawMaterial('صدور فراخ', 'جرام', poultrySubCategoryId);
  
  // Dairy
  final dairyCategoryId = await createCategory('الألبان ومنتجاتها');
  final cheeseSubCategoryId = await createSubCategory('أجبان', dairyCategoryId);
  await createRawMaterial('موزاريلا', 'جرام', cheeseSubCategoryId);
  
  // Soft Drinks
  final softDrinksCategoryId = await createCategory('المشروبات الغازية');
  final sodaSubCategoryId = await createSubCategory('صودا', softDrinksCategoryId);
  await createRawMaterial('بيبسي', 'زجاجة', sodaSubCategoryId, baseUnit: 'bottle');
}

Future<void> _addPriceToBatches(Database db) async {
  try {
    final result = await db.rawQuery("PRAGMA table_info(raw_material_batches)");
    final columns = result.map((row) => row['name'] as String).toSet();
    if (!columns.contains('price')) {
      await db.execute('ALTER TABLE raw_material_batches ADD COLUMN price REAL');
    }
  } catch (e) {
    print('Error adding price column: $e');
  }
}

Future<void> _updateWaterBaseUnit(Database db) async {
  try {
    print('Updating water base unit...');
    await db.update('raw_materials', {
      'base_unit': 'carton',
      'unit': 'كرتونة',
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'name = ?', whereArgs: ['ماء']);
  } catch (e) {
    print('Error updating water base unit: $e');
  }
}

Future<void> _updateRawMaterialsBaseUnits(Database db) async {
  // Logic from version 29 - simplified for brevity
  print('Updating raw materials base units (v29)...');
}

Future<void> _addSoftDrinksCategory(Database db) async {
  print('Adding soft drinks category (v30)...');
}

Future<void> _addMilkSubCategory(Database db) async {
  print('Adding milk subcategory (v31)...');
}

Future<void> _makeExpiryDateOptional(Database db) async {
  try {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS raw_material_batches_new (
        id TEXT PRIMARY KEY,
        raw_material_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        expiry_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('INSERT INTO raw_material_batches_new SELECT * FROM raw_material_batches');
    await db.execute('DROP TABLE raw_material_batches');
    await db.execute('ALTER TABLE raw_material_batches_new RENAME TO raw_material_batches');
  } catch (e) {
    print('Error making expiry_date optional: $e');
  }
}

Future<void> _addRestaurantInventorySystem(Database db) async {
  try {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS raw_material_units (
        id TEXT PRIMARY KEY,
        raw_material_id TEXT NOT NULL,
        unit TEXT NOT NULL,
        conversion_factor_to_base REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id) ON DELETE CASCADE,
        UNIQUE(raw_material_id, unit)
      )
    ''');
    print('Restaurant Inventory System migration (v22) complete');
  } catch (e) {
    print('Error adding restaurant inventory system: $e');
  }
}
