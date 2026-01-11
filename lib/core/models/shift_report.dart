/// Shift Report Model
/// Represents a shift closing report for a specific floor/device
class ShiftReport {
  final String id;
  final String shiftId; // Unique identifier for this shift
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final int? floorId; // Floor number (null if no floor)
  final String? deviceId; // Device that generated this report
  final double totalSales;
  final double cashTotal;
  final double visaTotal;
  final int ordersCount;
  final double discounts;
  final double service;
  final double tax;
  final DateTime createdAt;
  final String masterDeviceId;
  final String syncStatus;
  final DateTime updatedAt;

  const ShiftReport({
    required this.id,
    required this.shiftId,
    required this.shiftStart,
    required this.shiftEnd,
    this.floorId,
    this.deviceId,
    required this.totalSales,
    required this.cashTotal,
    required this.visaTotal,
    required this.ordersCount,
    required this.discounts,
    required this.service,
    required this.tax,
    required this.createdAt,
    required this.masterDeviceId,
    required this.syncStatus,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shift_id': shiftId,
      'shift_start': shiftStart.toIso8601String(),
      'shift_end': shiftEnd.toIso8601String(),
      'floor_id': floorId,
      'device_id': deviceId,
      'total_sales': totalSales,
      'cash_total': cashTotal,
      'visa_total': visaTotal,
      'orders_count': ordersCount,
      'discounts': discounts,
      'service': service,
      'tax': tax,
      'created_at': createdAt.toIso8601String(),
      'master_device_id': masterDeviceId,
      'sync_status': syncStatus,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ShiftReport.fromMap(Map<String, dynamic> map) {
    return ShiftReport(
      id: map['id'] as String,
      shiftId: map['shift_id'] as String,
      shiftStart: DateTime.parse(map['shift_start'] as String),
      shiftEnd: DateTime.parse(map['shift_end'] as String),
      floorId: map['floor_id'] as int?,
      deviceId: map['device_id'] as String?,
      totalSales: (map['total_sales'] as num).toDouble(),
      cashTotal: (map['cash_total'] as num).toDouble(),
      visaTotal: (map['visa_total'] as num).toDouble(),
      ordersCount: map['orders_count'] as int,
      discounts: (map['discounts'] as num).toDouble(),
      service: (map['service'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      masterDeviceId: map['master_device_id'] as String,
      syncStatus: map['sync_status'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ShiftReport copyWith({
    String? id,
    String? shiftId,
    DateTime? shiftStart,
    DateTime? shiftEnd,
    int? floorId,
    String? deviceId,
    double? totalSales,
    double? cashTotal,
    double? visaTotal,
    int? ordersCount,
    double? discounts,
    double? service,
    double? tax,
    DateTime? createdAt,
    String? masterDeviceId,
    String? syncStatus,
    DateTime? updatedAt,
  }) {
    return ShiftReport(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      shiftStart: shiftStart ?? this.shiftStart,
      shiftEnd: shiftEnd ?? this.shiftEnd,
      floorId: floorId ?? this.floorId,
      deviceId: deviceId ?? this.deviceId,
      totalSales: totalSales ?? this.totalSales,
      cashTotal: cashTotal ?? this.cashTotal,
      visaTotal: visaTotal ?? this.visaTotal,
      ordersCount: ordersCount ?? this.ordersCount,
      discounts: discounts ?? this.discounts,
      service: service ?? this.service,
      tax: tax ?? this.tax,
      createdAt: createdAt ?? this.createdAt,
      masterDeviceId: masterDeviceId ?? this.masterDeviceId,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

