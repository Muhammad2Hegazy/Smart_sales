import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'base_dao.dart';
import '../models/master.dart';
import '../models/device.dart';

/// Data Access Object for Master and Device management
class DevicesDao extends BaseDao {

  // ============ Master ============

  /// Insert a master device
  Future<void> insertMaster(Master master) async {
    final db = await database;
    await db.insert(
      'masters',
      master.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get the master device
  Future<Master?> getMaster() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('masters', limit: 1);
    if (maps.isEmpty) return null;
    return Master.fromMap(maps.first);
  }

  /// Update master name
  Future<void> updateMasterName(String masterDeviceId, String newName) async {
    final db = await database;
    await db.update(
      'masters',
      {'master_name': newName},
      where: 'master_device_id = ?',
      whereArgs: [masterDeviceId],
    );
  }

  // ============ Devices ============

  /// Insert a device
  Future<void> insertDevice(Device device) async {
    final db = await database;
    await db.insert(
      'devices',
      device.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all devices
  Future<List<Device>> getAllDevices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('devices');
    return maps.map((map) => Device.fromMap(map)).toList();
  }

  /// Get devices by master ID
  Future<List<Device>> getDevicesByMasterId(String masterDeviceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where: 'master_device_id = ?',
      whereArgs: [masterDeviceId],
    );
    return maps.map((map) => Device.fromMap(map)).toList();
  }

  /// Get device by ID
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

  /// Update device last seen timestamp
  Future<void> updateDeviceLastSeen(String deviceId) async {
    final db = await database;
    await db.update(
      'devices',
      {'last_seen_at': DateTime.now().toIso8601String()},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  /// Delete a device
  Future<void> deleteDevice(String deviceId) async {
    final db = await database;
    await db.delete(
      'devices',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  /// Set a device as master
  Future<void> setDeviceAsMaster(String masterDeviceId, String deviceId) async {
    final db = await database;
    // First, reset all devices to non-master
    await db.update(
      'devices',
      {'is_master': 0},
      where: 'master_device_id = ?',
      whereArgs: [masterDeviceId],
    );
    // Then set the specified device as master
    await db.update(
      'devices',
      {'is_master': 1},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  /// Update device MAC address
  Future<void> updateDeviceMacAddress(String deviceId, String macAddress) async {
    final db = await database;
    await db.update(
      'devices',
      {'mac_address': macAddress},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  /// Update device floor
  Future<void> updateDeviceFloor(String deviceId, int? floor) async {
    final db = await database;
    await db.update(
      'devices',
      {'floor': floor},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  /// Get device by MAC address
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
    final List<Map<String, dynamic>> maps;
    if (floor == null) {
      maps = await db.query(
        'devices',
        where: 'floor IS NULL',
      );
    } else {
      maps = await db.query(
        'devices',
        where: 'floor = ?',
        whereArgs: [floor],
      );
    }
    return maps.map((map) => Device.fromMap(map)).toList();
  }

  // ============ Sync ============

  /// Get pending sync records for a table
  Future<List<Map<String, dynamic>>> getPendingSyncRecords(String tableName, String masterDeviceId) async {
    final db = await database;
    return await db.query(
      tableName,
      where: "master_device_id = ? AND sync_status = 'pending'",
      whereArgs: [masterDeviceId],
    );
  }

  /// Update sync status for a record
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
