class LowStockWarning {
  final String rawMaterialId;
  final String rawMaterialName;
  final double currentQuantity;
  final double requiredQuantity;
  final String unit;
  final double percentageRemaining; // 0-100

  const LowStockWarning({
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.currentQuantity,
    required this.requiredQuantity,
    required this.unit,
    required this.percentageRemaining,
  });

  String get message {
    if (currentQuantity <= 0) {
      return 'المخزون نفد: $rawMaterialName';
    } else if (percentageRemaining < 10) {
      return 'تحذير: المخزون منخفض جداً ($rawMaterialName - ${currentQuantity.toStringAsFixed(2)} $unit)';
    } else if (percentageRemaining < 25) {
      return 'تحذير: المخزون قارب على النفاد ($rawMaterialName - ${currentQuantity.toStringAsFixed(2)} $unit)';
    } else {
      return 'تنبيه: المخزون منخفض ($rawMaterialName - ${currentQuantity.toStringAsFixed(2)} $unit)';
    }
  }

  bool get isCritical => currentQuantity <= 0 || percentageRemaining < 10;
  bool get isWarning => percentageRemaining < 25;
}

