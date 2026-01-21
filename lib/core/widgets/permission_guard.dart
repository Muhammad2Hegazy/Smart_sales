import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../database/database_helper.dart';
import '../repositories/user_management_repository.dart';
import '../data_sources/local/user_management_local_data_source.dart';

/// A widget that conditionally renders its child based on permission
/// Shows nothing or a fallback widget if permission is denied
class PermissionGuard extends StatefulWidget {
  /// The permission key to check
  final String permissionKey;

  /// The widget to show if permission is granted
  final Widget child;

  /// Optional widget to show if permission is denied (defaults to SizedBox.shrink())
  final Widget? fallback;

  /// If true, shows the child as disabled instead of hiding it
  final bool showDisabled;

  /// Callback when permission is denied and user tries to access
  final VoidCallback? onDenied;

  const PermissionGuard({
    super.key,
    required this.permissionKey,
    required this.child,
    this.fallback,
    this.showDisabled = false,
    this.onDenied,
  });

  @override
  State<PermissionGuard> createState() => _PermissionGuardState();
}

class _PermissionGuardState extends State<PermissionGuard> {
  late PermissionService _permissionService;
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPermissionService();
  }

  void _initPermissionService() {
    final dbHelper = DatabaseHelper();
    final userManagementLocalDataSource = UserManagementLocalDataSource();
    final userManagementRepository = UserManagementRepository(
      userManagementLocalDataSource,
      dbHelper,
    );
    _permissionService = PermissionService(dbHelper, userManagementRepository);
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final hasPermission = await _permissionService.hasPermission(
        widget.permissionKey,
      );
      if (mounted) {
        setState(() {
          _hasPermission = hasPermission;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_hasPermission) {
      return widget.child;
    }

    if (widget.showDisabled) {
      return Opacity(opacity: 0.5, child: IgnorePointer(child: widget.child));
    }

    return widget.fallback ?? const SizedBox.shrink();
  }
}

/// A button wrapper that checks permission before executing onPressed
class PermissionButton extends StatefulWidget {
  /// The permission key to check
  final String permissionKey;

  /// The button widget to wrap
  final Widget child;

  /// The callback when permission is granted and button is pressed
  final VoidCallback onPressed;

  /// Callback when permission is denied
  final VoidCallback? onDenied;

  /// Message to show when permission is denied
  final String? deniedMessage;

  const PermissionButton({
    super.key,
    required this.permissionKey,
    required this.child,
    required this.onPressed,
    this.onDenied,
    this.deniedMessage,
  });

  @override
  State<PermissionButton> createState() => _PermissionButtonState();
}

class _PermissionButtonState extends State<PermissionButton> {
  late PermissionService _permissionService;
  bool _hasPermission = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPermissionService();
  }

  void _initPermissionService() {
    final dbHelper = DatabaseHelper();
    final userManagementLocalDataSource = UserManagementLocalDataSource();
    final userManagementRepository = UserManagementRepository(
      userManagementLocalDataSource,
      dbHelper,
    );
    _permissionService = PermissionService(dbHelper, userManagementRepository);
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final hasPermission = await _permissionService.hasPermission(
        widget.permissionKey,
      );
      if (mounted) {
        setState(() {
          _hasPermission = hasPermission;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasPermission = true; // Default to allow on error
          _isLoading = false;
        });
      }
    }
  }

  void _handlePress() {
    if (_hasPermission) {
      widget.onPressed();
    } else {
      if (widget.onDenied != null) {
        widget.onDenied!();
      } else if (widget.deniedMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.deniedMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Opacity(opacity: 0.5, child: IgnorePointer(child: widget.child));
    }

    return GestureDetector(
      onTap: _handlePress,
      child: Opacity(opacity: _hasPermission ? 1.0 : 0.5, child: widget.child),
    );
  }
}

/// Mixin for screens that need permission checking
mixin PermissionCheckMixin<T extends StatefulWidget> on State<T> {
  late PermissionService permissionService;

  @override
  void initState() {
    super.initState();
    final dbHelper = DatabaseHelper();
    final userManagementLocalDataSource = UserManagementLocalDataSource();
    final userManagementRepository = UserManagementRepository(
      userManagementLocalDataSource,
      dbHelper,
    );
    permissionService = PermissionService(dbHelper, userManagementRepository);
  }

  /// Check if user has a specific permission
  Future<bool> hasPermission(String permissionKey) async {
    return await permissionService.hasPermission(permissionKey);
  }

  /// Show permission denied message
  void showPermissionDenied(String? message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Permission denied'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Execute action if permission is granted
  Future<void> executeWithPermission(
    String permissionKey,
    VoidCallback action, {
    String? deniedMessage,
  }) async {
    final hasAccess = await hasPermission(permissionKey);
    if (hasAccess) {
      action();
    } else {
      showPermissionDenied(deniedMessage);
    }
  }
}
