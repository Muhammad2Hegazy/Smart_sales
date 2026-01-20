class Customer {
  final String id;
  final String name;
  final String? phone;
  final double balance;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.balance = 0.0,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
