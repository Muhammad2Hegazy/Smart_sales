import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'base_dao.dart';
import '../models/financial_transaction.dart';

/// Data Access Object for Financial Transaction operations
class FinancialDao extends BaseDao {

  /// Insert a financial transaction
  Future<void> insertFinancialTransaction(FinancialTransaction transaction) async {
    final db = await database;
    await db.insert(
      'financial_transactions',
      {
        'id': transaction.id,
        'type': transaction.type,
        'amount': transaction.amount,
        'description': transaction.description,
        'created_at': transaction.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all financial transactions
  Future<List<FinancialTransaction>> getAllFinancialTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'financial_transactions',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => FinancialTransaction.fromMap(map)).toList();
  }

  /// Get financial transactions by date range
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

  /// Get total cash in by date range
  Future<double> getTotalCashInByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM financial_transactions WHERE type = 'cash_in' AND created_at >= ? AND created_at <= ?",
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total cash out by date range
  Future<double> getTotalCashOutByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM financial_transactions WHERE type = 'cash_out' AND created_at >= ? AND created_at <= ?",
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
