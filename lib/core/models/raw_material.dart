import 'raw_material_batch.dart';

class RawMaterial {
  final String id;
  final String name;
  final String unit; // 'number', 'kg', 'packet', 'carton', 'bottle', 'bag'
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RawMaterialBatch> batches;

  const RawMaterial({
    required this.id,
    required this.name,
    required this.unit,
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
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RawMaterialBatch>? batches,
  }) {
    return RawMaterial(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      batches: batches ?? this.batches,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RawMaterial.fromMap(Map<String, dynamic> map) {
    return RawMaterial(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      unit: map['unit']?.toString() ?? 'number',
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
      batches: const [],
    );
  }
}

