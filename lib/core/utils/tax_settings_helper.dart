import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class TaxSettingsHelper {
  static const String _keyVatRate = 'vat_rate';
  static const String _keyServiceChargeRate = 'service_charge_rate';
  static const String _keyDeliveryTaxRate = 'delivery_tax_rate';
  static const String _keyHospitalityTaxRate = 'hospitality_tax_rate';

  /// Load VAT rate from SharedPreferences
  static Future<double> loadVatRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_keyVatRate) ?? AppConstants.defaultTaxRate;
    } catch (e) {
      debugPrint('Error loading VAT rate: $e');
      return AppConstants.defaultTaxRate;
    }
  }

  /// Save VAT rate to SharedPreferences
  static Future<bool> saveVatRate(double rate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setDouble(_keyVatRate, rate);
    } catch (e) {
      debugPrint('Error saving VAT rate: $e');
      return false;
    }
  }

  /// Load service charge rate from SharedPreferences
  static Future<double> loadServiceChargeRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_keyServiceChargeRate) ?? 0.10; // Default 10%
    } catch (e) {
      debugPrint('Error loading service charge rate: $e');
      return 0.10;
    }
  }

  /// Save service charge rate to SharedPreferences
  static Future<bool> saveServiceChargeRate(double rate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setDouble(_keyServiceChargeRate, rate);
    } catch (e) {
      debugPrint('Error saving service charge rate: $e');
      return false;
    }
  }

  /// Load delivery tax rate from SharedPreferences
  static Future<double> loadDeliveryTaxRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_keyDeliveryTaxRate) ?? 0.05; // Default 5%
    } catch (e) {
      debugPrint('Error loading delivery tax rate: $e');
      return 0.05;
    }
  }

  /// Save delivery tax rate to SharedPreferences
  static Future<bool> saveDeliveryTaxRate(double rate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setDouble(_keyDeliveryTaxRate, rate);
    } catch (e) {
      debugPrint('Error saving delivery tax rate: $e');
      return false;
    }
  }

  /// Load hospitality tax rate from SharedPreferences
  static Future<double> loadHospitalityTaxRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_keyHospitalityTaxRate) ?? 0.05; // Default 5%
    } catch (e) {
      debugPrint('Error loading hospitality tax rate: $e');
      return 0.05;
    }
  }

  /// Save hospitality tax rate to SharedPreferences
  static Future<bool> saveHospitalityTaxRate(double rate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setDouble(_keyHospitalityTaxRate, rate);
    } catch (e) {
      debugPrint('Error saving hospitality tax rate: $e');
      return false;
    }
  }
}

