part of 'database_helper.dart';

extension DatabaseHelperMaster on DatabaseHelper {
  // Masters CRUD
  Future<void> insertMaster(Master master) async {
    final db = await database;
    await db.insert(
      'masters',
      master.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Master?> getMaster() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('masters', limit: 1);
    if (maps.isEmpty) return null;
    return Master.fromMap(maps.first);
  }

  Future<void> updateMasterName(String masterDeviceId, String newName) async {
    final db = await database;
    await db.update(
      'masters',
      {'master_name': newName},
      where: 'master_device_id = ?',
      whereArgs: [masterDeviceId],
    );
  }

  // Devices CRUD
  Future<void> insertDevice(Device device) async {
    final db = await database;
    await db.insert(
      'devices',
      device.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Device>> getAllDevices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('devices');
    return maps.map((map) => Device.fromMap(map)).toList();
  }

  Future<List<Device>> getDevicesByMasterId(String masterDeviceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where: 'master_device_id = ?',
      whereArgs: [masterDeviceId],
    );
    return maps.map((map) => Device.fromMap(map)).toList();
  }

  Future<Device?> getDeviceById(String deviceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where: 'device_id = ?',
      whereArgs: [deviceId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Device.fromMap(maps.first);
  }

  Future<void> updateDeviceLastSeen(String deviceId) async {
    final db = await database;
    await db.update(
      'devices',
      {'last_seen_at': DateTime.now().toIso8601String()},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  Future<void> deleteDevice(String deviceId) async {
    final db = await database;
    await db.delete(
      'devices',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  Future<void> setDeviceAsMaster(String masterDeviceId, String deviceId) async {
    final db = await database;
    // First, set all devices in this master group to not master
    await db.update(
      'devices',
      {'is_master': 0},
      where: 'master_device_id = ?',
      whereArgs: [masterDeviceId],
    );
    // Then set the selected device as master
    await db.update(
      'devices',
      {'is_master': 1},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  Future<void> updateDeviceMacAddress(String deviceId, String macAddress) async {
    final db = await database;
    await db.update(
      'devices',
      {'mac_address': macAddress},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  Future<void> updateDeviceFloor(String deviceId, int? floor) async {
    final db = await database;
    await db.update(
      'devices',
      {'floor': floor},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  Future<Device?> getDeviceByMacAddress(String macAddress) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where: 'mac_address = ?',
      whereArgs: [macAddress],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Device.fromMap(maps.first);
  }

  /// Get devices by floor
  Future<List<Device>> getDevicesByFloor(int? floor) async {
    final db = await database;
    if (floor == null) {
      // Get devices with no floor assigned
      final List<Map<String, dynamic>> maps = await db.query(
        'devices',
        where: 'floor IS NULL',
      );
      return maps.map((map) => Device.fromMap(map)).toList();
    } else {
      final List<Map<String, dynamic>> maps = await db.query(
        'devices',
        where: 'floor = ?',
        whereArgs: [floor],
      );
      return maps.map((map) => Device.fromMap(map)).toList();
    }
  }

  /// Ensure developer device is always registered
  /// Developer MAC: E0:0A:F6:C3:BA:FF
  // Sync status helpers
  Future<List<Map<String, dynamic>>> getPendingSyncRecords(String tableName, String masterDeviceId) async {
    final db = await database;
    return await db.query(
      tableName,
      where: 'master_device_id = ? AND sync_status = ?',
      whereArgs: [masterDeviceId, 'pending'],
    );
  }

  Future<void> updateSyncStatus(String tableName, String id, String status) async {
    final db = await database;
    await db.update(
      tableName,
      {
        'sync_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
