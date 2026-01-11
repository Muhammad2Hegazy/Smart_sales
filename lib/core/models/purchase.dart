/// Purchase Model
/// Represents a purchase from a supplier
class Purchase {
  final String id;
  final String invoiceNumber; // Auto-generated invoice number
  final String supplierId;
  final String? supplierInvoiceNumber; // Optional supplier's invoice number
  final DateTime purchaseDate;
  final String paymentType; // 'cash' or 'credit'
  final double totalAmount;
  final double paidAmount;
  final double? discountAmount;
  final String? notes;
  final DateTime createdAt;
  final String masterDeviceId;
  final String syncStatus;
  final DateTime updatedAt;
  final List<PurchaseItem> items;

  const Purchase({
    required this.id,
    required this.invoiceNumber,
    required this.supplierId,
    this.supplierInvoiceNumber,
    required this.purchaseDate,
    required this.paymentType,
    required this.totalAmount,
    required this.paidAmount,
    this.discountAmount,
    this.notes,
    required this.createdAt,
    required this.masterDeviceId,
    required this.syncStatus,
    required this.updatedAt,
    required this.items,
  });

  Map<String, dynamic> toMap({bool includeItems = false}) {
    final map = {
      'id': id,
      'invoice_number': invoiceNumber,
      'supplier_id': supplierId,
      'supplier_invoice_number': supplierInvoiceNumber,
      'purchase_date': purchaseDate.toIso8601String(),
      'payment_type': paymentType,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'discount_amount': discountAmount,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'master_device_id': masterDeviceId,
      'sync_status': syncStatus,
      'updated_at': updatedAt.toIso8601String(),
    };
    return map;
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String? ?? '',
      supplierId: map['supplier_id'] as String,
      supplierInvoiceNumber: map['supplier_invoice_number'] as String?,
      purchaseDate: DateTime.parse(map['purchase_date'] as String),
      paymentType: map['payment_type'] as String? ?? 'cash',
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      masterDeviceId: map['master_device_id'] as String,
      syncStatus: map['sync_status'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      items: [], // Items will be loaded separately
    );
  }

  Purchase copyWith({
    String? id,
    String? invoiceNumber,
    String? supplierId,
    String? supplierInvoiceNumber,
    DateTime? purchaseDate,
    String? paymentType,
    double? totalAmount,
    double? paidAmount,
    double? discountAmount,
    String? notes,
    DateTime? createdAt,
    String? masterDeviceId,
    String? syncStatus,
    DateTime? updatedAt,
    List<PurchaseItem>? items,
  }) {
    return Purchase(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierInvoiceNumber: supplierInvoiceNumber ?? this.supplierInvoiceNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      paymentType: paymentType ?? this.paymentType,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      masterDeviceId: masterDeviceId ?? this.masterDeviceId,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

/// Purchase Item Model
class PurchaseItem {
  final String id;
  final String purchaseId;
  final String itemId;
  final String itemName;
  final String unit; // Stock unit (number, kg, packet, etc.)
  final double quantity;
  final double unitPrice;
  final double discount; // Discount per item
  final double total;
  final String masterDeviceId;
  final String syncStatus;
  final DateTime updatedAt;

  const PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.total,
    required this.masterDeviceId,
    required this.syncStatus,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'item_id': itemId,
      'item_name': itemName,
      'unit': unit,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'total': total,
      'master_device_id': masterDeviceId,
      'sync_status': syncStatus,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'] as String,
      purchaseId: map['purchase_id'] as String,
      itemId: map['item_id'] as String,
      itemName: map['item_name'] as String,
      unit: map['unit'] as String? ?? 'number',
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num).toDouble(),
      masterDeviceId: map['master_device_id'] as String,
      syncStatus: map['sync_status'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

