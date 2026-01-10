class AppConstants {
  // Currency
  static const String currency = 'EGP';
  static const String currencySymbol = 'ج.م';
  
  // App Info
  static const String appName = 'Smart Sales POS';
  static const String appVersion = '1.0.0';
  
  // Default Values
  static const int lowStockThreshold = 30;
  static const double defaultTaxRate = 0.14; // 14% VAT in Egypt
  
  // Locale
  static const String defaultLocale = 'ar';
  static const String arabicLocale = 'ar';
  static const String englishLocale = 'en';
  
  // Shared Preferences Keys
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyUsername = 'username';
  static const String keyLanguage = 'language';
  static const String keyTheme = 'theme';
  static const String keyCurrency = 'currency';
  
  // Private constructor to prevent instantiation
  AppConstants._();
}

