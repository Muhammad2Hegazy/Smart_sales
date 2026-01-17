import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_core.dart';

/// Base Data Access Object class that provides common database functionality
abstract class BaseDao {
  final DatabaseCore _databaseCore = DatabaseCore();

  /// Get the database instance
  Future<Database> get database => _databaseCore.database;
}
