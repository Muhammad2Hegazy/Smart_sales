import 'package:equatable/equatable.dart';

/// User Management Events
abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();

  @override
  List<Object?> get props => [];
}

/// Load all users (admin only)
class LoadUsers extends UserManagementEvent {
  const LoadUsers();
}

/// Create a new user (admin only)
class CreateUser extends UserManagementEvent {
  final String username;
  final String password;
  final String? name;
  final String role; // 'admin', 'manager', 'cashier', or custom role

  const CreateUser({
    required this.username,
    required this.password,
    this.name,
    required this.role,
  });

  @override
  List<Object?> get props => [username, password, name, role];
}

/// Update user role (admin only)
class UpdateUserRole extends UserManagementEvent {
  final String userId;
  final String role; // 'admin' or 'user'

  const UpdateUserRole({
    required this.userId,
    required this.role,
  });

  @override
  List<Object?> get props => [userId, role];
}

/// Promote user to admin (admin only)
class PromoteToAdmin extends UserManagementEvent {
  final String userId;

  const PromoteToAdmin({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Load permissions for a specific user
class LoadUserPermissions extends UserManagementEvent {
  final String userId;

  const LoadUserPermissions({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Update a specific permission for a user (admin only)
class UpdateUserPermission extends UserManagementEvent {
  final String userId;
  final String permissionKey;
  final bool allowed;

  const UpdateUserPermission({
    required this.userId,
    required this.permissionKey,
    required this.allowed,
  });

  @override
  List<Object?> get props => [userId, permissionKey, allowed];
}

/// Check if current user is admin
class CheckAdminStatus extends UserManagementEvent {
  const CheckAdminStatus();
}

