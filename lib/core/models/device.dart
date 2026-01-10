/// Device Model
/// Represents a device (master or slave) in the system
class Device {
  final String deviceId; // UUID of this device
  final String deviceName; // User-friendly name for the device
  final String masterDeviceId; // UUID of the master device this device belongs to
  final bool isMaster; // Whether this device is the master
  final DateTime lastSeenAt; // Last time this device was seen/active
  final String? macAddress; // MAC address of the device
  final int? floor; // Floor/level number where the device is located

  const Device({
    required this.deviceId,
    required this.deviceName,
    required this.masterDeviceId,
    required this.isMaster,
    required this.lastSeenAt,
    this.macAddress,
    this.floor,
  });

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'master_device_id': masterDeviceId,
      'is_master': isMaster ? 1 : 0,
      'last_seen_at': lastSeenAt.toIso8601String(),
      'mac_address': macAddress,
      'floor': floor,
    };
  }

  /// Create from Map (database or Firestore)
  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      deviceId: map['device_id'] as String? ?? map['deviceId'] as String,
      deviceName: map['device_name'] as String? ?? map['deviceName'] as String,
      masterDeviceId: map['master_device_id'] as String? ?? map['masterDeviceId'] as String,
      isMaster: map['is_master'] != null
          ? (map['is_master'] as int) == 1
          : (map['isMaster'] as bool? ?? false),
      lastSeenAt: map['last_seen_at'] != null
          ? DateTime.parse(map['last_seen_at'] as String)
          : DateTime.parse(map['lastSeenAt'] as String),
      macAddress: map['mac_address'] as String? ?? map['macAddress'] as String?,
      floor: map['floor'] != null ? (map['floor'] as int) : null,
    );
  }

  /// Create a copy with updated fields
  Device copyWith({
    String? deviceId,
    String? deviceName,
    String? masterDeviceId,
    bool? isMaster,
    DateTime? lastSeenAt,
    String? macAddress,
    int? floor,
  }) {
    return Device(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      masterDeviceId: masterDeviceId ?? this.masterDeviceId,
      isMaster: isMaster ?? this.isMaster,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      macAddress: macAddress ?? this.macAddress,
      floor: floor ?? this.floor,
    );
  }

  @override
  String toString() {
    return 'Device(deviceId: $deviceId, deviceName: $deviceName, masterDeviceId: $masterDeviceId, isMaster: $isMaster, lastSeenAt: $lastSeenAt, macAddress: $macAddress)';
  }
}

