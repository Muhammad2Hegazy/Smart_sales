import '../data_sources/local/master_local_data_source.dart';
import '../data_sources/local/device_local_data_source.dart';
import '../models/master.dart';
import '../models/device.dart';
import 'package:uuid/uuid.dart';


class DeviceRepository {
  final MasterLocalDataSource _masterLocalDataSource;
  final DeviceLocalDataSource _deviceLocalDataSource;
  final Uuid _uuid;

  DeviceRepository(
    this._masterLocalDataSource,
    this._deviceLocalDataSource,
    this._uuid,
  );

  Future<Master> initializeMaster({
    required String userId,
    String? deviceName,
  }) async {
    final existingMaster = await _masterLocalDataSource.getMaster();
    
    if (existingMaster != null) {
      if (existingMaster.userId != userId) {
        final updatedMaster = existingMaster.copyWith(userId: userId);
        await _masterLocalDataSource.saveMaster(updatedMaster);
        return updatedMaster;
      }
      return existingMaster;
    }

    final masterDeviceId = _uuid.v4();
    final master = Master(
      masterDeviceId: masterDeviceId,
      masterName: deviceName ?? 'Master Device',
      userId: userId,
      createdAt: DateTime.now(),
    );

    await _masterLocalDataSource.saveMaster(master);
    return master;
  }

  Future<Master?> getMaster() async {
    return await _masterLocalDataSource.getMaster();
  }

  Future<void> updateMasterName(String masterDeviceId, String newName) async {
    await _masterLocalDataSource.updateMasterName(masterDeviceId, newName);
  }

  Future<Device> registerCurrentDevice({
    required String masterDeviceId,
    String? deviceName,
    bool isMaster = false,
    String? macAddress,
  }) async {
    // If MAC address is provided, check if device with this MAC already exists
    if (macAddress != null && macAddress.isNotEmpty) {
      final existingDevice = await _deviceLocalDataSource.getDeviceByMacAddress(macAddress);
      if (existingDevice != null) {
        // Device with this MAC already exists - update last seen and return it
        await _deviceLocalDataSource.updateDeviceLastSeen(existingDevice.deviceId);
        // Update device name if provided and different
        if (deviceName != null && deviceName.isNotEmpty && existingDevice.deviceName != deviceName) {
          // Note: We don't have an updateDeviceName method, so we'll keep the existing name
          // Or we could add that method if needed
        }
        return existingDevice.copyWith(lastSeenAt: DateTime.now());
      }
    }

    // No existing device found - create new one
    final deviceId = _uuid.v4();
    
    final finalDeviceName = deviceName ?? 'Device ${deviceId.substring(0, 8)}';
    
    final device = Device(
      deviceId: deviceId,
      deviceName: finalDeviceName,
      masterDeviceId: masterDeviceId,
      isMaster: isMaster,
      lastSeenAt: DateTime.now(),
      macAddress: macAddress,
    );

    await _deviceLocalDataSource.saveDevice(device);
    return device;
  }

  Future<List<Device>> getDevicesByMasterId(String masterDeviceId) async {
    return await _deviceLocalDataSource.getDevicesByMasterId(masterDeviceId);
  }

  Future<void> updateDeviceLastSeen(String masterDeviceId, String deviceId) async {
    await _deviceLocalDataSource.updateDeviceLastSeen(deviceId);
  }

  Future<void> deleteDevice(String masterDeviceId, String deviceId) async {
    await _deviceLocalDataSource.deleteDevice(deviceId);
  }

  Future<void> setDeviceAsMaster(String masterDeviceId, String deviceId) async {
    await _deviceLocalDataSource.setDeviceAsMaster(masterDeviceId, deviceId);
  }

  Future<void> updateDeviceMacAddress(String deviceId, String macAddress) async {
    await _deviceLocalDataSource.updateDeviceMacAddress(deviceId, macAddress);
  }

  Future<Device?> getDeviceByMacAddress(String macAddress) async {
    return await _deviceLocalDataSource.getDeviceByMacAddress(macAddress);
  }

  Future<void> updateDeviceFloor(String deviceId, int? floor) async {
    await _deviceLocalDataSource.updateDeviceFloor(deviceId, floor);
  }

  Future<List<Device>> getDevicesByFloor(int? floor) async {
    return await _deviceLocalDataSource.getDevicesByFloor(floor);
  }

  Future<String> getCurrentDeviceId() async {
    return _uuid.v4();
  }
}
