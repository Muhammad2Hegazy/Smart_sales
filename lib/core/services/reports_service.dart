import '../database/database_helper.dart';
import '../models/sale.dart';
import '../models/shift_report.dart';
import '../models/inventory_movement.dart';
import 'package:uuid/uuid.dart';

/// Reports Service
/// Handles all report generation logic for the POS system
class ReportsService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  /// Calculate business day start (5:00 AM)
  DateTime _getBusinessDayStart(DateTime date) {
    if (date.hour < 5) {
      // Before 5 AM, use previous day starting from 5 AM
      final yesterday = date.subtract(const Duration(days: 1));
      return DateTime(yesterday.year, yesterday.month, yesterday.day, 5, 0, 0);
    } else {
      // After 5 AM, use current day starting from 5 AM
      return DateTime(date.year, date.month, date.day, 5, 0, 0);
    }
  }


  /// Generate and store shift close report
  Future<ShiftReport> generateShiftCloseReport({
    required DateTime shiftStart,
    required DateTime shiftEnd,
    int? floorId,
    String? deviceId,
  }) async {
    // Get sales for the shift period
    List<Sale> sales;
    if (floorId != null || deviceId != null) {
      // Get devices for the floor
      List<String> deviceIds = [];
      if (floorId != null) {
        final floorDevices = await _dbHelper.getDevicesByFloor(floorId);
        deviceIds = floorDevices.map((d) => d.deviceId).toList();
      } else if (deviceId != null) {
        deviceIds = [deviceId];
      }

      if (deviceIds.isNotEmpty) {
        sales = await _dbHelper.getSalesByDeviceIdsAndDateRange(
          deviceIds,
          shiftStart,
          shiftEnd,
        );
      } else {
        sales = await _dbHelper.getSalesByDateRange(shiftStart, shiftEnd);
      }
    } else {
      sales = await _dbHelper.getSalesByDateRange(shiftStart, shiftEnd);
    }

    // Calculate totals
    double totalSales = 0.0;
    double cashTotal = 0.0;
    double visaTotal = 0.0;
    int ordersCount = sales.length;
    double discounts = 0.0;
    double service = 0.0;
    double tax = 0.0;

    for (var sale in sales) {
      totalSales += sale.total;
      discounts += sale.discountAmount;
      service += sale.serviceCharge;
      tax += sale.deliveryTax + sale.hospitalityTax;

      if (sale.paymentMethod.toLowerCase() == 'cash') {
        cashTotal += sale.total;
      } else {
        visaTotal += sale.total;
      }
    }

    // Get master device ID
    final master = await _dbHelper.getMaster();
    final masterDeviceId = master?.masterDeviceId ?? '';
    final now = DateTime.now();

    // Create shift report
    final shiftId = '${shiftStart.toIso8601String()}_${floorId ?? 'all'}';
    final report = ShiftReport(
      id: _uuid.v4(),
      shiftId: shiftId,
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
      floorId: floorId,
      deviceId: deviceId,
      totalSales: totalSales,
      cashTotal: cashTotal,
      visaTotal: visaTotal,
      ordersCount: ordersCount,
      discounts: discounts,
      service: service,
      tax: tax,
      createdAt: now,
      masterDeviceId: masterDeviceId,
      syncStatus: 'pending',
      updatedAt: now,
    );

    // Store the report
    await _dbHelper.insertShiftReport(report);

    return report;
  }

  /// Get daily sales report data
  Future<Map<String, dynamic>> getDailySalesReport({
    required DateTime date,
    int? floorId,
    String? paymentMethod,
  }) async {
    // Business day starts at 5 AM
    final dayStart = _getBusinessDayStart(date);
    final dayEnd = dayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));

    // Get sales for the day
    List<Sale> sales;
    if (floorId != null) {
      final floorDevices = await _dbHelper.getDevicesByFloor(floorId);
      final deviceIds = floorDevices.map((d) => d.deviceId).toList();
      if (deviceIds.isNotEmpty) {
        sales = await _dbHelper.getSalesByDeviceIdsAndDateRange(
          deviceIds,
          dayStart,
          dayEnd,
        );
      } else {
        sales = [];
      }
    } else {
      sales = await _dbHelper.getSalesByDateRange(dayStart, dayEnd);
    }

    // Filter by payment method if specified
    if (paymentMethod != null) {
      sales = sales.where((s) => s.paymentMethod.toLowerCase() == paymentMethod.toLowerCase()).toList();
    }

    // Calculate totals
    double totalSales = 0.0;
    double discounts = 0.0;
    int ordersCount = sales.length;

    for (var sale in sales) {
      totalSales += sale.total;
      discounts += sale.discountAmount;
    }

    final netSales = totalSales - discounts;

    return {
      'date': date,
      'totalSales': totalSales,
      'netSales': netSales,
      'ordersCount': ordersCount,
      'discounts': discounts,
      'sales': sales,
    };
  }

  /// Get category sales report
  Future<List<Map<String, dynamic>>> getCategorySalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Get all sales in date range
    final sales = await _dbHelper.getSalesByDateRange(startDate, endDate);

    // Get all categories and items
    final categories = await _dbHelper.getAllCategories();
    final subCategories = await _dbHelper.getAllSubCategories();
    final items = await _dbHelper.getAllItems();

    // Group sales by category
    final Map<String, Map<String, dynamic>> categoryData = {};

    for (var sale in sales) {
      for (var saleItem in sale.items) {
        // Find item
        final item = items.firstWhere(
          (i) => i.id == saleItem.itemId,
          orElse: () => items.first,
        );

        // Find subcategory
        final subCategory = subCategories.firstWhere(
          (s) => s.id == item.subCategoryId,
          orElse: () => subCategories.first,
        );

        // Find category
        final category = categories.firstWhere(
          (c) => c.id == subCategory.categoryId,
          orElse: () => categories.first,
        );

        // Initialize category data if needed
        if (!categoryData.containsKey(category.id)) {
          categoryData[category.id] = {
            'category': category,
            'quantity': 0,
            'totalValue': 0.0,
            'percentage': 0.0,
          };
        }

        // Update category data
        categoryData[category.id]!['quantity'] =
            (categoryData[category.id]!['quantity'] as int) + saleItem.quantity;
        categoryData[category.id]!['totalValue'] =
            (categoryData[category.id]!['totalValue'] as double) + saleItem.total;
      }
    }

    // Calculate total sales for percentage calculation
    final totalSales = categoryData.values.fold<double>(
      0.0,
      (sum, data) => sum + (data['totalValue'] as double),
    );

    // Calculate percentages
    for (var data in categoryData.values) {
      if (totalSales > 0) {
        data['percentage'] = ((data['totalValue'] as double) / totalSales) * 100;
      }
    }

    return categoryData.values.toList();
  }

  /// Get item sales report
  Future<List<Map<String, dynamic>>> getItemSalesReport({
    required DateTime startDate,
    required DateTime endDate,
    int? floorId,
  }) async {
    // Get sales in date range
    List<Sale> sales;
    if (floorId != null) {
      final floorDevices = await _dbHelper.getDevicesByFloor(floorId);
      final deviceIds = floorDevices.map((d) => d.deviceId).toList();
      if (deviceIds.isNotEmpty) {
        sales = await _dbHelper.getSalesByDeviceIdsAndDateRange(
          deviceIds,
          startDate,
          endDate,
        );
      } else {
        sales = [];
      }
    } else {
      sales = await _dbHelper.getSalesByDateRange(startDate, endDate);
    }

    // Get all items
    final items = await _dbHelper.getAllItems();

    // Group sales by item
    final Map<String, Map<String, dynamic>> itemData = {};

    for (var sale in sales) {
      for (var saleItem in sale.items) {
        // Initialize item data if needed
        if (!itemData.containsKey(saleItem.itemId)) {
          final item = items.firstWhere(
            (i) => i.id == saleItem.itemId,
            orElse: () => items.first,
          );
          itemData[saleItem.itemId] = {
            'item': item,
            'quantity': 0,
            'totalSales': 0.0,
            'prices': <double>[],
          };
        }

        // Update item data
        itemData[saleItem.itemId]!['quantity'] =
            (itemData[saleItem.itemId]!['quantity'] as int) + saleItem.quantity;
        itemData[saleItem.itemId]!['totalSales'] =
            (itemData[saleItem.itemId]!['totalSales'] as double) + saleItem.total;
        (itemData[saleItem.itemId]!['prices'] as List<double>).add(saleItem.price);
      }
    }

    // Calculate average prices
    for (var data in itemData.values) {
      final prices = data['prices'] as List<double>;
      if (prices.isNotEmpty) {
        data['averagePrice'] = prices.reduce((a, b) => a + b) / prices.length;
      } else {
        data['averagePrice'] = 0.0;
      }
    }

    return itemData.values.toList();
  }

  /// Get inventory count (current stock per item)
  Future<List<Map<String, dynamic>>> getInventoryCount() async {
    final items = await _dbHelper.getAllItems();
    
    return items.map((item) {
      return {
        'item': item,
        'currentQuantity': item.stockQuantity,
        'unit': item.stockUnit,
        'availableQuantity': item.availableQuantity,
      };
    }).toList();
  }

  /// Get inventory by category
  Future<List<Map<String, dynamic>>> getInventoryByCategory() async {
    final items = await _dbHelper.getAllItems();
    final categories = await _dbHelper.getAllCategories();
    final subCategories = await _dbHelper.getAllSubCategories();

    // Group items by category
    final Map<String, Map<String, dynamic>> categoryData = {};

    for (var item in items) {
      // Find subcategory
      final subCategory = subCategories.firstWhere(
        (s) => s.id == item.subCategoryId,
        orElse: () => subCategories.first,
      );

      // Find category
      final category = categories.firstWhere(
        (c) => c.id == subCategory.categoryId,
        orElse: () => categories.first,
      );

      // Initialize category data if needed
      if (!categoryData.containsKey(category.id)) {
        categoryData[category.id] = {
          'category': category,
          'totalQuantity': 0.0,
          'totalValue': 0.0,
        };
      }

      // Update category data
      categoryData[category.id]!['totalQuantity'] =
          (categoryData[category.id]!['totalQuantity'] as double) + item.stockQuantity;
      categoryData[category.id]!['totalValue'] =
          (categoryData[category.id]!['totalValue'] as double) + (item.stockQuantity * item.price);
    }

    return categoryData.values.toList();
  }

  /// Get item movement report
  Future<List<InventoryMovement>> getItemMovementReport({
    required String itemId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _dbHelper.getInventoryMovementsByItemId(
      itemId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get inventory movement summary
  Future<Map<String, dynamic>> getInventoryMovementSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Get all movements in date range
    final purchases = await _dbHelper.getInventoryMovementsByType(
      'purchase',
      startDate: startDate,
      endDate: endDate,
    );
    final sales = await _dbHelper.getInventoryMovementsByType(
      'sale',
      startDate: startDate,
      endDate: endDate,
    );
    final returns = await _dbHelper.getInventoryMovementsByType(
      'return',
      startDate: startDate,
      endDate: endDate,
    );
    final adjustments = await _dbHelper.getInventoryMovementsByType(
      'adjustment',
      startDate: startDate,
      endDate: endDate,
    );

    double totalPurchases = purchases.fold<double>(
      0.0,
      (sum, m) => sum + (m.totalValue ?? 0.0),
    );
    double totalSales = sales.fold<double>(
      0.0,
      (sum, m) => sum + (m.totalValue ?? 0.0),
    );
    double totalReturns = returns.fold<double>(
      0.0,
      (sum, m) => sum + (m.totalValue ?? 0.0),
    );
    double totalAdjustments = adjustments.fold<double>(
      0.0,
      (sum, m) => sum + (m.totalValue ?? 0.0),
    );

    return {
      'purchases': {
        'count': purchases.length,
        'totalValue': totalPurchases,
      },
      'sales': {
        'count': sales.length,
        'totalValue': totalSales,
      },
      'returns': {
        'count': returns.length,
        'totalValue': totalReturns,
      },
      'adjustments': {
        'count': adjustments.length,
        'totalValue': totalAdjustments,
      },
    };
  }

  /// Get supplier purchases report
  Future<List<Map<String, dynamic>>> getSupplierPurchasesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final suppliers = await _dbHelper.getAllSuppliers();
    final List<Map<String, dynamic>> reportData = [];

    for (var supplier in suppliers) {
      final purchases = await _dbHelper.getPurchasesBySupplierId(
        supplier.id,
        startDate: startDate,
        endDate: endDate,
      );

      if (purchases.isNotEmpty) {
        double totalPurchases = 0.0;
        double totalPaid = 0.0;

        for (var purchase in purchases) {
          totalPurchases += purchase.totalAmount;
          totalPaid += purchase.paidAmount;
        }

        reportData.add({
          'supplier': supplier,
          'totalPurchases': totalPurchases,
          'totalPaid': totalPaid,
          'unpaid': totalPurchases - totalPaid,
          'purchasesCount': purchases.length,
        });
      }
    }

    return reportData;
  }

  /// Get total sales summary (aggregated across all floors/shifts)
  Future<Map<String, dynamic>> getTotalSalesSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Get all sales in date range
    final sales = await _dbHelper.getSalesByDateRange(startDate, endDate);

    // Calculate totals
    double totalSales = 0.0;
    double cashTotal = 0.0;
    double visaTotal = 0.0;
    int ordersCount = sales.length;
    double discounts = 0.0;
    double service = 0.0;
    double tax = 0.0;

    for (var sale in sales) {
      totalSales += sale.total;
      discounts += sale.discountAmount;
      service += sale.serviceCharge;
      tax += sale.deliveryTax + sale.hospitalityTax;

      if (sale.paymentMethod.toLowerCase() == 'cash') {
        cashTotal += sale.total;
      } else {
        visaTotal += sale.total;
      }
    }

    final netSales = totalSales - discounts;

    return {
      'startDate': startDate,
      'endDate': endDate,
      'totalSales': totalSales,
      'netSales': netSales,
      'cashTotal': cashTotal,
      'visaTotal': visaTotal,
      'ordersCount': ordersCount,
      'discounts': discounts,
      'service': service,
      'tax': tax,
    };
  }
}

