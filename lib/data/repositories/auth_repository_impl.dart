import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/data_sources/local/auth_local_data_source.dart';

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

    return user;
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

    return user;
  }

  @override
  Future<void> signOut() async {
    await _localDataSource.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = await _localDataSource.getCurrentUser();
    return user;
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _localDataSource.isAuthenticated();
  }
}
