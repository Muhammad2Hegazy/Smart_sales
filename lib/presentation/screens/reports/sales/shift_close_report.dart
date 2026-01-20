import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/invoice_printer.dart';
import '../../../bloc/financial/financial_bloc.dart';
import '../../../bloc/financial/financial_state.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/reports_service.dart';
import '../../../../core/models/shift_report.dart';
import '../../../../core/models/sale.dart';
import '../../../../core/models/financial_transaction.dart';
import '../widgets/report_dialog.dart';
import '../widgets/report_widgets.dart';

class ShiftCloseReport {
  static Future<void> show(BuildContext context, int? selectedFloor) async {
    final l10n = AppLocalizations.of(context)!;
    final dbHelper = DatabaseHelper();
    final reportsService = ReportsService();
    
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

    // Get devices for selected floor
    List<String> deviceIds = [];
    if (selectedFloor != null) {
      final floorDevices = await dbHelper.getDevicesByFloor(selectedFloor);
      deviceIds = floorDevices.map((d) => d.deviceId).toList();
    } else {
      // If no floor selected, get all devices
      final allDevices = await dbHelper.getAllDevices();
      deviceIds = allDevices.map((d) => d.deviceId).toList();
    }

    if (!context.mounted) return;
    
    // Always regenerate report from database to get latest data
    // This ensures the report shows the most recent sales
    try {
      final shiftReport = await reportsService.generateShiftCloseReport(
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
        floorId: selectedFloor,
        deviceId: deviceIds.isNotEmpty ? deviceIds.first : null,
      );
      
      if (!context.mounted) return;
      
      ReportDialog.show(
        context,
        l10n.shiftClosingReport,
        _buildShiftCloseReport(
          context,
          l10n,
          shiftReport,
          shiftStart,
          shiftEnd,
          selectedFloor,
          deviceIds,
        ),
        onPrint: () async {
          // Print button clicked - get latest data and print
          await _printReportFromData(
            context,
            l10n,
            shiftStart,
            shiftEnd,
            selectedFloor,
            deviceIds,
          );
        },
      );
    } catch (e) {
      debugPrint('Error generating shift report: $e');
      if (!context.mounted) return;
      // Fallback to detailed sales report
      ReportDialog.show(
        context,
        l10n.shiftClosingReport,
        _buildDetailedShiftReport(context, l10n, shiftStart, shiftEnd, selectedFloor, deviceIds),
      );
    }
  }

