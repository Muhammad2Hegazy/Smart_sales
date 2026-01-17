import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'base_dao.dart';
import '../models/user_profile.dart';
import '../models/user_permission.dart';

/// Data Access Object for User Profile and Permission operations
class UsersDao extends BaseDao {
  // ============ User Profiles ============

  /// Insert a user profile with password
  Future<void> insertUserProfile(
    UserProfile profile,
    String passwordHash,
  ) async {
    final db = await database;
    await db.insert(
      'user_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert('passwords', {
      'user_id': profile.userId,
      'password_hash': passwordHash,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  /// Get user profile by username
  Future<UserProfile?> getUserProfileByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  /// Get user password hash
  Future<String?> getUserPasswordHash(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'passwords',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['password_hash'] as String?;
  }

  /// Update user password
  Future<void> updateUserPassword(String userId, String newPasswordHash) async {
    final db = await database;

    // Check if password entry exists
    final existing = await db.query(
      'passwords',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (existing.isEmpty) {
      await db.insert('passwords', {
        'user_id': userId,
        'password_hash': newPasswordHash,
      });
    } else {
      await db.update(
        'passwords',
        {'password_hash': newPasswordHash},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  /// Get all user profiles
  Future<List<UserProfile>> getAllUserProfiles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_profiles');
    return maps.map((map) => UserProfile.fromMap(map)).toList();
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String role) async {
    final db = await database;
    await db.update(
      'user_profiles',
      {'role': role},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Check if admin exists
  Future<bool> adminExists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      where: 'role = ?',
      whereArgs: ['admin'],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  // ============ User Permissions ============

  /// Insert a user permission
  Future<void> insertUserPermission(UserPermission permission) async {
    final db = await database;
    await db.insert(
      'user_permissions',
      permission.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get user permissions by user ID
  Future<List<UserPermission>> getUserPermissions(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_permissions',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => UserPermission.fromMap(map)).toList();
  }

  /// Get all user permissions
  Future<List<UserPermission>> getAllUserPermissions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_permissions');
    return maps.map((map) => UserPermission.fromMap(map)).toList();
  }

  /// Update user permission
  Future<void> updateUserPermission(
    String userId,
    String permissionKey,
    bool allowed,
  ) async {
    final db = await database;

    // Check if permission exists
    final existing = await db.query(
      'user_permissions',
      where: 'user_id = ? AND permission_key = ?',
      whereArgs: [userId, permissionKey],
    );

    if (existing.isEmpty) {
      await db.insert('user_permissions', {
        'id': const Uuid().v4(),
        'user_id': userId,
        'permission_key': permissionKey,
        'allowed': allowed ? 1 : 0,
      });
    } else {
      await db.update(
        'user_permissions',
        {'allowed': allowed ? 1 : 0},
        where: 'user_id = ? AND permission_key = ?',
        whereArgs: [userId, permissionKey],
      );
    }
  }

  /// Check if user has a specific permission
  Future<bool> hasPermission(String userId, String permissionKey) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_permissions',
      where: 'user_id = ? AND permission_key = ?',
      whereArgs: [userId, permissionKey],
      limit: 1,
    );
    if (maps.isEmpty) return false;
    return (maps.first['allowed'] as int) == 1;
  }

  /// Create default admin user
  Future<void> createDefaultAdminUser(Database db) async {
    try {
      // Check if admin already exists
      final existing = await db.query(
        'user_profiles',
        where: 'username = ?',
        whereArgs: ['admin'],
      );

      if (existing.isEmpty) {
        final adminId = const Uuid().v4();
        final now = DateTime.now();

        await db.insert('user_profiles', {
          'id': adminId,
          'username': 'admin',
          'role': 'admin',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });

        // Hash the default password
        final passwordBytes = utf8.encode('mohamed2003');
        final passwordHash = sha256.convert(passwordBytes).toString();

        await db.insert('passwords', {
          'user_id': adminId,
          'password_hash': passwordHash,
        });

        debugPrint('Default admin user created successfully');
      }
    } catch (e) {
      debugPrint('Error creating default admin user: $e');
    }
  }
}
