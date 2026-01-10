class InventoryItem {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final double price;
  final String unit;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.price,
    required this.unit,
  });

  bool get isLowStock => quantity < 30;

  double get totalValue => quantity * price;

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    double? price,
    String? unit,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      unit: unit ?? this.unit,
    );
  }
}