  static Widget _buildShiftCloseReport(
    BuildContext context,
    AppLocalizations l10n,
    ShiftReport report,
    DateTime shiftStart,
    DateTime shiftEnd,
    int? selectedFloor,
    List<String> deviceIds,
  ) {
    // Always reload data from database to ensure we have the latest sales
    return FutureBuilder<List<Sale>>(
      future: _getSalesFromDatabase(deviceIds, shiftStart, shiftEnd),
      builder: (context, salesSnapshot) {
        return BlocBuilder<FinancialBloc, FinancialState>(
          builder: (context, financialState) {
            // Get filtered sales from database
            List<Sale> filteredSales = salesSnapshot.data ?? [];

            // Recalculate all values from actual sales data (not from cached report)
            // This ensures we always show the latest data
            double totalSales = 0.0;
            double discount = 0.0;
            double dineInService = 0.0;
            double deliveryService = 0.0;
            double cashSales = 0.0;
            double creditSales = 0.0;
            
            for (final sale in filteredSales) {
              totalSales += sale.total;
              discount += sale.discountAmount;
              dineInService += sale.serviceCharge;
              deliveryService += sale.deliveryTax;
              if (sale.paymentMethod.toLowerCase() == 'cash') {
                cashSales += sale.total;
              } else {
                creditSales += sale.total;
              }
            }
            
            double netSales = totalSales - discount;
            double visa = creditSales;
            
            // Calculate cost of sales (30% of total sales)
            double costOfSales = totalSales * 0.3;
            double otherRevenues = 0.0;
            double totalReceipts = cashSales + otherRevenues;
            
            // Calculate payments
            double expensesAndPurchases = 0.0;
            double suppliesToSubTreasury = 0.0;
            double totalPayments = expensesAndPurchases + suppliesToSubTreasury;
            
            // Calculate net movement
            double netMovementForDay = totalReceipts - totalPayments;
            
            // Calculate previous balance
            double previousBalance = 0.0;
            try {
              final transactionsBeforeShift = financialState.transactions
                  .where((t) => t.createdAt.isBefore(shiftStart))
                  .toList();
              previousBalance = transactionsBeforeShift.fold<double>(
                0.0,
                (sum, t) => sum + (t.type == TransactionType.cashIn ? t.amount : -t.amount),
              );
            } catch (e) {
              previousBalance = 0.0;
            }
            
            double netCash = previousBalance + netMovementForDay;

            // Show loading if data is not ready
            if (!salesSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Get itemized sales
            final Map<String, Map<String, dynamic>> itemizedSales = {};
            for (final sale in filteredSales) {
              for (final saleItem in sale.items) {
                if (itemizedSales.containsKey(saleItem.itemName)) {
                  itemizedSales[saleItem.itemName]!['quantity'] = 
                      (itemizedSales[saleItem.itemName]!['quantity'] as int) + saleItem.quantity;
                  itemizedSales[saleItem.itemName]!['total'] = 
                      (itemizedSales[saleItem.itemName]!['total'] as double) + saleItem.total;
                } else {
                  itemizedSales[saleItem.itemName] = {
                    'quantity': saleItem.quantity,
                    'price': saleItem.price,
                    'total': saleItem.total,
                  };
                }
              }
            }

            final reportDateTime = DateTime.now();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Date and Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${ReportWidgets.formatDate(reportDateTime)} ${ReportWidgets.formatTime(reportDateTime)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l10n.shiftClosingReport,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (selectedFloor != null)
                            Text(
                              selectedFloor == 0
                                  ? l10n.groundFloor
                                  : selectedFloor == 2
                                      ? l10n.secondFloor
                                      : selectedFloor == 3
                                          ? l10n.thirdFloor
                                          : '${l10n.floor} $selectedFloor',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Sales Section
                  ReportWidgets.buildReportSection(
                    l10n.totalSales,
                    [
                      ReportWidgets.buildReportRow(l10n.totalSales, CurrencyFormatter.format(totalSales)),
                      ReportWidgets.buildReportRow(l10n.discount, CurrencyFormatter.format(discount)),
                      ReportWidgets.buildReportRow(l10n.netSales, CurrencyFormatter.format(netSales), isBold: true),
                      ReportWidgets.buildReportRow(l10n.dineInService, CurrencyFormatter.format(dineInService)),
                      ReportWidgets.buildReportRow(l10n.deliveryService, CurrencyFormatter.format(deliveryService)),
                      ReportWidgets.buildReportRow(l10n.creditSales, CurrencyFormatter.format(creditSales)),
                      ReportWidgets.buildReportRow(l10n.visa, CurrencyFormatter.format(visa)),
                      ReportWidgets.buildReportRow(l10n.costOfSales, CurrencyFormatter.format(costOfSales)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Receipts Section
                  ReportWidgets.buildReportSection(
                    l10n.totalReceipts,
                    [
                      ReportWidgets.buildReportRow(l10n.cashSales, CurrencyFormatter.format(cashSales), index: 0),
                      ReportWidgets.buildReportRow(l10n.otherRevenues, CurrencyFormatter.format(otherRevenues), index: 1),
                      ReportWidgets.buildReportRow(l10n.totalReceipts, CurrencyFormatter.format(totalReceipts), isBold: true, index: 2),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Payments Section
                  ReportWidgets.buildReportSection(
                    l10n.totalPayments,
                    [
                      ReportWidgets.buildReportRow(l10n.expensesAndPurchases, CurrencyFormatter.format(expensesAndPurchases), index: 0),
                      ReportWidgets.buildReportRow(l10n.suppliesToSubTreasury, CurrencyFormatter.format(suppliesToSubTreasury), index: 1),
                      ReportWidgets.buildReportRow(l10n.totalPayments, CurrencyFormatter.format(totalPayments), isBold: true, index: 2),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Summary Section
                  ReportWidgets.buildReportSection(
                    '',
                    [
                      ReportWidgets.buildReportRow(l10n.netMovementForDay, CurrencyFormatter.format(netMovementForDay), index: 0),
                      ReportWidgets.buildReportRow(l10n.previousBalance, CurrencyFormatter.format(previousBalance), index: 1),
                      ReportWidgets.buildReportRow(l10n.netCash, CurrencyFormatter.format(netCash), isBold: true, isHighlighted: true, index: 2),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Itemized Sales Table
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
                            l10n.quantity,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  
                  // Table rows
                  ...itemizedSales.entries.toList().asMap().entries.map((mapEntry) {
                    final index = mapEntry.key;
                    final entry = mapEntry.value;
                    final itemData = entry.value;
                    final quantity = itemData['quantity'] as int;
                    final total = itemData['total'] as double;
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
                              quantity.toString(),
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              CurrencyFormatter.format(total),
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Total Count
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
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                          ),
                          child: Text(
                            itemizedSales.values.fold<int>(
                              0,
                              (sum, itemData) {
                                return sum + (itemData['quantity'] as int);
                              },
                            ).toString(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Get sales from database directly (not from BLoC)
  static Future<List<Sale>> _getSalesFromDatabase(
    List<String> deviceIds,
    DateTime shiftStart,
    DateTime shiftEnd,
  ) async {
    final dbHelper = DatabaseHelper();
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('ShiftCloseReport: Getting sales from database');
    debugPrint('  Shift Start: ${shiftStart.toIso8601String()}');
    debugPrint('  Shift End: ${shiftEnd.toIso8601String()}');
    debugPrint('  Device IDs: $deviceIds');
    debugPrint('  Device IDs count: ${deviceIds.length}');
    debugPrint('═══════════════════════════════════════════════════════');
    
    List<Sale> sales;
    if (deviceIds.isNotEmpty) {
      sales = await dbHelper.getSalesByDeviceIdsAndDateRange(
        deviceIds,
        shiftStart,
        shiftEnd,
      );
      debugPrint('Found ${sales.length} sales for device IDs: $deviceIds');
    } else {
      // If no device IDs, get ALL sales in date range (including those without device_id)
      sales = await dbHelper.getSalesByDateRange(shiftStart, shiftEnd);
      debugPrint('Found ${sales.length} sales for all devices (no device filter)');
    }
    
    // Debug: Print sample sales
    if (sales.isNotEmpty) {
      debugPrint('Sample sales:');
      for (var i = 0; i < (sales.length > 3 ? 3 : sales.length); i++) {
        final sale = sales[i];
        debugPrint('  Sale ${i + 1}: ID=${sale.id}, Total=${sale.total}, Device=${sale.deviceId}, Created=${sale.createdAt.toIso8601String()}');
      }
    } else {
      debugPrint('⚠️  WARNING: No sales found in date range!');
      // Try to get all sales to debug
      final allSales = await dbHelper.getAllSales();
      debugPrint('Total sales in database: ${allSales.length}');
      if (allSales.isNotEmpty) {
        debugPrint('Sample of all sales:');
        for (var i = 0; i < (allSales.length > 3 ? 3 : allSales.length); i++) {
          final sale = allSales[i];
          debugPrint('  Sale ${i + 1}: ID=${sale.id}, Total=${sale.total}, Device=${sale.deviceId}, Created=${sale.createdAt.toIso8601String()}');
        }
      }
    }
    
    debugPrint('═══════════════════════════════════════════════════════');
    
    return sales;
  }

  static Future<void> _printReportFromData(
    BuildContext context,
    AppLocalizations l10n,
    DateTime shiftStart,
    DateTime shiftEnd,
    int? selectedFloor,
    List<String> deviceIds,
  ) async {
    try {
      // Get sales data
      final sales = await _getSalesFromDatabase(deviceIds, shiftStart, shiftEnd);
      
      // Calculate all values
      double totalSales = 0.0;
      double discount = 0.0;
      double dineInService = 0.0;
      double deliveryService = 0.0;
      double cashSales = 0.0;
      double creditSales = 0.0;
      
      for (final sale in sales) {
        totalSales += sale.total;
        discount += sale.discountAmount;
        dineInService += sale.serviceCharge;
        deliveryService += sale.deliveryTax;
        if (sale.paymentMethod.toLowerCase() == 'cash') {
          cashSales += sale.total;
        } else {
          creditSales += sale.total;
        }
      }
      
      double netSales = totalSales - discount;
      double visa = creditSales;
      double costOfSales = totalSales * 0.3;
      double otherRevenues = 0.0;
      double totalReceipts = cashSales + otherRevenues;
      double expensesAndPurchases = 0.0;
      double suppliesToSubTreasury = 0.0;
      double totalPayments = expensesAndPurchases + suppliesToSubTreasury;
      double netMovementForDay = totalReceipts - totalPayments;
      
      // Calculate previous balance
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
        previousBalance = 0.0;
      }
      
      double netCash = previousBalance + netMovementForDay;

      // Get itemized sales
      final Map<String, Map<String, dynamic>> itemizedSales = {};
      for (final sale in sales) {
        for (final saleItem in sale.items) {
          if (itemizedSales.containsKey(saleItem.itemName)) {
            itemizedSales[saleItem.itemName]!['quantity'] = 
                (itemizedSales[saleItem.itemName]!['quantity'] as int) + saleItem.quantity;
            itemizedSales[saleItem.itemName]!['total'] = 
                (itemizedSales[saleItem.itemName]!['total'] as double) + saleItem.total;
          } else {
            itemizedSales[saleItem.itemName] = {
              'quantity': saleItem.quantity,
              'price': saleItem.price,
              'total': saleItem.total,
            };
          }
        }
      }

      final totalCount = itemizedSales.values.fold<int>(
        0,
        (sum, itemData) => sum + (itemData['quantity'] as int),
      );

      final floorName = selectedFloor == null
          ? null
          : selectedFloor == 0
              ? l10n.groundFloor
              : selectedFloor == 2
                  ? l10n.secondFloor
                  : selectedFloor == 3
                      ? l10n.thirdFloor
                      : '${l10n.floor} $selectedFloor';

      // Print the report
      await InvoicePrinter.printShiftCloseReport(
        title: l10n.shiftClosingReport,
        reportDate: DateTime.now(),
        floorName: floorName,
        totalSales: totalSales,
        discount: discount,
        netSales: netSales,
        dineInService: dineInService,
        deliveryService: deliveryService,
        creditSales: creditSales,
        visa: visa,
        costOfSales: costOfSales,
        cashSales: cashSales,
        otherRevenues: otherRevenues,
        totalReceipts: totalReceipts,
        expensesAndPurchases: expensesAndPurchases,
        suppliesToSubTreasury: suppliesToSubTreasury,
        totalPayments: totalPayments,
        netMovementForDay: netMovementForDay,
        previousBalance: previousBalance,
        netCash: netCash,
        itemizedSales: itemizedSales,
        totalCount: totalCount,
        l10n: l10n,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إرسال التقرير للطباعة'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error printing report: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  static Widget _buildDetailedShiftReport(
    BuildContext context,
    AppLocalizations l10n,
    DateTime shiftStart,
    DateTime shiftEnd,
    int? selectedFloor,
    List<String> deviceIds,
  ) {
    return FutureBuilder<List<Sale>>(
      future: _getSalesFromDatabase(deviceIds, shiftStart, shiftEnd),
      builder: (context, salesSnapshot) {
        if (!salesSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (salesSnapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${salesSnapshot.error}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          );
        }

        // Get sales from database
        List<Sale> filteredSales = salesSnapshot.data ?? [];

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

        return BlocBuilder<FinancialBloc, FinancialState>(
          builder: (context, financialState) {
            // Calculate totals
            double totalSales = 0.0;
            double discount = 0.0;
            double dineInService = 0.0;
            double deliveryService = 0.0;
            double cashSales = 0.0;
            double creditSales = 0.0;
            
            for (final sale in filteredSales) {
              totalSales += sale.total;
              discount += sale.discountAmount;
              dineInService += sale.serviceCharge;
              if (sale.paymentMethod.toLowerCase() == 'cash') {
                cashSales += sale.total;
              } else {
                creditSales += sale.total;
              }
            }
            
            double netSales = totalSales - discount;
            double visa = creditSales;
            double costOfSales = totalSales * 0.3;
            double otherRevenues = 0.0;
            double totalReceipts = cashSales + otherRevenues;
            double expensesAndPurchases = 0.0;
            double suppliesToSubTreasury = 0.0;
            double totalPayments = expensesAndPurchases + suppliesToSubTreasury;
            double netMovementForDay = totalReceipts - totalPayments;
            
            // Calculate previous balance
            double previousBalance = 0.0;
            try {
              final transactionsBeforeShift = financialState.transactions
                  .where((t) => t.createdAt.isBefore(shiftStart))
                  .toList();
              previousBalance = transactionsBeforeShift.fold<double>(
                0.0,
                (sum, t) => sum + (t.type == TransactionType.cashIn ? t.amount : -t.amount),
              );
            } catch (e) {
              previousBalance = 0.0;
            }
            
            double netCash = previousBalance + netMovementForDay;

        // Get itemized sales
        final Map<String, Map<String, dynamic>> itemizedSales = {};
        for (final sale in filteredSales) {
          for (final saleItem in sale.items) {
            if (itemizedSales.containsKey(saleItem.itemName)) {
              itemizedSales[saleItem.itemName]!['quantity'] = 
                  (itemizedSales[saleItem.itemName]!['quantity'] as int) + saleItem.quantity;
              itemizedSales[saleItem.itemName]!['total'] = 
                  (itemizedSales[saleItem.itemName]!['total'] as double) + saleItem.total;
            } else {
              itemizedSales[saleItem.itemName] = {
                'quantity': saleItem.quantity,
                'price': saleItem.price,
                'total': saleItem.total,
              };
            }
          }
        }

        final reportDateTime = DateTime.now();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Date and Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${ReportWidgets.formatDate(reportDateTime)} ${ReportWidgets.formatTime(reportDateTime)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.shiftClosingReport,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (selectedFloor != null)
                        Text(
                          selectedFloor == 0
                              ? l10n.groundFloor
                              : selectedFloor == 2
                                  ? l10n.secondFloor
                                  : selectedFloor == 3
                                      ? l10n.thirdFloor
                                      : '${l10n.floor} $selectedFloor',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Sales Section
              ReportWidgets.buildReportSection(
                l10n.totalSales,
                [
                  ReportWidgets.buildReportRow(l10n.totalSales, CurrencyFormatter.format(totalSales)),
                  ReportWidgets.buildReportRow(l10n.discount, CurrencyFormatter.format(discount)),
                  ReportWidgets.buildReportRow(l10n.netSales, CurrencyFormatter.format(netSales), isBold: true),
                  ReportWidgets.buildReportRow(l10n.dineInService, CurrencyFormatter.format(dineInService)),
                  ReportWidgets.buildReportRow(l10n.deliveryService, CurrencyFormatter.format(deliveryService)),
                  ReportWidgets.buildReportRow(l10n.creditSales, CurrencyFormatter.format(creditSales)),
                  ReportWidgets.buildReportRow(l10n.visa, CurrencyFormatter.format(visa)),
                  ReportWidgets.buildReportRow(l10n.costOfSales, CurrencyFormatter.format(costOfSales)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Receipts Section
              ReportWidgets.buildReportSection(
                l10n.totalReceipts,
                [
                  ReportWidgets.buildReportRow(l10n.cashSales, CurrencyFormatter.format(cashSales), index: 0),
                  ReportWidgets.buildReportRow(l10n.otherRevenues, CurrencyFormatter.format(otherRevenues), index: 1),
                  ReportWidgets.buildReportRow(l10n.totalReceipts, CurrencyFormatter.format(totalReceipts), isBold: true, index: 2),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Payments Section
              ReportWidgets.buildReportSection(
                l10n.totalPayments,
                [
                  ReportWidgets.buildReportRow(l10n.expensesAndPurchases, CurrencyFormatter.format(expensesAndPurchases), index: 0),
                  ReportWidgets.buildReportRow(l10n.suppliesToSubTreasury, CurrencyFormatter.format(suppliesToSubTreasury), index: 1),
                  ReportWidgets.buildReportRow(l10n.totalPayments, CurrencyFormatter.format(totalPayments), isBold: true, index: 2),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Summary Section
              ReportWidgets.buildReportSection(
                '',
                [
                  ReportWidgets.buildReportRow(l10n.netMovementForDay, CurrencyFormatter.format(netMovementForDay), index: 0),
                  ReportWidgets.buildReportRow(l10n.previousBalance, CurrencyFormatter.format(previousBalance), index: 1),
                  ReportWidgets.buildReportRow(l10n.netCash, CurrencyFormatter.format(netCash), isBold: true, isHighlighted: true, index: 2),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Itemized Sales Table
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
                        l10n.quantity,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              
              // Table rows
              ...itemizedSales.entries.toList().asMap().entries.map((mapEntry) {
                final index = mapEntry.key;
                final entry = mapEntry.value;
                final itemData = entry.value;
                final quantity = itemData['quantity'] as int;
                final total = itemData['total'] as double;
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
                          quantity.toString(),
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          CurrencyFormatter.format(total),
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: AppSpacing.md),
              
              // Total Count
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
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      ),
                      child: Text(
                        itemizedSales.values.fold<int>(
                          0,
                          (sum, itemData) {
                            return sum + (itemData['quantity'] as int);
                          },
                        ).toString(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }
}
