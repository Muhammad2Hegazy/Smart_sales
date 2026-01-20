part of 'database_helper.dart';

extension DatabaseHelperPendingInvoices on DatabaseHelper {
  // Pending Invoices CRUD (for multi-table support and caching)
  /// Save a pending invoice (draft invoice)
  Future<void> savePendingInvoice({
    required List<String> tableNumbers,
    required List<Map<String, dynamic>> items,
    Map<String, int>? tableOrderNumbers,
    int? orderNumber, // Deprecated, use tableOrderNumbers instead
    double discountPercentage = 0.0,
    double discountAmount = 0.0,
    double serviceCharge = 0.0,
    double deliveryTax = 0.0,
    double hospitalityTax = 0.0,
  }) async {
    final db = await database;
    final master = await getMaster();
    final masterDeviceId = master?.masterDeviceId ?? '';
    final now = DateTime.now();
    final uuid = const Uuid();
    
    // Create a unique ID based on table numbers
    final tableNumbersKey = tableNumbers.join(',');
    final id = uuid.v5('6ba7b811-9dad-11d1-80b4-00c04fd430c8', 'pending_invoice_$tableNumbersKey');
    
    // Store table order numbers as JSON, fallback to orderNumber if provided
    String? orderNumbersJson;
    if (tableOrderNumbers != null && tableOrderNumbers.isNotEmpty) {
      orderNumbersJson = jsonEncode(tableOrderNumbers);
    } else if (orderNumber != null) {
      // Legacy support: create map with single entry
      final legacyMap = <String, int>{};
      if (tableNumbers.isNotEmpty) {
        legacyMap[tableNumbers.first] = orderNumber;
      }
      orderNumbersJson = jsonEncode(legacyMap);
    }
    
    await db.insert(
      'pending_invoices',
      {
        'id': id,
        'table_numbers': tableNumbersKey,
        'items': jsonEncode(items),
        'order_number': orderNumbersJson, // Store as JSON string
        'discount_percentage': discountPercentage,
        'discount_amount': discountAmount,
        'service_charge': serviceCharge,
        'delivery_tax': deliveryTax,
        'hospitality_tax': hospitalityTax,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'master_device_id': masterDeviceId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a pending invoice by table numbers
  Future<Map<String, dynamic>?> getPendingInvoiceByTableNumbers(List<String> tableNumbers) async {
    final db = await database;
    final tableNumbersKey = tableNumbers.join(',');
    
    final List<Map<String, dynamic>> maps = await db.query(
      'pending_invoices',
      where: 'table_numbers = ?',
      whereArgs: [tableNumbersKey],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    
    final map = maps.first;
    
    // Parse order numbers - can be JSON string (Map) or integer (legacy)
    Map<String, int>? tableOrderNumbers;
    final orderNumberValue = map['order_number'];
    if (orderNumberValue != null) {
      if (orderNumberValue is String) {
        try {
          // Try to parse as JSON first
          final decoded = jsonDecode(orderNumberValue);
          if (decoded is Map) {
            tableOrderNumbers = Map<String, int>.from(
              decoded.map((key, value) => MapEntry(key.toString(), value as int)),
            );
          }
        } catch (e) {
          // If not JSON, might be legacy integer (but stored as string)
          // Ignore and leave as null
        }
      } else if (orderNumberValue is int) {
        // Legacy: single order number for all tables
        final tableNumbersList = (map['table_numbers'] as String).split(',');
        if (tableNumbersList.isNotEmpty) {
          tableOrderNumbers = {tableNumbersList.first: orderNumberValue};
        }
      }
    }
    
    return {
      'id': map['id'],
      'table_numbers': (map['table_numbers'] as String).split(','),
      'items': jsonDecode(map['items'] as String),
      'order_number': orderNumberValue, // Keep for backward compatibility
      'table_order_numbers': tableOrderNumbers,
      'discount_percentage': map['discount_percentage'] as double,
      'discount_amount': map['discount_amount'] as double,
      'service_charge': map['service_charge'] as double,
      'delivery_tax': map['delivery_tax'] as double,
      'hospitality_tax': map['hospitality_tax'] as double,
      'created_at': map['created_at'],
      'updated_at': map['updated_at'],
    };
  }

  /// Get all pending invoices
  Future<List<Map<String, dynamic>>> getAllPendingInvoices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pending_invoices',
      orderBy: 'updated_at DESC',
    );
    
    return maps.map((map) => {
      'id': map['id'],
      'table_numbers': (map['table_numbers'] as String).split(','),
      'items': jsonDecode(map['items'] as String),
      'order_number': map['order_number'],
      'discount_percentage': map['discount_percentage'] as double,
      'discount_amount': map['discount_amount'] as double,
      'service_charge': map['service_charge'] as double,
      'delivery_tax': map['delivery_tax'] as double,
      'hospitality_tax': map['hospitality_tax'] as double,
      'created_at': map['created_at'],
      'updated_at': map['updated_at'],
    }).toList();
  }

  /// Delete a pending invoice by table numbers
  Future<void> deletePendingInvoiceByTableNumbers(List<String> tableNumbers) async {
    final db = await database;
    final tableNumbersKey = tableNumbers.join(',');
    
    await db.delete(
      'pending_invoices',
      where: 'table_numbers = ?',
      whereArgs: [tableNumbersKey],
    );
  }

  /// Delete all pending invoices
  Future<void> deleteAllPendingInvoices() async {
    final db = await database;
    await db.delete('pending_invoices');
  }
}
