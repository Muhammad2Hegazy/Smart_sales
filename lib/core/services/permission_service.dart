import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user_permission.dart';
import '../repositories/user_management_repository.dart';

/// Permission Service
/// Handles permission checks for page access and features
class PermissionService {
  final DatabaseHelper _dbHelper;
  final UserManagementRepository _userManagementRepository;
  
  // Cache for current user permissions
  Map<String, bool>? _permissionsCache;
  String? _cachedUserId;

  PermissionService(this._dbHelper, this._userManagementRepository);

  /// Get current user ID from SharedPreferences
  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_user_id');
  }

  /// Load and cache user permissions
  Future<void> _loadPermissions() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      _permissionsCache = {};
      _cachedUserId = null;
      return;
    }

    // If cache is valid, return
    if (_cachedUserId == userId && _permissionsCache != null) {
      return;
    }

    // Load permissions from database
    final permissions = await _dbHelper.getUserPermissions(userId);
    _permissionsCache = {};
    for (final perm in permissions) {
      _permissionsCache![perm.permissionKey] = perm.allowed;
    }
    _cachedUserId = userId;
  }

  /// Clear permission cache (call after permission updates)
  void clearCache() {
    _permissionsCache = null;
    _cachedUserId = null;
  }

  /// Check if current user has a specific permission
  Future<bool> hasPermission(String permissionKey) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return false;

    // Check if user is admin (admins have all permissions)
    final isAdmin = await _userManagementRepository.isCurrentUserAdmin();
    if (isAdmin) return true;

    // Load permissions if not cached
    await _loadPermissions();

    // Check permission
    return _permissionsCache?[permissionKey] ?? false;
  }

  /// Check if current user can access a specific menu item/page
  /// menuItem: 'pos', 'inventory', 'items', 'reports', 'profitLoss', 'settings'
  Future<bool> canAccessPage(String menuItem) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return false;

    // Check if user is admin (admins have access to all pages)
    final isAdmin = await _userManagementRepository.isCurrentUserAdmin();
    if (isAdmin) return true;

    // Map MenuItem to permission key
    final permissionKey = _getPermissionKeyForMenuItem(menuItem);
    if (permissionKey == null) return true; // No permission required

    // Check permission
    return await hasPermission(permissionKey);
  }

  /// Get permission key for a menu item
  String? _getPermissionKeyForMenuItem(String menuItem) {
    switch (menuItem) {
      case 'pos':
        return PermissionKeys.accessPosScreen;
      case 'items':
        return PermissionKeys.accessItemsScreen;
      case 'inventory':
        return PermissionKeys.accessInventoryScreen;
      case 'reports':
        return PermissionKeys.accessReportsScreen;
      case 'profitLoss':
        return PermissionKeys.accessFinancialScreen;
      case 'settings':
        return PermissionKeys.accessSettingsScreen;
      default:
        return null;
    }
  }

  /// Get all accessible menu items for current user
  Future<List<String>> getAccessibleMenuItems() async {
    final allItems = ['pos', 'items', 'inventory', 'reports', 'profitLoss', 'settings'];
    final accessibleItems = <String>[];

    for (final item in allItems) {
      if (await canAccessPage(item)) {
        accessibleItems.add(item);
      }
    }

    return accessibleItems;
  }
}

/// Helper extension to add viewReports permission
extension PermissionKeysExtension on PermissionKeys {
  static const String viewReports = 'view_reports';
}

