// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نقاط البيع الذكية';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signInToContinue => 'سجل الدخول للمتابعة';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get enterUsername => 'أدخل اسم المستخدم';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get pointOfSale => 'نقطة البيع';

  @override
  String get inventory => 'المخزون';

  @override
  String get settings => 'الإعدادات';

  @override
  String get pos => 'نقطة البيع';

  @override
  String get cart => 'السلة';

  @override
  String get cartEmpty => 'السلة فارغة';

  @override
  String get total => 'الإجمالي';

  @override
  String get processPayment => 'معالجة الدفع';

  @override
  String get pay => 'دفع';

  @override
  String get clearCart => 'مسح السلة';

  @override
  String get searchProducts => 'البحث عن المنتجات';

  @override
  String get search => 'بحث';

  @override
  String get addItem => 'إضافة عنصر';

  @override
  String get category => 'الفئة';

  @override
  String get all => 'الكل';

  @override
  String get totalItems => 'إجمالي العناصر';

  @override
  String get lowStock => 'مخزون منخفض';

  @override
  String get categories => 'الفئات';

  @override
  String get noItemsFound => 'لا توجد عناصر';

  @override
  String get price => 'السعر';

  @override
  String get quantity => 'الكمية';

  @override
  String get each => 'لكل';

  @override
  String get lowStockLabel => 'مخزون منخفض';

  @override
  String get edit => 'تعديل';

  @override
  String get close => 'إغلاق';

  @override
  String get addNewItem => 'إضافة عنصر جديد';

  @override
  String get itemAdded => 'تمت إضافة العنصر بنجاح';

  @override
  String get itemUpdated => 'تم تحديث العنصر بنجاح';

  @override
  String get generalSettings => 'الإعدادات العامة';

  @override
  String get enableNotifications => 'تفعيل الإشعارات';

  @override
  String get notificationsDescription => 'تلقي إشعارات للتحديثات المهمة';

  @override
  String get soundEffects => 'الأصوات';

  @override
  String get soundDescription => 'تشغيل الصوت للمعاملات';

  @override
  String get autoPrintReceipts => 'طباعة الفواتير تلقائياً';

  @override
  String get autoPrintDescription => 'طباعة الفواتير تلقائياً بعد الدفع';

  @override
  String get appearance => 'المظهر';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get system => 'النظام';

  @override
  String get businessSettings => 'إعدادات العمل';

  @override
  String get currency => 'العملة';

  @override
  String get taxSettings => 'إعدادات الضرائب';

  @override
  String get taxDescription => 'تكوين معدلات وقواعد الضرائب';

  @override
  String get receiptSettings => 'إعدادات الفواتير';

  @override
  String get receiptDescription => 'تخصيص قالب الفاتورة';

  @override
  String get systemSettings => 'النظام';

  @override
  String get backupRestore => 'النسخ الاحتياطي والاستعادة';

  @override
  String get backupDescription => 'النسخ الاحتياطي أو استعادة بياناتك';

  @override
  String get createBackup => 'إنشاء نسخة احتياطية';

  @override
  String get restoreFromBackup => 'الاستعادة من النسخة الاحتياطية';

  @override
  String get backupCreated => 'تم إنشاء النسخة الاحتياطية بنجاح';

  @override
  String get about => 'حول';

  @override
  String get aboutDescription => 'إصدار التطبيق والمعلومات';

  @override
  String get dangerZone => 'المنطقة الخطرة';

  @override
  String get clearAllData => 'مسح جميع البيانات';

  @override
  String get clearDataDescription => 'حذف جميع البيانات بشكل دائم';

  @override
  String get clearDataWarning => 'لا يمكن التراجع عن هذا الإجراء. سيتم حذف جميع بياناتك بشكل دائم.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirm => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get user => 'المستخدم';

  @override
  String get cashier => 'الكاشير';

  @override
  String get paymentMethod => 'اختر طريقة الدفع:';

  @override
  String get cash => 'نقدي';

  @override
  String get card => 'بطاقة';

  @override
  String paymentProcessed(String method) {
    return 'تم معالجة الدفع عبر $method';
  }

  @override
  String get demoCredentials => 'تجريبي: أدخل أي اسم مستخدم وكلمة مرور';

  @override
  String get pleaseEnterUsername => 'يرجى إدخال اسم المستخدم';

  @override
  String get pleaseEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get pleaseEnterUsernameAndPassword => 'يرجى إدخال اسم المستخدم وكلمة المرور';

  @override
  String get subCategory => 'الفئة الفرعية';

  @override
  String get subCategories => 'الفئات الفرعية';

  @override
  String get items => 'العناصر';

  @override
  String get notes => 'الملاحظات';

  @override
  String get hasNotes => 'يحتوي على ملاحظات';

  @override
  String get noCategories => 'لا توجد فئات.\nاستورد من Excel.';

  @override
  String get noSubcategories => 'لا توجد فئات فرعية';

  @override
  String get noItems => 'لا توجد عناصر';

  @override
  String get noNotes => 'لا توجد ملاحظات';

  @override
  String get importCategories => 'استيراد الفئات';

  @override
  String get importSubCategories => 'استيراد الفئات الفرعية';

  @override
  String get importItems => 'استيراد العناصر (مطلوب)';

  @override
  String get importNotes => 'استيراد الملاحظات';

  @override
  String get importAllWithJson => 'استيراد الكل عبر JSON';

  @override
  String get importFromExcel => 'استيراد من Excel';

  @override
  String get table => 'طاولة';

  @override
  String get tables => 'طاولات';

  @override
  String get tableNumber => 'رقم الطاولة';

  @override
  String get takeaway => 'طلب خارجي';

  @override
  String get delivery => 'توصيل';

  @override
  String get hospitalityTable => 'طاولة الضيافة';

  @override
  String get selectTable => 'اختر الطاولة';

  @override
  String get selectedTables => 'الطاولات المحددة';

  @override
  String get reports => 'التقارير';

  @override
  String get dailyReport => 'التقرير اليومي';

  @override
  String get weeklyReport => 'التقرير الأسبوعي';

  @override
  String get monthlyReport => 'التقرير الشهري';

  @override
  String get yearlyReport => 'التقرير السنوي';

  @override
  String get profitLoss => 'الأرباح والخسائر';

  @override
  String get cashIn => 'إيداع نقدي';

  @override
  String get cashOut => 'سحب نقدي';

  @override
  String get totalSales => 'إجمالي المبيعات';

  @override
  String get totalCashIn => 'إجمالي الإيداعات';

  @override
  String get totalCashOut => 'إجمالي السحوبات';

  @override
  String get netProfit => 'صافي الربح';

  @override
  String get netLoss => 'صافي الخسارة';

  @override
  String get description => 'الوصف';

  @override
  String get amount => 'المبلغ';

  @override
  String get date => 'التاريخ';

  @override
  String get time => 'الوقت';

  @override
  String get transactionType => 'نوع المعاملة';

  @override
  String get addCashIn => 'إضافة إيداع نقدي';

  @override
  String get addCashOut => 'إضافة سحب نقدي';

  @override
  String get enterDescription => 'أدخل الوصف';

  @override
  String get enterAmount => 'أدخل المبلغ';

  @override
  String get salesReport => 'تقرير المبيعات';

  @override
  String get financialReport => 'التقرير المالي';

  @override
  String get fromDate => 'من تاريخ';

  @override
  String get toDate => 'إلى تاريخ';

  @override
  String get barcode => 'باركود';

  @override
  String get totalQuantitySold => 'اجمالي الكميه المباعه';

  @override
  String get averageSellingPrice => 'متوسط سعر البيع';

  @override
  String get totalValue => 'اجمالي القيمه';

  @override
  String get grandTotals => 'الأجماليات';

  @override
  String get totalByType => 'اجمالي النوع';

  @override
  String get totalByCategory => 'اجمالي الفئه';

  @override
  String get salesFromDate => 'المبيعات من تاريخ';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get today => 'اليوم';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get thisYear => 'هذا العام';

  @override
  String get noSalesFound => 'لا توجد مبيعات';

  @override
  String get noTransactionsFound => 'لا توجد معاملات';

  @override
  String get transactionAdded => 'تمت إضافة المعاملة بنجاح';

  @override
  String get saleRecorded => 'تم تسجيل البيع بنجاح';

  @override
  String get id => 'المعرف';

  @override
  String get name => 'الاسم';

  @override
  String get payment => 'الدفع';

  @override
  String get method => 'الطريقة';

  @override
  String get selectPeriod => 'اختر الفترة';

  @override
  String get period => 'الفترة';

  @override
  String get salesCount => 'عدد المبيعات';

  @override
  String get averageSale => 'متوسط البيع';

  @override
  String get filter => 'تصفية';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get export => 'تصدير';

  @override
  String get income => 'الدخل';

  @override
  String get expenses => 'المصروفات';

  @override
  String get balance => 'الرصيد';

  @override
  String get addTransaction => 'إضافة معاملة';

  @override
  String get transactionDetails => 'تفاصيل المعاملة';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get summary => 'ملخص';

  @override
  String get transactions => 'المعاملات';

  @override
  String get sales => 'المبيعات';

  @override
  String get allowPrinting => 'السماح بالطباعة';

  @override
  String get printCustomerInvoice => 'طباعة فاتورة العميل';

  @override
  String get printKitchenInvoice => 'طباعة فاتورة المطبخ';

  @override
  String get invoice => 'فاتورة';

  @override
  String get salesInvoice => 'فاتورة مبيعات';

  @override
  String get orderNumber => 'رقم الطلب';

  @override
  String get invoiceNumber => 'فاتورة رقم';

  @override
  String get waiter => 'ويتر';

  @override
  String get customer => 'العميل';

  @override
  String get phone => 'الهاتف';

  @override
  String get item => 'الصنف';

  @override
  String get value => 'القيمة';

  @override
  String get totalInvoice => 'اجمالي الفاتورة';

  @override
  String get totalDiscount => 'اجمالي الخصم';

  @override
  String get service => 'خدمة';

  @override
  String get netInvoice => 'صافي الفاتورة';

  @override
  String get welcome => 'اهلا بكم';

  @override
  String get printerSettings => 'إعدادات الطابعة';

  @override
  String get printerName => 'اسم الطابعة';

  @override
  String get paperSize => 'حجم الورق';

  @override
  String get paperSource => 'مصدر الورق';

  @override
  String get orientation => 'الاتجاه';

  @override
  String get paperWidth => 'عرض الورق';

  @override
  String get paperHeight => 'ارتفاع الورق';

  @override
  String get continuousPaper => 'ورق مستمر (اتركه فارغاً)';

  @override
  String get leaveEmptyForContinuous => 'اتركه فارغاً للورق المستمر';

  @override
  String get noPrintersAvailable => 'لا توجد طابعات متاحة';

  @override
  String get refresh => 'تحديث';

  @override
  String get invalidNumber => 'رقم غير صحيح';

  @override
  String get portrait => 'عمودي';

  @override
  String get landscape => 'أفقي';

  @override
  String get configurePrinter => 'تكوين الطابعة';

  @override
  String get printerConfigured => 'تم تكوين الطابعة بنجاح';

  @override
  String get printerConfigurationFailed => 'فشل تكوين الطابعة';

  @override
  String get printingCustomerInvoice => 'جاري طباعة فاتورة العميل...';

  @override
  String get customerInvoicePrinted => 'تم طباعة فاتورة العميل بنجاح';

  @override
  String get errorPrintingCustomerInvoice => 'خطأ في طباعة فاتورة العميل';

  @override
  String get printingKitchenInvoice => 'جاري طباعة فاتورة المطبخ...';

  @override
  String get kitchenInvoicePrinted => 'تم طباعة فاتورة المطبخ بنجاح';

  @override
  String get errorPrintingKitchenInvoice => 'خطأ في طباعة فاتورة المطبخ';

  @override
  String get saleRecordedButPrintFailed => 'تم تسجيل البيع ولكن فشلت الطباعة';

  @override
  String get addStock => 'إضافة مخزون';

  @override
  String get selectItem => 'اختر العنصر';

  @override
  String get enterQuantity => 'أدخل الكمية';

  @override
  String get stockUpdated => 'تم تحديث المخزون بنجاح';

  @override
  String get errorUpdatingStock => 'خطأ في تحديث المخزون';

  @override
  String get pleaseSelectItem => 'يرجى اختيار عنصر';

  @override
  String get pleaseEnterValidQuantity => 'يرجى إدخال كمية صحيحة';

  @override
  String get stockStatus => 'حالة المخزون';

  @override
  String get outOfStock => 'نفد المخزون';

  @override
  String get inStock => 'متوفر';

  @override
  String get conversionRate => 'معادلة التحويل';

  @override
  String get enterConversionRate => 'أدخل معادلة التحويل (مثال: 1 كجم = 80 كوب، أدخل 80)';

  @override
  String get itemName => 'اسم العنصر';

  @override
  String get enterItemName => 'أدخل اسم العنصر';

  @override
  String get selectSubCategory => 'اختر الفئة الفرعية';

  @override
  String get enterPrice => 'أدخل السعر';

  @override
  String get errorAddingItem => 'خطأ في إضافة العنصر';

  @override
  String get warehouses => 'المخازن';

  @override
  String get accounts => 'الحسابات';

  @override
  String get shiftClosingReport => 'تقرير تقفيل الوردية';

  @override
  String get dailySalesReport => 'تقرير المبيعات اليومي';

  @override
  String get salesReportByCategory => 'تقرير مبيعات عن فئة';

  @override
  String get salesReportByItem => 'تقرير مبيعات صنف';

  @override
  String get salesReportForCustomer => 'تقرير مبيعات لعميل';

  @override
  String get consolidatedSalesReport => 'تقرير مجمع للمبيعات';

  @override
  String get inventoryCount => 'جرد المخزن';

  @override
  String get inventoryCountByCategory => 'جرد المخزن عن فئة';

  @override
  String get itemMovementReport => 'تقرير حركة صنف';

  @override
  String get itemByMovementReport => 'تقرير صنف عن حركة';

  @override
  String get warehouseMovementReport => 'تقرير المخزن عن حركة';

  @override
  String get supplierPurchasesReport => 'تقرير مشتريات مورد';

  @override
  String get customerAccountStatement => 'كشف حساب العميل';

  @override
  String get customerBalancesReport => 'تقرير ارصدة العملاء';

  @override
  String get supplierAccountStatement => 'كشف حساب المورد';

  @override
  String get supplierBalancesReport => 'تقرير ارصدة الموردين';

  @override
  String get generalLedgerReport => 'تقرير حساب الاستاذ';

  @override
  String get accountBalancesReport => 'تقرير ارصدة الحسابات';

  @override
  String get incomeStatementReport => 'تقرير قائمة الدخل';

  @override
  String get profitReportForPeriod => 'تقرير الارباح عن فترة';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get show => 'عرض';

  @override
  String get selectCategory => 'اختر الفئة';

  @override
  String get discount => 'خصم';

  @override
  String get netSales => 'صافي المبيعات';

  @override
  String get dineInService => 'خدمه صاله';

  @override
  String get deliveryService => 'خدمه توصیل';

  @override
  String get valueAddedTax => 'ضریبه قیمه مضافه';

  @override
  String get creditSales => 'مبيعات وایرادات اجل';

  @override
  String get visa => 'فيزا';

  @override
  String get costOfSales => 'تكلفة المبيعات';

  @override
  String get cashSales => 'مبيعات نقدی';

  @override
  String get otherRevenues => 'ایرادات اخرى';

  @override
  String get totalReceipts => 'اجمالي المقبوضات';

  @override
  String get expensesAndPurchases => 'مصروفات ومشتريات';

  @override
  String get suppliesToSubTreasury => 'توريدات للخزينة الفرعيه';

  @override
  String get totalPayments => 'اجمالي المدفوعات';

  @override
  String get netMovementForDay => 'صافي حركة اليوم';

  @override
  String get previousBalance => 'الرصيد السابق';

  @override
  String get netCash => 'صافي النقدية';

  @override
  String get itemizedSales => 'الأصناف المباعة';

  @override
  String get totalCount => 'اجمالي العدد';

  @override
  String get importItemsButton => 'استيراد العناصر';

  @override
  String get optional => 'اختياري';

  @override
  String get required => 'مطلوب';

  @override
  String get addItemsOrImport => 'إضافة عناصر أو استيراد من Excel';

  @override
  String get action => 'إجراء';

  @override
  String get unknown => 'غير معروف';

  @override
  String get editItem => 'تعديل العنصر';

  @override
  String get createNewCategory => 'إنشاء فئة جديدة';

  @override
  String get createNewSubCategory => 'إنشاء فئة فرعية جديدة';

  @override
  String get newCategoryName => 'اسم الفئة الجديدة';

  @override
  String get newSubCategoryName => 'اسم الفئة الفرعية الجديدة';

  @override
  String get enterCategoryName => 'أدخل اسم الفئة';

  @override
  String get enterSubCategoryName => 'أدخل اسم الفئة الفرعية';

  @override
  String get pleaseEnterCategoryName => 'الرجاء إدخال اسم الفئة';

  @override
  String get pleaseEnterSubCategoryName => 'الرجاء إدخال اسم الفئة الفرعية';

  @override
  String itemsImportedSuccessfully(int count) {
    return 'تم استيراد العناصر بنجاح ($count عنصر). هذه العناصر متاحة في نقطة البيع فقط.';
  }

  @override
  String get addNewMaterial => 'إضافة مادة خام جديدة';

  @override
  String get rawMaterialsManagement => 'إدارة المواد الخام';

  @override
  String get addNewRawMaterialsToInventory => 'إضافة مواد خام جديدة إلى المخزون';

  @override
  String get importRawMaterialsFromExcel => 'يمكنك أيضاً استيراد المواد الخام من Excel\nفي شاشة الإعدادات';

  @override
  String get noSubcategoriesAvailable => 'لا توجد فئات فرعية متاحة. يرجى استيراد الفئات الفرعية أولاً.';

  @override
  String get materialName => 'اسم المادة';

  @override
  String get enterMaterialName => 'أدخل اسم المادة';

  @override
  String get unit => 'الوحدة:';

  @override
  String get pleaseEnterMaterialName => 'يرجى إدخال اسم المادة';

  @override
  String get materialAddedSuccessfully => 'تمت إضافة المادة بنجاح';

  @override
  String errorAddingMaterial(String error) {
    return 'خطأ في إضافة المادة: $error';
  }

  @override
  String get userManagement => 'إدارة المستخدمين';

  @override
  String get devices => 'الأجهزة';

  @override
  String get sync => 'المزامنة';

  @override
  String get account => 'الحساب';

  @override
  String get role => 'الدور';

  @override
  String get loadingProfile => 'جاري تحميل الملف الشخصي...';

  @override
  String get notAuthenticated => 'غير مصادق عليه';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutFromAccount => 'تسجيل الخروج من حسابك';

  @override
  String get dataImport => 'استيراد البيانات';

  @override
  String get importRawMaterials => 'استيراد المواد الخام';

  @override
  String get createNewUser => 'إنشاء مستخدم جديد';

  @override
  String get addUser => 'إضافة مستخدم';

  @override
  String get createNewUserAccount => 'إنشاء حساب مستخدم جديد';

  @override
  String get users => 'المستخدمون';

  @override
  String get noUsersFound => 'لم يتم العثور على مستخدمين';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get managePermissions => 'إدارة الصلاحيات';

  @override
  String get promoteToAdmin => 'ترقية إلى مدير';

  @override
  String get unknownState => 'حالة غير معروفة';

  @override
  String get deviceManagement => 'إدارة الأجهزة';

  @override
  String get loadingDevices => 'جاري تحميل الأجهزة...';

  @override
  String get syncStatus => 'حالة المزامنة';

  @override
  String get syncStatusUnavailable => 'حالة المزامنة غير متاحة';

  @override
  String get syncServiceNotAvailable => 'خدمة المزامنة غير متاحة';

  @override
  String get syncRequiresSupabase => 'تتطلب المزامنة تكوين Supabase لمزامنة البيانات';

  @override
  String get pleaseEnterValidVatRate => 'يرجى إدخال معدل ضريبة القيمة المضافة صحيح (0-100)';

  @override
  String get pleaseEnterValidServiceChargeRate => 'يرجى إدخال معدل رسوم الخدمة صحيح (0-100)';

  @override
  String get pleaseEnterValidDeliveryTaxRate => 'يرجى إدخال معدل ضريبة التوصيل صحيح (0-100)';

  @override
  String get pleaseEnterValidHospitalityTaxRate => 'يرجى إدخال معدل ضريبة الضيافة صحيح (0-100)';

  @override
  String get settingsSavedSuccessfully => 'تم حفظ الإعدادات بنجاح';

  @override
  String get failedToSaveSettings => 'فشل حفظ الإعدادات';

  @override
  String get restore => 'استعادة';

  @override
  String get selectBackupDatabaseFile => 'اختر ملف قاعدة البيانات الاحتياطي';

  @override
  String get noFileSelected => 'لم يتم اختيار ملف';

  @override
  String get backupFileNotFound => 'لم يتم العثور على ملف النسخة الاحتياطية';

  @override
  String get databaseRestoredSuccessfully => 'تم استعادة قاعدة البيانات بنجاح';

  @override
  String get restoreComplete => 'اكتملت الاستعادة';

  @override
  String get ok => 'موافق';

  @override
  String errorRestoringBackup(String error) {
    return 'خطأ في استعادة النسخة الاحتياطية: $error';
  }

  @override
  String get modernPointOfSaleSystem => 'نظام نقاط البيع الحديث لنظام Windows.';

  @override
  String get copyright => '© 2024 Smart Sales. جميع الحقوق محفوظة.';

  @override
  String get allDataCleared => 'تم مسح جميع البيانات';

  @override
  String get failedToGetFilePath => 'فشل الحصول على مسار الملف';

  @override
  String get masterDevice => 'الجهاز الرئيسي';

  @override
  String masterDeviceId(String id) {
    return 'معرف الجهاز الرئيسي: $id...';
  }

  @override
  String get current => 'الحالي';

  @override
  String get online => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String get allSynced => 'تمت المزامنة بالكامل';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String lastSync(String time) {
    return 'آخر مزامنة: $time';
  }

  @override
  String get justNow => 'الآن';

  @override
  String get editMasterName => 'تعديل اسم الجهاز الرئيسي';

  @override
  String get masterName => 'اسم الجهاز الرئيسي';

  @override
  String get areYouSureSignOut => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String areYouSurePromoteToAdmin(String username) {
    return 'هل أنت متأكد أنك تريد ترقية \"$username\" إلى مدير؟';
  }

  @override
  String get promote => 'ترقية';

  @override
  String get usernameRequired => 'اسم المستخدم مطلوب';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get roleRequired => 'الدور مطلوب';

  @override
  String get userCreatedSuccessfully => 'تم إنشاء المستخدم بنجاح';

  @override
  String changePasswordForUser(String username) {
    return 'تغيير كلمة المرور لـ $username';
  }

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get enterNewPassword => 'أدخل كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get pleaseConfirmPassword => 'يرجى تأكيد كلمة المرور';

  @override
  String get passwordMinLength => 'يجب أن تكون كلمة المرور 5 أحرف على الأقل';

  @override
  String get passwordChangedSuccessfully => 'تم تغيير كلمة المرور بنجاح';

  @override
  String errorChangingPassword(String error) {
    return 'خطأ في تغيير كلمة المرور: $error';
  }

  @override
  String get customRole => 'دور مخصص';

  @override
  String get enterCustomRole => 'أدخل الدور المخصص';

  @override
  String get permissionsUpdatedSuccessfully => 'تم تحديث الصلاحيات بنجاح';

  @override
  String errorLoadingUsers(String error) {
    return 'خطأ في تحميل المستخدمين: $error';
  }

  @override
  String get pleaseCreateAccountFirst => 'يرجى إنشاء حساب أولاً';

  @override
  String get selectUser => 'اختر المستخدم';

  @override
  String get chooseUser => 'اختر المستخدم';

  @override
  String get pleaseSelectUser => 'يرجى اختيار مستخدم';

  @override
  String get forgotPassword => 'نسيت كلمة المرور';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get selectUserAndEnterPassword => 'اختر مستخدم وأدخل كلمة المرور';

  @override
  String get passwordResetSuccessfully => 'تم إعادة تعيين كلمة المرور بنجاح';

  @override
  String errorResettingPassword(String error) {
    return 'خطأ في إعادة تعيين كلمة المرور: $error';
  }

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get selectPermissionsForUser => 'اختر الصلاحيات لهذا المستخدم:';

  @override
  String permissionsForUser(String username) {
    return 'الصلاحيات: $username';
  }

  @override
  String get permissionModuleMainScreens => 'الشاشات الرئيسية';

  @override
  String get permissionModuleSettingsTabs => 'تبويبات الإعدادات';

  @override
  String get permissionModulePosFeatures => 'ميزات نقطة البيع';

  @override
  String get permissionModuleFinancialFeatures => 'الميزات المالية';

  @override
  String get permissionModuleReportsFeatures => 'ميزات التقارير';

  @override
  String get permissionModuleSettingsFeatures => 'ميزات الإعدادات';

  @override
  String get permissionModulePermissions => 'الصلاحيات';

  @override
  String get permissionModuleBasicData => 'البيانات الأساسية';

  @override
  String get permissionModuleInventory => 'المخزون';

  @override
  String get permissionModulePurchases => 'المشتريات';

  @override
  String get permissionModuleVendors => 'الموردون';

  @override
  String get permissionModuleSalesInvoice => 'فاتورة المبيعات';

  @override
  String get permissionModuleSalesReturns => 'مرتجعات المبيعات';

  @override
  String get permissionModuleAccounts => 'الحسابات';

  @override
  String get permissionModuleInventoryReports => 'تقارير المخزون';

  @override
  String get permissionModulePurchaseReports => 'تقارير المشتريات';

  @override
  String get permissionModuleSalesReports => 'تقارير المبيعات';

  @override
  String get permissionModuleAccountReports => 'تقارير الحسابات';

  @override
  String get permissionViewReports => 'عرض التقارير';

  @override
  String get permissionUserPermissions => 'صلاحيات المستخدم';

  @override
  String get permissionAccessPosScreen => 'الوصول إلى شاشة نقطة البيع';

  @override
  String get permissionAccessInventoryScreen => 'الوصول إلى شاشة المخزون';

  @override
  String get permissionAccessItemsScreen => 'الوصول إلى شاشة العناصر';

  @override
  String get permissionAccessReportsScreen => 'الوصول إلى شاشة التقارير';

  @override
  String get permissionAccessFinancialScreen => 'الوصول إلى الشاشة المالية';

  @override
  String get permissionAccessSettingsScreen => 'الوصول إلى شاشة الإعدادات';

  @override
  String get permissionAccessGeneralSettings => 'الوصول إلى الإعدادات العامة';

  @override
  String get permissionAccessUserManagement => 'الوصول إلى إدارة المستخدمين';

  @override
  String get permissionAccessDeviceManagement => 'الوصول إلى إدارة الأجهزة';

  @override
  String get permissionAccessSyncSettings => 'الوصول إلى إعدادات المزامنة';

  @override
  String get permissionAccessSystemSettings => 'الوصول إلى إعدادات النظام';

  @override
  String get permissionPosApplyDiscount => 'نقطة البيع: تطبيق الخصم';

  @override
  String get permissionPosProcessPayment => 'نقطة البيع: معالجة الدفع';

  @override
  String get permissionPosPrintInvoice => 'نقطة البيع: طباعة الفاتورة';

  @override
  String get permissionPosSelectTable => 'نقطة البيع: اختيار الطاولة';

  @override
  String get permissionPosAccessHospitalityTable => 'نقطة البيع: الوصول إلى طاولة الضيافة';

  @override
  String get permissionPosClearCart => 'نقطة البيع: مسح السلة';

  @override
  String get permissionPosViewCart => 'نقطة البيع: عرض السلة';

  @override
  String get permissionFinancialAddCashIn => 'المالية: إضافة إيداع نقدي';

  @override
  String get permissionFinancialAddCashOut => 'المالية: إضافة سحب نقدي';

  @override
  String get permissionFinancialViewProfitLoss => 'المالية: عرض الأرباح/الخسائر';

  @override
  String get permissionFinancialViewTransactions => 'المالية: عرض المعاملات';

  @override
  String get permissionFinancialCalculateProfitLoss => 'المالية: حساب الأرباح/الخسائر';

  @override
  String get permissionReportsViewSalesReport => 'التقارير: عرض تقرير المبيعات';

  @override
  String get permissionReportsViewFinancialReport => 'التقارير: عرض التقرير المالي';

  @override
  String get permissionReportsExportReports => 'التقارير: تصدير التقارير';

  @override
  String get permissionReportsViewDailyReport => 'التقارير: عرض التقرير اليومي';

  @override
  String get permissionReportsViewWeeklyReport => 'التقارير: عرض التقرير الأسبوعي';

  @override
  String get permissionReportsViewMonthlyReport => 'التقارير: عرض التقرير الشهري';

  @override
  String get permissionReportsViewYearlyReport => 'التقارير: عرض التقرير السنوي';

  @override
  String get permissionSettingsCreateUser => 'الإعدادات: إنشاء مستخدم';

  @override
  String get permissionSettingsEditUser => 'الإعدادات: تعديل مستخدم';

  @override
  String get permissionSettingsDeleteUser => 'الإعدادات: حذف مستخدم';

  @override
  String get permissionSettingsChangePassword => 'الإعدادات: تغيير كلمة المرور';

  @override
  String get permissionSettingsManagePermissions => 'الإعدادات: إدارة الصلاحيات';

  @override
  String get permissionSettingsBackupRestore => 'الإعدادات: النسخ الاحتياطي/الاستعادة';

  @override
  String get permissionSettingsClearData => 'الإعدادات: مسح البيانات';

  @override
  String get permissionSettingsImportData => 'الإعدادات: استيراد البيانات';

  @override
  String get permissionSettingsExportData => 'الإعدادات: تصدير البيانات';

  @override
  String get permissionSettingsConfigureTax => 'الإعدادات: تكوين الضرائب';

  @override
  String get permissionSettingsConfigurePrinter => 'الإعدادات: تكوين الطابعة';

  @override
  String get permissionBasicData => 'البيانات الأساسية';

  @override
  String get permissionAddEditItemsProducts => 'إضافة/تعديل العناصر/المنتجات';

  @override
  String get permissionRegisterOpeningBalance => 'تسجيل الرصيد الافتتاحي';

  @override
  String get permissionRetrieveEditOpeningBalance => 'استرجاع/تعديل الرصيد الافتتاحي';

  @override
  String get permissionRegisterTransfersToWarehouses => 'تسجيل التحويلات إلى المخازن';

  @override
  String get permissionRegisterTransfersFromWarehouses => 'تسجيل التحويلات من المخازن';

  @override
  String get permissionPrintBarcode => 'طباعة الباركود';

  @override
  String get permissionRegisterPurchaseInvoice => 'تسجيل فاتورة الشراء';

  @override
  String get permissionRetrieveEditPurchaseInvoice => 'استرجاع/تعديل فاتورة الشراء';

  @override
  String get permissionRegisterPurchaseReturns => 'تسجيل مرتجعات الشراء';

  @override
  String get permissionAddVendors => 'إضافة موردين';

  @override
  String get permissionAdjustSalePrice => 'تعديل سعر البيع';

  @override
  String get permissionRegisterSalesInvoice => 'تسجيل فاتورة المبيعات';

  @override
  String get permissionClearAllCurrentInvoice => 'مسح جميع الفاتورة الحالية';

  @override
  String get permissionClearItemCurrentInvoice => 'مسح عنصر الفاتورة الحالية';

  @override
  String get permissionChangeItemCurrentInvoice => 'تغيير عنصر الفاتورة الحالية';

  @override
  String get permissionChangeItemQuantityLess => 'تغيير كمية العنصر أقل';

  @override
  String get permissionDiscountInvoiceItems => 'خصم عناصر الفاتورة';

  @override
  String get permissionTemporaryPrintBeforeSave => 'طباعة مؤقتة قبل الحفظ';

  @override
  String get permissionInquireTreasuryBalance => 'الاستعلام عن رصيد الخزينة';

  @override
  String get permissionRetrieveEditSalesInvoice => 'استرجاع/تعديل فاتورة المبيعات';

  @override
  String get permissionRegisterSalesReturns => 'تسجيل مرتجعات المبيعات';

  @override
  String get permissionAddNewAccount => 'إضافة حساب جديد';

  @override
  String get permissionRegisterCashReceipt => 'تسجيل إيصال نقدي';

  @override
  String get permissionRegisterCashDisbursement => 'تسجيل صرف نقدي';

  @override
  String get permissionRegisterAdjustmentEntries => 'تسجيل قيود التسوية';

  @override
  String get permissionInventoryCountReport => 'تقرير جرد المخزون';

  @override
  String get permissionInventoryCountReportByCategory => 'تقرير جرد المخزون حسب الفئة';

  @override
  String get permissionInventoryMovementReport => 'تقرير حركة المخزون';

  @override
  String get permissionItemMovementReport => 'تقرير حركة العنصر';

  @override
  String get permissionItemMovementReportByItem => 'تقرير حركة العنصر حسب العنصر';

  @override
  String get permissionPurchaseReportByVendor => 'تقرير المشتريات حسب المورد';

  @override
  String get permissionShiftPreferenceReport => 'تقرير تفضيل الوردية';

  @override
  String get permissionDailySalesReport => 'تقرير المبيعات اليومي';

  @override
  String get permissionAggregatedSalesReportByItems => 'تقرير المبيعات المجمع حسب العناصر';

  @override
  String get permissionSalesReportByItem => 'تقرير المبيعات حسب العنصر';

  @override
  String get permissionSalesReportByCategory => 'تقرير المبيعات حسب الفئة';

  @override
  String get permissionSalesReportByCustomer => 'تقرير المبيعات حسب العميل';

  @override
  String get permissionCustomerAccountStatement => 'كشف حساب العميل';

  @override
  String get permissionSupplierAccountStatement => 'كشف حساب المورد';

  @override
  String get permissionCustomerBalancesReport => 'تقرير أرصدة العملاء';

  @override
  String get permissionSupplierBalancesReport => 'تقرير أرصدة الموردين';

  @override
  String get permissionGeneralLedgerReport => 'تقرير حساب الأستاذ';

  @override
  String get permissionAccountBalancesReport => 'تقرير أرصدة الحسابات';

  @override
  String get permissionProfitReportForPeriod => 'تقرير الأرباح للفترة';

  @override
  String get permissionIncomeStatementReport => 'تقرير قائمة الدخل';

  @override
  String get macAddress => 'عنوان MAC';

  @override
  String get setAsMaster => 'تعيين كجهاز رئيسي';

  @override
  String get deleteDevice => 'حذف الجهاز';

  @override
  String get areYouSureDeleteDevice => 'هل أنت متأكد أنك تريد حذف هذا الجهاز؟';

  @override
  String get deviceDeletedSuccessfully => 'تم حذف الجهاز بنجاح';

  @override
  String get deviceSetAsMasterSuccessfully => 'تم تعيين الجهاز كجهاز رئيسي بنجاح';

  @override
  String get enterMacAddress => 'أدخل عنوان MAC';

  @override
  String get macAddressRequired => 'عنوان MAC مطلوب';

  @override
  String get addDevice => 'إضافة جهاز';

  @override
  String get deviceName => 'اسم الجهاز';

  @override
  String get enterDeviceName => 'أدخل اسم الجهاز';

  @override
  String get getMacAddress => 'الحصول على عنوان MAC';

  @override
  String get deleteAllDevices => 'حذف جميع الأجهزة';

  @override
  String get deleteAllDevicesDescription => 'حذف جميع الأجهزة باستثناء الجهاز الحالي';

  @override
  String get areYouSureDeleteAllDevices => 'هل أنت متأكد أنك تريد حذف جميع الأجهزة باستثناء الجهاز الحالي؟';

  @override
  String get allDevicesDeletedSuccessfully => 'تم حذف جميع الأجهزة بنجاح';

  @override
  String get deviceNotAuthorized => 'الجهاز غير مصرح به. يرجى الاتصال بالمسؤول لتسجيل هذا الجهاز.';

  @override
  String get deviceDeletedLogout => 'تم إزالة هذا الجهاز. سيتم تسجيل الخروج.';

  @override
  String get manageDeviceFloors => 'إدارة أدوار الأجهزة';

  @override
  String get manageDeviceFloorsDescription => 'تعيين الأجهزة على الأدوار';

  @override
  String get selectDeviceAndFloor => 'اختر الجهاز وعيّن رقم الدور';

  @override
  String get floor => 'الدور';

  @override
  String get noFloor => 'بدون دور';

  @override
  String get groundFloor => 'المرسى';

  @override
  String get secondFloor => 'الدور الثاني';

  @override
  String get thirdFloor => 'الدور الثالث';

  @override
  String get floorsUpdatedSuccessfully => 'تم تحديث الأدوار بنجاح';

  @override
  String get expiryDate => 'تاريخ الصلاحية';

  @override
  String get editMaterial => 'تعديل المادة';

  @override
  String get addBatch => 'إضافة دفعة';

  @override
  String get batchExpiryDate => 'تاريخ صلاحية الدفعة';

  @override
  String get materialQuantity => 'كمية المادة';

  @override
  String get materialUnit => 'وحدة المادة';

  @override
  String get pleaseEnterQuantity => 'يرجى إدخال الكمية';

  @override
  String get pleaseSelectExpiryDate => 'يرجى اختيار تاريخ الصلاحية';

  @override
  String get batchAddedSuccessfully => 'تمت إضافة الدفعة بنجاح';

  @override
  String get batchUpdatedSuccessfully => 'تم تحديث الدفعة بنجاح';

  @override
  String get materialNameColumn => 'اسم المادة';

  @override
  String get quantityColumn => 'الكمية';

  @override
  String get expiryDateColumn => 'تاريخ الصلاحية';

  @override
  String get recipe => 'الوصفة';

  @override
  String get recipeManagement => 'إدارة الوصفات';

  @override
  String get manageRecipe => 'إدارة الوصفة';

  @override
  String get recipeIngredients => 'مكونات الوصفة';

  @override
  String get addIngredient => 'إضافة مكون';

  @override
  String get selectRawMaterial => 'اختر المادة الخام';

  @override
  String get ingredientQuantity => 'كمية المكون';

  @override
  String get pleaseSelectRawMaterial => 'يرجى اختيار المادة الخام';

  @override
  String get pleaseEnterIngredientQuantity => 'يرجى إدخال كمية المكون';

  @override
  String get ingredientAddedSuccessfully => 'تمت إضافة المكون بنجاح';

  @override
  String get ingredientUpdatedSuccessfully => 'تم تحديث المكون بنجاح';

  @override
  String get ingredientDeletedSuccessfully => 'تم حذف المكون بنجاح';

  @override
  String get recipeCreatedSuccessfully => 'تم إنشاء الوصفة بنجاح';

  @override
  String get recipeUpdatedSuccessfully => 'تم تحديث الوصفة بنجاح';

  @override
  String get noRecipeFound => 'لا توجد وصفة لهذا المنتج';

  @override
  String get createRecipe => 'إنشاء وصفة';

  @override
  String get editIngredient => 'تعديل المكون';

  @override
  String get deleteIngredient => 'حذف المكون';

  @override
  String get minimize => 'تصغير';

  @override
  String get exitFullScreen => 'تبديل ملء الشاشة';

  @override
  String get exitApp => 'إغلاق التطبيق';

  @override
  String get exitAppConfirm => 'هل أنت متأكد من إغلاق التطبيق؟';

  @override
  String get exit => 'خروج';
}
