part of 'database_helper.dart';

extension DatabaseHelperHelpers on DatabaseHelper {
  /// Format stock quantity for smart display
  /// Returns formatted string with the most meaningful unit
  Future<Map<String, String>> formatStockForDisplay(String rawMaterialId) async {
    final material = await getRawMaterialById(rawMaterialId);
    if (material == null) {
      throw Exception('Raw material not found: $rawMaterialId');
    }

    final totalQuantity = material.totalQuantity;
    debugPrint('formatStockForDisplay: ${material.name}, baseUnit: ${material.baseUnit}, totalQuantity: $totalQuantity');
    String quantityDisplay;
    String unitDisplay;

    if (material.baseUnit == 'gram') {
      // Weight-based: show kg if >= 1000g, otherwise grams
      if (totalQuantity >= 1000) {
        final kilos = totalQuantity / 1000.0;
        final remainingGrams = (totalQuantity % 1000).round();
        if (remainingGrams > 0) {
          quantityDisplay = '${kilos.toStringAsFixed(0)} كيلو\n$remainingGrams جرام';
        } else {
          quantityDisplay = '${kilos.toStringAsFixed(2)} كيلو';
        }
        unitDisplay = 'كيلو / جرام';
      } else {
        quantityDisplay = totalQuantity.toStringAsFixed(2);
        unitDisplay = 'جرام';
      }
    } else if (material.baseUnit == 'ml') {
      // Volume-based: show liters if >= 1000ml, otherwise ml
      if (totalQuantity >= 1000) {
        final liters = totalQuantity / 1000.0;
        final remainingMl = (totalQuantity % 1000).round();
        if (remainingMl > 0) {
          quantityDisplay = '${liters.toStringAsFixed(0)} لتر\n$remainingMl مل';
        } else {
          quantityDisplay = '${liters.toStringAsFixed(2)} لتر';
        }
        unitDisplay = 'لتر / مل';
      } else {
        quantityDisplay = totalQuantity.toStringAsFixed(2);
        unitDisplay = 'مل';
      }
    } else if (material.baseUnit == 'carton') {
      // Carton-based: show cartons + remaining bottles
      unitDisplay = 'كرتونة / زجاجة';
      
      if (totalQuantity <= 0) {
        // Out of stock - still show correct unit
        quantityDisplay = '0';
      } else {
        final units = await getRawMaterialUnits(rawMaterialId);
        final bottleUnit = units.firstWhere(
          (u) => u.unit == 'bottle' || u.unit == 'زجاجة',
          orElse: () => RawMaterialUnit(
            id: '',
            rawMaterialId: rawMaterialId,
            unit: 'bottle',
            conversionFactorToBase: 1.0 / 20.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final bottlesPerCarton = (1.0 / bottleUnit.conversionFactorToBase).round();
        final totalBottles = (totalQuantity * bottlesPerCarton).round();
        final cartons = (totalBottles / bottlesPerCarton).floor();
        final remainingBottles = totalBottles % bottlesPerCarton;

        if (cartons > 0 && remainingBottles > 0) {
          quantityDisplay = '$cartons كرتونة ($bottlesPerCarton)\n+ $remainingBottles زجاجة';
        } else if (cartons > 0) {
          quantityDisplay = '$cartons كرتونة ($bottlesPerCarton)';
        } else if (totalBottles > 0) {
          quantityDisplay = '$totalBottles زجاجة';
        } else {
          quantityDisplay = '0';
        }
      }
    } else if (material.baseUnit == 'packet') {
      // Packet-based: totalQuantity is in packets (base unit)
      // 1 packet = 10kg = 10000g
      final totalPackets = totalQuantity;
      final wholePackets = totalPackets.floor();
      final fractionalPackets = totalPackets - wholePackets;
      final remainingKg = fractionalPackets * 10.0; // 1 packet = 10kg

      if (wholePackets > 0 && remainingKg > 0.01) {
        quantityDisplay = '$wholePackets باكيت\n+ ${remainingKg.toStringAsFixed(2)} كيلو';
      } else if (wholePackets > 0) {
        quantityDisplay = '$wholePackets باكيت';
      } else if (remainingKg > 0.01) {
        quantityDisplay = '${remainingKg.toStringAsFixed(2)} كيلو';
      } else {
        quantityDisplay = '0';
      }
      unitDisplay = 'باكيت / كيلو';
    } else if (material.baseUnit == 'jar') {
      // Jar-based: show strictly as jars
      quantityDisplay = totalQuantity.toStringAsFixed(0);
      unitDisplay = 'جرة';
    } else if (material.baseUnit == 'piece') {
      // Piece-based
      quantityDisplay = totalQuantity.toStringAsFixed(0);
      unitDisplay = 'قطعة';
    } else {
      // Default
      quantityDisplay = totalQuantity.toStringAsFixed(2);
      unitDisplay = material.baseUnit;
    }

    return {
      'quantity': quantityDisplay,
      'unit': unitDisplay,
    };
  }
}
