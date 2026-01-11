import 'raw_material_batch.dart';

class RawMaterial {
  final String id;
  final String name;
  final String? category;
  final String baseUnit; // 'gram', 'ml', 'piece', 'bag'
  final double stockQuantity;
  final double minimumAlertQuantity;
  final String unit; // Legacy field: 'number', 'kg', 'packet', 'carton', 'bottle', 'bag'
  final String? subCategoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RawMaterialBatch> batches;

  const RawMaterial({
    required this.id,
    required this.name,
    this.category,
    this.baseUnit = 'gram',
    this.stockQuantity = 0.0,
    this.minimumAlertQuantity = 0.0,
    this.unit = 'number', // Legacy field
    this.subCategoryId,
    required this.createdAt,
    required this.updatedAt,
    this.batches = const [],
  });

  double get totalQuantity {
    return batches.fold(0.0, (sum, batch) => sum + batch.quantity);
  }

  bool get isInStock => totalQuantity > 0;

  RawMaterial copyWith({
    String? id,
    String? name,
    String? category,
    String? baseUnit,
    double? stockQuantity,
    double? minimumAlertQuantity,
    String? unit,
    String? subCategoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RawMaterialBatch>? batches,
  }) {
    return RawMaterial(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      baseUnit: baseUnit ?? this.baseUnit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minimumAlertQuantity: minimumAlertQuantity ?? this.minimumAlertQuantity,
      unit: unit ?? this.unit,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      batches: batches ?? this.batches,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'base_unit': baseUnit,
      'stock_quantity': stockQuantity,
      'minimum_alert_quantity': minimumAlertQuantity,
      'unit': unit,
      'sub_category_id': subCategoryId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RawMaterial.fromMap(Map<String, dynamic> map) {
    return RawMaterial(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString(),
      baseUnit: map['base_unit']?.toString() ?? 'gram',
      stockQuantity: (map['stock_quantity'] as num?)?.toDouble() ?? 0.0,
      minimumAlertQuantity: (map['minimum_alert_quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit']?.toString() ?? 'number',
      subCategoryId: map['sub_category_id']?.toString(),
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
      batches: const [],
    );
  }
}

