import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/repositories/user_management_repository.dart';
import '../../../core/models/user_permission.dart';
import 'user_management_event.dart';
import 'user_management_state.dart';

/// User Management BLoC
/// Manages user management state and operations
class UserManagementBloc extends Bloc<UserManagementEvent, UserManagementState> {
  final UserManagementRepository _repository;

  UserManagementBloc(this._repository) : super(const UserManagementInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<CreateUser>(_onCreateUser);
    on<UpdateUserRole>(_onUpdateUserRole);
    on<PromoteToAdmin>(_onPromoteToAdmin);
    on<LoadUserPermissions>(_onLoadUserPermissions);
    on<UpdateUserPermission>(_onUpdateUserPermission);
    on<CheckAdminStatus>(_onCheckAdminStatus);

    // Check admin status on initialization
    add(const CheckAdminStatus());
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(const UserManagementLoading());
    try {
      // Check if user is admin
      final isAdmin = await _repository.isCurrentUserAdmin();
      if (!isAdmin) {
        emit(const UserManagementError('Only admins can view users'));
        return;
      }

      // Load users and permissions
      final users = await _repository.getAllUserProfiles();
      final userPermissions = await _repository.getAllUserPermissions();

      emit(UserManagementLoaded(
        users: users,
        userPermissions: userPermissions,
        isAdmin: isAdmin,
      ));
    } catch (e) {
      emit(UserManagementError('Failed to load users: $e'));
    }
  }

  Future<void> _onCreateUser(
    CreateUser event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(const UserManagementLoading());
    try {
      // Check if user is admin
      final isAdmin = await _repository.isCurrentUserAdmin();
      if (!isAdmin) {
        emit(const UserManagementError('Only admins can create users'));
        return;
      }

      // Create user with specified role
      await _repository.createUser(
        username: event.username,
        password: event.password,
        role: event.role,
        name: event.name,
      );

      // Reload users
      add(const LoadUsers());
    } catch (e) {
      emit(UserManagementError('Failed to create user: $e'));
    }
  }

  Future<void> _onUpdateUserRole(
    UpdateUserRole event,
    Emitter<UserManagementState> emit,
  ) async {
    if (state is! UserManagementLoaded) return;

    emit(const UserManagementLoading());
    try {
      // Check if user is admin
      final isAdmin = await _repository.isCurrentUserAdmin();
      if (!isAdmin) {
        emit(const UserManagementError('Only admins can update user roles'));
        return;
      }

      // Update role
      await _repository.updateUserRole(event.userId, event.role);

      // Reload users
      add(const LoadUsers());
    } catch (e) {
      emit(UserManagementError('Failed to update user role: $e'));
    }
  }

  Future<void> _onLoadUserPermissions(
    LoadUserPermissions event,
    Emitter<UserManagementState> emit,
  ) async {
    if (state is! UserManagementLoaded) return;

    try {
      // Load permissions for the user
      final permissions = await _repository.getUserPermissions(event.userId);

      // Update state with selected user
      final currentState = state as UserManagementLoaded;
      final updatedPermissions = Map<String, List<UserPermission>>.from(
        currentState.userPermissions,
      );
      updatedPermissions[event.userId] = permissions;

      emit(currentState.copyWith(
        userPermissions: updatedPermissions,
        selectedUserId: event.userId,
      ));
    } catch (e) {
      emit(UserManagementError('Failed to load user permissions: $e'));
    }
  }

  Future<void> _onUpdateUserPermission(
    UpdateUserPermission event,
    Emitter<UserManagementState> emit,
  ) async {
    if (state is! UserManagementLoaded) return;

    try {
      // Check if user is admin
      final isAdmin = await _repository.isCurrentUserAdmin();
      if (!isAdmin) {
        emit(const UserManagementError('Only admins can update permissions'));
        return;
      }

      // Update permission
      await _repository.updateUserPermission(
        event.userId,
        event.permissionKey,
        event.allowed,
      );

      // Update local state
      final currentState = state as UserManagementLoaded;
      final updatedPermissions = Map<String, List<UserPermission>>.from(
        currentState.userPermissions,
      );

      // Update or add permission
      final userPerms = List<UserPermission>.from(
        updatedPermissions[event.userId] ?? [],
      );

      final existingIndex = userPerms.indexWhere(
        (p) => p.permissionKey == event.permissionKey,
      );

      if (existingIndex >= 0) {
        userPerms[existingIndex] = userPerms[existingIndex].copyWith(
          allowed: event.allowed,
        );
      } else {
        // Create new permission - this happens when a permission is added for the first time
        // The database will generate the ID, but we need to reload from DB to get it
        // For now, generate a temporary ID that will be replaced when we reload
        final uuid = const Uuid();
        userPerms.add(UserPermission(
          id: uuid.v4(), // Generate UUID for new permission
          userId: event.userId,
          permissionKey: event.permissionKey,
          allowed: event.allowed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      updatedPermissions[event.userId] = userPerms;

      emit(currentState.copyWith(userPermissions: updatedPermissions));
      
      // Reload permissions from database to ensure they're saved
      // This ensures the database has the latest state
      await Future.delayed(const Duration(milliseconds: 100));
      final savedPermissions = await _repository.getUserPermissions(event.userId);
      final savedPermsMap = <String, List<UserPermission>>{};
      savedPermsMap[event.userId] = savedPermissions;
      final finalState = state as UserManagementLoaded;
      emit(finalState.copyWith(
        userPermissions: {...updatedPermissions, ...savedPermsMap},
      ));
    } catch (e) {
      emit(UserManagementError('Failed to update permission: $e'));
    }
  }

  Future<void> _onPromoteToAdmin(
    PromoteToAdmin event,
    Emitter<UserManagementState> emit,
  ) async {
    if (state is! UserManagementLoaded) return;

    emit(const UserManagementLoading());
    try {
      // Check if user is admin
      final isAdmin = await _repository.isCurrentUserAdmin();
      if (!isAdmin) {
        emit(const UserManagementError('Only admins can promote users'));
        return;
      }

      // Promote to admin
      await _repository.promoteToAdmin(event.userId);

      // Reload users
      add(const LoadUsers());
    } catch (e) {
      emit(UserManagementError('Failed to promote user: $e'));
    }
  }

  Future<void> _onCheckAdminStatus(
    CheckAdminStatus event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      final isAdmin = await _repository.isCurrentUserAdmin();
      
      if (state is UserManagementLoaded) {
        emit((state as UserManagementLoaded).copyWith(isAdmin: isAdmin));
      } else {
        emit(UserManagementLoaded(
          users: [],
          userPermissions: {},
          isAdmin: isAdmin,
        ));
      }
    } catch (e) {
      // Silently fail, assume not admin
      if (state is UserManagementLoaded) {
        emit((state as UserManagementLoaded).copyWith(isAdmin: false));
      }
    }
  }
}

