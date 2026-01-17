import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_text_field.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../core/database/database_helper.dart';
import '../core/models/user_profile.dart';
import '../core/models/device.dart';
import '../core/models/master.dart';
import '../core/utils/mac_address_helper.dart';

/// Login Screen
/// UI only - all logic handled by AuthBloc
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  List<UserProfile> _users = [];
  UserProfile? _selectedUser;
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final dbHelper = DatabaseHelper();
      final users = await dbHelper.getAllUserProfiles();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoadingUsers = false;
          // Auto-select first user if available
          if (users.isNotEmpty) {
            _selectedUser = users.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
        final l10n = AppLocalizations.of(context)!;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorLoadingUsers(e.toString())),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) => Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.point_of_sale,
                            size: 64,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.appTitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.displaySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.signInToContinue,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // User Selection Dropdown
                          if (_isLoadingUsers)
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_users.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.error, width: 1.5),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_off_outlined,
                                    size: 48,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'No users found',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    l10n.pleaseCreateAccountFirst,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else
                            Builder(
                              builder: (context) {
                                return DropdownButtonFormField<UserProfile>(
                                  key: ValueKey('user_dropdown_${_users.length}'),
                                  // ignore: deprecated_member_use
                                  value: _selectedUser,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: l10n.selectUser,
                                    hintText: l10n.chooseUser,
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      color: AppColors.textSecondary,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.error),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.error, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.md,
                                    ),
                                    labelStyle: AppTextStyles.bodyMedium,
                                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  style: AppTextStyles.bodyLarge,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: AppColors.textSecondary,
                                  ),
                                  dropdownColor: AppColors.surface,
                                  selectedItemBuilder: (BuildContext context) {
                                    return _users.map((user) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.person,
                                              size: 20,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            Flexible(
                                              child: Text(
                                                user.username,
                                                style: AppTextStyles.bodyLarge,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.sm,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getRoleColor(user.role).withValues(alpha:0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                user.role.toUpperCase(),
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: _getRoleColor(user.role),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList();
                                  },
                                  items: _users.map((user) {
                                    return DropdownMenuItem<UserProfile>(
                                      value: user,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: _getRoleColor(user.role).withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.person,
                                                size: 24,
                                                color: _getRoleColor(user.role),
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.md),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    user.username,
                                                    style: AppTextStyles.bodyLarge.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: AppSpacing.sm,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _getRoleColor(user.role).withValues(alpha:0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      user.role.toUpperCase(),
                                                      style: AppTextStyles.bodySmall.copyWith(
                                                        color: _getRoleColor(user.role),
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 10,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (UserProfile? user) {
                                    if (mounted) {
                                      setState(() {
                                        _selectedUser = user;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a user';
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            key: const ValueKey('password_field'),
                            controller: _passwordController,
                            label: l10n.password,
                            hint: l10n.enterPassword,
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleLogin(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                }
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.pleaseEnterPassword;
                              }
                              if (value.length < 5) {
                                return 'Password must be at least 5 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return AppButton(
                                label: l10n.signIn,
                                onPressed: state is AuthLoading
                                    ? null
                                    : _handleLogin,
                                isLoading: state is AuthLoading,
                                isFullWidth: true,
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextButton(
                            onPressed: () {
                              _showForgotPasswordDialog(context);
                            },
                            child: Text(
                              'Forgot Password',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ),
            ),
            // Transparent button in bottom left
            Positioned(
              left: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleMacAddressSave,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const SizedBox(
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.error;
      case 'manager':
        return AppColors.warning;
      case 'cashier':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a user'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
          AuthSignInRequested(
            username: _selectedUser!.username,
            password: _passwordController.text,
          ),
        );
  }

  Future<void> _handleMacAddressSave() async {
    try {
      // Get MAC address
      final macAddress = await MacAddressHelper.getMacAddress();
      
      if (macAddress == null || macAddress.isEmpty || macAddress == '02:00:00:00:00:00') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to retrieve MAC address'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final dbHelper = DatabaseHelper();
      
      // Check if device with this MAC already exists
      final existingDevice = await dbHelper.getDeviceByMacAddress(macAddress);
      
      if (existingDevice != null) {
        // Update last seen time
        await dbHelper.insertDevice(existingDevice.copyWith(
          lastSeenAt: DateTime.now(),
        ));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('MAC address already registered: $macAddress'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        return;
      }

      // Get or create master device
      var master = await dbHelper.getMaster();
      String masterDeviceId;
      
      if (master == null) {
        // Create a temporary master
        masterDeviceId = const Uuid().v4();
        master = Master(
          masterDeviceId: masterDeviceId,
          masterName: 'Master Device',
          userId: 'system',
          createdAt: DateTime.now(),
        );
        await dbHelper.insertMaster(master);
      } else {
        masterDeviceId = master.masterDeviceId;
      }

      // Create new device entry
      final device = Device(
        deviceId: const Uuid().v4(),
        deviceName: 'Device ${macAddress.substring(macAddress.length - 5)}',
        masterDeviceId: masterDeviceId,
        isMaster: false,
        lastSeenAt: DateTime.now(),
        macAddress: macAddress,
      );

      await dbHelper.insertDevice(device);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('MAC address saved: $macAddress'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving MAC address: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    UserProfile? selectedUserForReset;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, setDialogState) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.lock_reset, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Reset Password'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.selectUserAndEnterPassword,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<UserProfile>(
                    // ignore: deprecated_member_use
                    value: selectedUserForReset,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.selectUser,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                    items: _users.map((user) {
                      return DropdownMenuItem(
                        value: user,
                        child: Row(
                          children: [
                            Text(user.username),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(user.role).withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _getRoleColor(user.role),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (UserProfile? user) {
                      setDialogState(() {
                        selectedUserForReset = user;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: newPasswordController,
                    label: 'New Password',
                    hint: 'Enter new password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: obscureNewPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.passwordRequired;
                      }
                      if (value.length < 5) {
                        return 'Password must be at least 5 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: confirmPasswordController,
                    label: l10n.confirmPassword,
                    hint: l10n.confirmNewPassword,
                    prefixIcon: Icons.lock_outline,
                    obscureText: obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseConfirmPassword;
                      }
                      if (value != newPasswordController.text) {
                        return l10n.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: Text(l10n.cancel),
              ),
              AppButton(
                label: l10n.resetPassword,
                onPressed: () async {
                  if (selectedUserForReset == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.pleaseSelectUser),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  if (newPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.passwordRequired),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  if (newPasswordController.text.length < 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.passwordMinLength),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  if (newPasswordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.passwordsDoNotMatch),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  try {
                    // Hash the new password
                    final bytes = utf8.encode(newPasswordController.text);
                    final digest = sha256.convert(bytes);
                    final hashedPassword = digest.toString();

                    // Update password in database
                    final dbHelper = DatabaseHelper();
                    await dbHelper.updateUserPassword(
                      selectedUserForReset!.userId,
                      hashedPassword,
                    );

                    if (!mounted) return;
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    if (mounted) {
                      final scaffoldContext = context;
                      if (scaffoldContext.mounted) {
                        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                          SnackBar(
                            content: Text(l10n.passwordResetSuccessfully),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (!mounted) return;
                    final scaffoldContext = context;
                    if (scaffoldContext.mounted) {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        SnackBar(
                          content: Text(l10n.errorResettingPassword(e.toString())),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
