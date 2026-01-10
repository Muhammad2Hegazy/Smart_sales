/// Master Device Model
/// Represents the master device that controls all linked devices
class Master {
  final String masterDeviceId; // UUID of the master device
  final String masterName; // User-friendly name for the master
  final String userId; // UUID of the Supabase Auth user
  final DateTime createdAt; // When the master was created

  const Master({
    required this.masterDeviceId,
    required this.masterName,
    required this.userId,
    required this.createdAt,
  });

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'master_device_id': masterDeviceId,
      'master_name': masterName,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from Map (database or Supabase)
  factory Master.fromMap(Map<String, dynamic> map) {
    return Master(
      masterDeviceId: map['master_device_id'] as String? ?? map['masterDeviceId'] as String,
      masterName: map['master_name'] as String? ?? map['masterName'] as String,
      userId: map['user_id'] as String? ?? map['userId'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Create a copy with updated fields
  Master copyWith({
    String? masterDeviceId,
    String? masterName,
    String? userId,
    DateTime? createdAt,
  }) {
    return Master(
      masterDeviceId: masterDeviceId ?? this.masterDeviceId,
      masterName: masterName ?? this.masterName,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Master(masterDeviceId: $masterDeviceId, masterName: $masterName, userId: $userId, createdAt: $createdAt)';
  }
}

