import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_border_radius.dart';
import '../core/widgets/app_card.dart';
import '../core/utils/currency_formatter.dart';
import '../bloc/sales/sales_bloc.dart';
import '../bloc/sales/sales_event.dart';
import '../bloc/sales/sales_state.dart';
import '../bloc/product/product_bloc.dart';
import '../bloc/product/product_state.dart';
import '../bloc/financial/financial_bloc.dart';
import '../core/models/category.dart';
import '../core/models/item.dart';
import '../core/models/sale.dart';
import '../core/models/financial_transaction.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'daily';
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'daily':
        // Shift ends at 5 AM, so if current time is before 5 AM, use previous day
        DateTime dayStart;
        if (now.hour < 5) {
          // Before 5 AM, use previous day starting from 5 AM
          final yesterday = now.subtract(const Duration(days: 1));
          dayStart = DateTime(yesterday.year, yesterday.month, yesterday.day, 5, 0, 0);
        } else {
          // After 5 AM, use current day starting from 5 AM
          dayStart = DateTime(now.year, now.month, now.day, 5, 0, 0);
        }
        _selectedStartDate = dayStart;
        // End at 4:59:59 AM next day
        _selectedEndDate = dayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        break;
      case 'weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        _selectedStartDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        _selectedEndDate = _selectedStartDate!.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case 'monthly':
        _selectedStartDate = DateTime(now.year, now.month, 1);
        _selectedEndDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'yearly':
        _selectedStartDate = DateTime(now.year, 1, 1);
        _selectedEndDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
    }
    _loadSales();
  }

  void _loadSales() {
    if (_selectedStartDate != null && _selectedEndDate != null) {
      context.read<SalesBloc>().add(
        LoadSalesByDateRange(
          startDate: _selectedStartDate!,
          endDate: _selectedEndDate!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.reports),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.shopping_cart),
              text: l10n.sales,
            ),
            Tab(
              icon: const Icon(Icons.warehouse),
              text: l10n.warehouses,
            ),
            Tab(
              icon: const Icon(Icons.account_balance),
              text: l10n.accounts,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Sales Tab
          _buildSalesReportsTab(l10n),
          // Warehouses Tab
          _buildWarehousesTab(l10n),
          // Accounts Tab
          _buildAccountsTab(l10n),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Sales Reports Methods
  void _showShiftClosingReport(AppLocalizations l10n) {
    // Calculate shift period: from 5 AM to 4:59:59 AM next day
    final now = DateTime.now();
    DateTime shiftStart;
    DateTime shiftEnd;
    
    if (now.hour < 5) {
      // Before 5 AM, use previous day starting from 5 AM
      final yesterday = now.subtract(const Duration(days: 1));
      shiftStart = DateTime(yesterday.year, yesterday.month, yesterday.day, 5, 0, 0);
      shiftEnd = DateTime(now.year, now.month, now.day, 4, 59, 59);
    } else {
      // After 5 AM, use current day starting from 5 AM
      shiftStart = DateTime(now.year, now.month, now.day, 5, 0, 0);
      final tomorrow = now.add(const Duration(days: 1));
      shiftEnd = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 4, 59, 59);
    }

    context.read<SalesBloc>().add(
      LoadSalesByDateRange(
        startDate: shiftStart,
        endDate: shiftEnd,
      ),
    );

    _showReportDialog(
      l10n.shiftClosingReport,
      _buildDetailedSalesReport(l10n, reportDate: now),
    );
  }

  void _showDailySalesReport(AppLocalizations l10n) async {
    final now = DateTime.now();
    DateTime? startDate = _selectedStartDate ?? DateTime(now.year, now.month, now.day, 5, 0, 0);
    DateTime? endDate = _selectedEndDate ?? DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Show date range picker
    final picked = await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (context) => _DateRangePickerDialog(
        initialStartDate: startDate,
        initialEndDate: endDate,
      ),
    );

    if (picked != null) {
      startDate = picked['start']!;
      endDate = picked['end']!;
      
      // Load sales for selected date range
      if (mounted) {
        context.read<SalesBloc>().add(
          LoadSalesByDateRange(
            startDate: startDate,
            endDate: endDate,
          ),
        );
      }
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      _showReportDialog(
        l10n.dailySalesReport,
        _buildDetailedSalesReport(l10n, reportDate: endDate),
      );
    }
  }

  void _showSalesReportByCategory(AppLocalizations l10n) async {
    final salesBloc = context.read<SalesBloc>();
    final productBloc = context.read<ProductBloc>();
    
    // Show category selection dialog
    final selectedCategory = await showDialog<Category>(
      context: context,
      builder: (context) => BlocProvider<ProductBloc>.value(
        value: productBloc,
        child: _CategorySelectionDialog(l10n: l10n),
      ),
    );

    if (selectedCategory != null) {
      // Load all sales
      salesBloc.add(const LoadSales());
      
      // Wait for sales to load, then show report
      await Future.delayed(const Duration(milliseconds: 300));
      
      _showReportDialog(
        '${l10n.salesReportByCategory} - ${selectedCategory.name}',
        _buildDetailedSalesReport(l10n, selectedCategory: selectedCategory),
      );
    }
  }

  void _showSalesReportByItem(AppLocalizations l10n) async {
    final salesBloc = context.read<SalesBloc>();
    final productBloc = context.read<ProductBloc>();
    
    // Show item selection dialog
    final selectedItem = await showDialog<Item>(
      context: context,
      builder: (context) => BlocProvider<ProductBloc>.value(
        value: productBloc,
        child: _ItemSelectionDialog(l10n: l10n),
      ),
    );

    if (selectedItem != null) {
      // Load all sales
      salesBloc.add(const LoadSales());
      
      // Wait for sales to load, then show report
      await Future.delayed(const Duration(milliseconds: 300));
      
      _showReportDialog(
        '${l10n.salesReportByItem} - ${selectedItem.name}',
        _buildDetailedSalesReport(l10n, selectedItem: selectedItem),
      );
    }
  }

  void _showConsolidatedSalesReport(AppLocalizations l10n) async {
    final salesBloc = context.read<SalesBloc>();
    final productBloc = context.read<ProductBloc>();
    
    // Show date range picker dialog
    final dateRange = await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (context) => BlocProvider<ProductBloc>.value(
        value: productBloc,
        child: _DateRangePickerDialog(),
      ),
    );

    if (dateRange != null) {
      final startDate = dateRange['start']!;
      final endDate = dateRange['end']!;
      
      // Load all sales
      salesBloc.add(const LoadSales());
      
      // Wait for sales to load, then show report
      await Future.delayed(const Duration(milliseconds: 300));
      
      _showReportDialog(
        l10n.consolidatedSalesReport,
        _buildConsolidatedSalesReport(l10n, startDate, endDate),
      );
    }
  }

  // Warehouses Reports Methods
  void _showInventoryCount(AppLocalizations l10n) {
    _showReportDialog(
      l10n.inventoryCount,
      Center(
        child: Text(
          '${l10n.inventoryCount} - Coming soon...',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }

  void _showInventoryCountByCategory(AppLocalizations l10n) {
    _showReportDialog(
      l10n.inventoryCountByCategory,
      Center(
        child: Text(
          '${l10n.inventoryCountByCategory} - Coming soon...',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }

  void _showItemMovementReport(AppLocalizations l10n) {
    _showReportDialog(
      l10n.itemMovementReport,
      Center(
        child: Text(
          '${l10n.itemMovementReport} - Coming soon...',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }

  void _showItemByMovementReport(AppLocalizations l10n) {
    _showReportDialog(
      l10n.itemByMovementReport,
      Center(
        child: Text(
          '${l10n.itemByMovementReport} - Coming soon...',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }

  void _showWarehouseMovementReport(AppLocalizations l10n) {
    _showReportDialog(
      l10n.warehouseMovementReport,
      Center(
        child: Text(
          '${l10n.warehouseMovementReport} - Coming soon...',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }

  void _showSupplierPurchasesReport(AppLocalizations l10n) {
    _showReportDialog(
      l10n.supplierPurchasesReport,
      Center(
        child: Text(
          '${l10n.supplierPurchasesReport} - Coming soon...',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }

  // Accounts Reports Methods
  void _showCustomerAccountStatement(AppLocalizations l10n) {
    _showReportDialog(
      l10n.customerAccountStatement,
      Center(
        child: Text(
          '${l10n.customerAccountStatement} - Coming soon...',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }

  void _showCustomerBalancesReport(AppLocalizations l10n) {
    _showReportDialog(
      l10n.customerBalancesReport,
      Center(
        child: Text(
          '${l10n.customerBalancesReport} - Coming soon...',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }

  void _showSupplierAccountStatement(AppLocalizations l10n) {
    _showReportDialog(
      l10n.supplierAccountStatement,
      Center(
        child: Text(
          '${l10n.supplierAccountStatement} - Coming soon...',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }

  void _showSupplierBalancesReport(AppLocalizations l10n) {
    _showReportDialog(
      l10n.supplierBalancesReport,
      Center(
        child: Text(
          '${l10n.supplierBalancesReport} - Coming soon...',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }

  void _showGeneralLedgerReport(AppLocalizations l10n) {
    _showReportDialog(
      l10n.generalLedgerReport,
      Center(
        child: Text(
          '${l10n.generalLedgerReport} - Coming soon...',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }

  void _showAccountBalancesReport(AppLocalizations l10n) {
    _showReportDialog(
      l10n.accountBalancesReport,
      Center(
        child: Text(
          '${l10n.accountBalancesReport} - Coming soon...',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }

  void _showIncomeStatementReport(AppLocalizations l10n) {
    _showReportDialog(
      l10n.incomeStatementReport,
      Center(
        child: Text(
          '${l10n.incomeStatementReport} - Coming soon...',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }

  void _showProfitReportForPeriod(AppLocalizations l10n) {
    _showReportDialog(
      l10n.profitReportForPeriod,
      Center(
        child: Text(
          '${l10n.profitReportForPeriod} - Coming soon...',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }

  void _showReportDialog(String title, Widget content) {
    final salesBloc = context.read<SalesBloc>();
    final productBloc = context.read<ProductBloc>();
    final financialBloc = context.read<FinancialBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider<SalesBloc>.value(value: salesBloc),
          BlocProvider<ProductBloc>.value(value: productBloc),
          BlocProvider<FinancialBloc>.value(value: financialBloc),
        ],
        child: Builder(
          builder: (builderContext) => AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              child: content,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(builderContext)!.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedSalesReport(
    AppLocalizations l10n, {
    Category? selectedCategory,
    Item? selectedItem,
    DateTime? reportDate,
  }) {
    // Calculate shift period for previous balance calculation
    final now = reportDate ?? DateTime.now();
    DateTime shiftStart;
    if (now.hour < 5) {
      final yesterday = now.subtract(const Duration(days: 1));
      shiftStart = DateTime(yesterday.year, yesterday.month, yesterday.day, 5, 0, 0);
    } else {
      shiftStart = DateTime(now.year, now.month, now.day, 5, 0, 0);
    }
    
    return Builder(
      builder: (builderContext) => BlocBuilder<SalesBloc, SalesState>(
        builder: (context, salesState) {
          if (salesState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (salesState.error != null) {
            return Center(
              child: Text(
                salesState.error!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            );
          }

          // Filter sales based on category or item or date range
          List<Sale> filteredSales = salesState.sales;
          
          // If reportDate is provided, filter by date range (shift period)
          if (reportDate != null) {
            DateTime shiftStart;
            DateTime shiftEnd;
            if (reportDate.hour < 5) {
              final yesterday = reportDate.subtract(const Duration(days: 1));
              shiftStart = DateTime(yesterday.year, yesterday.month, yesterday.day, 5, 0, 0);
              shiftEnd = DateTime(reportDate.year, reportDate.month, reportDate.day, 4, 59, 59);
            } else {
              shiftStart = DateTime(reportDate.year, reportDate.month, reportDate.day, 5, 0, 0);
              final tomorrow = reportDate.add(const Duration(days: 1));
              shiftEnd = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 4, 59, 59);
            }
            filteredSales = filteredSales.where((sale) {
              return sale.createdAt.isAfter(shiftStart.subtract(const Duration(seconds: 1))) &&
                     sale.createdAt.isBefore(shiftEnd.add(const Duration(seconds: 1)));
            }).toList();
          }
          
          if (selectedCategory != null) {
            // Get all subcategories for this category
            final productState = context.read<ProductBloc>().state;
            final subCategoryIds = productState.subCategories
                .where((sub) => sub.categoryId == selectedCategory.id)
                .map((sub) => sub.id)
                .toList();
            
            // Get all items in these subcategories
            final itemIds = productState.items
                .where((item) => subCategoryIds.contains(item.subCategoryId))
                .map((item) => item.id)
                .toList();
            
            // Filter sales that contain items from this category
            filteredSales = salesState.sales.where((sale) {
              return sale.items.any((saleItem) => itemIds.contains(saleItem.itemId));
            }).toList();
          } else if (selectedItem != null) {
            // Filter sales that contain this item
            filteredSales = salesState.sales.where((sale) {
              return sale.items.any((saleItem) => saleItem.itemId == selectedItem.id);
            }).toList();
          }

          if (filteredSales.isEmpty) {
            return Center(
              child: Text(
                l10n.noSalesFound,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          // Get item IDs for filtering (if category or item is selected)
          Set<String>? relevantItemIds;
          if (selectedCategory != null) {
            final productState = context.read<ProductBloc>().state;
            final subCategoryIds = productState.subCategories
                .where((sub) => sub.categoryId == selectedCategory.id)
                .map((sub) => sub.id)
                .toList();
            relevantItemIds = productState.items
                .where((item) => subCategoryIds.contains(item.subCategoryId))
                .map((item) => item.id)
                .toSet();
          } else if (selectedItem != null) {
            relevantItemIds = {selectedItem.id};
          }

          // Calculate totals - only for items from selected category/item
          double totalSales = 0.0;
          double categoryCashSales = 0.0;
          double categoryCreditSales = 0.0;
          double categoryCostOfSales = 0.0;
          double totalDiscount = 0.0;
          double totalServiceCharge = 0.0;
          
          for (final sale in filteredSales) {
            double saleTotalForCategory = 0.0;
            for (final saleItem in sale.items) {
              // Only count items from the selected category/item
              if (relevantItemIds == null || relevantItemIds.contains(saleItem.itemId)) {
                saleTotalForCategory += saleItem.total;
                categoryCostOfSales += saleItem.price * saleItem.quantity * 0.3; // Assuming 30% cost
              }
            }
            totalSales += saleTotalForCategory;
            
            // Accumulate discount and service charge proportionally
            if (saleTotalForCategory > 0 && sale.total > 0) {
              final saleProportion = saleTotalForCategory / sale.total;
              totalDiscount += sale.discountAmount * saleProportion;
              totalServiceCharge += sale.serviceCharge * saleProportion;
            }
            
            // Distribute cash/credit based on category items
            if (saleTotalForCategory > 0) {
              if (sale.paymentMethod == 'cash') {
                categoryCashSales += saleTotalForCategory;
              } else {
                categoryCreditSales += saleTotalForCategory;
              }
            }
          }
          
          final discount = totalDiscount;
          final netSales = totalSales - discount;
          final dineInService = totalServiceCharge;
          final deliveryService = 0.0;
          final vat = netSales * 0.14; // 14% VAT
          final creditSales = categoryCreditSales;
          final visa = creditSales;
          final costOfSales = categoryCostOfSales;
          
          final cashSales = categoryCashSales;
          final otherRevenues = 0.0;
          final totalReceipts = cashSales + otherRevenues;
          
          final expensesAndPurchases = 0.0;
          final suppliesToSubTreasury = 0.0;
          final totalPayments = expensesAndPurchases + suppliesToSubTreasury;
          
          final netMovementForDay = totalReceipts - totalPayments;
          
          // Calculate previous balance from financial transactions before shift start
          double previousBalance = 0.0;
          try {
            final financialBloc = context.read<FinancialBloc>();
            final financialState = financialBloc.state;
            final transactionsBeforeShift = financialState.transactions
                .where((t) => t.createdAt.isBefore(shiftStart))
                .toList();
            previousBalance = transactionsBeforeShift.fold<double>(
              0.0,
              (sum, t) => sum + (t.type == TransactionType.cashIn ? t.amount : -t.amount),
            );
          } catch (e) {
            // FinancialBloc might not be available, use default value
            previousBalance = 0.0;
          }
          
          final netCash = previousBalance + netMovementForDay;

          // Get itemized sales - only for items from selected category/item
          final Map<String, int> itemizedSales = {};
          final Map<String, double> itemizedPrices = {};
          for (final sale in filteredSales) {
            for (final saleItem in sale.items) {
              // Filter by category or item
              if (relevantItemIds != null && !relevantItemIds.contains(saleItem.itemId)) {
                continue;
              }
              itemizedSales[saleItem.itemName] = (itemizedSales[saleItem.itemName] ?? 0) + saleItem.quantity;
              itemizedPrices[saleItem.itemName] = saleItem.price;
            }
          }

          final reportDateTime = reportDate ?? DateTime.now();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Date and Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatDate(reportDateTime)} ${_formatTime(reportDateTime)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      selectedCategory != null 
                          ? '${l10n.salesReportByCategory} - ${selectedCategory.name}'
                          : selectedItem != null
                              ? '${l10n.salesReportByItem} - ${selectedItem.name}'
                              : reportDate != null
                                  ? l10n.shiftClosingReport
                                  : l10n.dailySalesReport,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Sales Section
                _buildReportSection(
                  l10n.totalSales,
                  [
                    _buildReportRow(l10n.totalSales, CurrencyFormatter.format(totalSales)),
                    _buildReportRow(l10n.discount, CurrencyFormatter.format(discount)),
                    _buildReportRow(l10n.netSales, CurrencyFormatter.format(netSales), isBold: true),
                    _buildReportRow(l10n.dineInService, CurrencyFormatter.format(dineInService)),
                    _buildReportRow(l10n.deliveryService, CurrencyFormatter.format(deliveryService)),
                    _buildReportRow(l10n.valueAddedTax, CurrencyFormatter.format(vat)),
                    _buildReportRow(l10n.creditSales, CurrencyFormatter.format(creditSales)),
                    _buildReportRow(l10n.visa, CurrencyFormatter.format(visa)),
                    _buildReportRow(l10n.costOfSales, CurrencyFormatter.format(costOfSales)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Receipts Section
                _buildReportSection(
                  l10n.totalReceipts,
                  [
                    _buildReportRow(l10n.cashSales, CurrencyFormatter.format(cashSales), index: 0),
                    _buildReportRow(l10n.otherRevenues, CurrencyFormatter.format(otherRevenues), index: 1),
                    _buildReportRow(l10n.totalReceipts, CurrencyFormatter.format(totalReceipts), isBold: true, index: 2),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Payments Section
                _buildReportSection(
                  l10n.totalPayments,
                  [
                    _buildReportRow(l10n.expensesAndPurchases, CurrencyFormatter.format(expensesAndPurchases), index: 0),
                    _buildReportRow(l10n.suppliesToSubTreasury, CurrencyFormatter.format(suppliesToSubTreasury), index: 1),
                    _buildReportRow(l10n.totalPayments, CurrencyFormatter.format(totalPayments), isBold: true, index: 2),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Summary Section
                _buildReportSection(
                  '',
                  [
                    _buildReportRow(l10n.netMovementForDay, CurrencyFormatter.format(netMovementForDay), index: 0),
                    _buildReportRow(l10n.previousBalance, CurrencyFormatter.format(previousBalance), index: 1),
                    _buildReportRow(l10n.netCash, CurrencyFormatter.format(netCash), isBold: true, isHighlighted: true, index: 2),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Itemized Sales
                Text(
                  l10n.itemizedSales,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Table header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          l10n.item,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          l10n.value,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          l10n.quantity,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ...itemizedSales.entries.toList().asMap().entries.map((mapEntry) {
                  final index = mapEntry.key;
                  final entry = mapEntry.value;
                  final isEven = index % 2 == 0;
                  final backgroundColor = isEven ? Colors.white : Colors.grey.shade100;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.key,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            CurrencyFormatter.format(itemizedPrices[entry.key] ?? 0.0),
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            entry.value.toString(),
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.totalCount,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        itemizedSales.values.fold<int>(0, (sum, qty) => sum + qty).toString(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConsolidatedSalesReport(
    AppLocalizations l10n,
    DateTime startDate,
    DateTime endDate,
  ) {
    return Builder(
      builder: (builderContext) => BlocBuilder<SalesBloc, SalesState>(
        builder: (context, salesState) {
          if (salesState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (salesState.error != null) {
            return Center(
              child: Text(
                salesState.error!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            );
          }

          // Filter sales by date range
          final filteredSales = salesState.sales.where((sale) {
            return sale.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
                   sale.createdAt.isBefore(endDate.add(const Duration(seconds: 1)));
          }).toList();

          if (filteredSales.isEmpty) {
            return Center(
              child: Text(
                l10n.noSalesFound,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          // Get product data
          final productState = context.read<ProductBloc>().state;
          
          // Structure: Category -> SubCategory -> Item -> Sales Data
          final Map<String, Map<String, Map<String, Map<String, dynamic>>>> categoryData = {};
          
          // Process all sales
          for (final sale in filteredSales) {
            for (final saleItem in sale.items) {
              // Find item, subcategory, and category
              final item = productState.items.firstWhere(
                (i) => i.id == saleItem.itemId,
                orElse: () => productState.items.first, // Fallback
              );
              
              final subCategory = productState.subCategories.firstWhere(
                (s) => s.id == item.subCategoryId,
                orElse: () => productState.subCategories.first, // Fallback
              );
              
              final category = productState.categories.firstWhere(
                (c) => productState.subCategories.any((s) => s.categoryId == c.id && s.id == subCategory.id),
                orElse: () => productState.categories.first, // Fallback
              );
              
              // Initialize structure if needed
              if (!categoryData.containsKey(category.id)) {
                categoryData[category.id] = {};
              }
              if (!categoryData[category.id]!.containsKey(subCategory.id)) {
                categoryData[category.id]![subCategory.id] = {};
              }
              if (!categoryData[category.id]![subCategory.id]!.containsKey(item.id)) {
                categoryData[category.id]![subCategory.id]![item.id] = {
                  'item': item,
                  'quantity': 0,
                  'totalValue': 0.0,
                  'totalDiscount': 0.0,
                  'netSales': 0.0,
                  'prices': <double>[],
                };
              }
              
              // Update item data
              final itemData = categoryData[category.id]![subCategory.id]![item.id]!;
              itemData['quantity'] = (itemData['quantity'] as int) + saleItem.quantity;
              itemData['totalValue'] = (itemData['totalValue'] as double) + saleItem.total;
              
              // Calculate discount proportionally for this item
              double itemDiscount = 0.0;
              if (sale.total > 0) {
                final itemProportion = saleItem.total / sale.total;
                itemDiscount = sale.discountAmount * itemProportion;
              }
              itemData['totalDiscount'] = (itemData['totalDiscount'] as double) + itemDiscount;
              itemData['netSales'] = (itemData['netSales'] as double) + saleItem.total;
              (itemData['prices'] as List<double>).add(saleItem.price);
            }
          }

          // Build report rows
          final List<Widget> reportRows = [];
          
          // Add header
          reportRows.add(
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text('باركود', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(flex: 3, child: Text(l10n.item, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('إجمالي الكميه المباعه', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('متوسط سعر البيع', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('اجمالي القيمه', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text(l10n.totalDiscount, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text(l10n.netSales, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                ],
              ),
            ),
          );
          
          reportRows.add(const SizedBox(height: AppSpacing.xs));
          
          // Grand totals
          int grandTotalQuantity = 0;
          double grandTotalValue = 0.0;
          double grandTotalDiscount = 0.0;
          double grandNetSales = 0.0;
          
          // Process each category
          for (final categoryEntry in categoryData.entries) {
            final category = productState.categories.firstWhere((c) => c.id == categoryEntry.key);
            int categoryTotalQuantity = 0;
            double categoryTotalValue = 0.0;
            double categoryTotalDiscount = 0.0;
            double categoryNetSales = 0.0;
            
            // Process each subcategory
            for (final subCategoryEntry in categoryEntry.value.entries) {
              final subCategory = productState.subCategories.firstWhere((s) => s.id == subCategoryEntry.key);
              int subCategoryTotalQuantity = 0;
              double subCategoryTotalValue = 0.0;
              double subCategoryTotalDiscount = 0.0;
              double subCategoryNetSales = 0.0;
              
              // Process each item
              for (final itemEntry in subCategoryEntry.value.entries) {
                final itemData = itemEntry.value;
                final item = itemData['item'] as Item;
                final quantity = itemData['quantity'] as int;
                final totalValue = itemData['totalValue'] as double;
                final totalDiscount = itemData['totalDiscount'] as double;
                final netSales = itemData['netSales'] as double;
                final prices = itemData['prices'] as List<double>;
                final avgPrice = prices.isNotEmpty ? prices.reduce((a, b) => a + b) / prices.length : 0.0;
                
                // Add item row
                reportRows.add(
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: Text(item.id, style: AppTextStyles.bodySmall, textAlign: TextAlign.center)),
                        Expanded(flex: 3, child: Text(item.name, style: AppTextStyles.bodySmall)),
                        Expanded(flex: 2, child: Text(quantity.toString(), style: AppTextStyles.bodySmall, textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text(CurrencyFormatter.format(avgPrice), style: AppTextStyles.bodySmall, textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text(CurrencyFormatter.format(totalValue), style: AppTextStyles.bodySmall, textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text(CurrencyFormatter.format(totalDiscount), style: AppTextStyles.bodySmall, textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text(CurrencyFormatter.format(netSales), style: AppTextStyles.bodySmall, textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                );
                
                subCategoryTotalQuantity += quantity;
                subCategoryTotalValue += totalValue;
                subCategoryTotalDiscount += totalDiscount;
                subCategoryNetSales += netSales;
              }
              
              // Add subcategory total row
              reportRows.add(
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: Container()),
                      Expanded(flex: 3, child: Text('اجمالي النوع: ${subCategory.name}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text(subCategoryTotalQuantity.toString(), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Container()),
                      Expanded(flex: 2, child: Text(CurrencyFormatter.format(subCategoryTotalValue), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text(CurrencyFormatter.format(subCategoryTotalDiscount), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text(CurrencyFormatter.format(subCategoryNetSales), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    ],
                  ),
                ),
              );
              
              categoryTotalQuantity += subCategoryTotalQuantity;
              categoryTotalValue += subCategoryTotalValue;
              categoryTotalDiscount += subCategoryTotalDiscount;
              categoryNetSales += subCategoryNetSales;
            }
            
            // Add category total row
            reportRows.add(
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha:0.1),
                  border: Border(bottom: BorderSide(color: AppColors.primary, width: 2)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Container()),
                    Expanded(flex: 3, child: Text('اجمالي الفئه: ${category.name}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text(categoryTotalQuantity.toString(), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Container()),
                    Expanded(flex: 2, child: Text(CurrencyFormatter.format(categoryTotalValue), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text(CurrencyFormatter.format(categoryTotalDiscount), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text(CurrencyFormatter.format(categoryNetSales), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  ],
                ),
              ),
            );
            
            grandTotalQuantity += categoryTotalQuantity;
            grandTotalValue += categoryTotalValue;
            grandTotalDiscount += categoryTotalDiscount;
            grandNetSales += categoryNetSales;
          }
          
          // Add grand totals row
          reportRows.add(
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Container()),
                  Expanded(flex: 3, child: Text('الأجماليات', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 2, child: Text(grandTotalQuantity.toString(), style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Container()),
                  Expanded(flex: 2, child: Text(CurrencyFormatter.format(grandTotalValue), style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text(CurrencyFormatter.format(grandTotalDiscount), style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text(CurrencyFormatter.format(grandNetSales), style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                ],
              ),
            ),
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date filters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المبيعات من تاريخ: ${_formatDate(startDate)}',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${l10n.toDate}: ${_formatDate(endDate)}',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ...reportRows,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        ...rows,
      ],
    );
  }

  Widget _buildReportRow(String label, String value, {bool isBold = false, bool isHighlighted = false, int index = 0}) {
    final isEven = index % 2 == 0;
    final backgroundColor = isEven ? Colors.white : Colors.grey.shade100;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Container(
            padding: isHighlighted ? const EdgeInsets.all(AppSpacing.xs) : EdgeInsets.zero,
            decoration: isHighlighted
                ? BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  )
                : null,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesReportsTab(AppLocalizations l10n) {
    final salesReports = [
      {
        'title': l10n.shiftClosingReport,
        'icon': Icons.access_time,
        'onTap': () => _showShiftClosingReport(l10n),
      },
      {
        'title': l10n.dailySalesReport,
        'icon': Icons.today,
        'onTap': () => _showDailySalesReport(l10n),
      },
      {
        'title': l10n.salesReportByCategory,
        'icon': Icons.category,
        'onTap': () => _showSalesReportByCategory(l10n),
      },
      {
        'title': l10n.salesReportByItem,
        'icon': Icons.inventory_2,
        'onTap': () => _showSalesReportByItem(l10n),
      },
      {
        'title': l10n.consolidatedSalesReport,
        'icon': Icons.summarize,
        'onTap': () => _showConsolidatedSalesReport(l10n),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ListView.builder(
        itemCount: salesReports.length,
        itemBuilder: (context, index) {
          final report = salesReports[index];
          return AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ListTile(
              leading: Icon(
                report['icon'] as IconData,
                color: AppColors.primary,
                size: 28,
              ),
              title: Text(
                report['title'] as String,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onTap: report['onTap'] as VoidCallback,
            ),
          );
        },
      ),
    );
  }

  Widget _buildWarehousesTab(AppLocalizations l10n) {
    final warehousesReports = [
      {
        'title': l10n.inventoryCount,
        'icon': Icons.inventory,
        'onTap': () => _showInventoryCount(l10n),
      },
      {
        'title': l10n.inventoryCountByCategory,
        'icon': Icons.category,
        'onTap': () => _showInventoryCountByCategory(l10n),
      },
      {
        'title': l10n.itemMovementReport,
        'icon': Icons.swap_horiz,
        'onTap': () => _showItemMovementReport(l10n),
      },
      {
        'title': l10n.itemByMovementReport,
        'icon': Icons.trending_up,
        'onTap': () => _showItemByMovementReport(l10n),
      },
      {
        'title': l10n.warehouseMovementReport,
        'icon': Icons.warehouse,
        'onTap': () => _showWarehouseMovementReport(l10n),
      },
      {
        'title': l10n.supplierPurchasesReport,
        'icon': Icons.shopping_bag,
        'onTap': () => _showSupplierPurchasesReport(l10n),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ListView.builder(
        itemCount: warehousesReports.length,
        itemBuilder: (context, index) {
          final report = warehousesReports[index];
          return AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ListTile(
              leading: Icon(
                report['icon'] as IconData,
                color: AppColors.secondary,
                size: 28,
              ),
              title: Text(
                report['title'] as String,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onTap: report['onTap'] as VoidCallback,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountsTab(AppLocalizations l10n) {
    final accountsReports = [
      {
        'title': l10n.customerAccountStatement,
        'icon': Icons.description,
        'onTap': () => _showCustomerAccountStatement(l10n),
      },
      {
        'title': l10n.customerBalancesReport,
        'icon': Icons.account_balance_wallet,
        'onTap': () => _showCustomerBalancesReport(l10n),
      },
      {
        'title': l10n.supplierAccountStatement,
        'icon': Icons.receipt_long,
        'onTap': () => _showSupplierAccountStatement(l10n),
      },
      {
        'title': l10n.supplierBalancesReport,
        'icon': Icons.balance,
        'onTap': () => _showSupplierBalancesReport(l10n),
      },
      {
        'title': l10n.generalLedgerReport,
        'icon': Icons.book,
        'onTap': () => _showGeneralLedgerReport(l10n),
      },
      {
        'title': l10n.accountBalancesReport,
        'icon': Icons.account_balance,
        'onTap': () => _showAccountBalancesReport(l10n),
      },
      {
        'title': l10n.incomeStatementReport,
        'icon': Icons.trending_up,
        'onTap': () => _showIncomeStatementReport(l10n),
      },
      {
        'title': l10n.profitReportForPeriod,
        'icon': Icons.attach_money,
        'onTap': () => _showProfitReportForPeriod(l10n),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ListView.builder(
        itemCount: accountsReports.length,
        itemBuilder: (context, index) {
          final report = accountsReports[index];
          return AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ListTile(
              leading: Icon(
                report['icon'] as IconData,
                color: AppColors.accent,
                size: 28,
              ),
              title: Text(
                report['title'] as String,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onTap: report['onTap'] as VoidCallback,
            ),
          );
        },
      ),
    );
  }
}

class _DateRangePickerDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const _DateRangePickerDialog({
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<_DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<_DateRangePickerDialog> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate ?? DateTime.now();
    _endDate = widget.initialEndDate ?? DateTime.now();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day, 5, 0, 0);
        if (_endDate.isBefore(_startDate)) {
          _endDate = DateTime(_startDate.year, _startDate.month, _startDate.day, 23, 59, 59);
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(l10n.dailySalesReport),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.from}:',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: () => _selectStartDate(context),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year} ${_startDate.hour.toString().padLeft(2, '0')}:${_startDate.minute.toString().padLeft(2, '0')}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${l10n.to}:',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: () => _selectEndDate(context),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_endDate.day}/${_endDate.month}/${_endDate.year} ${_endDate.hour.toString().padLeft(2, '0')}:${_endDate.minute.toString().padLeft(2, '0')}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'start': _startDate,
              'end': _endDate,
            });
          },
          child: Text(l10n.show),
        ),
      ],
    );
  }
}

class _CategorySelectionDialog extends StatelessWidget {
  final AppLocalizations l10n;

  const _CategorySelectionDialog({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.categories.isEmpty) {
          return AlertDialog(
            title: Text(l10n.selectCategory),
            content: Text(l10n.noItemsFound),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          );
        }

        return AlertDialog(
          title: Text(l10n.selectCategory),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return ListTile(
                  title: Text(category.name),
                  onTap: () => Navigator.pop(context, category),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }
}

class _ItemSelectionDialog extends StatelessWidget {
  final AppLocalizations l10n;

  const _ItemSelectionDialog({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.items.isEmpty) {
          return AlertDialog(
            title: Text(l10n.selectItem),
            content: Text(l10n.noItemsFound),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          );
        }

        return AlertDialog(
          title: Text(l10n.selectItem),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(CurrencyFormatter.format(item.price)),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }
}

