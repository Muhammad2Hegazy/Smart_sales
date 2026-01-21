import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import 'api_client.dart';

class SyncService {
  final DatabaseHelper _dbHelper;
  final ApiClient _apiClient = ApiClient();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  static const List<String> syncableTables = [
    'categories',
    'sub_categories',
    'items',
    'sales',
    'sale_items',
    'financial_transactions',
    'shift_reports',
    'inventory_movements',
  ];

  SyncService(this._dbHelper);

  Future<bool> hasInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  void startSyncListener(Function(bool isOnline, int pendingRecords) onStatusChanged) {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) async {
      final isOnline = !results.contains(ConnectivityResult.none);
      final pendingRecords = await getPendingRecordsCount();
      onStatusChanged(isOnline, pendingRecords);
    });
  }

  void stopSyncListener() {
    _connectivitySubscription?.cancel();
  }

  Future<int> getPendingRecordsCount() async {
    int total = 0;
    final master = await _dbHelper.getMaster();
    if (master == null) return 0;

    for (final table in syncableTables) {
      final pending = await _dbHelper.getPendingSyncRecords(table, master.masterDeviceId);
      total += pending.length;
    }
    return total;
  }

  Future<void> syncAllPendingRecords() async {
    final master = await _dbHelper.getMaster();
    if (master == null) return;

    for (final table in syncableTables) {
      await _syncTable(table, master.masterDeviceId);
    }
  }

  Future<void> _syncTable(String tableName, String masterDeviceId) async {
    try {
      // 1. Push pending
      final pending = await _dbHelper.getPendingSyncRecords(tableName, masterDeviceId);
      if (pending.isNotEmpty) {
        final response = await _apiClient.post('/sync/$tableName/push', {
          'master_device_id': masterDeviceId,
          'records': pending,
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          for (var record in pending) {
            final id = record['id'] ?? record['user_id'] ?? record['device_id'];
            if (id != null) {
              await _dbHelper.updateSyncStatus(tableName, id.toString(), 'synced');
            }
          }
        }
      }

      // 2. Pull updates
      final lastSyncTime = await _getLastSyncTime(tableName);
      final response = await _apiClient.get('/sync/$tableName/pull', queryParameters: {
        'master_device_id': masterDeviceId,
        'since': lastSyncTime,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> records = data['records'] ?? [];

        if (records.isNotEmpty) {
          final db = await _dbHelper.database;
          await db.transaction((txn) async {
            for (var record in records) {
              await txn.insert(
                tableName,
                record as Map<String, dynamic>,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          });
          await _setLastSyncTime(tableName, DateTime.now().toIso8601String());
        }
      }
    } catch (e) {
      print('Error syncing table $tableName: $e');
    }
  }

  Future<String> _getLastSyncTime(String tableName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_sync_$tableName') ?? '1970-01-01T00:00:00Z';
  }

  Future<void> _setLastSyncTime(String tableName, String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_$tableName', time);
  }

  Future<void> markForSync(String tableName, String id) async {
    await _dbHelper.updateSyncStatus(tableName, id, 'pending');
  }
}
