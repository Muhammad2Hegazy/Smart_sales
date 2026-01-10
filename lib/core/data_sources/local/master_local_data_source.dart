import '../../database/database_helper.dart';
import '../../models/master.dart';

/// Local Data Source for Master Device
/// Handles all local database operations for master device
class MasterLocalDataSource {
  final DatabaseHelper _dbHelper;

  MasterLocalDataSource(this._dbHelper);

  /// Save master device to local database
  Future<void> saveMaster(Master master) async {
    await _dbHelper.insertMaster(master);
  }

  /// Get master device from local database
  /// Returns null if no master exists
  Future<Master?> getMaster() async {
    return await _dbHelper.getMaster();
  }

  /// Update master device name
  Future<void> updateMasterName(String masterDeviceId, String newName) async {
    await _dbHelper.updateMasterName(masterDeviceId, newName);
  }
}

