class InvoiceItem {
  final String id;
  final String invoiceId;
  final String itemId;
  final double quantitySold;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.itemId,
    required this.quantitySold,
    required this.createdAt,
    required this.updatedAt,
  });

  InvoiceItem copyWith({
    String? id,
    String? invoiceId,
    String? itemId,
    double? quantitySold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      itemId: itemId ?? this.itemId,
      quantitySold: quantitySold ?? this.quantitySold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'item_id': itemId,
      'quantity_sold': quantitySold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id']?.toString() ?? '',
      invoiceId: map['invoice_id']?.toString() ?? '',
      itemId: map['item_id']?.toString() ?? '',
      quantitySold: (map['quantity_sold'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}

