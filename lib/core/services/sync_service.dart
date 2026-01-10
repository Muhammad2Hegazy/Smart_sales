import '../database/database_helper.dart';

class SyncService {
  final DatabaseHelper _dbHelper;

  SyncService(this._dbHelper);

  Future<bool> hasInternetConnection() async {
    return false;
  }

  void startSyncListener(Function(bool isOnline, int pendingRecords) onStatusChanged) {
  }

  void stopSyncListener() {
  }

  Future<int> getPendingRecordsCount() async {
    return 0;
  }

  Future<void> syncAllPendingRecords() async {
    return;
  }

  Future<void> markForSync(String tableName, String id) async {
    await _dbHelper.updateSyncStatus(tableName, id, 'pending');
  }
}
