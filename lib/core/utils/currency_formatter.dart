import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  // Use 'en_US' locale to ensure English/Western numerals are always used
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
    locale: 'en_US', // Force English numerals
  );

  static String format(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatWithoutSymbol(double amount) {
    // Use 'en_US' locale to ensure English numerals
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  static String formatCompact(double amount) {
    return NumberFormat.compactCurrency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 0,
      locale: 'en_US', // Force English numerals
    ).format(amount);
  }
  
  /// Format number as plain text with English numerals (no currency symbol)
  static String formatNumber(double amount, {int decimalDigits = 2}) {
    return NumberFormat('#,##0.${'0' * decimalDigits}', 'en_US').format(amount);
  }
  
  /// Format integer as string with English numerals
  static String formatInt(int value) {
    return NumberFormat('#,##0', 'en_US').format(value);
  }
  
  /// Format double with specific decimal places using English numerals
  static String formatDouble(double value, int decimalPlaces) {
    return NumberFormat('#,##0.${'0' * decimalPlaces}', 'en_US').format(value);
  }
  
  /// Convert any number to string with English numerals (ensures no Arabic-Indic numerals)
  static String numberToString(num value) {
    if (value is int) {
      return formatInt(value);
    } else if (value is double) {
      // Check if it's a whole number
      if (value == value.truncateToDouble()) {
        return formatInt(value.toInt());
      }
      return formatDouble(value, 2);
    }
    return value.toString(); // Fallback
  }
}

