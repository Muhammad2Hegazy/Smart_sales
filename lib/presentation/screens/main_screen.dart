import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../blocs/navigation/navigation_bloc.dart';
import '../blocs/navigation/navigation_event.dart';
import '../blocs/navigation/navigation_state.dart';
import 'invoices_tabs.dart';
import 'purchase_invoice_screen.dart';
import 'inventory_screen.dart';
import 'items_screen.dart';
import 'settings_screen.dart';
import 'reports/reports_tabs.dart';
import 'financial_screen.dart';
import '../blocs/sales/sales_bloc.dart';
import '../blocs/sales/sales_event.dart';
import '../blocs/financial/financial_bloc.dart';
import '../blocs/financial/financial_event.dart';
import '../blocs/product/product_bloc.dart';
import '../blocs/product/product_event.dart';
import '../../core/services/permission_service.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/user_management_repository.dart';
import '../../core/data_sources/local/user_management_local_data_source.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PermissionService _permissionService;
  List<String> _accessibleMenuItems = [];
  bool _isLoadingPermissions = true;

  @override
  void initState() {
    super.initState();
    _initializePermissionService();
    _loadAccessibleMenuItems();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializePermissionService() {
    final dbHelper = DatabaseHelper();
    final userManagementLocalDataSource = UserManagementLocalDataSource();
    final userManagementRepository = UserManagementRepository(
      userManagementLocalDataSource,
      dbHelper,
    );
    _permissionService = PermissionService(dbHelper, userManagementRepository);
  }

  Future<void> _loadAccessibleMenuItems() async {
    try {
      // Add timeout to prevent hanging
      final accessibleItems = await _permissionService.getAccessibleMenuItems()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Permission loading timeout - using all menu items');
              // Return all items as fallback if timeout
              return ['pos', 'purchaseInvoice', 'items', 'inventory', 'reports', 'profitLoss', 'settings'];
            },
          );
      
      if (mounted) {
        setState(() {
          _accessibleMenuItems = accessibleItems;
          _isLoadingPermissions = false;
          
          // If current selected item is not accessible, redirect to first accessible item
          final currentState = context.read<NavigationBloc>().state;
          final currentItemName = currentState.selectedItem.toString().split('.').last;
          if (!accessibleItems.contains(currentItemName) && accessibleItems.isNotEmpty) {
            // Convert string to MenuItem
            MenuItem? firstAccessibleItem;
            switch (accessibleItems.first) {
              case 'pos':
                firstAccessibleItem = MenuItem.pos;
                break;
              case 'purchaseInvoice':
                firstAccessibleItem = MenuItem.purchaseInvoice;
                break;
              case 'items':
                firstAccessibleItem = MenuItem.items;
                break;
              case 'inventory':
                firstAccessibleItem = MenuItem.inventory;
                break;
              case 'reports':
                firstAccessibleItem = MenuItem.reports;
                break;
              case 'profitLoss':
                firstAccessibleItem = MenuItem.profitLoss;
                break;
              case 'settings':
                firstAccessibleItem = MenuItem.settings;
                break;
            }
            if (firstAccessibleItem != null) {
              context.read<NavigationBloc>().add(
                NavigateToMenuItem(firstAccessibleItem),
              );
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading accessible menu items: $e');
      // On error, allow access to all items
      if (mounted) {
        setState(() {
          _accessibleMenuItems = ['pos', 'purchaseInvoice', 'items', 'inventory', 'reports', 'profitLoss', 'settings'];
          _isLoadingPermissions = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPermissions) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        // Check if current page is accessible
        final currentItemName = state.selectedItem.toString().split('.').last;
        if (!_accessibleMenuItems.contains(currentItemName)) {
          // Redirect to first accessible page
          if (_accessibleMenuItems.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              MenuItem? firstAccessibleItem;
              switch (_accessibleMenuItems.first) {
                case 'pos':
                  firstAccessibleItem = MenuItem.pos;
                  break;
                case 'purchaseInvoice':
                  firstAccessibleItem = MenuItem.purchaseInvoice;
                  break;
                case 'items':
                  firstAccessibleItem = MenuItem.items;
                  break;
                case 'inventory':
                  firstAccessibleItem = MenuItem.inventory;
                  break;
                case 'reports':
                  firstAccessibleItem = MenuItem.reports;
                  break;
                case 'profitLoss':
                  firstAccessibleItem = MenuItem.profitLoss;
                  break;
                case 'settings':
                  firstAccessibleItem = MenuItem.settings;
                  break;
              }
              if (firstAccessibleItem != null) {
                context.read<NavigationBloc>().add(
                  NavigateToMenuItem(firstAccessibleItem),
                );
              }
            });
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              _buildSideMenu(context, state.selectedItem),
              Expanded(
                child: _buildContent(state.selectedItem),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSideMenu(BuildContext context, MenuItem selectedItem) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.point_of_sale,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appTitle,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.pos,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: _buildMenuItems(context, selectedItem, l10n),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              children: [
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final l10n = AppLocalizations.of(context)!;
                    String username = l10n.user;
                    String role = l10n.cashier;
                    
                    if (authState is AuthAuthenticated) {
                      username = authState.user.name ?? authState.user.username;
                      role = _getRoleDisplayName(authState.user.role, l10n);
                    }
                    
                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                role,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: AppLocalizations.of(context)!.logout,
                  onPressed: () => _handleLogout(context),
                  type: AppButtonType.outline,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, MenuItem selectedItem, AppLocalizations l10n) {
    final menuItems = <Widget>[];
    
    // Sales Invoice (formerly POS)
    if (_accessibleMenuItems.contains('pos')) {
      menuItems.add(
        _buildMenuItem(
          context,
          icon: Icons.shopping_cart_outlined,
          title: l10n.salesInvoice,
          selected: selectedItem == MenuItem.pos,
          onTap: () {
            context.read<NavigationBloc>().add(
              NavigateToMenuItem(MenuItem.pos),
            );
          },
        ),
      );
    }
    
    // Purchase Invoice
    if (_accessibleMenuItems.contains('purchaseInvoice')) {
      menuItems.add(
        _buildMenuItem(
          context,
          icon: Icons.shopping_bag_outlined,
          title: 'فاتورة المشتريات',
          selected: selectedItem == MenuItem.purchaseInvoice,
          onTap: () {
            context.read<NavigationBloc>().add(
              NavigateToMenuItem(MenuItem.purchaseInvoice),
            );
          },
        ),
      );
    }
    
    // Items
    if (_accessibleMenuItems.contains('items')) {
      menuItems.add(
        _buildMenuItem(
          context,
          icon: Icons.shopping_bag_outlined,
          title: l10n.items,
          selected: selectedItem == MenuItem.items,
          onTap: () {
            context.read<NavigationBloc>().add(
              NavigateToMenuItem(MenuItem.items),
            );
          },
        ),
      );
    }
    
    // Inventory
    if (_accessibleMenuItems.contains('inventory')) {
      menuItems.add(
        _buildMenuItem(
          context,
          icon: Icons.inventory_2_outlined,
          title: l10n.inventory,
          selected: selectedItem == MenuItem.inventory,
          onTap: () {
            context.read<NavigationBloc>().add(
              NavigateToMenuItem(MenuItem.inventory),
            );
          },
        ),
      );
    }
    
    // Reports
    if (_accessibleMenuItems.contains('reports')) {
      menuItems.add(
        _buildMenuItem(
          context,
          icon: Icons.assessment_outlined,
          title: l10n.reports,
          selected: selectedItem == MenuItem.reports,
          onTap: () {
            context.read<NavigationBloc>().add(
              NavigateToMenuItem(MenuItem.reports),
            );
          },
        ),
      );
    }
    
    // Profit/Loss
    if (_accessibleMenuItems.contains('profitLoss')) {
      menuItems.add(
        _buildMenuItem(
          context,
          icon: Icons.account_balance_outlined,
          title: l10n.profitLoss,
          selected: selectedItem == MenuItem.profitLoss,
          onTap: () {
            context.read<NavigationBloc>().add(
              NavigateToMenuItem(MenuItem.profitLoss),
            );
          },
        ),
      );
    }
    
    // Settings
    if (_accessibleMenuItems.contains('settings')) {
      menuItems.add(
        _buildMenuItem(
          context,
          icon: Icons.settings_outlined,
          title: l10n.settings,
          selected: selectedItem == MenuItem.settings,
          onTap: () {
            context.read<NavigationBloc>().add(
              NavigateToMenuItem(MenuItem.settings),
            );
          },
        ),
      );
    }
    
    return menuItems;
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const Spacer(),
                if (selected)
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(MenuItem selectedItem) {
    switch (selectedItem) {
      case MenuItem.pos:
        return const InvoicesTabs();
      case MenuItem.purchaseInvoice:
        return MultiBlocProvider(
          providers: [
            BlocProvider<FinancialBloc>(
              create: (context) => FinancialBloc()..add(const LoadFinancialTransactions()),
            ),
          ],
          child: const PurchaseInvoiceScreen(),
        );
      case MenuItem.inventory:
        return const InventoryScreen();
      case MenuItem.items:
        return const ItemsScreen();
      case MenuItem.reports:
        return MultiBlocProvider(
          providers: [
            BlocProvider<SalesBloc>(
              create: (context) => SalesBloc()..add(const LoadSales()),
            ),
            BlocProvider<ProductBloc>(
              create: (context) => ProductBloc()..add(const LoadProducts()),
            ),
            BlocProvider<FinancialBloc>(
              create: (context) => FinancialBloc()..add(const LoadFinancialTransactions()),
            ),
          ],
          child: const ReportsTabs(),
        );
      case MenuItem.profitLoss:
        return MultiBlocProvider(
          providers: [
            BlocProvider<FinancialBloc>(
              create: (context) => FinancialBloc()..add(const LoadFinancialTransactions()),
            ),
          ],
          child: const FinancialScreen(),
        );
      case MenuItem.settings:
        return const SettingsScreen();
    }
  }

  String _getRoleDisplayName(String role, AppLocalizations l10n) {
    switch (role.toLowerCase()) {
      case 'admin':
        return l10n.admin;
      case 'cashier':
        return l10n.cashier;
      case 'manager':
        return l10n.manager;
      default:
        return role;
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          AppButton(
            label: l10n.logout,
            onPressed: () => Navigator.pop(context, true),
            type: AppButtonType.danger,
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Use AuthBloc to sign out - this will automatically trigger
      // the BlocBuilder in main.dart to show LoginScreen
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }
}
