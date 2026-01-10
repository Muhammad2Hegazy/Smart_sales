import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../data_sources/local/user_management_local_data_source.dart';
import '../models/user_profile.dart';
import '../models/user_permission.dart';
import '../database/database_helper.dart';

/// User Management Repository
/// Implements repository pattern for user management operations (local only)
class UserManagementRepository {
  final UserManagementLocalDataSource _localDataSource;
  final DatabaseHelper _dbHelper;

  UserManagementRepository(
    this._localDataSource,
    this._dbHelper,
  );

  /// Get all user profiles (admin only)
  Future<List<UserProfile>> getAllUserProfiles() async {
    return await _dbHelper.getAllUserProfiles();
  }

  /// Get user profile by user ID
  Future<UserProfile?> getUserProfile(String userId) async {
    final profiles = await _dbHelper.getAllUserProfiles();
    try {
      return profiles.firstWhere((p) => p.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    // Get current user ID from local storage
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('auth_user_id');
    if (currentUserId == null) return null;

    // Get from local database
    final profile = await getUserProfile(currentUserId);

    // Cache role locally
    if (profile != null) {
      await _localDataSource.saveCurrentUserRole(profile.role);
      await _localDataSource.saveCurrentUserEmail(profile.username);
    }

    return profile;
  }

  /// Update user role (admin only)
  Future<void> updateUserRole(String userId, String role) async {
    await _dbHelper.updateUserRole(userId, role);
  }

  /// Promote user to admin (admin only)
  Future<void> promoteToAdmin(String userId) async {
    await _dbHelper.updateUserRole(userId, 'admin');
  }

  /// Get all permissions for a user
  Future<List<UserPermission>> getUserPermissions(String userId) async {
    return await _dbHelper.getUserPermissions(userId);
  }

  /// Get all permissions for all users (admin only)
  Future<Map<String, List<UserPermission>>> getAllUserPermissions() async {
    final permissions = await _dbHelper.getAllUserPermissions();
    final Map<String, List<UserPermission>> grouped = {};
    for (final perm in permissions) {
      grouped.putIfAbsent(perm.userId, () => []).add(perm);
    }
    return grouped;
  }

  /// Update user permission (admin only)
  Future<void> updateUserPermission(
    String userId,
    String permissionKey,
    bool allowed,
  ) async {
    await _dbHelper.updateUserPermission(userId, permissionKey, allowed);
  }

  /// Check if user has a specific permission
  Future<bool> hasPermission(String userId, String permissionKey) async {
    return await _dbHelper.hasPermission(userId, permissionKey);
  }

  /// Create a new user with specified role (admin only)
  Future<String> createUser({
    required String username,
    required String password,
    required String role,
    String? name,
  }) async {
    // Check if username already exists
    final existingProfile = await _dbHelper.getUserProfileByUsername(username);
    if (existingProfile != null) {
      throw Exception('Username already exists');
    }

    // Generate user ID
    final userId = DateTime.now().millisecondsSinceEpoch.toString();

    // Hash password
    final passwordBytes = utf8.encode(password);
    final passwordHash = sha256.convert(passwordBytes).toString();

    // Create user profile
    final profile = UserProfile(
      userId: userId,
      username: username,
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save user profile and password to local database
    await _dbHelper.insertUserProfile(profile, passwordHash);

    return userId;
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    // Get current user ID from local storage
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('auth_user_id');
    if (currentUserId == null) return false;

    // Get profile from local database
    final profile = await getUserProfile(currentUserId);
    return profile?.isAdmin ?? false;
  }
}

