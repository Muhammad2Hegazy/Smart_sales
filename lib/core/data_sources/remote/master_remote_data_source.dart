import '../../models/master.dart';

class MasterRemoteDataSource {
  MasterRemoteDataSource();

  Future<void> saveMaster(Master master) async {
    throw UnimplementedError('Not used - SQLite only');
  }

  Future<Master?> getMaster(String masterDeviceId) async {
    return null;
  }

  Future<Master?> getMasterByUserId(String userId) async {
    return null;
  }

  Future<void> updateMasterName(String masterDeviceId, String newName) async {
    throw UnimplementedError('Not used - SQLite only');
  }

  Future<bool> masterExists(String masterDeviceId) async {
    return false;
  }
}
