enum TransactionType {
  cashIn,
  cashOut,
}

class FinancialTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final String? notes;
  final DateTime createdAt;

  const FinancialTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap({String? masterDeviceId, String? syncStatus, String? updatedAt}) {
    final map = {
      'id': id,
      'type': type == TransactionType.cashIn ? 'cash_in' : 'cash_out',
      'amount': amount,
      'description': description,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
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

  factory FinancialTransaction.fromMap(Map<String, dynamic> map) {
    return FinancialTransaction(
      id: map['id'] as String,
      type: map['type'] == 'cash_in' ? TransactionType.cashIn : TransactionType.cashOut,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

