import '../../models/user_profile.dart';
import '../../models/user_permission.dart';

class UserManagementRemoteDataSource {
  UserManagementRemoteDataSource();

  Future<List<UserProfile>> getAllUserProfiles() async {
    return [];
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    return null;
  }

  Future<void> createUserProfile(UserProfile profile) async {
    throw UnimplementedError('Not used - SQLite only');
  }

  Future<void> updateUserRole(String userId, String role) async {
    throw UnimplementedError('Not used - SQLite only');
  }

  Future<void> updateUserEmail(String userId, String email) async {
    throw UnimplementedError('Not used - SQLite only');
  }

  Future<void> promoteToAdmin(String userId) async {
    throw UnimplementedError('Not used - SQLite only');
  }

  Future<List<UserPermission>> getUserPermissions(String userId) async {
    return [];
  }

  Future<Map<String, List<UserPermission>>> getAllUserPermissions() async {
    return {};
  }

  Future<void> updateUserPermission(
    String userId,
    String permissionKey,
    bool allowed,
  ) async {
    throw UnimplementedError('Not used - SQLite only');
  }

  Future<bool> isUserAdmin(String userId) async {
    return false;
  }
}
