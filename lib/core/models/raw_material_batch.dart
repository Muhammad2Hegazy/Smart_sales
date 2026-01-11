class RawMaterialBatch {
  final String id;
  final String rawMaterialId;
  final double quantity;
  final double? price;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RawMaterialBatch({
    required this.id,
    required this.rawMaterialId,
    required this.quantity,
    this.price,
    this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'raw_material_id': rawMaterialId,
      'quantity': quantity,
      'price': price,
      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RawMaterialBatch.fromMap(Map<String, dynamic> map) {
    DateTime? parsedExpiryDate;
    final expiryDateStr = map['expiry_date']?.toString();
    if (expiryDateStr != null && expiryDateStr.isNotEmpty) {
      try {
        parsedExpiryDate = DateTime.parse(expiryDateStr);
      } catch (e) {
        parsedExpiryDate = null;
      }
    }
    
    return RawMaterialBatch(
      id: map['id']?.toString() ?? '',
      rawMaterialId: map['raw_material_id']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num?)?.toDouble(),
      expiryDate: parsedExpiryDate,
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  RawMaterialBatch copyWith({
    String? id,
    String? rawMaterialId,
    double? quantity,
    double? price,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RawMaterialBatch(
      id: id ?? this.id,
      rawMaterialId: rawMaterialId ?? this.rawMaterialId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }
}

