import '../../core/base/base_entity.dart';

class UserEntity extends BaseEntity {
  final String id;
  final String username;
  final String email;
  final String? name;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.name,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [id, username, email, name, role, createdAt, updatedAt];
}
