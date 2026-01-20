import 'note.dart';

class Item {
  final String id;
  final String name;
  final String subCategoryId;
  final double price;
  final String? imageUrl;
  final bool hasNotes;
  final List<Note> notes;
  final double stockQuantity;
  final String stockUnit; // 'number', 'kg', 'packet'
  final double? conversionRate; // e.g., 1 kg = 80 cups (conversionRate = 80)
  final bool isPosOnly; // If true, item is only available in POS, not in inventory
  final String? barcode;

  const Item({
    required this.id,
    required this.name,
    required this.subCategoryId,
    required this.price,
    this.imageUrl,
    this.hasNotes = false,
    this.notes = const [],
    this.stockQuantity = 0.0,
    this.stockUnit = 'number',
    this.conversionRate,

    this.isPosOnly = false,
    this.barcode,
  });

  bool get isInStock {
    try {
      final qty = stockQuantity;
      return qty > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get available quantity in base unit (e.g., cups from kg)
  double get availableQuantity {
    if (conversionRate != null && conversionRate! > 0) {
      return stockQuantity * conversionRate!;
    }
    return stockQuantity;
  }

  Item copyWith({
    String? id,
    String? name,
    String? subCategoryId,
    double? price,
    String? imageUrl,
    bool? hasNotes,
    List<Note>? notes,
    double? stockQuantity,
    String? stockUnit,
    double? conversionRate,

    bool? isPosOnly,
    String? barcode,
  }) {
    // Safely get stockQuantity and stockUnit
    double finalStockQty;
    String finalStockUnit;
    try {
      finalStockQty = stockQuantity ?? this.stockQuantity;
      finalStockUnit = stockUnit ?? this.stockUnit;
    } catch (e) {
      // If stockQuantity or stockUnit is null or invalid, use defaults
      finalStockQty = stockQuantity ?? 0.0;
      finalStockUnit = stockUnit ?? 'number';
    }
    
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      hasNotes: hasNotes ?? this.hasNotes,
      notes: notes ?? this.notes,
      stockQuantity: finalStockQty,
      stockUnit: finalStockUnit,
      conversionRate: conversionRate ?? this.conversionRate,

      isPosOnly: isPosOnly ?? this.isPosOnly,
      barcode: barcode ?? this.barcode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sub_category_id': subCategoryId,
      'price': price,
      'has_notes': hasNotes ? 1 : 0,
      'image_url': imageUrl,
      'stock_quantity': stockQuantity,
      'stock_unit': stockUnit,
      'conversion_rate': conversionRate,

      'is_pos_only': isPosOnly ? 1 : 0,
      'barcode': barcode,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    // Safely parse stockQuantity
    double stockQty = 0.0;
    try {
      final stockQtyValue = map['stock_quantity'];
      if (stockQtyValue != null) {
        if (stockQtyValue is num) {
          stockQty = stockQtyValue.toDouble();
        } else if (stockQtyValue is String) {
          stockQty = double.tryParse(stockQtyValue) ?? 0.0;
        }
      }
    } catch (e) {
      stockQty = 0.0;
    }
    
    // Safely parse stockUnit
    String stockUnitValue = 'number';
    try {
      final unitValue = map['stock_unit'];
      if (unitValue != null) {
        stockUnitValue = unitValue.toString();
      }
    } catch (e) {
      stockUnitValue = 'number';
    }
    
    return Item(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      subCategoryId: map['sub_category_id']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      hasNotes: (map['has_notes'] as int? ?? 0) == 1,
      imageUrl: map['image_url']?.toString(),
      stockQuantity: stockQty,
      stockUnit: stockUnitValue,
      conversionRate: (map['conversion_rate'] as num?)?.toDouble(),

      isPosOnly: (map['is_pos_only'] as int? ?? 0) == 1,
      barcode: map['barcode']?.toString(),
    );
  }
}

