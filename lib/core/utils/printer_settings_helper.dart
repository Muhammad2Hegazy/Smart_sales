import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/printer_settings.dart';

class PrinterSettingsHelper {
  static const String _keyPrinterSettings = 'printer_settings';

  /// Load printer settings from SharedPreferences
  static Future<PrinterSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_keyPrinterSettings);
      
      if (settingsJson != null) {
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        return PrinterSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error loading printer settings: $e');
    }
    
    // Return default settings if loading fails
    return PrinterSettings.defaultSettings();
  }

  /// Save printer settings to SharedPreferences
  static Future<bool> saveSettings(PrinterSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      return await prefs.setString(_keyPrinterSettings, settingsJson);
    } catch (e) {
      debugPrint('Error saving printer settings: $e');
      return false;
    }
  }

  /// Check if printer settings are configured
  static Future<bool> hasSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyPrinterSettings);
    } catch (e) {
      return false;
    }
  }
}

