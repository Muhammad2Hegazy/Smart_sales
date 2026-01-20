part of 'database_helper.dart';

extension DatabaseHelperAccounting on DatabaseHelper {
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
}
