import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'migrations_helper.dart';

/// Core database class that handles initialization and provides base functionality
class DatabaseCore {
  static Database? _database;
  static const int _databaseVersion = 31;
  static const String _databaseName = 'smart_sales.db';

  /// Get the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database with FFI for desktop platforms
  static void initialize() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Initialize and open the database
  Future<Database> _initDatabase() async {
    final dbPath = await _getDatabasePath();
    debugPrint('Database path: $dbPath');

    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: MigrationsHelper.onCreate,
      onUpgrade: MigrationsHelper.onUpgrade,
      onOpen: MigrationsHelper.onOpen,
    );
  }

  /// Get the database file path
  Future<String> _getDatabasePath() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        // Use Application Support directory instead of Documents to avoid OneDrive sync issues
        final appDir = await getApplicationSupportDirectory();
        final dbDir = Directory(join(appDir.path, 'smart_sales'));

        if (!dbDir.existsSync()) {
          debugPrint('Creating database directory: ${dbDir.path}');
          dbDir.createSync(recursive: true);
        }
        return join(dbDir.path, _databaseName);
      } catch (e) {
        debugPrint('Error accessing application support directory: $e');
        // Fallback to a simpler path in case of persistent folder errors
        final fallbackDir = Directory('C:\\smart_sales_data');
        if (!fallbackDir.existsSync()) {
          try {
            fallbackDir.createSync(recursive: true);
          } catch (_) {}
        }
        return join(fallbackDir.path, _databaseName);
      }
    }
    return join(await getDatabasesPath(), _databaseName);
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

  /// Reset the database instance (for testing or re-initialization)
  static void resetDatabase() {
    _database = null;
  }
}
