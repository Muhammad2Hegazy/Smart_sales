import '../entities/user_entity.dart';

abstract class IAuthRepository {
  Future<UserEntity> signUp({
    required String username,
    required String password,
    String? name,
  });

  Future<UserEntity> signIn({
    required String username,
    required String password,
  });

  Future<void> signOut();

  Future<UserEntity?> getCurrentUser();

  Future<bool> isAuthenticated();
}
