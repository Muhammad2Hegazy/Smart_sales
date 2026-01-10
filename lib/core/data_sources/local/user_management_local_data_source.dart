import 'package:shared_preferences/shared_preferences.dart';

/// Local Data Source for User Management
/// Handles local caching of user profile information
class UserManagementLocalDataSource {
  static const String _keyCurrentUserRole = 'current_user_role';
  static const String _keyCurrentUserEmail = 'current_user_email';

  /// Save current user role to local storage
  Future<void> saveCurrentUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUserRole, role);
  }

  /// Get current user role from local storage
  Future<String?> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentUserRole);
  }

  /// Save current user email to local storage
  Future<void> saveCurrentUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUserEmail, email);
  }

  /// Get current user email from local storage
  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentUserEmail);
  }

  /// Clear local storage
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUserRole);
    await prefs.remove(_keyCurrentUserEmail);
  }
}

