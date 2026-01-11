/// Supplier Model
/// Represents a supplier/vendor
class Supplier {
  final String id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final double? balance; // Current balance (positive = we owe, negative = they owe)
  final DateTime createdAt;
  final DateTime updatedAt;
  final String masterDeviceId;
  final String syncStatus;

  const Supplier({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.balance,
    required this.createdAt,
    required this.updatedAt,
    required this.masterDeviceId,
    required this.syncStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'master_device_id': masterDeviceId,
      'sync_status': syncStatus,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String,
      contactPerson: map['contact_person'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      balance: (map['balance'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      masterDeviceId: map['master_device_id'] as String,
      syncStatus: map['sync_status'] as String,
    );
  }

  Supplier copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? masterDeviceId,
    String? syncStatus,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      masterDeviceId: masterDeviceId ?? this.masterDeviceId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

