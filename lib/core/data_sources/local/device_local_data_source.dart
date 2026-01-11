import '../../database/database_helper.dart';
import '../../models/device.dart';

/// Local Data Source for Devices
/// Handles all local database operations for devices
class DeviceLocalDataSource {
  final DatabaseHelper _dbHelper;

  DeviceLocalDataSource(this._dbHelper);

  /// Save device to local database
  Future<void> saveDevice(Device device) async {
    await _dbHelper.insertDevice(device);
  }

  /// Get all devices from local database
  Future<List<Device>> getAllDevices() async {
    return await _dbHelper.getAllDevices();
  }

  /// Get devices by master device ID
  Future<List<Device>> getDevicesByMasterId(String masterDeviceId) async {
    return await _dbHelper.getDevicesByMasterId(masterDeviceId);
  }

  /// Get device by device ID
  Future<Device?> getDeviceById(String deviceId) async {
    return await _dbHelper.getDeviceById(deviceId);
  }

  /// Update device last seen timestamp
  Future<void> updateDeviceLastSeen(String deviceId) async {
    await _dbHelper.updateDeviceLastSeen(deviceId);
  }

  /// Delete device from local database
  Future<void> deleteDevice(String deviceId) async {
    await _dbHelper.deleteDevice(deviceId);
  }

  /// Set device as master
  Future<void> setDeviceAsMaster(String masterDeviceId, String deviceId) async {
    await _dbHelper.setDeviceAsMaster(masterDeviceId, deviceId);
  }

  /// Update device MAC address
  Future<void> updateDeviceMacAddress(String deviceId, String macAddress) async {
    await _dbHelper.updateDeviceMacAddress(deviceId, macAddress);
  }

  /// Get device by MAC address
  Future<Device?> getDeviceByMacAddress(String macAddress) async {
    return await _dbHelper.getDeviceByMacAddress(macAddress);
  }

  /// Update device floor
  Future<void> updateDeviceFloor(String deviceId, int? floor) async {
    await _dbHelper.updateDeviceFloor(deviceId, floor);
  }

  /// Get devices by floor
  Future<List<Device>> getDevicesByFloor(int? floor) async {
    return await _dbHelper.getDevicesByFloor(floor);
  }
}

