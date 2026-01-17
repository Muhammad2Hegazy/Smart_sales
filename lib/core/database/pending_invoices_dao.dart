import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'base_dao.dart';
import 'devices_dao.dart';

/// Data Access Object for Pending Invoice (draft) operations
class PendingInvoicesDao extends BaseDao {
  final DevicesDao _devicesDao = DevicesDao();

  /// Save a pending invoice
  Future<void> savePendingInvoice({
    required List<String> tableNumbers,
    required List<Map<String, dynamic>> items,
    Map<String, int>? tableOrderNumbers,
    int? orderNumber,
    double discountPercentage = 0.0,
    double discountAmount = 0.0,
    double serviceCharge = 0.0,
    double deliveryTax = 0.0,
    double hospitalityTax = 0.0,
  }) async {
    final db = await database;
    final tableNumbersKey = tableNumbers.join(',');
    
    // Get master device ID
    final master = await _devicesDao.getMaster();
    final masterDeviceId = master?.masterDeviceId ?? '';
    
    final now = DateTime.now();
    
    // Prepare table order numbers
    final orderNumbersJson = tableOrderNumbers != null 
        ? jsonEncode(tableOrderNumbers)
        : (orderNumber != null ? jsonEncode({tableNumbers.first: orderNumber}) : null);
    
    await db.insert(
      'pending_invoices',
      {
        'id': const Uuid().v4(),
        'table_numbers': tableNumbersKey,
        'items': jsonEncode(items),
        'order_number': orderNumber,
        'table_order_numbers': orderNumbersJson,
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
          final decoded = jsonDecode(orderNumberValue);
          if (decoded is Map) {
            tableOrderNumbers = Map<String, int>.from(
              decoded.map((key, value) => MapEntry(key.toString(), value as int)),
            );
          }
        } catch (e) {
          // Ignore parse errors
        }
      } else if (orderNumberValue is int) {
        final tableNumbersList = (map['table_numbers'] as String).split(',');
        if (tableNumbersList.isNotEmpty) {
          tableOrderNumbers = {tableNumbersList.first: orderNumberValue};
        }
      }
    }
    
    // Also check table_order_numbers column
    final tableOrderNumbersValue = map['table_order_numbers'];
    if (tableOrderNumbersValue != null && tableOrderNumbersValue is String) {
      try {
        final decoded = jsonDecode(tableOrderNumbersValue);
        if (decoded is Map) {
          tableOrderNumbers = Map<String, int>.from(
            decoded.map((key, value) => MapEntry(key.toString(), value as int)),
          );
        }
      } catch (e) {
        // Ignore parse errors
      }
    }
    
    return {
      'id': map['id'],
      'tableNumbers': tableNumbers,
      'items': jsonDecode(map['items'] as String) as List<dynamic>,
      'tableOrderNumbers': tableOrderNumbers,
      'orderNumber': orderNumberValue is int ? orderNumberValue : null,
      'discountPercentage': (map['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      'discountAmount': (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      'serviceCharge': (map['service_charge'] as num?)?.toDouble() ?? 0.0,
      'deliveryTax': (map['delivery_tax'] as num?)?.toDouble() ?? 0.0,
      'hospitalityTax': (map['hospitality_tax'] as num?)?.toDouble() ?? 0.0,
      'createdAt': DateTime.parse(map['created_at'] as String),
    };
  }

  /// Get all pending invoices
  Future<List<Map<String, dynamic>>> getAllPendingInvoices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pending_invoices',
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) {
      return {
        'id': map['id'],
        'tableNumbers': (map['table_numbers'] as String).split(','),
        'items': jsonDecode(map['items'] as String) as List<dynamic>,
        'orderNumber': map['order_number'],
        'discountPercentage': (map['discount_percentage'] as num?)?.toDouble() ?? 0.0,
        'discountAmount': (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
        'serviceCharge': (map['service_charge'] as num?)?.toDouble() ?? 0.0,
        'deliveryTax': (map['delivery_tax'] as num?)?.toDouble() ?? 0.0,
        'hospitalityTax': (map['hospitality_tax'] as num?)?.toDouble() ?? 0.0,
        'createdAt': DateTime.parse(map['created_at'] as String),
      };
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
