class Sale {
  final String id;
  final String? tableNumber; // null for takeaway/delivery, "takeaway", "delivery", "hospitality", or "1"-"100"
  final double total;
  final String paymentMethod; // "cash" or "card"
  final DateTime createdAt;
  final List<SaleItem> items;
  final double discountPercentage; // Discount percentage (0-100)
  final double discountAmount; // Discount amount in currency
  final double serviceCharge; // Service charge amount (for dine-in)
  final double deliveryTax; // Delivery tax amount (for delivery orders)
  final double hospitalityTax; // Hospitality tax amount (for hospitality orders)
  final String? deviceId; // Device ID that created this sale

  const Sale({
    required this.id,
    this.tableNumber,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
    this.discountPercentage = 0.0,
    this.discountAmount = 0.0,
    this.serviceCharge = 0.0,
    this.deliveryTax = 0.0,
    this.hospitalityTax = 0.0,
    this.deviceId,
  });

  Sale copyWith({
    String? id,
    String? tableNumber,
    double? total,
    String? paymentMethod,
    DateTime? createdAt,
    List<SaleItem>? items,
    double? discountPercentage,
    double? discountAmount,
    double? serviceCharge,
    double? deliveryTax,
    double? hospitalityTax,
    String? deviceId,
  }) {
    return Sale(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      deliveryTax: deliveryTax ?? this.deliveryTax,
      hospitalityTax: hospitalityTax ?? this.hospitalityTax,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toMap({String? masterDeviceId, String? syncStatus, String? updatedAt, String? deviceId}) {
    final map = {
      'id': id,
      'table_number': tableNumber,
      'total': total,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'discount_percentage': discountPercentage,
      'discount_amount': discountAmount,
      'service_charge': serviceCharge,
      'delivery_tax': deliveryTax,
      'hospitality_tax': hospitalityTax,
    };
    
    // Add device_id if provided
    if (deviceId != null) {
      map['device_id'] = deviceId;
    } else if (this.deviceId != null) {
      map['device_id'] = this.deviceId;
    }
    
    // Add sync fields if provided
    if (masterDeviceId != null) {
      map['master_device_id'] = masterDeviceId;
    }
    if (syncStatus != null) {
      map['sync_status'] = syncStatus;
    }
    if (updatedAt != null) {
      map['updated_at'] = updatedAt;
    }
    
    return map;
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String,
      tableNumber: map['table_number'] as String?,
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: [], // Items will be loaded separately
      discountPercentage: (map['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      serviceCharge: (map['service_charge'] as num?)?.toDouble() ?? 0.0,
      deliveryTax: (map['delivery_tax'] as num?)?.toDouble() ?? 0.0,
      hospitalityTax: (map['hospitality_tax'] as num?)?.toDouble() ?? 0.0,
      deviceId: map['device_id'] as String?,
    );
  }
}

class SaleItem {
  final String id;
  final String saleId;
  final String itemId;
  final String itemName;
  final double price;
  final int quantity;
  final double total;

  const SaleItem({
    required this.id,
    required this.saleId,
    required this.itemId,
    required this.itemName,
    required this.price,
    required this.quantity,
    required this.total,
  });

  Map<String, dynamic> toMap({String? masterDeviceId, String? syncStatus, String? updatedAt}) {
    final map = {
      'id': id,
      'sale_id': saleId,
      'item_id': itemId,
      'item_name': itemName,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
    
    // Add sync fields if provided
    if (masterDeviceId != null) {
      map['master_device_id'] = masterDeviceId;
    }
    if (syncStatus != null) {
      map['sync_status'] = syncStatus;
    }
    if (updatedAt != null) {
      map['updated_at'] = updatedAt;
    }
    
    return map;
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as String,
      saleId: map['sale_id'] as String,
      itemId: map['item_id'] as String,
      itemName: map['item_name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toInt(),
      total: (map['total'] as num).toDouble(),
    );
  }
}

