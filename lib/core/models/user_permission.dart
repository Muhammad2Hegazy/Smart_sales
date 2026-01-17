import '../../l10n/app_localizations.dart';

/// User Permission Model
/// Represents a single permission for a user
class UserPermission {
  final String id; // UUID
  final String userId; // UUID from auth.users
  final String permissionKey; // e.g., 'manage_users', 'view_reports', etc.
  final bool allowed; // Whether the permission is allowed
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPermission({
    required this.id,
    required this.userId,
    required this.permissionKey,
    required this.allowed,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Map (Database response)
  factory UserPermission.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return UserPermission(
      id: (map['id'] ?? '') as String,
      userId: (map['user_id'] ?? '') as String,
      permissionKey: (map['permission_key'] ?? '') as String,
      allowed: (map['allowed'] == 1 || map['allowed'] == true),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at'] ?? map['created_at']),
    );
  }

  /// Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'permission_key': permissionKey,
      'allowed': allowed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserPermission copyWith({
    String? id,
    String? userId,
    String? permissionKey,
    bool? allowed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPermission(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      permissionKey: permissionKey ?? this.permissionKey,
      allowed: allowed ?? this.allowed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserPermission(id: $id, userId: $userId, permissionKey: $permissionKey, allowed: $allowed)';
  }
}

/// Permission Keys Constants
/// Based on the comprehensive permission system with modules
///
/// Note: This class requires AppLocalizations for localized labels.
/// Use getLabel() and getModuleLabel() methods with AppLocalizations instance.
class PermissionKeys {
  // General permissions
  static const String viewReports = 'view_reports';
  // Permissions Module
  static const String userPermissions = 'user_permissions';

  // Basic Data Module
  static const String basicData = 'basic_data';
  static const String addEditItemsProducts = 'add_edit_items_products';
  static const String registerOpeningBalance = 'register_opening_balance';
  static const String retrieveEditOpeningBalance =
      'retrieve_edit_opening_balance';

  // Inventory Module
  static const String registerTransfersToWarehouses =
      'register_transfers_to_warehouses';
  static const String registerTransfersFromWarehouses =
      'register_transfers_from_warehouses';
  static const String printBarcode = 'print_barcode';

  // Purchases Module
  static const String registerPurchaseInvoice = 'register_purchase_invoice';
  static const String retrieveEditPurchaseInvoice =
      'retrieve_edit_purchase_invoice';
  static const String registerPurchaseReturns = 'register_purchase_returns';

  // Vendors/Sellers Module
  static const String addVendors = 'add_vendors';
  static const String adjustSalePrice = 'adjust_sale_price';

  // Sales Invoice Module
  static const String registerSalesInvoice = 'register_sales_invoice';
  static const String clearAllCurrentInvoice = 'clear_all_current_invoice';
  static const String clearItemCurrentInvoice = 'clear_item_current_invoice';
  static const String changeItemCurrentInvoice = 'change_item_current_invoice';
  static const String changeItemQuantityLess = 'change_item_quantity_less';
  static const String discountInvoiceItems = 'discount_invoice_items';
  static const String temporaryPrintBeforeSave = 'temporary_print_before_save';
  static const String inquireTreasuryBalance = 'inquire_treasury_balance';
  static const String retrieveEditSalesInvoice = 'retrieve_edit_sales_invoice';

  // Sales Returns Module
  static const String registerSalesReturns = 'register_sales_returns';

  // Accounts Module
  static const String addNewAccount = 'add_new_account';
  static const String registerCashReceipt = 'register_cash_receipt';
  static const String registerCashDisbursement = 'register_cash_disbursement';
  static const String registerAdjustmentEntries = 'register_adjustment_entries';

  // Inventory Reports Module
  static const String inventoryCountReport = 'inventory_count_report';
  static const String inventoryCountReportByCategory =
      'inventory_count_report_by_category';
  static const String inventoryMovementReport = 'inventory_movement_report';
  static const String itemMovementReport = 'item_movement_report';
  static const String itemMovementReportByItem = 'item_movement_report_by_item';

  // Purchase Reports Module
  static const String purchaseReportByVendor = 'purchase_report_by_vendor';

  // Sales Reports Module
  static const String shiftPreferenceReport = 'shift_preference_report';
  static const String dailySalesReport = 'daily_sales_report';
  static const String aggregatedSalesReportByItems =
      'aggregated_sales_report_by_items';
  static const String salesReportByItem = 'sales_report_by_item';
  static const String salesReportByCategory = 'sales_report_by_category';
  static const String salesReportByCustomer = 'sales_report_by_customer';
  static const String customerAccountStatement = 'customer_account_statement';

  // Account Reports Module
  static const String supplierAccountStatement = 'supplier_account_statement';
  static const String customerBalancesReport = 'customer_balances_report';
  static const String supplierBalancesReport = 'supplier_balances_report';
  static const String generalLedgerReport = 'general_ledger_report';
  static const String accountBalancesReport = 'account_balances_report';
  static const String profitReportForPeriod = 'profit_report_for_period';
  static const String incomeStatementReport = 'income_statement_report';

  // Main Screens Access
  static const String accessPosScreen = 'access_pos_screen';
  static const String accessInventoryScreen = 'access_inventory_screen';
  static const String accessItemsScreen = 'access_items_screen';
  static const String accessReportsScreen = 'access_reports_screen';
  static const String accessFinancialScreen = 'access_financial_screen';
  static const String accessSettingsScreen = 'access_settings_screen';

  // Settings Tabs
  static const String accessGeneralSettings = 'access_general_settings';
  static const String accessUserManagement = 'access_user_management';
  static const String accessDeviceManagement = 'access_device_management';
  static const String accessSyncSettings = 'access_sync_settings';
  static const String accessSystemSettings = 'access_system_settings';

  // POS Features
  static const String posApplyDiscount = 'pos_apply_discount';
  static const String posProcessPayment = 'pos_process_payment';
  static const String posPrintInvoice = 'pos_print_invoice';
  static const String posSelectTable = 'pos_select_table';
  static const String posAccessHospitalityTable =
      'pos_access_hospitality_table';
  static const String posClearCart = 'pos_clear_cart';
  static const String posViewCart = 'pos_view_cart';

  // Financial Features
  static const String financialAddCashIn = 'financial_add_cash_in';
  static const String financialAddCashOut = 'financial_add_cash_out';
  static const String financialViewProfitLoss = 'financial_view_profit_loss';
  static const String financialViewTransactions = 'financial_view_transactions';
  static const String financialCalculateProfitLoss =
      'financial_calculate_profit_loss';

  // Reports Features
  static const String reportsViewSalesReport = 'reports_view_sales_report';
  static const String reportsViewFinancialReport =
      'reports_view_financial_report';
  static const String reportsExportReports = 'reports_export_reports';
  static const String reportsViewDailyReport = 'reports_view_daily_report';
  static const String reportsViewWeeklyReport = 'reports_view_weekly_report';
  static const String reportsViewMonthlyReport = 'reports_view_monthly_report';
  static const String reportsViewYearlyReport = 'reports_view_yearly_report';

  // Settings Features
  static const String settingsCreateUser = 'settings_create_user';
  static const String settingsEditUser = 'settings_edit_user';
  static const String settingsDeleteUser = 'settings_delete_user';
  static const String settingsChangePassword = 'settings_change_password';
  static const String settingsManagePermissions = 'settings_manage_permissions';
  static const String settingsBackupRestore = 'settings_backup_restore';
  static const String settingsClearData = 'settings_clear_data';
  static const String settingsImportData = 'settings_import_data';
  static const String settingsExportData = 'settings_export_data';
  static const String settingsConfigureTax = 'settings_configure_tax';
  static const String settingsConfigurePrinter = 'settings_configure_printer';

  /// Get all available permission keys
  static List<String> get all => [
    // General permissions
    viewReports,
    // Permissions
    userPermissions,
    // Main Screens Access
    accessPosScreen,
    accessInventoryScreen,
    accessItemsScreen,
    accessReportsScreen,
    accessFinancialScreen,
    accessSettingsScreen,
    // Settings Tabs
    accessGeneralSettings,
    accessUserManagement,
    accessDeviceManagement,
    accessSyncSettings,
    accessSystemSettings,
    // POS Features
    posApplyDiscount,
    posProcessPayment,
    posPrintInvoice,
    posSelectTable,
    posAccessHospitalityTable,
    posClearCart,
    posViewCart,
    // Financial Features
    financialAddCashIn,
    financialAddCashOut,
    financialViewProfitLoss,
    financialViewTransactions,
    financialCalculateProfitLoss,
    // Reports Features
    reportsViewSalesReport,
    reportsViewFinancialReport,
    reportsExportReports,
    reportsViewDailyReport,
    reportsViewWeeklyReport,
    reportsViewMonthlyReport,
    reportsViewYearlyReport,
    // Settings Features
    settingsCreateUser,
    settingsEditUser,
    settingsDeleteUser,
    settingsChangePassword,
    settingsManagePermissions,
    settingsBackupRestore,
    settingsClearData,
    settingsImportData,
    settingsExportData,
    settingsConfigureTax,
    settingsConfigurePrinter,
    // Basic Data
    basicData,
    addEditItemsProducts,
    registerOpeningBalance,
    retrieveEditOpeningBalance,
    // Inventory
    registerTransfersToWarehouses,
    registerTransfersFromWarehouses,
    printBarcode,
    // Purchases
    registerPurchaseInvoice,
    retrieveEditPurchaseInvoice,
    registerPurchaseReturns,
    // Vendors
    addVendors,
    adjustSalePrice,
    // Sales Invoice
    registerSalesInvoice,
    clearAllCurrentInvoice,
    clearItemCurrentInvoice,
    changeItemCurrentInvoice,
    changeItemQuantityLess,
    discountInvoiceItems,
    temporaryPrintBeforeSave,
    inquireTreasuryBalance,
    retrieveEditSalesInvoice,
    // Sales Returns
    registerSalesReturns,
    // Accounts
    addNewAccount,
    registerCashReceipt,
    registerCashDisbursement,
    registerAdjustmentEntries,
    // Inventory Reports
    inventoryCountReport,
    inventoryCountReportByCategory,
    inventoryMovementReport,
    itemMovementReport,
    itemMovementReportByItem,
    // Purchase Reports
    purchaseReportByVendor,
    // Sales Reports
    shiftPreferenceReport,
    dailySalesReport,
    aggregatedSalesReportByItems,
    salesReportByItem,
    salesReportByCategory,
    salesReportByCustomer,
    customerAccountStatement,
    // Account Reports
    supplierAccountStatement,
    customerBalancesReport,
    supplierBalancesReport,
    generalLedgerReport,
    accountBalancesReport,
    profitReportForPeriod,
    incomeStatementReport,
  ];

  /// Get all modules
  static List<String> getModules() => [
    'main_screens',
    'settings_tabs',
    'pos_features',
    'financial_features',
    'reports_features',
    'settings_features',
    'permissions',
    'basic_data',
    'inventory',
    'purchases',
    'vendors',
    'sales_invoice',
    'sales_returns',
    'accounts',
    'inventory_reports',
    'purchase_reports',
    'sales_reports',
    'account_reports',
  ];

  /// Get permissions by module
  static List<String> getPermissionsByModule(String module) {
    switch (module) {
      case 'main_screens':
        return [
          accessPosScreen,
          accessInventoryScreen,
          accessItemsScreen,
          accessReportsScreen,
          accessFinancialScreen,
          accessSettingsScreen,
        ];
      case 'settings_tabs':
        return [
          accessGeneralSettings,
          accessUserManagement,
          accessDeviceManagement,
          accessSyncSettings,
          accessSystemSettings,
        ];
      case 'pos_features':
        return [
          posApplyDiscount,
          posProcessPayment,
          posPrintInvoice,
          posSelectTable,
          posAccessHospitalityTable,
          posClearCart,
          posViewCart,
        ];
      case 'financial_features':
        return [
          financialAddCashIn,
          financialAddCashOut,
          financialViewProfitLoss,
          financialViewTransactions,
          financialCalculateProfitLoss,
        ];
      case 'reports_features':
        return [
          reportsViewSalesReport,
          reportsViewFinancialReport,
          reportsExportReports,
          reportsViewDailyReport,
          reportsViewWeeklyReport,
          reportsViewMonthlyReport,
          reportsViewYearlyReport,
        ];
      case 'settings_features':
        return [
          settingsCreateUser,
          settingsEditUser,
          settingsDeleteUser,
          settingsChangePassword,
          settingsManagePermissions,
          settingsBackupRestore,
          settingsClearData,
          settingsImportData,
          settingsExportData,
          settingsConfigureTax,
          settingsConfigurePrinter,
        ];
      case 'permissions':
        return [userPermissions];
      case 'basic_data':
        return [
          basicData,
          addEditItemsProducts,
          registerOpeningBalance,
          retrieveEditOpeningBalance,
        ];
      case 'inventory':
        return [
          registerTransfersToWarehouses,
          registerTransfersFromWarehouses,
          printBarcode,
        ];
      case 'purchases':
        return [
          registerPurchaseInvoice,
          retrieveEditPurchaseInvoice,
          registerPurchaseReturns,
        ];
      case 'vendors':
        return [addVendors, adjustSalePrice];
      case 'sales_invoice':
        return [
          registerSalesInvoice,
          clearAllCurrentInvoice,
          clearItemCurrentInvoice,
          changeItemCurrentInvoice,
          changeItemQuantityLess,
          discountInvoiceItems,
          temporaryPrintBeforeSave,
          inquireTreasuryBalance,
          retrieveEditSalesInvoice,
        ];
      case 'sales_returns':
        return [registerSalesReturns];
      case 'accounts':
        return [
          addNewAccount,
          registerCashReceipt,
          registerCashDisbursement,
          registerAdjustmentEntries,
        ];
      case 'inventory_reports':
        return [
          inventoryCountReport,
          inventoryCountReportByCategory,
          inventoryMovementReport,
          itemMovementReport,
          itemMovementReportByItem,
        ];
      case 'purchase_reports':
        return [purchaseReportByVendor];
      case 'sales_reports':
        return [
          shiftPreferenceReport,
          dailySalesReport,
          aggregatedSalesReportByItems,
          salesReportByItem,
          salesReportByCategory,
          salesReportByCustomer,
          customerAccountStatement,
        ];
      case 'account_reports':
        return [
          supplierAccountStatement,
          customerBalancesReport,
          supplierBalancesReport,
          generalLedgerReport,
          accountBalancesReport,
          profitReportForPeriod,
          incomeStatementReport,
        ];
      default:
        return [];
    }
  }

  /// Get module label (localized)
  /// Requires AppLocalizations instance for localization
  static String getModuleLabel(String module, AppLocalizations l10n) {
    switch (module) {
      case 'main_screens':
        return l10n.permissionModuleMainScreens;
      case 'settings_tabs':
        return l10n.permissionModuleSettingsTabs;
      case 'pos_features':
        return l10n.permissionModulePosFeatures;
      case 'financial_features':
        return l10n.permissionModuleFinancialFeatures;
      case 'reports_features':
        return l10n.permissionModuleReportsFeatures;
      case 'settings_features':
        return l10n.permissionModuleSettingsFeatures;
      case 'permissions':
        return l10n.permissionModulePermissions;
      case 'basic_data':
        return l10n.permissionModuleBasicData;
      case 'inventory':
        return l10n.permissionModuleInventory;
      case 'purchases':
        return l10n.permissionModulePurchases;
      case 'vendors':
        return l10n.permissionModuleVendors;
      case 'sales_invoice':
        return l10n.permissionModuleSalesInvoice;
      case 'sales_returns':
        return l10n.permissionModuleSalesReturns;
      case 'accounts':
        return l10n.permissionModuleAccounts;
      case 'inventory_reports':
        return l10n.permissionModuleInventoryReports;
      case 'purchase_reports':
        return l10n.permissionModulePurchaseReports;
      case 'sales_reports':
        return l10n.permissionModuleSalesReports;
      case 'account_reports':
        return l10n.permissionModuleAccountReports;
      default:
        return module;
    }
  }

  /// Get human-readable label for permission key (localized)
  /// Requires AppLocalizations instance for localization
  static String getLabel(String key, AppLocalizations l10n) {
    switch (key) {
      // Main Screens
      case accessPosScreen:
        return l10n.permissionAccessPosScreen;
      case accessInventoryScreen:
        return l10n.permissionAccessInventoryScreen;
      case accessItemsScreen:
        return l10n.permissionAccessItemsScreen;
      case accessReportsScreen:
        return l10n.permissionAccessReportsScreen;
      case accessFinancialScreen:
        return l10n.permissionAccessFinancialScreen;
      case accessSettingsScreen:
        return l10n.permissionAccessSettingsScreen;
      // Settings Tabs
      case accessGeneralSettings:
        return l10n.permissionAccessGeneralSettings;
      case accessUserManagement:
        return l10n.permissionAccessUserManagement;
      case accessDeviceManagement:
        return l10n.permissionAccessDeviceManagement;
      case accessSyncSettings:
        return l10n.permissionAccessSyncSettings;
      case accessSystemSettings:
        return l10n.permissionAccessSystemSettings;
      // POS Features
      case posApplyDiscount:
        return l10n.permissionPosApplyDiscount;
      case posProcessPayment:
        return l10n.permissionPosProcessPayment;
      case posPrintInvoice:
        return l10n.permissionPosPrintInvoice;
      case posSelectTable:
        return l10n.permissionPosSelectTable;
      case posAccessHospitalityTable:
        return l10n.permissionPosAccessHospitalityTable;
      case posClearCart:
        return l10n.permissionPosClearCart;
      case posViewCart:
        return l10n.permissionPosViewCart;
      // Financial Features
      case financialAddCashIn:
        return l10n.permissionFinancialAddCashIn;
      case financialAddCashOut:
        return l10n.permissionFinancialAddCashOut;
      case financialViewProfitLoss:
        return l10n.permissionFinancialViewProfitLoss;
      case financialViewTransactions:
        return l10n.permissionFinancialViewTransactions;
      case financialCalculateProfitLoss:
        return l10n.permissionFinancialCalculateProfitLoss;
      // Reports Features
      case reportsViewSalesReport:
        return l10n.permissionReportsViewSalesReport;
      case reportsViewFinancialReport:
        return l10n.permissionReportsViewFinancialReport;
      case reportsExportReports:
        return l10n.permissionReportsExportReports;
      case reportsViewDailyReport:
        return l10n.permissionReportsViewDailyReport;
      case reportsViewWeeklyReport:
        return l10n.permissionReportsViewWeeklyReport;
      case reportsViewMonthlyReport:
        return l10n.permissionReportsViewMonthlyReport;
      case reportsViewYearlyReport:
        return l10n.permissionReportsViewYearlyReport;
      // Settings Features
      case settingsCreateUser:
        return l10n.permissionSettingsCreateUser;
      case settingsEditUser:
        return l10n.permissionSettingsEditUser;
      case settingsDeleteUser:
        return l10n.permissionSettingsDeleteUser;
      case settingsChangePassword:
        return l10n.permissionSettingsChangePassword;
      case settingsManagePermissions:
        return l10n.permissionSettingsManagePermissions;
      case settingsBackupRestore:
        return l10n.permissionSettingsBackupRestore;
      case settingsClearData:
        return l10n.permissionSettingsClearData;
      case settingsImportData:
        return l10n.permissionSettingsImportData;
      case settingsExportData:
        return l10n.permissionSettingsExportData;
      case settingsConfigureTax:
        return l10n.permissionSettingsConfigureTax;
      case settingsConfigurePrinter:
        return l10n.permissionSettingsConfigurePrinter;
      // Permissions
      case userPermissions:
        return l10n.permissionUserPermissions;
      // Basic Data
      case basicData:
        return l10n.permissionBasicData;
      case addEditItemsProducts:
        return l10n.permissionAddEditItemsProducts;
      case registerOpeningBalance:
        return l10n.permissionRegisterOpeningBalance;
      case retrieveEditOpeningBalance:
        return l10n.permissionRetrieveEditOpeningBalance;
      // Inventory
      case registerTransfersToWarehouses:
        return l10n.permissionRegisterTransfersToWarehouses;
      case registerTransfersFromWarehouses:
        return l10n.permissionRegisterTransfersFromWarehouses;
      case printBarcode:
        return l10n.permissionPrintBarcode;
      // Purchases
      case registerPurchaseInvoice:
        return l10n.permissionRegisterPurchaseInvoice;
      case retrieveEditPurchaseInvoice:
        return l10n.permissionRetrieveEditPurchaseInvoice;
      case registerPurchaseReturns:
        return l10n.permissionRegisterPurchaseReturns;
      // Vendors
      case addVendors:
        return l10n.permissionAddVendors;
      case adjustSalePrice:
        return l10n.permissionAdjustSalePrice;
      // Sales Invoice
      case registerSalesInvoice:
        return l10n.permissionRegisterSalesInvoice;
      case clearAllCurrentInvoice:
        return l10n.permissionClearAllCurrentInvoice;
      case clearItemCurrentInvoice:
        return l10n.permissionClearItemCurrentInvoice;
      case changeItemCurrentInvoice:
        return l10n.permissionChangeItemCurrentInvoice;
      case changeItemQuantityLess:
        return l10n.permissionChangeItemQuantityLess;
      case discountInvoiceItems:
        return l10n.permissionDiscountInvoiceItems;
      case temporaryPrintBeforeSave:
        return l10n.permissionTemporaryPrintBeforeSave;
      case inquireTreasuryBalance:
        return l10n.permissionInquireTreasuryBalance;
      case retrieveEditSalesInvoice:
        return l10n.permissionRetrieveEditSalesInvoice;
      // Sales Returns
      case registerSalesReturns:
        return l10n.permissionRegisterSalesReturns;
      // Accounts
      case addNewAccount:
        return l10n.permissionAddNewAccount;
      case registerCashReceipt:
        return l10n.permissionRegisterCashReceipt;
      case registerCashDisbursement:
        return l10n.permissionRegisterCashDisbursement;
      case registerAdjustmentEntries:
        return l10n.permissionRegisterAdjustmentEntries;
      // Inventory Reports
      case inventoryCountReport:
        return l10n.permissionInventoryCountReport;
      case inventoryCountReportByCategory:
        return l10n.permissionInventoryCountReportByCategory;
      case inventoryMovementReport:
        return l10n.permissionInventoryMovementReport;
      case itemMovementReport:
        return l10n.permissionItemMovementReport;
      case itemMovementReportByItem:
        return l10n.permissionItemMovementReportByItem;
      // Purchase Reports
      case purchaseReportByVendor:
        return l10n.permissionPurchaseReportByVendor;
      // Sales Reports
      case shiftPreferenceReport:
        return l10n.permissionShiftPreferenceReport;
      case dailySalesReport:
        return l10n.permissionDailySalesReport;
      case aggregatedSalesReportByItems:
        return l10n.permissionAggregatedSalesReportByItems;
      case salesReportByItem:
        return l10n.permissionSalesReportByItem;
      case salesReportByCategory:
        return l10n.permissionSalesReportByCategory;
      case salesReportByCustomer:
        return l10n.permissionSalesReportByCustomer;
      case customerAccountStatement:
        return l10n.permissionCustomerAccountStatement;
      // Account Reports
      case supplierAccountStatement:
        return l10n.permissionSupplierAccountStatement;
      case customerBalancesReport:
        return l10n.permissionCustomerBalancesReport;
      case supplierBalancesReport:
        return l10n.permissionSupplierBalancesReport;
      case generalLedgerReport:
        return l10n.permissionGeneralLedgerReport;
      case accountBalancesReport:
        return l10n.permissionAccountBalancesReport;
      case profitReportForPeriod:
        return l10n.permissionProfitReportForPeriod;
      case incomeStatementReport:
        return l10n.permissionIncomeStatementReport;
      case viewReports:
        return l10n.permissionViewReports;
      default:
        // Fallback: format the key
        return key
            .split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
}
