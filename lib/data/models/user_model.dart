import '../../core/base/base_model.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity implements BaseModel {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    super.name,
    required super.role,
    super.createdAt,
    super.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      return DateTime.tryParse(value.toString());
    }

    return UserModel(
      id: (map['id'] ?? map['user_id'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      name: map['name']?.toString(),
      role: (map['role'] ?? 'user').toString(),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at'] ?? map['created_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
