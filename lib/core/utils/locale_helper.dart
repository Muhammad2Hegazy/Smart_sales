import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class LocaleHelper {
  static Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyLanguage) ?? 
        AppConstants.defaultLocale;
  }

  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLanguage, languageCode);
  }

  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return 'Arabic';
      case 'en':
        return 'English';
      default:
        return 'English';
    }
  }

  static String getLanguageCode(String languageName) {
    switch (languageName) {
      case 'Arabic':
        return 'ar';
      case 'English':
        return 'en';
      default:
        return 'ar';
    }
  }
}

