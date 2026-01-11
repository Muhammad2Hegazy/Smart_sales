class RawMaterialUnit {
  final String id;
  final String rawMaterialId;
  final String unit; // 'gram', 'kilogram', 'ml', 'piece', 'bag'
  final double conversionFactorToBase;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RawMaterialUnit({
    required this.id,
    required this.rawMaterialId,
    required this.unit,
    required this.conversionFactorToBase,
    required this.createdAt,
    required this.updatedAt,
  });

  RawMaterialUnit copyWith({
    String? id,
    String? rawMaterialId,
    String? unit,
    double? conversionFactorToBase,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RawMaterialUnit(
      id: id ?? this.id,
      rawMaterialId: rawMaterialId ?? this.rawMaterialId,
      unit: unit ?? this.unit,
      conversionFactorToBase: conversionFactorToBase ?? this.conversionFactorToBase,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'raw_material_id': rawMaterialId,
      'unit': unit,
      'conversion_factor_to_base': conversionFactorToBase,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RawMaterialUnit.fromMap(Map<String, dynamic> map) {
    return RawMaterialUnit(
      id: map['id']?.toString() ?? '',
      rawMaterialId: map['raw_material_id']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      conversionFactorToBase: (map['conversion_factor_to_base'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}

