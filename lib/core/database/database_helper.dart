import 'dart:io';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/csv_importer.dart';

// Model imports
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
import '../models/invoice_item.dart';

// Parts
part 'database_helper_migrations.dart';
part 'database_helper_items.dart';
part 'database_helper_sales.dart';
part 'database_helper_pending_invoices.dart';
part 'database_helper_accounting.dart';
part 'database_helper_users.dart';
part 'database_helper_master.dart';
part 'database_helper_raw_materials.dart';
part 'database_helper_reports.dart';
part 'database_helper_helpers.dart';

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
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await _getDbPath();
    
    // Ensure the directory exists
    final dbFile = File(dbPath);
    final dbDirectory = dbFile.parent;
    if (!await dbDirectory.exists()) {
      await dbDirectory.create(recursive: true);
    }
    
    return await openDatabase(
      dbPath,
      version: 33,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<String> _getDbPath() async {
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
    return await _getDbPath();
  }

  /// Close the database connection (public method for backup/restore)
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
