// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Sales POS';

  @override
  String get signIn => 'Sign In';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get enterUsername => 'Enter your username';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get pointOfSale => 'Point of Sale';

  @override
  String get inventory => 'Inventory';

  @override
  String get settings => 'Settings';

  @override
  String get pos => 'POS';

  @override
  String get cart => 'Cart';

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get total => 'Total';

  @override
  String get processPayment => 'Process Payment';

  @override
  String get pay => 'Pay';

  @override
  String get clearCart => 'Clear Cart';

  @override
  String get searchProducts => 'Search Products';

  @override
  String get search => 'Search';

  @override
  String get addItem => 'Add Item';

  @override
  String get category => 'Category';

  @override
  String get all => 'All';

  @override
  String get totalItems => 'Total Items';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get categories => 'Categories';

  @override
  String get noItemsFound => 'No items found';

  @override
  String get price => 'Price';

  @override
  String get quantity => 'Quantity';

  @override
  String get each => 'each';

  @override
  String get lowStockLabel => 'Low Stock';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get addNewItem => 'Add New Item';

  @override
  String get itemAdded => 'Item added successfully';

  @override
  String get itemUpdated => 'Item updated successfully';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get notificationsDescription => 'Receive notifications for important updates';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get soundDescription => 'Play sound for transactions';

  @override
  String get autoPrintReceipts => 'Auto Print Receipts';

  @override
  String get autoPrintDescription => 'Automatically print receipts after payment';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get businessSettings => 'Business Settings';

  @override
  String get currency => 'Currency';

  @override
  String get taxSettings => 'Tax Settings';

  @override
  String get taxDescription => 'Configure tax rates and rules';

  @override
  String get receiptSettings => 'Receipt Settings';

  @override
  String get receiptDescription => 'Customize receipt template';

  @override
  String get systemSettings => 'System';

  @override
  String get backupRestore => 'Backup & Restore';

  @override
  String get backupDescription => 'Backup or restore your data';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get restoreFromBackup => 'Restore from Backup';

  @override
  String get backupCreated => 'Backup created successfully';

  @override
  String get about => 'About';

  @override
  String get aboutDescription => 'App version and information';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get clearDataDescription => 'Permanently delete all data';

  @override
  String get clearDataWarning => 'This action cannot be undone. All your data will be permanently deleted.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get user => 'User';

  @override
  String get cashier => 'Cashier';

  @override
  String get paymentMethod => 'Select Payment Method:';

  @override
  String get cash => 'Cash';

  @override
  String get card => 'Card';

  @override
  String paymentProcessed(String method) {
    return 'Payment processed via $method';
  }

  @override
  String get demoCredentials => 'Demo: Enter any username and password';

  @override
  String get pleaseEnterUsername => 'Please enter your username';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get pleaseEnterUsernameAndPassword => 'Please enter username and password';

  @override
  String get subCategory => 'Sub Category';

  @override
  String get subCategories => 'Sub Categories';

  @override
  String get items => 'Items';

  @override
  String get notes => 'Notes';

  @override
  String get hasNotes => 'Has Notes';

  @override
  String get noCategories => 'No categories.\nImport from Excel.';

  @override
  String get noSubcategories => 'No subcategories';

  @override
  String get noItems => 'No items';

  @override
  String get noNotes => 'No notes';

  @override
  String get importCategories => 'Import Categories';

  @override
  String get importSubCategories => 'Import Sub Categories';

  @override
  String get importItems => 'Import Items (Required)';

  @override
  String get importNotes => 'Import Notes';

  @override
  String get importFromExcel => 'Import from Excel';

  @override
  String get table => 'Table';

  @override
  String get tables => 'Tables';

  @override
  String get tableNumber => 'Table Number';

  @override
  String get takeaway => 'Takeaway';

  @override
  String get delivery => 'Delivery';

  @override
  String get hospitalityTable => 'Hospitality Table';

  @override
  String get selectTable => 'Select Table';

  @override
  String get reports => 'Reports';

  @override
  String get dailyReport => 'Daily Report';

  @override
  String get weeklyReport => 'Weekly Report';

  @override
  String get monthlyReport => 'Monthly Report';

  @override
  String get yearlyReport => 'Yearly Report';

  @override
  String get profitLoss => 'Profit & Loss';

  @override
  String get cashIn => 'Cash In';

  @override
  String get cashOut => 'Cash Out';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get totalCashIn => 'Total Cash In';

  @override
  String get totalCashOut => 'Total Cash Out';

  @override
  String get netProfit => 'Net Profit';

  @override
  String get netLoss => 'Net Loss';

  @override
  String get description => 'Description';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get transactionType => 'Transaction Type';

  @override
  String get addCashIn => 'Add Cash In';

  @override
  String get addCashOut => 'Add Cash Out';

  @override
  String get enterDescription => 'Enter description';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get salesReport => 'Sales Report';

  @override
  String get financialReport => 'Financial Report';

  @override
  String get fromDate => 'From Date';

  @override
  String get toDate => 'To Date';

  @override
  String get barcode => 'Barcode';

  @override
  String get totalQuantitySold => 'Total Quantity Sold';

  @override
  String get averageSellingPrice => 'Average Selling Price';

  @override
  String get totalValue => 'Total Value';

  @override
  String get grandTotals => 'Grand Totals';

  @override
  String get totalByType => 'Total by Type';

  @override
  String get totalByCategory => 'Total by Category';

  @override
  String get salesFromDate => 'Sales from Date';

  @override
  String get selectDate => 'Select Date';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get thisYear => 'This Year';

  @override
  String get noSalesFound => 'No sales found';

  @override
  String get noTransactionsFound => 'No transactions found';

  @override
  String get transactionAdded => 'Transaction added successfully';

  @override
  String get saleRecorded => 'Sale recorded successfully';

  @override
  String get id => 'ID';

  @override
  String get name => 'Name';

  @override
  String get payment => 'Payment';

  @override
  String get method => 'Method';

  @override
  String get selectPeriod => 'Select Period';

  @override
  String get period => 'Period';

  @override
  String get salesCount => 'Sales Count';

  @override
  String get averageSale => 'Average Sale';

  @override
  String get filter => 'Filter';

  @override
  String get reset => 'Reset';

  @override
  String get export => 'Export';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get balance => 'Balance';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get transactionDetails => 'Transaction Details';

  @override
  String get viewDetails => 'View Details';

  @override
  String get summary => 'Summary';

  @override
  String get transactions => 'Transactions';

  @override
  String get sales => 'Sales';

  @override
  String get allowPrinting => 'Allow Printing';

  @override
  String get printCustomerInvoice => 'Print Customer Invoice';

  @override
  String get printKitchenInvoice => 'Print Kitchen Invoice';

  @override
  String get invoice => 'Invoice';

  @override
  String get salesInvoice => 'Sales Invoice';

  @override
  String get orderNumber => 'Order Number';

  @override
  String get invoiceNumber => 'Invoice Number';

  @override
  String get waiter => 'Waiter';

  @override
  String get customer => 'Customer';

  @override
  String get phone => 'Phone';

  @override
  String get item => 'Item';

  @override
  String get value => 'Value';

  @override
  String get totalInvoice => 'Total Invoice';

  @override
  String get totalDiscount => 'Total Discount';

  @override
  String get service => 'Service';

  @override
  String get netInvoice => 'Net Invoice';

  @override
  String get welcome => 'Welcome';

  @override
  String get printerSettings => 'Printer Settings';

  @override
  String get printerName => 'Printer Name';

  @override
  String get paperSize => 'Paper Size';

  @override
  String get paperSource => 'Paper Source';

  @override
  String get orientation => 'Orientation';

  @override
  String get paperWidth => 'Paper Width';

  @override
  String get paperHeight => 'Paper Height';

  @override
  String get continuousPaper => 'Continuous (leave empty)';

  @override
  String get leaveEmptyForContinuous => 'Leave empty for continuous paper';

  @override
  String get noPrintersAvailable => 'No printers available';

  @override
  String get refresh => 'Refresh';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get portrait => 'Portrait';

  @override
  String get landscape => 'Landscape';

  @override
  String get configurePrinter => 'Configure Printer';

  @override
  String get printerConfigured => 'Printer configured successfully';

  @override
  String get printerConfigurationFailed => 'Failed to configure printer';

  @override
  String get printingCustomerInvoice => 'Printing customer invoice...';

  @override
  String get customerInvoicePrinted => 'Customer invoice printed successfully';

  @override
  String get errorPrintingCustomerInvoice => 'Error printing customer invoice';

  @override
  String get printingKitchenInvoice => 'Printing kitchen invoice...';

  @override
  String get kitchenInvoicePrinted => 'Kitchen invoice printed successfully';

  @override
  String get errorPrintingKitchenInvoice => 'Error printing kitchen invoice';

  @override
  String get saleRecordedButPrintFailed => 'Sale recorded but printing failed';

  @override
  String get addStock => 'Add Stock';

  @override
  String get selectItem => 'Select Item';

  @override
  String get enterQuantity => 'Enter Quantity';

  @override
  String get stockUpdated => 'Stock updated successfully';

  @override
  String get errorUpdatingStock => 'Error updating stock';

  @override
  String get pleaseSelectItem => 'Please select an item';

  @override
  String get pleaseEnterValidQuantity => 'Please enter a valid quantity';

  @override
  String get stockStatus => 'Stock Status';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get inStock => 'In Stock';

  @override
  String get conversionRate => 'Conversion Rate';

  @override
  String get enterConversionRate => 'Enter conversion rate (e.g., 1 kg = 80 cups, enter 80)';

  @override
  String get itemName => 'Item Name';

  @override
  String get enterItemName => 'Enter item name';

  @override
  String get selectSubCategory => 'Select Sub Category';

  @override
  String get enterPrice => 'Enter price';

  @override
  String get errorAddingItem => 'Error adding item';

  @override
  String get warehouses => 'Warehouses';

  @override
  String get accounts => 'Accounts';

  @override
  String get shiftClosingReport => 'Shift Closing Report';

  @override
  String get dailySalesReport => 'Daily Sales Report';

  @override
  String get salesReportByCategory => 'Sales Report by Category';

  @override
  String get salesReportByItem => 'Sales Report by Item';

  @override
  String get salesReportForCustomer => 'Sales Report for a Customer';

  @override
  String get consolidatedSalesReport => 'Consolidated Sales Report';

  @override
  String get inventoryCount => 'Inventory Count';

  @override
  String get inventoryCountByCategory => 'Inventory Count by Category';

  @override
  String get itemMovementReport => 'Item Movement Report';

  @override
  String get itemByMovementReport => 'Item by Movement Report';

  @override
  String get warehouseMovementReport => 'Warehouse Movement Report';

  @override
  String get supplierPurchasesReport => 'Supplier Purchases Report';

  @override
  String get customerAccountStatement => 'Customer Account Statement';

  @override
  String get customerBalancesReport => 'Customer Balances Report';

  @override
  String get supplierAccountStatement => 'Supplier Account Statement';

  @override
  String get supplierBalancesReport => 'Supplier Balances Report';

  @override
  String get generalLedgerReport => 'General Ledger Report';

  @override
  String get accountBalancesReport => 'Account Balances Report';

  @override
  String get incomeStatementReport => 'Income Statement Report';

  @override
  String get profitReportForPeriod => 'Profit Report for a Period';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get show => 'Show';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get discount => 'Discount';

  @override
  String get netSales => 'Net Sales';

  @override
  String get dineInService => 'Dine-in Service';

  @override
  String get deliveryService => 'Delivery Service';

  @override
  String get valueAddedTax => 'Value Added Tax';

  @override
  String get creditSales => 'Credit Sales and Revenues';

  @override
  String get visa => 'Visa';

  @override
  String get costOfSales => 'Cost of Sales';

  @override
  String get cashSales => 'Cash Sales';

  @override
  String get otherRevenues => 'Other Revenues';

  @override
  String get totalReceipts => 'Total Receipts';

  @override
  String get expensesAndPurchases => 'Expenses and Purchases';

  @override
  String get suppliesToSubTreasury => 'Supplies to Sub-treasury';

  @override
  String get totalPayments => 'Total Payments';

  @override
  String get netMovementForDay => 'Net Movement for the Day';

  @override
  String get previousBalance => 'Previous Balance';

  @override
  String get netCash => 'Net Cash';

  @override
  String get itemizedSales => 'Itemized Sales';

  @override
  String get totalCount => 'Total Count';

  @override
  String get importItemsButton => 'Import Items';

  @override
  String get optional => 'Optional';

  @override
  String get required => 'Required';

  @override
  String get addItemsOrImport => 'Add items or import from Excel';

  @override
  String get action => 'Action';

  @override
  String get unknown => 'Unknown';

  @override
  String get editItem => 'Edit Item';

  @override
  String get createNewCategory => 'Create New Category';

  @override
  String get createNewSubCategory => 'Create New Sub Category';

  @override
  String get newCategoryName => 'New Category Name';

  @override
  String get newSubCategoryName => 'New Sub Category Name';

  @override
  String get enterCategoryName => 'Enter category name';

  @override
  String get enterSubCategoryName => 'Enter sub category name';

  @override
  String get pleaseEnterCategoryName => 'Please enter category name';

  @override
  String get pleaseEnterSubCategoryName => 'Please enter sub category name';

  @override
  String itemsImportedSuccessfully(int count) {
    return 'Items imported successfully ($count items). These items are available in POS only.';
  }

  @override
  String get addNewMaterial => 'Add New Material';

  @override
  String get rawMaterialsManagement => 'Raw Materials Management';

  @override
  String get addNewRawMaterialsToInventory => 'Add new raw materials to your inventory';

  @override
  String get importRawMaterialsFromExcel => 'You can also import raw materials from Excel\nin the Settings screen';

  @override
  String get noSubcategoriesAvailable => 'No subcategories available. Please import subcategories first.';

  @override
  String get materialName => 'Material Name';

  @override
  String get enterMaterialName => 'Enter material name';

  @override
  String get unit => 'Unit:';

  @override
  String get pleaseEnterMaterialName => 'Please enter material name';

  @override
  String get materialAddedSuccessfully => 'Material added successfully';

  @override
  String errorAddingMaterial(String error) {
    return 'Error adding material: $error';
  }

  @override
  String get userManagement => 'User Management';

  @override
  String get devices => 'Devices';

  @override
  String get sync => 'Sync';

  @override
  String get account => 'Account';

  @override
  String get role => 'Role';

  @override
  String get loadingProfile => 'Loading profile...';

  @override
  String get notAuthenticated => 'Not authenticated';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutFromAccount => 'Sign out from your account';

  @override
  String get dataImport => 'Data Import';

  @override
  String get importRawMaterials => 'Import Raw Materials';

  @override
  String get createNewUser => 'Create New User';

  @override
  String get addUser => 'Add User';

  @override
  String get createNewUserAccount => 'Create a new user account';

  @override
  String get users => 'Users';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get changePassword => 'Change Password';

  @override
  String get managePermissions => 'Manage Permissions';

  @override
  String get promoteToAdmin => 'Promote to Admin';

  @override
  String get unknownState => 'Unknown state';

  @override
  String get deviceManagement => 'Device Management';

  @override
  String get loadingDevices => 'Loading devices...';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get syncStatusUnavailable => 'Sync status unavailable';

  @override
  String get syncServiceNotAvailable => 'Sync service not available';

  @override
  String get syncRequiresSupabase => 'Sync requires Supabase configuration for data synchronization';

  @override
  String get pleaseEnterValidVatRate => 'Please enter a valid VAT rate (0-100)';

  @override
  String get pleaseEnterValidServiceChargeRate => 'Please enter a valid service charge rate (0-100)';

  @override
  String get pleaseEnterValidDeliveryTaxRate => 'Please enter a valid delivery tax rate (0-100)';

  @override
  String get pleaseEnterValidHospitalityTaxRate => 'Please enter a valid hospitality tax rate (0-100)';

  @override
  String get settingsSavedSuccessfully => 'Settings saved successfully';

  @override
  String get failedToSaveSettings => 'Failed to save settings';

  @override
  String get restore => 'Restore';

  @override
  String get selectBackupDatabaseFile => 'Select Backup Database File';

  @override
  String get noFileSelected => 'No file selected';

  @override
  String get backupFileNotFound => 'Backup file not found';

  @override
  String get databaseRestoredSuccessfully => 'Database restored successfully';

  @override
  String get restoreComplete => 'Restore Complete';

  @override
  String get ok => 'OK';

  @override
  String errorRestoringBackup(String error) {
    return 'Error restoring backup: $error';
  }

  @override
  String get modernPointOfSaleSystem => 'A modern Point of Sale system for Windows.';

  @override
  String get copyright => '© 2024 Smart Sales. All rights reserved.';

  @override
  String get allDataCleared => 'All data cleared';

  @override
  String get failedToGetFilePath => 'Failed to get file path';

  @override
  String get masterDevice => 'Master Device';

  @override
  String masterDeviceId(String id) {
    return 'Master Device ID: $id...';
  }

  @override
  String get current => 'Current';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get allSynced => 'All synced';

  @override
  String get syncNow => 'Sync Now';

  @override
  String lastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get editMasterName => 'Edit Master Name';

  @override
  String get masterName => 'Master Name';

  @override
  String get areYouSureSignOut => 'Are you sure you want to sign out?';

  @override
  String areYouSurePromoteToAdmin(String username) {
    return 'Are you sure you want to promote \"$username\" to admin?';
  }

  @override
  String get promote => 'Promote';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get roleRequired => 'Role is required';

  @override
  String get userCreatedSuccessfully => 'User created successfully';

  @override
  String changePasswordForUser(String username) {
    return 'Change Password for $username';
  }

  @override
  String get newPassword => 'New Password';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get pleaseConfirmPassword => 'Please confirm password';

  @override
  String get passwordMinLength => 'Password must be at least 5 characters';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String errorChangingPassword(String error) {
    return 'Error changing password: $error';
  }

  @override
  String get customRole => 'Custom Role';

  @override
  String get enterCustomRole => 'Enter Custom Role';

  @override
  String get permissionsUpdatedSuccessfully => 'Permissions updated successfully';

  @override
  String errorLoadingUsers(String error) {
    return 'Error loading users: $error';
  }

  @override
  String get pleaseCreateAccountFirst => 'Please create an account first';

  @override
  String get selectUser => 'Select User';

  @override
  String get chooseUser => 'Choose user';

  @override
  String get pleaseSelectUser => 'Please select a user';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get selectUserAndEnterPassword => 'Select a user and enter password';

  @override
  String get passwordResetSuccessfully => 'Password reset successfully';

  @override
  String errorResettingPassword(String error) {
    return 'Error resetting password: $error';
  }

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get selectPermissionsForUser => 'Select permissions for this user:';

  @override
  String permissionsForUser(String username) {
    return 'Permissions: $username';
  }

  @override
  String get permissionModuleMainScreens => 'Main Screens';

  @override
  String get permissionModuleSettingsTabs => 'Settings Tabs';

  @override
  String get permissionModulePosFeatures => 'POS Features';

  @override
  String get permissionModuleFinancialFeatures => 'Financial Features';

  @override
  String get permissionModuleReportsFeatures => 'Reports Features';

  @override
  String get permissionModuleSettingsFeatures => 'Settings Features';

  @override
  String get permissionModulePermissions => 'Permissions';

  @override
  String get permissionModuleBasicData => 'Basic Data';

  @override
  String get permissionModuleInventory => 'Inventory';

  @override
  String get permissionModulePurchases => 'Purchases';

  @override
  String get permissionModuleVendors => 'Vendors';

  @override
  String get permissionModuleSalesInvoice => 'Sales Invoice';

  @override
  String get permissionModuleSalesReturns => 'Sales Returns';

  @override
  String get permissionModuleAccounts => 'Accounts';

  @override
  String get permissionModuleInventoryReports => 'Inventory Reports';

  @override
  String get permissionModulePurchaseReports => 'Purchase Reports';

  @override
  String get permissionModuleSalesReports => 'Sales Reports';

  @override
  String get permissionModuleAccountReports => 'Account Reports';

  @override
  String get permissionViewReports => 'View Reports';

  @override
  String get permissionUserPermissions => 'User Permissions';

  @override
  String get permissionAccessPosScreen => 'Access POS Screen';

  @override
  String get permissionAccessInventoryScreen => 'Access Inventory Screen';

  @override
  String get permissionAccessItemsScreen => 'Access Items Screen';

  @override
  String get permissionAccessReportsScreen => 'Access Reports Screen';

  @override
  String get permissionAccessFinancialScreen => 'Access Financial Screen';

  @override
  String get permissionAccessSettingsScreen => 'Access Settings Screen';

  @override
  String get permissionAccessGeneralSettings => 'Access General Settings';

  @override
  String get permissionAccessUserManagement => 'Access User Management';

  @override
  String get permissionAccessDeviceManagement => 'Access Device Management';

  @override
  String get permissionAccessSyncSettings => 'Access Sync Settings';

  @override
  String get permissionAccessSystemSettings => 'Access System Settings';

  @override
  String get permissionPosApplyDiscount => 'POS: Apply Discount';

  @override
  String get permissionPosProcessPayment => 'POS: Process Payment';

  @override
  String get permissionPosPrintInvoice => 'POS: Print Invoice';

  @override
  String get permissionPosSelectTable => 'POS: Select Table';

  @override
  String get permissionPosAccessHospitalityTable => 'POS: Access Hospitality Table';

  @override
  String get permissionPosClearCart => 'POS: Clear Cart';

  @override
  String get permissionPosViewCart => 'POS: View Cart';

  @override
  String get permissionFinancialAddCashIn => 'Financial: Add Cash In';

  @override
  String get permissionFinancialAddCashOut => 'Financial: Add Cash Out';

  @override
  String get permissionFinancialViewProfitLoss => 'Financial: View Profit/Loss';

  @override
  String get permissionFinancialViewTransactions => 'Financial: View Transactions';

  @override
  String get permissionFinancialCalculateProfitLoss => 'Financial: Calculate Profit/Loss';

  @override
  String get permissionReportsViewSalesReport => 'Reports: View Sales Report';

  @override
  String get permissionReportsViewFinancialReport => 'Reports: View Financial Report';

  @override
  String get permissionReportsExportReports => 'Reports: Export Reports';

  @override
  String get permissionReportsViewDailyReport => 'Reports: View Daily Report';

  @override
  String get permissionReportsViewWeeklyReport => 'Reports: View Weekly Report';

  @override
  String get permissionReportsViewMonthlyReport => 'Reports: View Monthly Report';

  @override
  String get permissionReportsViewYearlyReport => 'Reports: View Yearly Report';

  @override
  String get permissionSettingsCreateUser => 'Settings: Create User';

  @override
  String get permissionSettingsEditUser => 'Settings: Edit User';

  @override
  String get permissionSettingsDeleteUser => 'Settings: Delete User';

  @override
  String get permissionSettingsChangePassword => 'Settings: Change Password';

  @override
  String get permissionSettingsManagePermissions => 'Settings: Manage Permissions';

  @override
  String get permissionSettingsBackupRestore => 'Settings: Backup/Restore';

  @override
  String get permissionSettingsClearData => 'Settings: Clear Data';

  @override
  String get permissionSettingsImportData => 'Settings: Import Data';

  @override
  String get permissionSettingsExportData => 'Settings: Export Data';

  @override
  String get permissionSettingsConfigureTax => 'Settings: Configure Tax';

  @override
  String get permissionSettingsConfigurePrinter => 'Settings: Configure Printer';

  @override
  String get permissionBasicData => 'Basic Data';

  @override
  String get permissionAddEditItemsProducts => 'Add/Edit Items/Products';

  @override
  String get permissionRegisterOpeningBalance => 'Register Opening Balance';

  @override
  String get permissionRetrieveEditOpeningBalance => 'Retrieve/Edit Opening Balance';

  @override
  String get permissionRegisterTransfersToWarehouses => 'Register Transfers To Warehouses';

  @override
  String get permissionRegisterTransfersFromWarehouses => 'Register Transfers From Warehouses';

  @override
  String get permissionPrintBarcode => 'Print Barcode';

  @override
  String get permissionRegisterPurchaseInvoice => 'Register Purchase Invoice';

  @override
  String get permissionRetrieveEditPurchaseInvoice => 'Retrieve/Edit Purchase Invoice';

  @override
  String get permissionRegisterPurchaseReturns => 'Register Purchase Returns';

  @override
  String get permissionAddVendors => 'Add Vendors';

  @override
  String get permissionAdjustSalePrice => 'Adjust Sale Price';

  @override
  String get permissionRegisterSalesInvoice => 'Register Sales Invoice';

  @override
  String get permissionClearAllCurrentInvoice => 'Clear All Current Invoice';

  @override
  String get permissionClearItemCurrentInvoice => 'Clear Item Current Invoice';

  @override
  String get permissionChangeItemCurrentInvoice => 'Change Item Current Invoice';

  @override
  String get permissionChangeItemQuantityLess => 'Change Item Quantity Less';

  @override
  String get permissionDiscountInvoiceItems => 'Discount Invoice Items';

  @override
  String get permissionTemporaryPrintBeforeSave => 'Temporary Print Before Save';

  @override
  String get permissionInquireTreasuryBalance => 'Inquire Treasury Balance';

  @override
  String get permissionRetrieveEditSalesInvoice => 'Retrieve/Edit Sales Invoice';

  @override
  String get permissionRegisterSalesReturns => 'Register Sales Returns';

  @override
  String get permissionAddNewAccount => 'Add New Account';

  @override
  String get permissionRegisterCashReceipt => 'Register Cash Receipt';

  @override
  String get permissionRegisterCashDisbursement => 'Register Cash Disbursement';

  @override
  String get permissionRegisterAdjustmentEntries => 'Register Adjustment Entries';

  @override
  String get permissionInventoryCountReport => 'Inventory Count Report';

  @override
  String get permissionInventoryCountReportByCategory => 'Inventory Count Report By Category';

  @override
  String get permissionInventoryMovementReport => 'Inventory Movement Report';

  @override
  String get permissionItemMovementReport => 'Item Movement Report';

  @override
  String get permissionItemMovementReportByItem => 'Item Movement Report By Item';

  @override
  String get permissionPurchaseReportByVendor => 'Purchase Report By Vendor';

  @override
  String get permissionShiftPreferenceReport => 'Shift Preference Report';

  @override
  String get permissionDailySalesReport => 'Daily Sales Report';

  @override
  String get permissionAggregatedSalesReportByItems => 'Aggregated Sales Report By Items';

  @override
  String get permissionSalesReportByItem => 'Sales Report By Item';

  @override
  String get permissionSalesReportByCategory => 'Sales Report By Category';

  @override
  String get permissionSalesReportByCustomer => 'Sales Report By Customer';

  @override
  String get permissionCustomerAccountStatement => 'Customer Account Statement';

  @override
  String get permissionSupplierAccountStatement => 'Supplier Account Statement';

  @override
  String get permissionCustomerBalancesReport => 'Customer Balances Report';

  @override
  String get permissionSupplierBalancesReport => 'Supplier Balances Report';

  @override
  String get permissionGeneralLedgerReport => 'General Ledger Report';

  @override
  String get permissionAccountBalancesReport => 'Account Balances Report';

  @override
  String get permissionProfitReportForPeriod => 'Profit Report For Period';

  @override
  String get permissionIncomeStatementReport => 'Income Statement Report';

  @override
  String get macAddress => 'MAC Address';

  @override
  String get setAsMaster => 'Set as Master';

  @override
  String get deleteDevice => 'Delete Device';

  @override
  String get areYouSureDeleteDevice => 'Are you sure you want to delete this device?';

  @override
  String get deviceDeletedSuccessfully => 'Device deleted successfully';

  @override
  String get deviceSetAsMasterSuccessfully => 'Device set as master successfully';

  @override
  String get enterMacAddress => 'Enter MAC Address';

  @override
  String get macAddressRequired => 'MAC address is required';

  @override
  String get addDevice => 'Add Device';

  @override
  String get deviceName => 'Device Name';

  @override
  String get enterDeviceName => 'Enter device name';

  @override
  String get getMacAddress => 'Get MAC Address';

  @override
  String get deleteAllDevices => 'Delete All Devices';

  @override
  String get deleteAllDevicesDescription => 'Delete all devices except the current one';

  @override
  String get areYouSureDeleteAllDevices => 'Are you sure you want to delete all devices except the current one?';

  @override
  String get allDevicesDeletedSuccessfully => 'All devices deleted successfully';

  @override
  String get deviceNotAuthorized => 'Device not authorized. Please contact administrator to register this device.';

  @override
  String get deviceDeletedLogout => 'This device has been removed. You will be logged out.';

  @override
  String get manageDeviceFloors => 'Manage Device Floors';

  @override
  String get manageDeviceFloorsDescription => 'Assign devices to floors';

  @override
  String get selectDeviceAndFloor => 'Select device and assign floor number';

  @override
  String get floor => 'Floor';

  @override
  String get noFloor => 'No Floor';

  @override
  String get groundFloor => 'Ground Floor';

  @override
  String get secondFloor => 'Second Floor';

  @override
  String get thirdFloor => 'Third Floor';

  @override
  String get floorsUpdatedSuccessfully => 'Floors updated successfully';

  @override
  String get expiryDate => 'Expiry Date';

  @override
  String get editMaterial => 'Edit Material';

  @override
  String get addBatch => 'Add Batch';

  @override
  String get batchExpiryDate => 'Batch Expiry Date';

  @override
  String get materialQuantity => 'Material Quantity';

  @override
  String get materialUnit => 'Material Unit';

  @override
  String get pleaseEnterQuantity => 'Please enter quantity';

  @override
  String get pleaseSelectExpiryDate => 'Please select expiry date';

  @override
  String get batchAddedSuccessfully => 'Batch added successfully';

  @override
  String get batchUpdatedSuccessfully => 'Batch updated successfully';

  @override
  String get materialNameColumn => 'Material Name';

  @override
  String get quantityColumn => 'Quantity';

  @override
  String get expiryDateColumn => 'Expiry Date';

  @override
  String get recipe => 'Recipe';

  @override
  String get recipeManagement => 'Recipe Management';

  @override
  String get manageRecipe => 'Manage Recipe';

  @override
  String get recipeIngredients => 'Recipe Ingredients';

  @override
  String get addIngredient => 'Add Ingredient';

  @override
  String get selectRawMaterial => 'Select Raw Material';

  @override
  String get ingredientQuantity => 'Ingredient Quantity';

  @override
  String get pleaseSelectRawMaterial => 'Please select raw material';

  @override
  String get pleaseEnterIngredientQuantity => 'Please enter ingredient quantity';

  @override
  String get ingredientAddedSuccessfully => 'Ingredient added successfully';

  @override
  String get ingredientUpdatedSuccessfully => 'Ingredient updated successfully';

  @override
  String get ingredientDeletedSuccessfully => 'Ingredient deleted successfully';

  @override
  String get recipeCreatedSuccessfully => 'Recipe created successfully';

  @override
  String get recipeUpdatedSuccessfully => 'Recipe updated successfully';

  @override
  String get noRecipeFound => 'No recipe found for this product';

  @override
  String get createRecipe => 'Create Recipe';

  @override
  String get editIngredient => 'Edit Ingredient';

  @override
  String get deleteIngredient => 'Delete Ingredient';
}
