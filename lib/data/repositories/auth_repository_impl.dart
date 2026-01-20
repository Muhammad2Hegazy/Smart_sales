import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/data_sources/local/auth_local_data_source.dart';
import '../../core/models/user_profile.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._localDataSource);

  @override
  Future<UserEntity> signUp({
    required String username,
    required String password,
    String? name,
  }) async {
    final user = await _localDataSource.signUp(
      username: username,
      password: password,
      name: name,
    );

    final profile = await _localDataSource.getCurrentUserProfile();

    return UserEntity(
      id: user.id,
      username: username,
      email: user.email,
      name: user.name,
      role: profile?.role ?? 'user',
      createdAt: profile?.createdAt,
      updatedAt: profile?.updatedAt,
    );
  }

  @override
  Future<UserEntity> signIn({
    required String username,
    required String password,
  }) async {
    final user = await _localDataSource.signIn(
      username: username,
      password: password,
    );

    final profile = await _localDataSource.getCurrentUserProfile();

    return UserEntity(
      id: user.id,
      username: username,
      email: user.email,
      name: user.name,
      role: profile?.role ?? 'user',
      createdAt: profile?.createdAt,
      updatedAt: profile?.updatedAt,
    );
  }

  @override
  Future<void> signOut() async {
    await _localDataSource.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = await _localDataSource.getCurrentUser();
    if (user == null) return null;

    final profile = await _localDataSource.getCurrentUserProfile();
    final username = UsernameEmailConverter.emailToUsername(user.email) ?? '';

    return UserEntity(
      id: user.id,
      username: username,
      email: user.email,
      name: user.name,
      role: profile?.role ?? 'user',
      createdAt: profile?.createdAt,
      updatedAt: profile?.updatedAt,
    );
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _localDataSource.isAuthenticated();
  }
}
