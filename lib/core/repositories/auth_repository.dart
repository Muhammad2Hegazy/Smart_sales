import '../data_sources/local/auth_local_data_source.dart';
import '../models/user.dart';

/// Auth Repository
/// Implements repository pattern for authentication
/// Handles local authentication only (no Supabase Auth)
class AuthRepository {
  final AuthLocalDataSource _localDataSource;

  AuthRepository(this._localDataSource);

  /// Sign up with username and password (local only)
  Future<AppUser> signUp({
    required String username,
    required String password,
    String? name,
  }) async {
    // Sign up locally
    return await _localDataSource.signUp(
      username: username,
      password: password,
      name: name,
    );
  }

  /// Sign in with username and password (local only)
  Future<AppUser> signIn({
    required String username,
    required String password,
  }) async {
    // Sign in locally
    return await _localDataSource.signIn(
      username: username,
      password: password,
    );
  }

  /// Sign out (local only)
  Future<void> signOut() async {
    await _localDataSource.signOut();
  }

  /// Get current user (local only)
  Future<AppUser?> getCurrentUser() async {
    return await _localDataSource.getCurrentUser();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _localDataSource.isAuthenticated();
  }
}
