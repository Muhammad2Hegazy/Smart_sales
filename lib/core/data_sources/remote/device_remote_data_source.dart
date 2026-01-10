import '../../models/device.dart';

class DeviceRemoteDataSource {
  DeviceRemoteDataSource();

  Future<void> saveDevice(Device device) async {
    throw UnimplementedError('Not used - SQLite only');
  }

  Future<List<Device>> getDevicesByMasterId(String masterDeviceId) async {
    return [];
  }

  Future<Device?> getDeviceById(String masterDeviceId, String deviceId) async {
    return null;
  }

  Future<void> updateDeviceLastSeen(String masterDeviceId, String deviceId) async {
    throw UnimplementedError('Not used - SQLite only');
  }

  Future<void> deleteDevice(String masterDeviceId, String deviceId) async {
    throw UnimplementedError('Not used - SQLite only');
  }
}
