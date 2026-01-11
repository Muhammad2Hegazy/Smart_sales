import 'invoice_item.dart';

class Invoice {
  final String id;
  final DateTime date;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<InvoiceItem> items;

  const Invoice({
    required this.id,
    required this.date,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  Invoice copyWith({
    String? id,
    DateTime? date,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: id ?? this.id,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id']?.toString() ?? '',
      date: DateTime.parse(map['date']?.toString() ?? DateTime.now().toIso8601String()),
      totalAmount: (map['total_amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
      items: const [],
    );
  }
}

