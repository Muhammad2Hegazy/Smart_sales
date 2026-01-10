import '../database/database_helper.dart';
import '../models/master.dart';

/// Master Device Helper
/// Utility functions to ensure masterDeviceId is set on all database operations
class MasterDeviceHelper {
  final DatabaseHelper _dbHelper;
  Master? _cachedMaster;

  MasterDeviceHelper(this._dbHelper);

  /// Get current master device ID
  /// Caches the result for performance
  Future<String?> getMasterDeviceId() async {
    if (_cachedMaster != null) {
      return _cachedMaster!.masterDeviceId;
    }

    _cachedMaster = await _dbHelper.getMaster();
    return _cachedMaster?.masterDeviceId;
  }

  /// Ensure masterDeviceId is set in a map
  /// Adds masterDeviceId, sync_status, and updated_at if not present
  Future<Map<String, dynamic>> ensureMasterDeviceFields(
    Map<String, dynamic> data,
  ) async {
    final masterDeviceId = await getMasterDeviceId();
    if (masterDeviceId == null) {
      throw Exception('Master device not initialized. Please initialize master device first.');
    }

    final result = Map<String, dynamic>.from(data);
    
    // Add master_device_id if not present
    if (!result.containsKey('master_device_id')) {
      result['master_device_id'] = masterDeviceId;
    }

    // Add sync_status if not present
    if (!result.containsKey('sync_status')) {
      result['sync_status'] = 'pending';
    }

    // Add updated_at if not present
    if (!result.containsKey('updated_at')) {
      result['updated_at'] = DateTime.now().toIso8601String();
    }

    return result;
  }

  /// Clear cache (call when master is updated)
  void clearCache() {
    _cachedMaster = null;
  }

  /// Refresh master from database
  Future<void> refreshMaster() async {
    _cachedMaster = await _dbHelper.getMaster();
  }
}

