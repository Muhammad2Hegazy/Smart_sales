import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:async';
import '../../../data/models/user_model.dart';
import '../../models/user_profile.dart';
import '../../models/device.dart';
import '../../models/master.dart';
import '../../database/database_helper.dart';
import '../../utils/mac_address_helper.dart';

class AuthLocalDataSource {
  static const String _keyCurrentUserId = 'auth_user_id';
  static const String _keyCurrentUsername = 'auth_username';
  static const String _keyCurrentUserRole = 'auth_user_role';
  static const String _keyIsLoggedIn = 'auth_is_logged_in';

  // Developer MAC address - always allowed
  static const String _developerMacAddress = 'E0:0A:F6:C3:BA:FF';

  final DatabaseHelper _dbHelper;

  AuthLocalDataSource(this._dbHelper);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserModel> signUp({
    required String username,
    required String password,
    String? name,
  }) async {
    final existingProfile = await _dbHelper.getUserProfileByUsername(username);
    if (existingProfile != null) {
      throw Exception('Username already exists');
    }

    final adminExists = await _dbHelper.adminExists();
    final role = adminExists ? 'user' : 'admin';

    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final hashedPassword = _hashPassword(password);

    final profile = UserProfile(
      userId: userId,
      username: username,
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _dbHelper.insertUserProfile(profile, hashedPassword);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUserId, userId);
    await prefs.setString(_keyCurrentUsername, username);
    await prefs.setString(_keyCurrentUserRole, role);
    await prefs.setBool(_keyIsLoggedIn, true);

    return UserModel(
      id: userId,
      username: username,
      email: UsernameEmailConverter.usernameToEmail(username),
      name: name,
      role: role,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  Future<UserModel> signIn({
    required String username,
    required String password,
  }) async {
    final profile = await _dbHelper.getUserProfileByUsername(username);
    if (profile == null) {
      throw Exception('Invalid username or password');
    }

    final storedPasswordHash = await _dbHelper.getUserPasswordHash(profile.userId);
    if (storedPasswordHash == null) {
      throw Exception('Invalid username or password');
    }

    final hashedPassword = _hashPassword(password);
    if (hashedPassword != storedPasswordHash) {
      throw Exception('Invalid username or password');
    }

    // Check MAC address - allow login only if device MAC address is registered
    // Developer MAC address is always allowed
    // STRICT: No fallbacks - MAC must be detected and must be developer MAC or registered device
    final currentMacAddress = await MacAddressHelper.getMacAddress();
    debugPrint('Detected MAC address: $currentMacAddress');

    // If MAC address detection failed, deny login
    if (currentMacAddress == null || currentMacAddress.isEmpty) {
      debugPrint('MAC address detection failed - denying login');
      throw Exception('Device not authorized. MAC address could not be detected. Please contact administrator.');
    }

    // Normalize MAC addresses for comparison (uppercase, standardize separators)
    final normalizedDetectedMac = currentMacAddress.toUpperCase()
        .replaceAll(RegExp(r'[\s\-]'), ':')
        .replaceAll(RegExp(r':+'), ':');

    final normalizedDeveloperMac = _developerMacAddress.toUpperCase()
        .replaceAll(RegExp(r'[\s\-]'), ':')
        .replaceAll(RegExp(r':+'), ':');

    debugPrint('Normalized detected MAC: $normalizedDetectedMac');
    debugPrint('Normalized developer MAC: $normalizedDeveloperMac');

    // Check if it's the developer's MAC address
    bool isDeveloperMac = false;
    if (normalizedDetectedMac == normalizedDeveloperMac) {
      isDeveloperMac = true;
      debugPrint('Developer MAC detected, registering device...');
      await _ensureDeveloperDeviceRegistered(profile.userId);
    }

    if (!isDeveloperMac) {
      // Not developer MAC - check if MAC address is registered in devices
      // Try both original format and normalized format
      Device? device = await _dbHelper.getDeviceByMacAddress(currentMacAddress);
      if (device == null && normalizedDetectedMac != currentMacAddress.toUpperCase()) {
        device = await _dbHelper.getDeviceByMacAddress(normalizedDetectedMac);
      }

      if (device == null) {
        debugPrint('Device not found in database. MAC: $currentMacAddress');
        throw Exception('Device not authorized. Please contact administrator to register this device.');
      }
      debugPrint('Device found in database: ${device.deviceName}');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUserId, profile.userId);
    await prefs.setString(_keyCurrentUsername, profile.username);
    await prefs.setString(_keyCurrentUserRole, profile.role);
    await prefs.setBool(_keyIsLoggedIn, true);

    return UserModel(
      id: profile.userId,
      username: profile.username,
      email: UsernameEmailConverter.usernameToEmail(profile.username),
      name: null,
      role: profile.role,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  /// Ensure developer device is always registered
  Future<void> _ensureDeveloperDeviceRegistered(String userId) async {
    try {
      // Check if developer device already exists
      final existingDevice = await _dbHelper.getDeviceByMacAddress(_developerMacAddress);
      if (existingDevice != null) {
        return; // Already registered
      }

      // Get or create master
      final master = await _dbHelper.getMaster();
      String masterDeviceId;

      if (master == null) {
        // Create master if it doesn't exist
        masterDeviceId = DateTime.now().millisecondsSinceEpoch.toString();
        final newMaster = Master(
          masterDeviceId: masterDeviceId,
          masterName: 'Master Device',
          userId: userId,
          createdAt: DateTime.now(),
        );
        await _dbHelper.insertMaster(newMaster);
      } else {
        masterDeviceId = master.masterDeviceId;
      }

      // Register developer device
      final device = Device(
        deviceId: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceName: 'DEV',
        masterDeviceId: masterDeviceId,
        isMaster: false,
        lastSeenAt: DateTime.now(),
        macAddress: _developerMacAddress,
      );
      await _dbHelper.insertDevice(device);
    } catch (e) {
      debugPrint('Error ensuring developer device registered: $e');
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUserId);
    await prefs.remove(_keyCurrentUsername);
    await prefs.remove(_keyCurrentUserRole);
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      debugPrint('Getting current user from SharedPreferences...');
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance().timeout(
          const Duration(milliseconds: 200),
          onTimeout: () {
            debugPrint('SharedPreferences timeout');
            throw TimeoutException('SharedPreferences timeout');
          },
        );
      } catch (e) {
        debugPrint('SharedPreferences error: $e - returning null');
        return null;
      }

      debugPrint('SharedPreferences obtained');
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      if (!isLoggedIn) {
        debugPrint('User not logged in');
        return null;
      }

      final userId = prefs.getString(_keyCurrentUserId);
      final username = prefs.getString(_keyCurrentUsername);
      final role = prefs.getString(_keyCurrentUserRole) ?? 'user';

      if (userId == null || username == null) {
        debugPrint('User ID or username is null');
        return null;
      }

      debugPrint('User found: $username');
      return UserModel(
        id: userId,
        username: username,
        email: UsernameEmailConverter.usernameToEmail(username),
        name: null,
        role: role,
      );
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyCurrentUserId);
    if (userId == null) return null;

    return await _dbHelper.getUserProfile(userId);
  }

  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null;
  }
}
