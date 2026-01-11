import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Smart Sales POS'**
  String get appTitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterUsername;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @pointOfSale.
  ///
  /// In en, this message translates to:
  /// **'Point of Sale'**
  String get pointOfSale;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @pos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get pos;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartEmpty;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @processPayment.
  ///
  /// In en, this message translates to:
  /// **'Process Payment'**
  String get processPayment;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search Products'**
  String get searchProducts;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @each.
  ///
  /// In en, this message translates to:
  /// **'each'**
  String get each;

  /// No description provided for @lowStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStockLabel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @addNewItem.
  ///
  /// In en, this message translates to:
  /// **'Add New Item'**
  String get addNewItem;

  /// No description provided for @itemAdded.
  ///
  /// In en, this message translates to:
  /// **'Item added successfully'**
  String get itemAdded;

  /// No description provided for @itemUpdated.
  ///
  /// In en, this message translates to:
  /// **'Item updated successfully'**
  String get itemUpdated;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @notificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications for important updates'**
  String get notificationsDescription;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// No description provided for @soundDescription.
  ///
  /// In en, this message translates to:
  /// **'Play sound for transactions'**
  String get soundDescription;

  /// No description provided for @autoPrintReceipts.
  ///
  /// In en, this message translates to:
  /// **'Auto Print Receipts'**
  String get autoPrintReceipts;

  /// No description provided for @autoPrintDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically print receipts after payment'**
  String get autoPrintDescription;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @businessSettings.
  ///
  /// In en, this message translates to:
  /// **'Business Settings'**
  String get businessSettings;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @taxSettings.
  ///
  /// In en, this message translates to:
  /// **'Tax Settings'**
  String get taxSettings;

  /// No description provided for @taxDescription.
  ///
  /// In en, this message translates to:
  /// **'Configure tax rates and rules'**
  String get taxDescription;

  /// No description provided for @receiptSettings.
  ///
  /// In en, this message translates to:
  /// **'Receipt Settings'**
  String get receiptSettings;

  /// No description provided for @receiptDescription.
  ///
  /// In en, this message translates to:
  /// **'Customize receipt template'**
  String get receiptDescription;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemSettings;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestore;

  /// No description provided for @backupDescription.
  ///
  /// In en, this message translates to:
  /// **'Backup or restore your data'**
  String get backupDescription;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackup;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get restoreFromBackup;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupCreated;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'App version and information'**
  String get aboutDescription;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @clearDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all data'**
  String get clearDataDescription;

  /// No description provided for @clearDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data will be permanently deleted.'**
  String get clearDataWarning;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @cashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get cashier;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method:'**
  String get paymentMethod;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @paymentProcessed.
  ///
  /// In en, this message translates to:
  /// **'Payment processed via {method}'**
  String paymentProcessed(String method);

  /// No description provided for @demoCredentials.
  ///
  /// In en, this message translates to:
  /// **'Demo: Enter any username and password'**
  String get demoCredentials;

  /// No description provided for @pleaseEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username'**
  String get pleaseEnterUsername;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseEnterUsernameAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter username and password'**
  String get pleaseEnterUsernameAndPassword;

  /// No description provided for @subCategory.
  ///
  /// In en, this message translates to:
  /// **'Sub Category'**
  String get subCategory;

  /// No description provided for @subCategories.
  ///
  /// In en, this message translates to:
  /// **'Sub Categories'**
  String get subCategories;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @hasNotes.
  ///
  /// In en, this message translates to:
  /// **'Has Notes'**
  String get hasNotes;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories.\nImport from Excel.'**
  String get noCategories;

  /// No description provided for @noSubcategories.
  ///
  /// In en, this message translates to:
  /// **'No subcategories'**
  String get noSubcategories;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItems;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get noNotes;

  /// No description provided for @importCategories.
  ///
  /// In en, this message translates to:
  /// **'Import Categories'**
  String get importCategories;

  /// No description provided for @importSubCategories.
  ///
  /// In en, this message translates to:
  /// **'Import Sub Categories'**
  String get importSubCategories;

  /// No description provided for @importItems.
  ///
  /// In en, this message translates to:
  /// **'Import Items (Required)'**
  String get importItems;

  /// No description provided for @importNotes.
  ///
  /// In en, this message translates to:
  /// **'Import Notes'**
  String get importNotes;

  /// No description provided for @importFromExcel.
  ///
  /// In en, this message translates to:
  /// **'Import from Excel'**
  String get importFromExcel;

  /// No description provided for @table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get table;

  /// No description provided for @tables.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get tables;

  /// No description provided for @tableNumber.
  ///
  /// In en, this message translates to:
  /// **'Table Number'**
  String get tableNumber;

  /// No description provided for @takeaway.
  ///
  /// In en, this message translates to:
  /// **'Takeaway'**
  String get takeaway;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @hospitalityTable.
  ///
  /// In en, this message translates to:
  /// **'Hospitality Table'**
  String get hospitalityTable;

  /// No description provided for @selectTable.
  ///
  /// In en, this message translates to:
  /// **'Select Table'**
  String get selectTable;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @dailyReport.
  ///
  /// In en, this message translates to:
  /// **'Daily Report'**
  String get dailyReport;

  /// No description provided for @weeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly Report'**
  String get weeklyReport;

  /// No description provided for @monthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get monthlyReport;

  /// No description provided for @yearlyReport.
  ///
  /// In en, this message translates to:
  /// **'Yearly Report'**
  String get yearlyReport;

  /// No description provided for @profitLoss.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss'**
  String get profitLoss;

  /// No description provided for @cashIn.
  ///
  /// In en, this message translates to:
  /// **'Cash In'**
  String get cashIn;

  /// No description provided for @cashOut.
  ///
  /// In en, this message translates to:
  /// **'Cash Out'**
  String get cashOut;

  /// No description provided for @totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSales;

  /// No description provided for @totalCashIn.
  ///
  /// In en, this message translates to:
  /// **'Total Cash In'**
  String get totalCashIn;

  /// No description provided for @totalCashOut.
  ///
  /// In en, this message translates to:
  /// **'Total Cash Out'**
  String get totalCashOut;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @netLoss.
  ///
  /// In en, this message translates to:
  /// **'Net Loss'**
  String get netLoss;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @addCashIn.
  ///
  /// In en, this message translates to:
  /// **'Add Cash In'**
  String get addCashIn;

  /// No description provided for @addCashOut.
  ///
  /// In en, this message translates to:
  /// **'Add Cash Out'**
  String get addCashOut;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @salesReport.
  ///
  /// In en, this message translates to:
  /// **'Sales Report'**
  String get salesReport;

  /// No description provided for @financialReport.
  ///
  /// In en, this message translates to:
  /// **'Financial Report'**
  String get financialReport;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get toDate;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @totalQuantitySold.
  ///
  /// In en, this message translates to:
  /// **'Total Quantity Sold'**
  String get totalQuantitySold;

  /// No description provided for @averageSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Average Selling Price'**
  String get averageSellingPrice;

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValue;

  /// No description provided for @grandTotals.
  ///
  /// In en, this message translates to:
  /// **'Grand Totals'**
  String get grandTotals;

  /// No description provided for @totalByType.
  ///
  /// In en, this message translates to:
  /// **'Total by Type'**
  String get totalByType;

  /// No description provided for @totalByCategory.
  ///
  /// In en, this message translates to:
  /// **'Total by Category'**
  String get totalByCategory;

  /// No description provided for @salesFromDate.
  ///
  /// In en, this message translates to:
  /// **'Sales from Date'**
  String get salesFromDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @noSalesFound.
  ///
  /// In en, this message translates to:
  /// **'No sales found'**
  String get noSalesFound;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFound;

  /// No description provided for @transactionAdded.
  ///
  /// In en, this message translates to:
  /// **'Transaction added successfully'**
  String get transactionAdded;

  /// No description provided for @saleRecorded.
  ///
  /// In en, this message translates to:
  /// **'Sale recorded successfully'**
  String get saleRecorded;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @selectPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Period'**
  String get selectPeriod;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @salesCount.
  ///
  /// In en, this message translates to:
  /// **'Sales Count'**
  String get salesCount;

  /// No description provided for @averageSale.
  ///
  /// In en, this message translates to:
  /// **'Average Sale'**
  String get averageSale;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @allowPrinting.
  ///
  /// In en, this message translates to:
  /// **'Allow Printing'**
  String get allowPrinting;

  /// No description provided for @printCustomerInvoice.
  ///
  /// In en, this message translates to:
  /// **'Print Customer Invoice'**
  String get printCustomerInvoice;

  /// No description provided for @printKitchenInvoice.
  ///
  /// In en, this message translates to:
  /// **'Print Kitchen Invoice'**
  String get printKitchenInvoice;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @salesInvoice.
  ///
  /// In en, this message translates to:
  /// **'Sales Invoice'**
  String get salesInvoice;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order Number'**
  String get orderNumber;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice Number'**
  String get invoiceNumber;

  /// No description provided for @waiter.
  ///
  /// In en, this message translates to:
  /// **'Waiter'**
  String get waiter;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @totalInvoice.
  ///
  /// In en, this message translates to:
  /// **'Total Invoice'**
  String get totalInvoice;

  /// No description provided for @totalDiscount.
  ///
  /// In en, this message translates to:
  /// **'Total Discount'**
  String get totalDiscount;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @netInvoice.
  ///
  /// In en, this message translates to:
  /// **'Net Invoice'**
  String get netInvoice;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @printerSettings.
  ///
  /// In en, this message translates to:
  /// **'Printer Settings'**
  String get printerSettings;

  /// No description provided for @printerName.
  ///
  /// In en, this message translates to:
  /// **'Printer Name'**
  String get printerName;

  /// No description provided for @paperSize.
  ///
  /// In en, this message translates to:
  /// **'Paper Size'**
  String get paperSize;

  /// No description provided for @paperSource.
  ///
  /// In en, this message translates to:
  /// **'Paper Source'**
  String get paperSource;

  /// No description provided for @orientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get orientation;

  /// No description provided for @paperWidth.
  ///
  /// In en, this message translates to:
  /// **'Paper Width'**
  String get paperWidth;

  /// No description provided for @paperHeight.
  ///
  /// In en, this message translates to:
  /// **'Paper Height'**
  String get paperHeight;

  /// No description provided for @continuousPaper.
  ///
  /// In en, this message translates to:
  /// **'Continuous (leave empty)'**
  String get continuousPaper;

  /// No description provided for @leaveEmptyForContinuous.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for continuous paper'**
  String get leaveEmptyForContinuous;

  /// No description provided for @noPrintersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No printers available'**
  String get noPrintersAvailable;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @portrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get portrait;

  /// No description provided for @landscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get landscape;

  /// No description provided for @configurePrinter.
  ///
  /// In en, this message translates to:
  /// **'Configure Printer'**
  String get configurePrinter;

  /// No description provided for @printerConfigured.
  ///
  /// In en, this message translates to:
  /// **'Printer configured successfully'**
  String get printerConfigured;

  /// No description provided for @printerConfigurationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to configure printer'**
  String get printerConfigurationFailed;

  /// No description provided for @printingCustomerInvoice.
  ///
  /// In en, this message translates to:
  /// **'Printing customer invoice...'**
  String get printingCustomerInvoice;

  /// No description provided for @customerInvoicePrinted.
  ///
  /// In en, this message translates to:
  /// **'Customer invoice printed successfully'**
  String get customerInvoicePrinted;

  /// No description provided for @errorPrintingCustomerInvoice.
  ///
  /// In en, this message translates to:
  /// **'Error printing customer invoice'**
  String get errorPrintingCustomerInvoice;

  /// No description provided for @printingKitchenInvoice.
  ///
  /// In en, this message translates to:
  /// **'Printing kitchen invoice...'**
  String get printingKitchenInvoice;

  /// No description provided for @kitchenInvoicePrinted.
  ///
  /// In en, this message translates to:
  /// **'Kitchen invoice printed successfully'**
  String get kitchenInvoicePrinted;

  /// No description provided for @errorPrintingKitchenInvoice.
  ///
  /// In en, this message translates to:
  /// **'Error printing kitchen invoice'**
  String get errorPrintingKitchenInvoice;

  /// No description provided for @saleRecordedButPrintFailed.
  ///
  /// In en, this message translates to:
  /// **'Sale recorded but printing failed'**
  String get saleRecordedButPrintFailed;

  /// No description provided for @addStock.
  ///
  /// In en, this message translates to:
  /// **'Add Stock'**
  String get addStock;

  /// No description provided for @selectItem.
  ///
  /// In en, this message translates to:
  /// **'Select Item'**
  String get selectItem;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter Quantity'**
  String get enterQuantity;

  /// No description provided for @stockUpdated.
  ///
  /// In en, this message translates to:
  /// **'Stock updated successfully'**
  String get stockUpdated;

  /// No description provided for @errorUpdatingStock.
  ///
  /// In en, this message translates to:
  /// **'Error updating stock'**
  String get errorUpdatingStock;

  /// No description provided for @pleaseSelectItem.
  ///
  /// In en, this message translates to:
  /// **'Please select an item'**
  String get pleaseSelectItem;

  /// No description provided for @pleaseEnterValidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid quantity'**
  String get pleaseEnterValidQuantity;

  /// No description provided for @stockStatus.
  ///
  /// In en, this message translates to:
  /// **'Stock Status'**
  String get stockStatus;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// No description provided for @conversionRate.
  ///
  /// In en, this message translates to:
  /// **'Conversion Rate'**
  String get conversionRate;

  /// No description provided for @enterConversionRate.
  ///
  /// In en, this message translates to:
  /// **'Enter conversion rate (e.g., 1 kg = 80 cups, enter 80)'**
  String get enterConversionRate;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @enterItemName.
  ///
  /// In en, this message translates to:
  /// **'Enter item name'**
  String get enterItemName;

  /// No description provided for @selectSubCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Sub Category'**
  String get selectSubCategory;

  /// No description provided for @enterPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter price'**
  String get enterPrice;

  /// No description provided for @errorAddingItem.
  ///
  /// In en, this message translates to:
  /// **'Error adding item'**
  String get errorAddingItem;

  /// No description provided for @warehouses.
  ///
  /// In en, this message translates to:
  /// **'Warehouses'**
  String get warehouses;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @shiftClosingReport.
  ///
  /// In en, this message translates to:
  /// **'Shift Closing Report'**
  String get shiftClosingReport;

  /// No description provided for @dailySalesReport.
  ///
  /// In en, this message translates to:
  /// **'Daily Sales Report'**
  String get dailySalesReport;

  /// No description provided for @salesReportByCategory.
  ///
  /// In en, this message translates to:
  /// **'Sales Report by Category'**
  String get salesReportByCategory;

  /// No description provided for @salesReportByItem.
  ///
  /// In en, this message translates to:
  /// **'Sales Report by Item'**
  String get salesReportByItem;

  /// No description provided for @salesReportForCustomer.
  ///
  /// In en, this message translates to:
  /// **'Sales Report for a Customer'**
  String get salesReportForCustomer;

  /// No description provided for @consolidatedSalesReport.
  ///
  /// In en, this message translates to:
  /// **'Consolidated Sales Report'**
  String get consolidatedSalesReport;

  /// No description provided for @inventoryCount.
  ///
  /// In en, this message translates to:
  /// **'Inventory Count'**
  String get inventoryCount;

  /// No description provided for @inventoryCountByCategory.
  ///
  /// In en, this message translates to:
  /// **'Inventory Count by Category'**
  String get inventoryCountByCategory;

  /// No description provided for @itemMovementReport.
  ///
  /// In en, this message translates to:
  /// **'Item Movement Report'**
  String get itemMovementReport;

  /// No description provided for @itemByMovementReport.
  ///
  /// In en, this message translates to:
  /// **'Item by Movement Report'**
  String get itemByMovementReport;

  /// No description provided for @warehouseMovementReport.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Movement Report'**
  String get warehouseMovementReport;

  /// No description provided for @supplierPurchasesReport.
  ///
  /// In en, this message translates to:
  /// **'Supplier Purchases Report'**
  String get supplierPurchasesReport;

  /// No description provided for @customerAccountStatement.
  ///
  /// In en, this message translates to:
  /// **'Customer Account Statement'**
  String get customerAccountStatement;

  /// No description provided for @customerBalancesReport.
  ///
  /// In en, this message translates to:
  /// **'Customer Balances Report'**
  String get customerBalancesReport;

  /// No description provided for @supplierAccountStatement.
  ///
  /// In en, this message translates to:
  /// **'Supplier Account Statement'**
  String get supplierAccountStatement;

  /// No description provided for @supplierBalancesReport.
  ///
  /// In en, this message translates to:
  /// **'Supplier Balances Report'**
  String get supplierBalancesReport;

  /// No description provided for @generalLedgerReport.
  ///
  /// In en, this message translates to:
  /// **'General Ledger Report'**
  String get generalLedgerReport;

  /// No description provided for @accountBalancesReport.
  ///
  /// In en, this message translates to:
  /// **'Account Balances Report'**
  String get accountBalancesReport;

  /// No description provided for @incomeStatementReport.
  ///
  /// In en, this message translates to:
  /// **'Income Statement Report'**
  String get incomeStatementReport;

  /// No description provided for @profitReportForPeriod.
  ///
  /// In en, this message translates to:
  /// **'Profit Report for a Period'**
  String get profitReportForPeriod;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @netSales.
  ///
  /// In en, this message translates to:
  /// **'Net Sales'**
  String get netSales;

  /// No description provided for @dineInService.
  ///
  /// In en, this message translates to:
  /// **'Dine-in Service'**
  String get dineInService;

  /// No description provided for @deliveryService.
  ///
  /// In en, this message translates to:
  /// **'Delivery Service'**
  String get deliveryService;

  /// No description provided for @valueAddedTax.
  ///
  /// In en, this message translates to:
  /// **'Value Added Tax'**
  String get valueAddedTax;

  /// No description provided for @creditSales.
  ///
  /// In en, this message translates to:
  /// **'Credit Sales and Revenues'**
  String get creditSales;

  /// No description provided for @visa.
  ///
  /// In en, this message translates to:
  /// **'Visa'**
  String get visa;

  /// No description provided for @costOfSales.
  ///
  /// In en, this message translates to:
  /// **'Cost of Sales'**
  String get costOfSales;

  /// No description provided for @cashSales.
  ///
  /// In en, this message translates to:
  /// **'Cash Sales'**
  String get cashSales;

  /// No description provided for @otherRevenues.
  ///
  /// In en, this message translates to:
  /// **'Other Revenues'**
  String get otherRevenues;

  /// No description provided for @totalReceipts.
  ///
  /// In en, this message translates to:
  /// **'Total Receipts'**
  String get totalReceipts;

  /// No description provided for @expensesAndPurchases.
  ///
  /// In en, this message translates to:
  /// **'Expenses and Purchases'**
  String get expensesAndPurchases;

  /// No description provided for @suppliesToSubTreasury.
  ///
  /// In en, this message translates to:
  /// **'Supplies to Sub-treasury'**
  String get suppliesToSubTreasury;

  /// No description provided for @totalPayments.
  ///
  /// In en, this message translates to:
  /// **'Total Payments'**
  String get totalPayments;

  /// No description provided for @netMovementForDay.
  ///
  /// In en, this message translates to:
  /// **'Net Movement for the Day'**
  String get netMovementForDay;

  /// No description provided for @previousBalance.
  ///
  /// In en, this message translates to:
  /// **'Previous Balance'**
  String get previousBalance;

  /// No description provided for @netCash.
  ///
  /// In en, this message translates to:
  /// **'Net Cash'**
  String get netCash;

  /// No description provided for @itemizedSales.
  ///
  /// In en, this message translates to:
  /// **'Itemized Sales'**
  String get itemizedSales;

  /// No description provided for @totalCount.
  ///
  /// In en, this message translates to:
  /// **'Total Count'**
  String get totalCount;

  /// No description provided for @importItemsButton.
  ///
  /// In en, this message translates to:
  /// **'Import Items'**
  String get importItemsButton;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @addItemsOrImport.
  ///
  /// In en, this message translates to:
  /// **'Add items or import from Excel'**
  String get addItemsOrImport;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItem;

  /// No description provided for @createNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Create New Category'**
  String get createNewCategory;

  /// No description provided for @createNewSubCategory.
  ///
  /// In en, this message translates to:
  /// **'Create New Sub Category'**
  String get createNewSubCategory;

  /// No description provided for @newCategoryName.
  ///
  /// In en, this message translates to:
  /// **'New Category Name'**
  String get newCategoryName;

  /// No description provided for @newSubCategoryName.
  ///
  /// In en, this message translates to:
  /// **'New Sub Category Name'**
  String get newSubCategoryName;

  /// No description provided for @enterCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Enter category name'**
  String get enterCategoryName;

  /// No description provided for @enterSubCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Enter sub category name'**
  String get enterSubCategoryName;

  /// No description provided for @pleaseEnterCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Please enter category name'**
  String get pleaseEnterCategoryName;

  /// No description provided for @pleaseEnterSubCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Please enter sub category name'**
  String get pleaseEnterSubCategoryName;

  /// No description provided for @itemsImportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Items imported successfully ({count} items). These items are available in POS only.'**
  String itemsImportedSuccessfully(int count);

  /// No description provided for @addNewMaterial.
  ///
  /// In en, this message translates to:
  /// **'Add New Material'**
  String get addNewMaterial;

  /// No description provided for @rawMaterialsManagement.
  ///
  /// In en, this message translates to:
  /// **'Raw Materials Management'**
  String get rawMaterialsManagement;

  /// No description provided for @addNewRawMaterialsToInventory.
  ///
  /// In en, this message translates to:
  /// **'Add new raw materials to your inventory'**
  String get addNewRawMaterialsToInventory;

  /// No description provided for @importRawMaterialsFromExcel.
  ///
  /// In en, this message translates to:
  /// **'You can also import raw materials from Excel\nin the Settings screen'**
  String get importRawMaterialsFromExcel;

  /// No description provided for @noSubcategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No subcategories available. Please import subcategories first.'**
  String get noSubcategoriesAvailable;

  /// No description provided for @materialName.
  ///
  /// In en, this message translates to:
  /// **'Material Name'**
  String get materialName;

  /// No description provided for @enterMaterialName.
  ///
  /// In en, this message translates to:
  /// **'Enter material name'**
  String get enterMaterialName;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit:'**
  String get unit;

  /// No description provided for @pleaseEnterMaterialName.
  ///
  /// In en, this message translates to:
  /// **'Please enter material name'**
  String get pleaseEnterMaterialName;

  /// No description provided for @materialAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Material added successfully'**
  String get materialAddedSuccessfully;

  /// No description provided for @errorAddingMaterial.
  ///
  /// In en, this message translates to:
  /// **'Error adding material: {error}'**
  String errorAddingMaterial(String error);

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get loadingProfile;

  /// No description provided for @notAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get notAuthenticated;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutFromAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out from your account'**
  String get signOutFromAccount;

  /// No description provided for @dataImport.
  ///
  /// In en, this message translates to:
  /// **'Data Import'**
  String get dataImport;

  /// No description provided for @importRawMaterials.
  ///
  /// In en, this message translates to:
  /// **'Import Raw Materials'**
  String get importRawMaterials;

  /// No description provided for @createNewUser.
  ///
  /// In en, this message translates to:
  /// **'Create New User'**
  String get createNewUser;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @createNewUserAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a new user account'**
  String get createNewUserAccount;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @managePermissions.
  ///
  /// In en, this message translates to:
  /// **'Manage Permissions'**
  String get managePermissions;

  /// No description provided for @promoteToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Promote to Admin'**
  String get promoteToAdmin;

  /// No description provided for @unknownState.
  ///
  /// In en, this message translates to:
  /// **'Unknown state'**
  String get unknownState;

  /// No description provided for @deviceManagement.
  ///
  /// In en, this message translates to:
  /// **'Device Management'**
  String get deviceManagement;

  /// No description provided for @loadingDevices.
  ///
  /// In en, this message translates to:
  /// **'Loading devices...'**
  String get loadingDevices;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @syncStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sync status unavailable'**
  String get syncStatusUnavailable;

  /// No description provided for @syncServiceNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Sync service not available'**
  String get syncServiceNotAvailable;

  /// No description provided for @syncRequiresSupabase.
  ///
  /// In en, this message translates to:
  /// **'Sync requires Supabase configuration for data synchronization'**
  String get syncRequiresSupabase;

  /// No description provided for @pleaseEnterValidVatRate.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid VAT rate (0-100)'**
  String get pleaseEnterValidVatRate;

  /// No description provided for @pleaseEnterValidServiceChargeRate.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid service charge rate (0-100)'**
  String get pleaseEnterValidServiceChargeRate;

  /// No description provided for @pleaseEnterValidDeliveryTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid delivery tax rate (0-100)'**
  String get pleaseEnterValidDeliveryTaxRate;

  /// No description provided for @pleaseEnterValidHospitalityTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid hospitality tax rate (0-100)'**
  String get pleaseEnterValidHospitalityTaxRate;

  /// No description provided for @settingsSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSavedSuccessfully;

  /// No description provided for @failedToSaveSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to save settings'**
  String get failedToSaveSettings;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @selectBackupDatabaseFile.
  ///
  /// In en, this message translates to:
  /// **'Select Backup Database File'**
  String get selectBackupDatabaseFile;

  /// No description provided for @noFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get noFileSelected;

  /// No description provided for @backupFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Backup file not found'**
  String get backupFileNotFound;

  /// No description provided for @databaseRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Database restored successfully'**
  String get databaseRestoredSuccessfully;

  /// No description provided for @restoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restore Complete'**
  String get restoreComplete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @errorRestoringBackup.
  ///
  /// In en, this message translates to:
  /// **'Error restoring backup: {error}'**
  String errorRestoringBackup(String error);

  /// No description provided for @modernPointOfSaleSystem.
  ///
  /// In en, this message translates to:
  /// **'A modern Point of Sale system for Windows.'**
  String get modernPointOfSaleSystem;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2024 Smart Sales. All rights reserved.'**
  String get copyright;

  /// No description provided for @allDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data cleared'**
  String get allDataCleared;

  /// No description provided for @failedToGetFilePath.
  ///
  /// In en, this message translates to:
  /// **'Failed to get file path'**
  String get failedToGetFilePath;

  /// No description provided for @masterDevice.
  ///
  /// In en, this message translates to:
  /// **'Master Device'**
  String get masterDevice;

  /// No description provided for @masterDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Master Device ID: {id}...'**
  String masterDeviceId(String id);

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @allSynced.
  ///
  /// In en, this message translates to:
  /// **'All synced'**
  String get allSynced;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String lastSync(String time);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @editMasterName.
  ///
  /// In en, this message translates to:
  /// **'Edit Master Name'**
  String get editMasterName;

  /// No description provided for @masterName.
  ///
  /// In en, this message translates to:
  /// **'Master Name'**
  String get masterName;

  /// No description provided for @areYouSureSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get areYouSureSignOut;

  /// No description provided for @areYouSurePromoteToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to promote \"{username}\" to admin?'**
  String areYouSurePromoteToAdmin(String username);

  /// No description provided for @promote.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get promote;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @roleRequired.
  ///
  /// In en, this message translates to:
  /// **'Role is required'**
  String get roleRequired;

  /// No description provided for @userCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User created successfully'**
  String get userCreatedSuccessfully;

  /// No description provided for @changePasswordForUser.
  ///
  /// In en, this message translates to:
  /// **'Change Password for {username}'**
  String changePasswordForUser(String username);

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 5 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @errorChangingPassword.
  ///
  /// In en, this message translates to:
  /// **'Error changing password: {error}'**
  String errorChangingPassword(String error);

  /// No description provided for @customRole.
  ///
  /// In en, this message translates to:
  /// **'Custom Role'**
  String get customRole;

  /// No description provided for @enterCustomRole.
  ///
  /// In en, this message translates to:
  /// **'Enter Custom Role'**
  String get enterCustomRole;

  /// No description provided for @permissionsUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Permissions updated successfully'**
  String get permissionsUpdatedSuccessfully;

  /// No description provided for @errorLoadingUsers.
  ///
  /// In en, this message translates to:
  /// **'Error loading users: {error}'**
  String errorLoadingUsers(String error);

  /// No description provided for @pleaseCreateAccountFirst.
  ///
  /// In en, this message translates to:
  /// **'Please create an account first'**
  String get pleaseCreateAccountFirst;

  /// No description provided for @selectUser.
  ///
  /// In en, this message translates to:
  /// **'Select User'**
  String get selectUser;

  /// No description provided for @chooseUser.
  ///
  /// In en, this message translates to:
  /// **'Choose user'**
  String get chooseUser;

  /// No description provided for @pleaseSelectUser.
  ///
  /// In en, this message translates to:
  /// **'Please select a user'**
  String get pleaseSelectUser;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @selectUserAndEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Select a user and enter password'**
  String get selectUserAndEnterPassword;

  /// No description provided for @passwordResetSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get passwordResetSuccessfully;

  /// No description provided for @errorResettingPassword.
  ///
  /// In en, this message translates to:
  /// **'Error resetting password: {error}'**
  String errorResettingPassword(String error);

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @selectPermissionsForUser.
  ///
  /// In en, this message translates to:
  /// **'Select permissions for this user:'**
  String get selectPermissionsForUser;

  /// No description provided for @permissionsForUser.
  ///
  /// In en, this message translates to:
  /// **'Permissions: {username}'**
  String permissionsForUser(String username);

  /// No description provided for @permissionModuleMainScreens.
  ///
  /// In en, this message translates to:
  /// **'Main Screens'**
  String get permissionModuleMainScreens;

  /// No description provided for @permissionModuleSettingsTabs.
  ///
  /// In en, this message translates to:
  /// **'Settings Tabs'**
  String get permissionModuleSettingsTabs;

  /// No description provided for @permissionModulePosFeatures.
  ///
  /// In en, this message translates to:
  /// **'POS Features'**
  String get permissionModulePosFeatures;

  /// No description provided for @permissionModuleFinancialFeatures.
  ///
  /// In en, this message translates to:
  /// **'Financial Features'**
  String get permissionModuleFinancialFeatures;

  /// No description provided for @permissionModuleReportsFeatures.
  ///
  /// In en, this message translates to:
  /// **'Reports Features'**
  String get permissionModuleReportsFeatures;

  /// No description provided for @permissionModuleSettingsFeatures.
  ///
  /// In en, this message translates to:
  /// **'Settings Features'**
  String get permissionModuleSettingsFeatures;

  /// No description provided for @permissionModulePermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionModulePermissions;

  /// No description provided for @permissionModuleBasicData.
  ///
  /// In en, this message translates to:
  /// **'Basic Data'**
  String get permissionModuleBasicData;

  /// No description provided for @permissionModuleInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get permissionModuleInventory;

  /// No description provided for @permissionModulePurchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get permissionModulePurchases;

  /// No description provided for @permissionModuleVendors.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get permissionModuleVendors;

  /// No description provided for @permissionModuleSalesInvoice.
  ///
  /// In en, this message translates to:
  /// **'Sales Invoice'**
  String get permissionModuleSalesInvoice;

  /// No description provided for @permissionModuleSalesReturns.
  ///
  /// In en, this message translates to:
  /// **'Sales Returns'**
  String get permissionModuleSalesReturns;

  /// No description provided for @permissionModuleAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get permissionModuleAccounts;

  /// No description provided for @permissionModuleInventoryReports.
  ///
  /// In en, this message translates to:
  /// **'Inventory Reports'**
  String get permissionModuleInventoryReports;

  /// No description provided for @permissionModulePurchaseReports.
  ///
  /// In en, this message translates to:
  /// **'Purchase Reports'**
  String get permissionModulePurchaseReports;

  /// No description provided for @permissionModuleSalesReports.
  ///
  /// In en, this message translates to:
  /// **'Sales Reports'**
  String get permissionModuleSalesReports;

  /// No description provided for @permissionModuleAccountReports.
  ///
  /// In en, this message translates to:
  /// **'Account Reports'**
  String get permissionModuleAccountReports;

  /// No description provided for @permissionViewReports.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get permissionViewReports;

  /// No description provided for @permissionUserPermissions.
  ///
  /// In en, this message translates to:
  /// **'User Permissions'**
  String get permissionUserPermissions;

  /// No description provided for @permissionAccessPosScreen.
  ///
  /// In en, this message translates to:
  /// **'Access POS Screen'**
  String get permissionAccessPosScreen;

  /// No description provided for @permissionAccessInventoryScreen.
  ///
  /// In en, this message translates to:
  /// **'Access Inventory Screen'**
  String get permissionAccessInventoryScreen;

  /// No description provided for @permissionAccessItemsScreen.
  ///
  /// In en, this message translates to:
  /// **'Access Items Screen'**
  String get permissionAccessItemsScreen;

  /// No description provided for @permissionAccessReportsScreen.
  ///
  /// In en, this message translates to:
  /// **'Access Reports Screen'**
  String get permissionAccessReportsScreen;

  /// No description provided for @permissionAccessFinancialScreen.
  ///
  /// In en, this message translates to:
  /// **'Access Financial Screen'**
  String get permissionAccessFinancialScreen;

  /// No description provided for @permissionAccessSettingsScreen.
  ///
  /// In en, this message translates to:
  /// **'Access Settings Screen'**
  String get permissionAccessSettingsScreen;

  /// No description provided for @permissionAccessGeneralSettings.
  ///
  /// In en, this message translates to:
  /// **'Access General Settings'**
  String get permissionAccessGeneralSettings;

  /// No description provided for @permissionAccessUserManagement.
  ///
  /// In en, this message translates to:
  /// **'Access User Management'**
  String get permissionAccessUserManagement;

  /// No description provided for @permissionAccessDeviceManagement.
  ///
  /// In en, this message translates to:
  /// **'Access Device Management'**
  String get permissionAccessDeviceManagement;

  /// No description provided for @permissionAccessSyncSettings.
  ///
  /// In en, this message translates to:
  /// **'Access Sync Settings'**
  String get permissionAccessSyncSettings;

  /// No description provided for @permissionAccessSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Access System Settings'**
  String get permissionAccessSystemSettings;

  /// No description provided for @permissionPosApplyDiscount.
  ///
  /// In en, this message translates to:
  /// **'POS: Apply Discount'**
  String get permissionPosApplyDiscount;

  /// No description provided for @permissionPosProcessPayment.
  ///
  /// In en, this message translates to:
  /// **'POS: Process Payment'**
  String get permissionPosProcessPayment;

  /// No description provided for @permissionPosPrintInvoice.
  ///
  /// In en, this message translates to:
  /// **'POS: Print Invoice'**
  String get permissionPosPrintInvoice;

  /// No description provided for @permissionPosSelectTable.
  ///
  /// In en, this message translates to:
  /// **'POS: Select Table'**
  String get permissionPosSelectTable;

  /// No description provided for @permissionPosAccessHospitalityTable.
  ///
  /// In en, this message translates to:
  /// **'POS: Access Hospitality Table'**
  String get permissionPosAccessHospitalityTable;

  /// No description provided for @permissionPosClearCart.
  ///
  /// In en, this message translates to:
  /// **'POS: Clear Cart'**
  String get permissionPosClearCart;

  /// No description provided for @permissionPosViewCart.
  ///
  /// In en, this message translates to:
  /// **'POS: View Cart'**
  String get permissionPosViewCart;

  /// No description provided for @permissionFinancialAddCashIn.
  ///
  /// In en, this message translates to:
  /// **'Financial: Add Cash In'**
  String get permissionFinancialAddCashIn;

  /// No description provided for @permissionFinancialAddCashOut.
  ///
  /// In en, this message translates to:
  /// **'Financial: Add Cash Out'**
  String get permissionFinancialAddCashOut;

  /// No description provided for @permissionFinancialViewProfitLoss.
  ///
  /// In en, this message translates to:
  /// **'Financial: View Profit/Loss'**
  String get permissionFinancialViewProfitLoss;

  /// No description provided for @permissionFinancialViewTransactions.
  ///
  /// In en, this message translates to:
  /// **'Financial: View Transactions'**
  String get permissionFinancialViewTransactions;

  /// No description provided for @permissionFinancialCalculateProfitLoss.
  ///
  /// In en, this message translates to:
  /// **'Financial: Calculate Profit/Loss'**
  String get permissionFinancialCalculateProfitLoss;

  /// No description provided for @permissionReportsViewSalesReport.
  ///
  /// In en, this message translates to:
  /// **'Reports: View Sales Report'**
  String get permissionReportsViewSalesReport;

  /// No description provided for @permissionReportsViewFinancialReport.
  ///
  /// In en, this message translates to:
  /// **'Reports: View Financial Report'**
  String get permissionReportsViewFinancialReport;

  /// No description provided for @permissionReportsExportReports.
  ///
  /// In en, this message translates to:
  /// **'Reports: Export Reports'**
  String get permissionReportsExportReports;

  /// No description provided for @permissionReportsViewDailyReport.
  ///
  /// In en, this message translates to:
  /// **'Reports: View Daily Report'**
  String get permissionReportsViewDailyReport;

  /// No description provided for @permissionReportsViewWeeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Reports: View Weekly Report'**
  String get permissionReportsViewWeeklyReport;

  /// No description provided for @permissionReportsViewMonthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Reports: View Monthly Report'**
  String get permissionReportsViewMonthlyReport;

  /// No description provided for @permissionReportsViewYearlyReport.
  ///
  /// In en, this message translates to:
  /// **'Reports: View Yearly Report'**
  String get permissionReportsViewYearlyReport;

  /// No description provided for @permissionSettingsCreateUser.
  ///
  /// In en, this message translates to:
  /// **'Settings: Create User'**
  String get permissionSettingsCreateUser;

  /// No description provided for @permissionSettingsEditUser.
  ///
  /// In en, this message translates to:
  /// **'Settings: Edit User'**
  String get permissionSettingsEditUser;

  /// No description provided for @permissionSettingsDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Settings: Delete User'**
  String get permissionSettingsDeleteUser;

  /// No description provided for @permissionSettingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Settings: Change Password'**
  String get permissionSettingsChangePassword;

  /// No description provided for @permissionSettingsManagePermissions.
  ///
  /// In en, this message translates to:
  /// **'Settings: Manage Permissions'**
  String get permissionSettingsManagePermissions;

  /// No description provided for @permissionSettingsBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Settings: Backup/Restore'**
  String get permissionSettingsBackupRestore;

  /// No description provided for @permissionSettingsClearData.
  ///
  /// In en, this message translates to:
  /// **'Settings: Clear Data'**
  String get permissionSettingsClearData;

  /// No description provided for @permissionSettingsImportData.
  ///
  /// In en, this message translates to:
  /// **'Settings: Import Data'**
  String get permissionSettingsImportData;

  /// No description provided for @permissionSettingsExportData.
  ///
  /// In en, this message translates to:
  /// **'Settings: Export Data'**
  String get permissionSettingsExportData;

  /// No description provided for @permissionSettingsConfigureTax.
  ///
  /// In en, this message translates to:
  /// **'Settings: Configure Tax'**
  String get permissionSettingsConfigureTax;

  /// No description provided for @permissionSettingsConfigurePrinter.
  ///
  /// In en, this message translates to:
  /// **'Settings: Configure Printer'**
  String get permissionSettingsConfigurePrinter;

  /// No description provided for @permissionBasicData.
  ///
  /// In en, this message translates to:
  /// **'Basic Data'**
  String get permissionBasicData;

  /// No description provided for @permissionAddEditItemsProducts.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit Items/Products'**
  String get permissionAddEditItemsProducts;

  /// No description provided for @permissionRegisterOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Register Opening Balance'**
  String get permissionRegisterOpeningBalance;

  /// No description provided for @permissionRetrieveEditOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Retrieve/Edit Opening Balance'**
  String get permissionRetrieveEditOpeningBalance;

  /// No description provided for @permissionRegisterTransfersToWarehouses.
  ///
  /// In en, this message translates to:
  /// **'Register Transfers To Warehouses'**
  String get permissionRegisterTransfersToWarehouses;

  /// No description provided for @permissionRegisterTransfersFromWarehouses.
  ///
  /// In en, this message translates to:
  /// **'Register Transfers From Warehouses'**
  String get permissionRegisterTransfersFromWarehouses;

  /// No description provided for @permissionPrintBarcode.
  ///
  /// In en, this message translates to:
  /// **'Print Barcode'**
  String get permissionPrintBarcode;

  /// No description provided for @permissionRegisterPurchaseInvoice.
  ///
  /// In en, this message translates to:
  /// **'Register Purchase Invoice'**
  String get permissionRegisterPurchaseInvoice;

  /// No description provided for @permissionRetrieveEditPurchaseInvoice.
  ///
  /// In en, this message translates to:
  /// **'Retrieve/Edit Purchase Invoice'**
  String get permissionRetrieveEditPurchaseInvoice;

  /// No description provided for @permissionRegisterPurchaseReturns.
  ///
  /// In en, this message translates to:
  /// **'Register Purchase Returns'**
  String get permissionRegisterPurchaseReturns;

  /// No description provided for @permissionAddVendors.
  ///
  /// In en, this message translates to:
  /// **'Add Vendors'**
  String get permissionAddVendors;

  /// No description provided for @permissionAdjustSalePrice.
  ///
  /// In en, this message translates to:
  /// **'Adjust Sale Price'**
  String get permissionAdjustSalePrice;

  /// No description provided for @permissionRegisterSalesInvoice.
  ///
  /// In en, this message translates to:
  /// **'Register Sales Invoice'**
  String get permissionRegisterSalesInvoice;

  /// No description provided for @permissionClearAllCurrentInvoice.
  ///
  /// In en, this message translates to:
  /// **'Clear All Current Invoice'**
  String get permissionClearAllCurrentInvoice;

  /// No description provided for @permissionClearItemCurrentInvoice.
  ///
  /// In en, this message translates to:
  /// **'Clear Item Current Invoice'**
  String get permissionClearItemCurrentInvoice;

  /// No description provided for @permissionChangeItemCurrentInvoice.
  ///
  /// In en, this message translates to:
  /// **'Change Item Current Invoice'**
  String get permissionChangeItemCurrentInvoice;

  /// No description provided for @permissionChangeItemQuantityLess.
  ///
  /// In en, this message translates to:
  /// **'Change Item Quantity Less'**
  String get permissionChangeItemQuantityLess;

  /// No description provided for @permissionDiscountInvoiceItems.
  ///
  /// In en, this message translates to:
  /// **'Discount Invoice Items'**
  String get permissionDiscountInvoiceItems;

  /// No description provided for @permissionTemporaryPrintBeforeSave.
  ///
  /// In en, this message translates to:
  /// **'Temporary Print Before Save'**
  String get permissionTemporaryPrintBeforeSave;

  /// No description provided for @permissionInquireTreasuryBalance.
  ///
  /// In en, this message translates to:
  /// **'Inquire Treasury Balance'**
  String get permissionInquireTreasuryBalance;

  /// No description provided for @permissionRetrieveEditSalesInvoice.
  ///
  /// In en, this message translates to:
  /// **'Retrieve/Edit Sales Invoice'**
  String get permissionRetrieveEditSalesInvoice;

  /// No description provided for @permissionRegisterSalesReturns.
  ///
  /// In en, this message translates to:
  /// **'Register Sales Returns'**
  String get permissionRegisterSalesReturns;

  /// No description provided for @permissionAddNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Add New Account'**
  String get permissionAddNewAccount;

  /// No description provided for @permissionRegisterCashReceipt.
  ///
  /// In en, this message translates to:
  /// **'Register Cash Receipt'**
  String get permissionRegisterCashReceipt;

  /// No description provided for @permissionRegisterCashDisbursement.
  ///
  /// In en, this message translates to:
  /// **'Register Cash Disbursement'**
  String get permissionRegisterCashDisbursement;

  /// No description provided for @permissionRegisterAdjustmentEntries.
  ///
  /// In en, this message translates to:
  /// **'Register Adjustment Entries'**
  String get permissionRegisterAdjustmentEntries;

  /// No description provided for @permissionInventoryCountReport.
  ///
  /// In en, this message translates to:
  /// **'Inventory Count Report'**
  String get permissionInventoryCountReport;

  /// No description provided for @permissionInventoryCountReportByCategory.
  ///
  /// In en, this message translates to:
  /// **'Inventory Count Report By Category'**
  String get permissionInventoryCountReportByCategory;

  /// No description provided for @permissionInventoryMovementReport.
  ///
  /// In en, this message translates to:
  /// **'Inventory Movement Report'**
  String get permissionInventoryMovementReport;

  /// No description provided for @permissionItemMovementReport.
  ///
  /// In en, this message translates to:
  /// **'Item Movement Report'**
  String get permissionItemMovementReport;

  /// No description provided for @permissionItemMovementReportByItem.
  ///
  /// In en, this message translates to:
  /// **'Item Movement Report By Item'**
  String get permissionItemMovementReportByItem;

  /// No description provided for @permissionPurchaseReportByVendor.
  ///
  /// In en, this message translates to:
  /// **'Purchase Report By Vendor'**
  String get permissionPurchaseReportByVendor;

  /// No description provided for @permissionShiftPreferenceReport.
  ///
  /// In en, this message translates to:
  /// **'Shift Preference Report'**
  String get permissionShiftPreferenceReport;

  /// No description provided for @permissionDailySalesReport.
  ///
  /// In en, this message translates to:
  /// **'Daily Sales Report'**
  String get permissionDailySalesReport;

  /// No description provided for @permissionAggregatedSalesReportByItems.
  ///
  /// In en, this message translates to:
  /// **'Aggregated Sales Report By Items'**
  String get permissionAggregatedSalesReportByItems;

  /// No description provided for @permissionSalesReportByItem.
  ///
  /// In en, this message translates to:
  /// **'Sales Report By Item'**
  String get permissionSalesReportByItem;

  /// No description provided for @permissionSalesReportByCategory.
  ///
  /// In en, this message translates to:
  /// **'Sales Report By Category'**
  String get permissionSalesReportByCategory;

  /// No description provided for @permissionSalesReportByCustomer.
  ///
  /// In en, this message translates to:
  /// **'Sales Report By Customer'**
  String get permissionSalesReportByCustomer;

  /// No description provided for @permissionCustomerAccountStatement.
  ///
  /// In en, this message translates to:
  /// **'Customer Account Statement'**
  String get permissionCustomerAccountStatement;

  /// No description provided for @permissionSupplierAccountStatement.
  ///
  /// In en, this message translates to:
  /// **'Supplier Account Statement'**
  String get permissionSupplierAccountStatement;

  /// No description provided for @permissionCustomerBalancesReport.
  ///
  /// In en, this message translates to:
  /// **'Customer Balances Report'**
  String get permissionCustomerBalancesReport;

  /// No description provided for @permissionSupplierBalancesReport.
  ///
  /// In en, this message translates to:
  /// **'Supplier Balances Report'**
  String get permissionSupplierBalancesReport;

  /// No description provided for @permissionGeneralLedgerReport.
  ///
  /// In en, this message translates to:
  /// **'General Ledger Report'**
  String get permissionGeneralLedgerReport;

  /// No description provided for @permissionAccountBalancesReport.
  ///
  /// In en, this message translates to:
  /// **'Account Balances Report'**
  String get permissionAccountBalancesReport;

  /// No description provided for @permissionProfitReportForPeriod.
  ///
  /// In en, this message translates to:
  /// **'Profit Report For Period'**
  String get permissionProfitReportForPeriod;

  /// No description provided for @permissionIncomeStatementReport.
  ///
  /// In en, this message translates to:
  /// **'Income Statement Report'**
  String get permissionIncomeStatementReport;

  /// No description provided for @macAddress.
  ///
  /// In en, this message translates to:
  /// **'MAC Address'**
  String get macAddress;

  /// No description provided for @setAsMaster.
  ///
  /// In en, this message translates to:
  /// **'Set as Master'**
  String get setAsMaster;

  /// No description provided for @deleteDevice.
  ///
  /// In en, this message translates to:
  /// **'Delete Device'**
  String get deleteDevice;

  /// No description provided for @areYouSureDeleteDevice.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this device?'**
  String get areYouSureDeleteDevice;

  /// No description provided for @deviceDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Device deleted successfully'**
  String get deviceDeletedSuccessfully;

  /// No description provided for @deviceSetAsMasterSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Device set as master successfully'**
  String get deviceSetAsMasterSuccessfully;

  /// No description provided for @enterMacAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter MAC Address'**
  String get enterMacAddress;

  /// No description provided for @macAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'MAC address is required'**
  String get macAddressRequired;

  /// No description provided for @addDevice.
  ///
  /// In en, this message translates to:
  /// **'Add Device'**
  String get addDevice;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceName;

  /// No description provided for @enterDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Enter device name'**
  String get enterDeviceName;

  /// No description provided for @getMacAddress.
  ///
  /// In en, this message translates to:
  /// **'Get MAC Address'**
  String get getMacAddress;

  /// No description provided for @deleteAllDevices.
  ///
  /// In en, this message translates to:
  /// **'Delete All Devices'**
  String get deleteAllDevices;

  /// No description provided for @deleteAllDevicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Delete all devices except the current one'**
  String get deleteAllDevicesDescription;

  /// No description provided for @areYouSureDeleteAllDevices.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all devices except the current one?'**
  String get areYouSureDeleteAllDevices;

  /// No description provided for @allDevicesDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'All devices deleted successfully'**
  String get allDevicesDeletedSuccessfully;

  /// No description provided for @deviceNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Device not authorized. Please contact administrator to register this device.'**
  String get deviceNotAuthorized;

  /// No description provided for @deviceDeletedLogout.
  ///
  /// In en, this message translates to:
  /// **'This device has been removed. You will be logged out.'**
  String get deviceDeletedLogout;

  /// No description provided for @manageDeviceFloors.
  ///
  /// In en, this message translates to:
  /// **'Manage Device Floors'**
  String get manageDeviceFloors;

  /// No description provided for @manageDeviceFloorsDescription.
  ///
  /// In en, this message translates to:
  /// **'Assign devices to floors'**
  String get manageDeviceFloorsDescription;

  /// No description provided for @selectDeviceAndFloor.
  ///
  /// In en, this message translates to:
  /// **'Select device and assign floor number'**
  String get selectDeviceAndFloor;

  /// No description provided for @floor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floor;

  /// No description provided for @noFloor.
  ///
  /// In en, this message translates to:
  /// **'No Floor'**
  String get noFloor;

  /// No description provided for @groundFloor.
  ///
  /// In en, this message translates to:
  /// **'Ground Floor'**
  String get groundFloor;

  /// No description provided for @secondFloor.
  ///
  /// In en, this message translates to:
  /// **'Second Floor'**
  String get secondFloor;

  /// No description provided for @thirdFloor.
  ///
  /// In en, this message translates to:
  /// **'Third Floor'**
  String get thirdFloor;

  /// No description provided for @floorsUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Floors updated successfully'**
  String get floorsUpdatedSuccessfully;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @editMaterial.
  ///
  /// In en, this message translates to:
  /// **'Edit Material'**
  String get editMaterial;

  /// No description provided for @addBatch.
  ///
  /// In en, this message translates to:
  /// **'Add Batch'**
  String get addBatch;

  /// No description provided for @batchExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Batch Expiry Date'**
  String get batchExpiryDate;

  /// No description provided for @materialQuantity.
  ///
  /// In en, this message translates to:
  /// **'Material Quantity'**
  String get materialQuantity;

  /// No description provided for @materialUnit.
  ///
  /// In en, this message translates to:
  /// **'Material Unit'**
  String get materialUnit;

  /// No description provided for @pleaseEnterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter quantity'**
  String get pleaseEnterQuantity;

  /// No description provided for @pleaseSelectExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Please select expiry date'**
  String get pleaseSelectExpiryDate;

  /// No description provided for @batchAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Batch added successfully'**
  String get batchAddedSuccessfully;

  /// No description provided for @batchUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Batch updated successfully'**
  String get batchUpdatedSuccessfully;

  /// No description provided for @materialNameColumn.
  ///
  /// In en, this message translates to:
  /// **'Material Name'**
  String get materialNameColumn;

  /// No description provided for @quantityColumn.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityColumn;

  /// No description provided for @expiryDateColumn.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDateColumn;

  /// No description provided for @recipe.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get recipe;

  /// No description provided for @recipeManagement.
  ///
  /// In en, this message translates to:
  /// **'Recipe Management'**
  String get recipeManagement;

  /// No description provided for @manageRecipe.
  ///
  /// In en, this message translates to:
  /// **'Manage Recipe'**
  String get manageRecipe;

  /// No description provided for @recipeIngredients.
  ///
  /// In en, this message translates to:
  /// **'Recipe Ingredients'**
  String get recipeIngredients;

  /// No description provided for @addIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredient'**
  String get addIngredient;

  /// No description provided for @selectRawMaterial.
  ///
  /// In en, this message translates to:
  /// **'Select Raw Material'**
  String get selectRawMaterial;

  /// No description provided for @ingredientQuantity.
  ///
  /// In en, this message translates to:
  /// **'Ingredient Quantity'**
  String get ingredientQuantity;

  /// No description provided for @pleaseSelectRawMaterial.
  ///
  /// In en, this message translates to:
  /// **'Please select raw material'**
  String get pleaseSelectRawMaterial;

  /// No description provided for @pleaseEnterIngredientQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter ingredient quantity'**
  String get pleaseEnterIngredientQuantity;

  /// No description provided for @ingredientAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Ingredient added successfully'**
  String get ingredientAddedSuccessfully;

  /// No description provided for @ingredientUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Ingredient updated successfully'**
  String get ingredientUpdatedSuccessfully;

  /// No description provided for @ingredientDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Ingredient deleted successfully'**
  String get ingredientDeletedSuccessfully;

  /// No description provided for @recipeCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Recipe created successfully'**
  String get recipeCreatedSuccessfully;

  /// No description provided for @recipeUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Recipe updated successfully'**
  String get recipeUpdatedSuccessfully;

  /// No description provided for @noRecipeFound.
  ///
  /// In en, this message translates to:
  /// **'No recipe found for this product'**
  String get noRecipeFound;

  /// No description provided for @createRecipe.
  ///
  /// In en, this message translates to:
  /// **'Create Recipe'**
  String get createRecipe;

  /// No description provided for @editIngredient.
  ///
  /// In en, this message translates to:
  /// **'Edit Ingredient'**
  String get editIngredient;

  /// No description provided for @deleteIngredient.
  ///
  /// In en, this message translates to:
  /// **'Delete Ingredient'**
  String get deleteIngredient;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
