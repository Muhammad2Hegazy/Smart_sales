import 'package:equatable/equatable.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/user_permission.dart';

/// User Management States
abstract class UserManagementState extends Equatable {
  const UserManagementState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class UserManagementInitial extends UserManagementState {
  const UserManagementInitial();
}

/// Loading state
class UserManagementLoading extends UserManagementState {
  const UserManagementLoading();
}

/// Loaded state with users and permissions
class UserManagementLoaded extends UserManagementState {
  final List<UserProfile> users;
  final Map<String, List<UserPermission>> userPermissions; // userId -> permissions
  final String? selectedUserId; // Currently selected user for permission editing
  final bool isAdmin;

  const UserManagementLoaded({
    required this.users,
    required this.userPermissions,
    this.selectedUserId,
    this.isAdmin = false,
  });

  /// Get permissions for selected user
  List<UserPermission> get selectedUserPermissions {
    if (selectedUserId == null) return [];
    return userPermissions[selectedUserId] ?? [];
  }

  /// Get selected user profile
  UserProfile? get selectedUser {
    if (selectedUserId == null) return null;
    return users.firstWhere(
      (user) => user.userId == selectedUserId,
      orElse: () => users.first, // Fallback, should not happen
    );
  }

  @override
  List<Object?> get props => [users, userPermissions, selectedUserId, isAdmin];

  /// Create a copy with updated fields
  UserManagementLoaded copyWith({
    List<UserProfile>? users,
    Map<String, List<UserPermission>>? userPermissions,
    String? selectedUserId,
    bool? isAdmin,
  }) {
    return UserManagementLoaded(
      users: users ?? this.users,
      userPermissions: userPermissions ?? this.userPermissions,
      selectedUserId: selectedUserId ?? this.selectedUserId,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

/// Error state
class UserManagementError extends UserManagementState {
  final String message;

  const UserManagementError(this.message);

  @override
  List<Object?> get props => [message];
}

