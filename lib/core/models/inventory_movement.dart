/// Inventory Movement Model
/// Represents inventory movements (purchases, sales, returns, adjustments)
class InventoryMovement {
  final String id;
  final String itemId;
  final String movementType; // 'purchase', 'sale', 'return', 'adjustment', 'opening_stock'
  final double quantity; // Positive for increases, negative for decreases
  final double? unitPrice; // Price per unit (for purchases/sales)
  final double? totalValue; // Total value of movement
  final String? referenceId; // Reference to sale_id, purchase_id, etc.
  final String? referenceType; // 'sale', 'purchase', 'return', etc.
  final String? notes;
  final DateTime createdAt;
  final String masterDeviceId;
  final String syncStatus;
  final DateTime updatedAt;

  const InventoryMovement({
    required this.id,
    required this.itemId,
    required this.movementType,
    required this.quantity,
    this.unitPrice,
    this.totalValue,
    this.referenceId,
    this.referenceType,
    this.notes,
    required this.createdAt,
    required this.masterDeviceId,
    required this.syncStatus,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'movement_type': movementType,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_value': totalValue,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'master_device_id': masterDeviceId,
      'sync_status': syncStatus,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InventoryMovement.fromMap(Map<String, dynamic> map) {
    return InventoryMovement(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      movementType: map['movement_type'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num?)?.toDouble(),
      totalValue: (map['total_value'] as num?)?.toDouble(),
      referenceId: map['reference_id'] as String?,
      referenceType: map['reference_type'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      masterDeviceId: map['master_device_id'] as String,
      syncStatus: map['sync_status'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  InventoryMovement copyWith({
    String? id,
    String? itemId,
    String? movementType,
    double? quantity,
    double? unitPrice,
    double? totalValue,
    String? referenceId,
    String? referenceType,
    String? notes,
    DateTime? createdAt,
    String? masterDeviceId,
    String? syncStatus,
    DateTime? updatedAt,
  }) {
    return InventoryMovement(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      movementType: movementType ?? this.movementType,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalValue: totalValue ?? this.totalValue,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      masterDeviceId: masterDeviceId ?? this.masterDeviceId,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

