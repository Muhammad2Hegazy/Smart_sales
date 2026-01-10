import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_text_field.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/locale_helper.dart';
import '../core/utils/excel_importer.dart';
import '../core/utils/printer_settings_helper.dart';
import '../core/models/printer_settings.dart';
import '../core/utils/tax_settings_helper.dart';
import '../core/database/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../bloc/product/product_bloc.dart';
import '../bloc/product/product_event.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/device/device_bloc.dart';
import '../bloc/device/device_event.dart';
import '../bloc/device/device_state.dart';
import '../bloc/sync/sync_bloc.dart';
import '../bloc/sync/sync_event.dart';
import '../bloc/sync/sync_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/user_management/user_management_bloc.dart';
import '../bloc/user_management/user_management_event.dart';
import '../bloc/user_management/user_management_state.dart';
import '../core/models/user_permission.dart';
import '../core/models/user_profile.dart';
import '../core/models/device.dart';
import '../core/utils/mac_address_helper.dart';
import 'package:printing/printing.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _autoPrintEnabled = false;
  String _selectedLanguageCode = 'ar';
  String _selectedCurrency = AppConstants.currency;
  String _selectedTheme = 'light'; // Use lowercase for consistency
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Load users if admin
    context.read<UserManagementBloc>().add(const CheckAdminStatus());
    context.read<UserManagementBloc>().add(const LoadUsers());
  }

  /// Get current user profile
  Future<UserProfile?> _getUserProfile(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('auth_user_id');
      if (currentUserId == null) return null;

      final dbHelper = DatabaseHelper();
      return await dbHelper.getUserProfile(currentUserId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadSettings() async {
    final languageCode = await LocaleHelper.getCurrentLanguage();
    setState(() {
      _selectedLanguageCode = languageCode;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return BlocBuilder<UserManagementBloc, UserManagementState>(
      builder: (context, userMgmtState) {
        final isAdmin = userMgmtState is UserManagementLoaded && userMgmtState.isAdmin;
        
        return DefaultTabController(
          length: isAdmin ? 5 : 4, // Add User Management tab for admin
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(l10n.settings),
              bottom: TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: l10n.generalSettings, icon: const Icon(Icons.settings_outlined)),
                  if (isAdmin) Tab(text: l10n.userManagement, icon: const Icon(Icons.people_outlined)),
                  Tab(text: l10n.devices, icon: const Icon(Icons.devices_outlined)),
                  Tab(text: l10n.sync, icon: const Icon(Icons.sync_outlined)),
                  Tab(text: l10n.systemSettings, icon: const Icon(Icons.info_outlined)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildGeneralTab(context, l10n),
                if (isAdmin) _buildUserManagementTab(context, l10n),
                _buildDeviceManagementTab(context, l10n),
                _buildSyncTab(context, l10n),
                _buildSystemTab(context, l10n),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeneralTab(BuildContext context, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildSectionHeader(l10n.account),
        _buildSettingsCard([
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                return Column(
                  children: [
                    FutureBuilder<UserProfile?>(
                      future: _getUserProfile(context),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final profile = snapshot.data!;
                          return ListTile(
                            leading: Icon(
                              profile.isAdmin ? Icons.admin_panel_settings : Icons.person,
                              color: AppColors.primary,
                            ),
                            title: Text(profile.username),
                            subtitle: Text('${l10n.role}: ${profile.role}'),
                          );
                        }
                        return ListTile(
                          leading: const Icon(Icons.person, color: AppColors.primary),
                          title: Text(authState.user.email),
                          subtitle: Text(l10n.loadingProfile),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      l10n.signOut,
                      l10n.signOutFromAccount,
                      Icons.logout,
                      () => _handleSignOut(context, l10n),
                      isDanger: true,
                    ),
                  ],
                );
              } else {
                return ListTile(
                  title: Text(l10n.notAuthenticated),
                );
              }
            },
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionHeader(l10n.generalSettings),
          _buildSettingsCard([
            _buildSwitchTile(
              l10n.enableNotifications,
              l10n.notificationsDescription,
              _notificationsEnabled,
              (value) => setState(() => _notificationsEnabled = value),
              Icons.notifications_outlined,
            ),
            _buildDivider(),
            _buildSwitchTile(
              l10n.soundEffects,
              l10n.soundDescription,
              _soundEnabled,
              (value) => setState(() => _soundEnabled = value),
              Icons.volume_up_outlined,
            ),
            _buildDivider(),
            _buildSwitchTile(
              l10n.autoPrintReceipts,
              l10n.autoPrintDescription,
              _autoPrintEnabled,
              (value) => setState(() => _autoPrintEnabled = value),
              Icons.print_outlined,
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
        _buildSectionHeader(l10n.appearance),
          _buildSettingsCard([
            _buildLanguageDropdown(l10n),
            _buildDivider(),
            _buildThemeDropdown(l10n),
          ]),
          const SizedBox(height: AppSpacing.lg),
        _buildSectionHeader(l10n.businessSettings),
          _buildSettingsCard([
            _buildDropdownTile(
              l10n.currency,
              _selectedCurrency,
              [AppConstants.currency],
              (value) => setState(() => _selectedCurrency = value!),
              Icons.attach_money_outlined,
            ),
            _buildDivider(),
            _buildListTile(
              l10n.taxSettings,
              l10n.taxDescription,
              Icons.receipt_long_outlined,
              () => _showTaxSettings(context, l10n),
            ),
            _buildDivider(),
            _buildListTile(
              l10n.printerSettings,
              l10n.receiptDescription,
              Icons.print_outlined,
              () => _showPrinterSettings(context, l10n),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
        _buildSectionHeader(l10n.dataImport),
        _buildSettingsCard([
          _buildListTile(
            l10n.importRawMaterials,
            'Import raw materials from Excel. These will appear in inventory.',
            Icons.inventory_2_outlined,
            () => _handleImportRawMaterials(context, l10n),
          ),
        ]),
      ],
    );
  }

  Widget _buildUserManagementTab(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<UserManagementBloc, UserManagementState>(
      builder: (context, state) {
        if (state is UserManagementInitial || state is UserManagementLoading) {
          context.read<UserManagementBloc>().add(const LoadUsers());
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is UserManagementError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        
        if (state is UserManagementLoaded) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _buildSectionHeader(l10n.createNewUser),
              _buildSettingsCard([
                _buildListTile(
                  l10n.addUser,
                  l10n.createNewUserAccount,
                  Icons.person_add_outlined,
                  () => _showCreateUserDialog(context, l10n),
                ),
              ]),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionHeader(l10n.users),
              _buildSettingsCard([
                if (state.users.isEmpty)
                  ListTile(
                    title: Text(l10n.noUsersFound),
                  )
                else
                  ...state.users.map((user) {
                    final userPermissions = state.userPermissions[user.userId] ?? [];
                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: AppColors.primary,
                          ),
                          title: Text(user.username),
                          subtitle: Text('${l10n.role}: ${user.role}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.lock_reset, color: AppColors.primary),
                                tooltip: l10n.changePassword,
                                onPressed: () => _showChangePasswordDialog(context, user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.security, color: AppColors.primary),
                                tooltip: l10n.managePermissions,
                                onPressed: () => _showPermissionsDialog(context, user, userPermissions),
                              ),
                              if (!user.isAdmin)
                                IconButton(
                                  icon: const Icon(Icons.admin_panel_settings, color: AppColors.primary),
                                  tooltip: l10n.promoteToAdmin,
                                  onPressed: () => _showPromoteToAdminDialog(context, user, l10n),
                                ),
                            ],
                          ),
                        ),
                        if (user != state.users.last) _buildDivider(),
                      ],
                    );
                  }),
              ]),
            ],
          );
        }
        
        return Center(child: Text(l10n.unknownState));
      },
    );
  }

  Widget _buildDeviceManagementTab(BuildContext context, AppLocalizations l10n) {
    return BlocListener<DeviceBloc, DeviceState>(
      listener: (context, deviceState) {
        // Check if current device was deleted (currentDevice is null but devices list exists)
        if (deviceState is DeviceReady && 
            deviceState.currentDevice == null && 
            deviceState.devices.isNotEmpty) {
          // Current device was deleted - logout user
          context.read<AuthBloc>().add(const AuthSignOutRequested());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.deviceDeletedLogout),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildSectionHeader(l10n.deviceManagement),
          _buildSettingsCard([
            BlocBuilder<DeviceBloc, DeviceState>(
              builder: (context, deviceState) {
              if (deviceState is DeviceReady) {
                return Column(
                  children: [
                    _buildListTile(
                      l10n.addDevice,
                      l10n.addDevice,
                      Icons.add_circle_outline,
                      () => _showAddDeviceDialog(context, deviceState.master, l10n),
                    ),
                    _buildDivider(),
                    _buildListTile(
                      l10n.manageDeviceFloors,
                      l10n.manageDeviceFloorsDescription,
                      Icons.layers,
                      () => _showManageFloorsDialog(context, deviceState.master, deviceState.devices, l10n),
                    ),
                    if (deviceState.devices.length > 1) ...[
                      _buildDivider(),
                      _buildListTile(
                        l10n.deleteAllDevices,
                        l10n.deleteAllDevicesDescription,
                        Icons.delete_sweep_outlined,
                        () => _showDeleteAllDevicesDialog(context, deviceState.master, deviceState.currentDevice, l10n),
                        isDanger: true,
                      ),
                    ],
                    if (deviceState.devices.isNotEmpty) _buildDivider(),
                    if (deviceState.devices.isNotEmpty)
                      ...deviceState.devices.map((device) => Column(
                        children: [
                          _buildDeviceTile(context, device, deviceState.currentDevice?.deviceId == device.deviceId, deviceState.master, l10n),
                          if (device != deviceState.devices.last) _buildDivider(),
                        ],
                      )),
                  ],
                );
              } else if (deviceState is DeviceError) {
                return ListTile(
                  title: Text('Error: ${deviceState.message}'),
                  leading: const Icon(Icons.error_outline, color: AppColors.error),
                );
              } else {
                return ListTile(
                  title: Text(l10n.loadingDevices),
                  leading: const CircularProgressIndicator(),
                );
              }
            },
          ),
        ]),
      ],
      ),
    );
  }

  Widget _buildSyncTab(BuildContext context, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildSectionHeader(l10n.syncStatus),
        _buildSettingsCard([
          // Check if SyncBloc is available
          Builder(
            builder: (context) {
              try {
                final syncBloc = context.read<SyncBloc>();
                return BlocBuilder<SyncBloc, SyncState>(
                  bloc: syncBloc,
                  builder: (context, syncState) {
                    if (syncState is SyncReady) {
                      return Column(
                        children: [
                          _buildSyncStatusTile(syncState, l10n),
                          _buildDivider(),
                          _buildSyncActionTile(context, syncState, l10n),
                        ],
                      );
                    } else {
                      return ListTile(
                        title: Text(l10n.syncStatusUnavailable),
                      );
                    }
                  },
                );
              } catch (e) {
                return ListTile(
                  title: Text(l10n.syncServiceNotAvailable),
                  subtitle: Text(l10n.syncRequiresSupabase),
                  leading: const Icon(Icons.info_outline, color: AppColors.primary),
                );
              }
            },
          ),
        ]),
      ],
    );
  }

  Widget _buildSystemTab(BuildContext context, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildSectionHeader(l10n.systemSettings),
        _buildSettingsCard([
          _buildListTile(
            l10n.backupRestore,
            l10n.backupDescription,
            Icons.backup_outlined,
            () => _showBackupDialog(context, l10n),
          ),
          _buildDivider(),
          _buildListTile(
            l10n.about,
            l10n.aboutDescription,
            Icons.info_outlined,
            () => _showAboutDialog(context, l10n),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionHeader(l10n.dangerZone),
        _buildSettingsCard([
          _buildListTile(
            l10n.clearAllData,
            l10n.clearDataDescription,
            Icons.delete_forever_outlined,
            () => _showClearDataDialog(context, l10n),
            isDanger: true,
          ),
        ]),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, left: AppSpacing.xs),
      child: Text(
        title,
        style: AppTextStyles.titleLarge.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildLanguageDropdown(AppLocalizations l10n) {
    final languageOptions = [
      {'code': 'en', 'label': l10n.english},
      {'code': 'ar', 'label': l10n.arabic},
    ];

    return ListTile(
      leading: const Icon(Icons.language_outlined, color: AppColors.primary),
      title: Text(l10n.language),
      trailing: DropdownButton<String>(
        value: _selectedLanguageCode,
        underline: const SizedBox(),
        items: languageOptions.map((option) {
          return DropdownMenuItem<String>(
            value: option['code']!,
            child: Text(option['label']!),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null && value != _selectedLanguageCode) {
            setState(() {
              _selectedLanguageCode = value;
            });
            _changeLanguage(value);
          }
        },
      ),
    );
  }

  Widget _buildThemeDropdown(AppLocalizations l10n) {
    final themeOptions = [
      {'value': 'light', 'label': l10n.light},
      {'value': 'dark', 'label': l10n.dark},
      {'value': 'system', 'label': l10n.system},
    ];

    return ListTile(
      leading: Icon(Icons.palette_outlined, color: AppColors.primary),
      title: Text(l10n.theme),
      trailing: DropdownButton<String>(
        value: _selectedTheme,
        underline: const SizedBox(),
        items: themeOptions.map((option) {
          return DropdownMenuItem(
            value: option['value'],
            child: Text(option['label']!),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedTheme = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDanger ? AppColors.error : AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? AppColors.error : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 72);
  }

  void _showTaxSettings(BuildContext context, AppLocalizations l10n) async {
    final currentVatRate = await TaxSettingsHelper.loadVatRate();
    final currentServiceChargeRate = await TaxSettingsHelper.loadServiceChargeRate();
    final currentDeliveryTaxRate = await TaxSettingsHelper.loadDeliveryTaxRate();
    final currentHospitalityTaxRate = await TaxSettingsHelper.loadHospitalityTaxRate();
    
    final vatRateController = TextEditingController(
      text: (currentVatRate * 100).toStringAsFixed(2),
    );
    final serviceChargeController = TextEditingController(
      text: (currentServiceChargeRate * 100).toStringAsFixed(2),
    );
    final deliveryTaxController = TextEditingController(
      text: (currentDeliveryTaxRate * 100).toStringAsFixed(2),
    );
    final hospitalityTaxController = TextEditingController(
      text: (currentHospitalityTaxRate * 100).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.taxSettings),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VAT Rate (%)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: vatRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'VAT Rate (%)',
                    hintText: '14.0',
                    border: const OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Service Charge Rate (%)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: serviceChargeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Service Charge Rate (%)',
                    hintText: '10.0',
                    border: const OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Delivery Tax Rate (%)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: deliveryTaxController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Delivery Tax Rate (%)',
                    hintText: '5.0',
                    border: const OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Hospitality Discount Rate (%)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: hospitalityTaxController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Hospitality Discount Rate (%)',
                    hintText: '5.0',
                    border: const OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Note: Service charge applies to dine-in orders only. Delivery tax applies to delivery orders only. Hospitality discount applies to hospitality orders only (as a discount, not a tax).',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            AppButton(
              label: l10n.save,
              onPressed: () async {
                final vatRate = double.tryParse(vatRateController.text);
                final serviceChargeRate = double.tryParse(serviceChargeController.text);
                final deliveryTaxRate = double.tryParse(deliveryTaxController.text);
                final hospitalityTaxRate = double.tryParse(hospitalityTaxController.text);
                
                if (vatRate == null || vatRate < 0 || vatRate > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid VAT rate (0-100)'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                
                if (serviceChargeRate == null || serviceChargeRate < 0 || serviceChargeRate > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseEnterValidServiceChargeRate),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                
                if (deliveryTaxRate == null || deliveryTaxRate < 0 || deliveryTaxRate > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseEnterValidDeliveryTaxRate),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                
                if (hospitalityTaxRate == null || hospitalityTaxRate < 0 || hospitalityTaxRate > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseEnterValidHospitalityTaxRate),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                
                final saved = await TaxSettingsHelper.saveVatRate(vatRate / 100);
                final savedService = await TaxSettingsHelper.saveServiceChargeRate(serviceChargeRate / 100);
                final savedDelivery = await TaxSettingsHelper.saveDeliveryTaxRate(deliveryTaxRate / 100);
                final savedHospitality = await TaxSettingsHelper.saveHospitalityTaxRate(hospitalityTaxRate / 100);
                
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(saved && savedService && savedDelivery && savedHospitality
                          ? l10n.settingsSavedSuccessfully
                          : l10n.failedToSaveSettings),
                      backgroundColor: saved && savedService && savedDelivery && savedHospitality ? AppColors.secondary : AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrinterSettings(BuildContext context, AppLocalizations l10n) async {
    // Load current settings
    final currentSettings = await PrinterSettingsHelper.loadSettings();
    
    // Get available printers
    List<Printer> printers = [];
    String? selectedPrinterName;
    
    try {
      printers = await Printing.listPrinters();
      
      // Find current printer name if it exists
      if (currentSettings.printerName.isNotEmpty && printers.isNotEmpty) {
        // Check if saved printer name exists in the list
        final printerExists = printers.any(
          (p) => p.name == currentSettings.printerName,
        );
        if (printerExists) {
          selectedPrinterName = currentSettings.printerName;
        } else {
          // If saved printer not found, use default or first available
          final defaultPrinter = printers.firstWhere(
            (p) => p.isDefault,
            orElse: () => printers.first,
          );
          selectedPrinterName = defaultPrinter.name;
        }
      } else if (printers.isNotEmpty) {
        final defaultPrinter = printers.firstWhere(
          (p) => p.isDefault,
          orElse: () => printers.first,
        );
        selectedPrinterName = defaultPrinter.name;
      }
    } catch (e) {
      debugPrint('Error loading printers: $e');
      printers = [];
    }
    
    // Controllers for form fields
    final paperSizeController = TextEditingController(text: currentSettings.paperSize);
    final paperSourceController = TextEditingController(text: currentSettings.paperSource);
    final widthController = TextEditingController(text: currentSettings.width.toString());
    final heightController = TextEditingController(
      text: currentSettings.height == double.infinity ? '' : currentSettings.height.toString()
    );
    bool isPortrait = currentSettings.isPortrait;
    bool isLoadingPrinters = false;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.printerSettings),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Printer selection dropdown
                if (printers.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: selectedPrinterName,
                    decoration: InputDecoration(
                      labelText: l10n.printerName,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: isLoadingPrinters
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                        onPressed: isLoadingPrinters
                            ? null
                            : () async {
                                setDialogState(() {
                                  isLoadingPrinters = true;
                                });
                                try {
                                  final updatedPrinters = await Printing.listPrinters();
                                  setDialogState(() {
                                    printers = updatedPrinters;
                                    if (updatedPrinters.isNotEmpty) {
                                      final defaultPrinter = updatedPrinters.firstWhere(
                                        (p) => p.isDefault,
                                        orElse: () => updatedPrinters.first,
                                      );
                                      selectedPrinterName = defaultPrinter.name;
                                    }
                                    isLoadingPrinters = false;
                                  });
                                } catch (e) {
                                  setDialogState(() {
                                    isLoadingPrinters = false;
                                  });
                                }
                              },
                        tooltip: l10n.refresh,
                      ),
                    ),
                    items: printers.map((printer) {
                      return DropdownMenuItem<String>(
                        value: printer.name,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (printer.isDefault)
                              const Icon(Icons.star, size: 16, color: AppColors.primary),
                            if (printer.isDefault) const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                printer.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (printerName) {
                      setDialogState(() {
                        selectedPrinterName = printerName;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else ...[
                  TextField(
                    controller: TextEditingController(text: currentSettings.printerName),
                    decoration: InputDecoration(
                      labelText: l10n.printerName,
                      border: const OutlineInputBorder(),
                      hintText: l10n.noPrintersAvailable,
                    ),
                    enabled: false,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                
                // Paper Size
                TextField(
                  controller: paperSizeController,
                  decoration: InputDecoration(
                    labelText: l10n.paperSize,
                    border: const OutlineInputBorder(),
                    hintText: '80(72.1) x 210 mm',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Paper Source
                TextField(
                  controller: paperSourceController,
                  decoration: InputDecoration(
                    labelText: l10n.paperSource,
                    border: const OutlineInputBorder(),
                    hintText: 'Automatically Select',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Width (mm)
                TextField(
                  controller: widthController,
                  decoration: InputDecoration(
                    labelText: l10n.paperWidth,
                    border: const OutlineInputBorder(),
                    hintText: '80',
                    suffixText: 'mm',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Height (mm) - empty for continuous
                TextField(
                  controller: heightController,
                  decoration: InputDecoration(
                    labelText: l10n.paperHeight,
                    border: const OutlineInputBorder(),
                    hintText: l10n.continuousPaper,
                    suffixText: 'mm',
                    helperText: l10n.leaveEmptyForContinuous,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Orientation
                Text(l10n.orientation, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setDialogState(() {
                            isPortrait = true;
                          });
                        },
                        child: Row(
                          children: [
                            Radio<bool>(
                              value: true,
                              groupValue: isPortrait,
                              onChanged: (value) {
                                setDialogState(() {
                                  isPortrait = value ?? true;
                                });
                              },
                            ),
                            Text(l10n.portrait),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setDialogState(() {
                            isPortrait = false;
                          });
                        },
                        child: Row(
                          children: [
                            Radio<bool>(
                              value: false,
                              groupValue: isPortrait,
                              onChanged: (value) {
                                setDialogState(() {
                                  isPortrait = value ?? false;
                                });
                              },
                            ),
                            Text(l10n.landscape),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            AppButton(
              label: l10n.save,
              onPressed: () async {
                // Parse width and height
                double width = currentSettings.width;
                double height = currentSettings.height;
                
                try {
                  if (widthController.text.trim().isNotEmpty) {
                    width = double.parse(widthController.text.trim());
                  }
                  if (heightController.text.trim().isNotEmpty) {
                    height = double.parse(heightController.text.trim());
                  } else {
                    height = double.infinity; // Continuous paper
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${l10n.invalidNumber}: ${l10n.paperWidth}/${l10n.paperHeight}'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                  return;
                }
                
                final newSettings = PrinterSettings(
                  printerName: selectedPrinterName ?? currentSettings.printerName,
                  paperSize: paperSizeController.text.trim().isEmpty 
                      ? currentSettings.paperSize 
                      : paperSizeController.text.trim(),
                  paperSource: paperSourceController.text.trim().isEmpty 
                      ? currentSettings.paperSource 
                      : paperSourceController.text.trim(),
                  isPortrait: isPortrait,
                  width: width,
                  height: height,
                );
                
                final saved = await PrinterSettingsHelper.saveSettings(newSettings);
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(saved 
                          ? l10n.printerConfigured 
                          : l10n.printerConfigurationFailed),
                      backgroundColor: saved ? AppColors.secondary : AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupRestore),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: l10n.createBackup,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.backupCreated),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
              icon: Icons.backup,
              isFullWidth: true,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.restoreFromBackup,
              onPressed: () async {
                Navigator.pop(context);
                await _restoreFromBackup(context, l10n);
              },
              type: AppButtonType.outline,
              isFullWidth: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreFromBackup(BuildContext context, AppLocalizations l10n) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreFromBackup),
        content: const Text(
          'This will replace your current database with the backup file. '
          'All current data will be lost. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          AppButton(
            label: l10n.restore,
            onPressed: () => Navigator.pop(context, true),
            type: AppButtonType.danger,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Pick backup file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite'],
        dialogTitle: l10n.selectBackupDatabaseFile,
      );

      if (result == null || result.files.single.path == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.noFileSelected),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      final backupPath = result.files.single.path!;
      final backupFile = File(backupPath);

      if (!await backupFile.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.backupFileNotFound),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Get current database path
      final dbHelper = DatabaseHelper();
      final dbPath = await dbHelper.getDatabasePath();
      final dbFile = File(dbPath);

      // Close current database connection
      await dbHelper.closeDatabase();

      // Create backup of current database (just in case)
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final currentBackupPath = '${dbPath}_backup_$timestamp';
      if (await dbFile.exists()) {
        await dbFile.copy(currentBackupPath);
      }

      // Copy backup file to database location
      await backupFile.copy(dbPath);

      // Reinitialize database
      await DatabaseHelper.initialize();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.databaseRestoredSuccessfully),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Show success message with option to restart
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.restoreComplete),
            content: const Text(
              'Database has been restored successfully. '
              'Please restart the application for changes to take effect.',
            ),
            actions: [
              AppButton(
                label: l10n.ok,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error restoring from backup: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorRestoringBackup(e.toString())),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: const Icon(
        Icons.point_of_sale,
        size: 48,
        color: AppColors.primary,
      ),
      children: [
        Text(l10n.modernPointOfSaleSystem),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.copyright),
      ],
    );
  }

  Future<void> _changeLanguage(String languageCode) async {
    await LocaleHelper.setLanguage(languageCode);
    
    if (mounted) {
      final appState = SmartSalesApp.of(context);
      if (appState != null) {
        appState.setLocale(Locale(languageCode));
      }
    }
  }

  void _showClearDataDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllData),
        content: Text(l10n.clearDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          AppButton(
            label: l10n.clearAllData,
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.allDataCleared),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            type: AppButtonType.danger,
          ),
        ],
      ),
    );
  }

  Future<void> _handleImportRawMaterials(BuildContext context, AppLocalizations l10n) async {
    try {
      final result = await ExcelImporter.pickExcelFile();
      if (result == null || result.files.isEmpty) {
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToGetFilePath),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final productBloc = context.read<ProductBloc>();
      bool success = false;
      String message = '';

      try {
        // Import raw materials with isPosOnly = false (default)
        final items = await ExcelImporter.importRawMaterials(filePath);
        if (items.isEmpty) {
          message = 'No raw materials found in the file.';
        } else {
          productBloc.add(ImportItems(items));
          success = true;
          message = 'Raw materials imported successfully (${items.length} items). These items will appear in inventory.';
        }
      } catch (e) {
        message = 'Error importing raw materials: $e';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? AppColors.secondary : AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildDeviceTile(BuildContext context, device, bool isCurrentDevice, master, AppLocalizations l10n) {
    final isMaster = device.isMaster;
    return ListTile(
      leading: Icon(
        isMaster ? Icons.star : (isCurrentDevice ? Icons.phone_android : Icons.devices),
        color: isMaster ? AppColors.primary : (isCurrentDevice ? AppColors.primary : AppColors.textSecondary),
      ),
      title: Row(
        children: [
          Expanded(child: Text(device.deviceName)),
          if (isMaster)
            Chip(
              label: Text(l10n.masterDevice),
              backgroundColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(color: AppColors.primary, fontSize: 12),
            ),
          if (isCurrentDevice && !isMaster)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Chip(
                label: Text(l10n.current),
                backgroundColor: AppColors.primary,
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      subtitle: Text(
        device.macAddress != null && device.macAddress!.isNotEmpty
            ? device.macAddress!
            : 'No MAC address',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMaster)
            IconButton(
              icon: const Icon(Icons.star_outline, color: AppColors.primary),
              tooltip: l10n.setAsMaster,
              onPressed: () => _showSetAsMasterDialog(context, device, master, l10n),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: l10n.deleteDevice,
            onPressed: () => _showDeleteDeviceDialog(context, device, master, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusTile(SyncReady syncState, AppLocalizations l10n) {
    return ListTile(
      leading: Icon(
        syncState.isOnline ? Icons.cloud_done : Icons.cloud_off,
        color: syncState.isOnline ? AppColors.secondary : AppColors.error,
      ),
      title: Text(syncState.isOnline ? l10n.online : l10n.offline),
      subtitle: Text(
        syncState.isSyncing
            ? 'Syncing...'
            : syncState.pendingRecords > 0
                ? '${syncState.pendingRecords} pending records'
                : l10n.allSynced,
      ),
      trailing: syncState.isSyncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }

  Widget _buildSyncActionTile(BuildContext context, SyncReady syncState, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.sync, color: AppColors.primary),
      title: Text(l10n.syncNow),
      subtitle: syncState.lastSyncTime != null
          ? Text(l10n.lastSync(_formatDateTime(DateTime.parse(syncState.lastSyncTime!))))
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: syncState.isOnline && !syncState.isSyncing
          ? () => context.read<SyncBloc>().add(const TriggerSync())
          : null,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _handleSignOut(BuildContext context, AppLocalizations l10n) {
    // Get AuthBloc from the outer context before showing dialog
    final authBloc = context.read<AuthBloc>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.areYouSureSignOut),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          AppButton(
            label: l10n.signOut,
            onPressed: () {
              Navigator.pop(dialogContext);
              authBloc.add(const AuthSignOutRequested());
            },
            type: AppButtonType.danger,
          ),
        ],
      ),
    );
  }


  /// Show Promote to Admin Dialog
  void _showPromoteToAdminDialog(BuildContext context, user, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.promoteToAdmin),
        content: Text(l10n.areYouSurePromoteToAdmin(user.username)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          AppButton(
            label: l10n.promote,
            onPressed: () {
              context.read<UserManagementBloc>().add(
                PromoteToAdmin(userId: user.userId),
              );

              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );
  }

  /// Show Create User Dialog
  void _showCreateUserDialog(BuildContext context, AppLocalizations l10n) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final customRoleController = TextEditingController();
    String selectedRole = 'cashier';
    bool isCustomRole = false;
    final predefinedRoles = ['admin', 'manager', 'cashier'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Get BLoCs from outer context before building dialog
        final userMgmtBloc = context.read<UserManagementBloc>();
        
        return StatefulBuilder(
          builder: (innerContext, setDialogState) => AlertDialog(
            title: Text(l10n.createNewUser),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: l10n.username,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: l10n.confirmPassword,
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Checkbox(
                        value: isCustomRole,
                        onChanged: (value) {
                          setDialogState(() {
                            isCustomRole = value ?? false;
                            if (!isCustomRole) {
                              customRoleController.clear();
                            }
                          });
                        },
                      ),
                      Text(l10n.customRole),
                    ],
                  ),
                  if (isCustomRole) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: customRoleController,
                      decoration: InputDecoration(
                        labelText: l10n.enterCustomRole,
                        border: OutlineInputBorder(),
                        hintText: 'e.g., supervisor, accountant',
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: l10n.role,
                        border: OutlineInputBorder(),
                      ),
                      items: predefinedRoles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role[0].toUpperCase() + role.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedRole = value ?? 'cashier';
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              AppButton(
                label: 'Create',
                onPressed: () {
                  if (usernameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.usernameRequired)),
                    );
                    return;
                  }
                  if (passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.passwordRequired)),
                    );
                    return;
                  }
                  if (passwordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.passwordsDoNotMatch)),
                    );
                    return;
                  }
                  
                  final role = isCustomRole 
                      ? customRoleController.text.trim()
                      : selectedRole;
                  
                  if (role.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.roleRequired)),
                    );
                    return;
                  }

                  // Create user via UserManagementBloc
                  userMgmtBloc.add(
                    CreateUser(
                      username: usernameController.text.trim(),
                      password: passwordController.text,
                      role: role,
                    ),
                  );

                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.userCreatedSuccessfully)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show Change Password Dialog
  void _showChangePasswordDialog(BuildContext context, UserProfile user) {
    final l10n = AppLocalizations.of(context)!;
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
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
                Expanded(
                  child: Text('Change Password for ${user.username}'),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                        return 'Password is required';
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
                    label: 'Confirm Password',
                    hint: 'Confirm new password',
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
                        return 'Please confirm password';
                      }
                      if (value != newPasswordController.text) {
                        return 'Passwords do not match';
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
                label: 'Change Password',
                onPressed: () async {
                  if (newPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Password is required'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  if (newPasswordController.text.length < 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Password must be at least 5 characters'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  if (newPasswordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Passwords do not match'),
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
                      user.userId,
                      hashedPassword,
                    );

                    if (!mounted) return;
                    Navigator.pop(dialogContext);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Password changed successfully'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error changing password: ${e.toString()}'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show Permissions Dialog with checkboxes for all features
  void _showPermissionsDialog(
    BuildContext context,
    UserProfile user,
    List<UserPermission> currentPermissions,
  ) {
    // Get BLoC from outer context before building dialog
    final userMgmtBloc = context.read<UserManagementBloc>();
    
    // Create a map of current permissions
    final permissionMap = <String, bool>{};
    for (final perm in currentPermissions) {
      permissionMap[perm.permissionKey] = perm.allowed;
    }

    // Initialize all permission keys
    final allPermissions = <String, bool>{};
    for (final key in PermissionKeys.all) {
      allPermissions[key] = permissionMap[key] ?? false;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setDialogState) {
          final dialogL10n = AppLocalizations.of(innerContext)!;
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.security, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(dialogL10n.permissionsForUser(user.username)),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dialogL10n.selectPermissionsForUser,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Group permissions by module
                    // Track displayed permissions to avoid duplicates
                    Builder(
                      builder: (builderContext) {
                        final displayedPermissions = <String>{};
                        final builderL10n = AppLocalizations.of(builderContext)!;
                        final expansionTiles = <Widget>[];
                        
                        for (final module in PermissionKeys.getModules()) {
                          final modulePermissions = PermissionKeys.getPermissionsByModule(module);
                          // Filter out already displayed permissions
                          final uniquePermissions = modulePermissions.where((key) {
                            if (displayedPermissions.contains(key)) {
                              return false; // Skip duplicate
                            }
                            displayedPermissions.add(key);
                            return true;
                          }).toList();
                          
                          // Only show expansion tile if there are unique permissions
                          if (uniquePermissions.isEmpty) {
                            continue;
                          }
                          
                          expansionTiles.add(
                            ExpansionTile(
                              title: Text(
                                PermissionKeys.getModuleLabel(module, builderL10n),
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              children: uniquePermissions.map((key) {
                                return CheckboxListTile(
                                  title: Text(PermissionKeys.getLabel(key, builderL10n)),
                                  value: allPermissions[key] ?? false,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      allPermissions[key] = value ?? false;
                                    });
                                  },
                                );
                              }).toList(),
                          ),
                        );
                      }
                      
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: expansionTiles,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(dialogL10n.cancel),
              ),
              AppButton(
                label: dialogL10n.save,
                onPressed: () async {
                  // Update all permissions - save each one to database
                  for (final key in PermissionKeys.all) {
                    final allowed = allPermissions[key] ?? false;
                    userMgmtBloc.add(
                      UpdateUserPermission(
                        userId: user.userId,
                        permissionKey: key,
                        allowed: allowed,
                      ),
                    );
                  }

                  // Wait a bit for all updates to complete
                  await Future.delayed(const Duration(milliseconds: 500));

                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  
                  if (mounted) {
                    final successL10n = AppLocalizations.of(context)!;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(successL10n.permissionsUpdatedSuccessfully),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }

                  // Reload users to refresh permissions
                  userMgmtBloc.add(const LoadUsers());
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Show Add Device Dialog
  void _showAddDeviceDialog(BuildContext context, master, AppLocalizations l10n) async {
    final deviceNameController = TextEditingController();
    final macAddressController = TextEditingController();
    bool isLoadingMac = false;

    // Automatically fetch physical MAC address when dialog opens
    try {
      final macAddress = await MacAddressHelper.getMacAddress();
      if (macAddress != null && macAddress.isNotEmpty && macAddress != '02:00:00:00:00:00') {
        macAddressController.text = macAddress;
      } else {
        // If physical MAC not available, try to get device identifier
        // But prefer physical MAC
        final identifier = await MacAddressHelper.getDeviceIdentifier();
        macAddressController.text = identifier;
      }
    } catch (e) {
      // Silently fail - user can manually enter or use refresh button
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setDialogState) => AlertDialog(
          title: Text(l10n.addDevice),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: deviceNameController,
                  decoration: InputDecoration(
                    labelText: l10n.deviceName,
                    hintText: l10n.enterDeviceName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: macAddressController,
                  decoration: InputDecoration(
                    labelText: l10n.macAddress,
                    hintText: l10n.enterMacAddress,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: isLoadingMac
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      onPressed: isLoadingMac
                          ? null
                            : () async {
                              setDialogState(() {
                                isLoadingMac = true;
                              });
                              try {
                                // Get physical MAC address
                                final macAddress = await MacAddressHelper.getMacAddress();
                                if (macAddress != null && macAddress.isNotEmpty && macAddress != '02:00:00:00:00:00') {
                                  macAddressController.text = macAddress;
                                } else {
                                  // If physical MAC not available, show error
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Physical MAC address not available. Please enter manually.'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to get MAC address: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              } finally {
                                setDialogState(() {
                                  isLoadingMac = false;
                                });
                              }
                            },
                      tooltip: l10n.getMacAddress,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            AppButton(
              label: l10n.addDevice,
              onPressed: () {
                if (deviceNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.deviceName} ${l10n.required.toLowerCase()}')),
                  );
                  return;
                }
                if (macAddressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.macAddressRequired)),
                  );
                  return;
                }

                if (master != null) {
                  context.read<DeviceBloc>().add(
                    RegisterCurrentDevice(
                      masterDeviceId: master.masterDeviceId,
                      deviceName: deviceNameController.text.trim(),
                      macAddress: macAddressController.text.trim(),
                      isMaster: false,
                    ),
                  );
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Device added successfully'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show Set as Master Dialog
  void _showSetAsMasterDialog(BuildContext context, device, master, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.setAsMaster),
        content: Text('Are you sure you want to set "${device.deviceName}" as the master device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          AppButton(
            label: l10n.setAsMaster,
            onPressed: () {
              if (master != null) {
                context.read<DeviceBloc>().add(
                  SetDeviceAsMaster(
                    masterDeviceId: master.masterDeviceId,
                    deviceId: device.deviceId,
                  ),
                );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.deviceSetAsMasterSuccessfully),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Show Delete Device Dialog
  void _showDeleteDeviceDialog(BuildContext context, device, master, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteDevice),
        content: Text(l10n.areYouSureDeleteDevice),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          AppButton(
            label: l10n.deleteDevice,
            onPressed: () {
              if (master != null) {
                context.read<DeviceBloc>().add(
                  DeleteDevice(
                    masterDeviceId: master.masterDeviceId,
                    deviceId: device.deviceId,
                  ),
                );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.deviceDeletedSuccessfully),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              }
            },
            type: AppButtonType.danger,
          ),
        ],
      ),
    );
  }

  /// Show Delete All Devices Dialog
  void _showDeleteAllDevicesDialog(BuildContext context, master, currentDevice, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAllDevices),
        content: Text(l10n.areYouSureDeleteAllDevices),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          AppButton(
            label: l10n.deleteAllDevices,
            onPressed: () {
              if (master != null && currentDevice != null) {
                context.read<DeviceBloc>().add(
                  DeleteAllDevices(
                    masterDeviceId: master.masterDeviceId,
                    currentDeviceId: currentDevice.deviceId,
                  ),
                );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.allDevicesDeletedSuccessfully),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              }
            },
            type: AppButtonType.danger,
          ),
        ],
      ),
    );
  }

  /// Show Manage Floors Dialog
  void _showManageFloorsDialog(BuildContext context, master, List<Device> devices, AppLocalizations l10n) {
    // Create a map to track device-floor assignments
    final Map<String, int?> deviceFloors = {};
    for (final device in devices) {
      deviceFloors[device.deviceId] = device.floor;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setDialogState) => AlertDialog(
          title: Text(l10n.manageDeviceFloors),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.selectDeviceAndFloor,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...devices.map((device) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${device.deviceName}${device.macAddress != null && device.macAddress!.isNotEmpty ? ' (${device.macAddress})' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int?>(
                                  value: deviceFloors[device.deviceId] ?? device.floor,
                                  decoration: InputDecoration(
                                    labelText: l10n.floor,
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: [
                                    DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text(l10n.noFloor),
                                    ),
                                    DropdownMenuItem<int?>(
                                      value: 1,
                                      child: Text(l10n.groundFloor),
                                    ),
                                    DropdownMenuItem<int?>(
                                      value: 2,
                                      child: Text(l10n.secondFloor),
                                    ),
                                    DropdownMenuItem<int?>(
                                      value: 3,
                                      child: Text(l10n.thirdFloor),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setDialogState(() {
                                      deviceFloors[device.deviceId] = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            AppButton(
              label: l10n.save,
              onPressed: () {
                // Update all device floors
                for (final device in devices) {
                  final newFloor = deviceFloors[device.deviceId];
                  if (newFloor != device.floor) {
                    context.read<DeviceBloc>().add(
                      UpdateDeviceFloor(
                        deviceId: device.deviceId,
                        floor: newFloor ?? device.floor,
                      ),
                    );
                  }
                }
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.floorsUpdatedSuccessfully),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
