import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/currency_formatter.dart';
import '../blocs/financial/financial_bloc.dart';
import '../blocs/financial/financial_event.dart';
import '../blocs/financial/financial_state.dart';
import '../../core/models/financial_transaction.dart';
import '../../core/database/database_helper.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedStartDate = DateTime(now.year, now.month, now.day);
    _selectedEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _loadTransactions();
  }

  void _loadTransactions() {
    if (_selectedStartDate != null && _selectedEndDate != null) {
      context.read<FinancialBloc>().add(
        LoadFinancialTransactionsByDateRange(
          startDate: _selectedStartDate!,
          endDate: _selectedEndDate!,
        ),
      );
    } else {
      // Load all transactions if no date range is selected
      context.read<FinancialBloc>().add(
        const LoadFinancialTransactions(),
      );
    }
  }

  Future<void> _calculateProfitLoss() async {
    if (_selectedStartDate == null || _selectedEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select date range first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final dbHelper = DatabaseHelper();
    final startDate = _selectedStartDate!;
    final endDate = _selectedEndDate!;

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get sales total (excludes hospitality sales)
      final salesTotal = await dbHelper.getTotalSalesByDateRange(startDate, endDate);
      
      // Get hospitality sales total (to be treated as losses)
      final hospitalitySales = await dbHelper.getTotalHospitalitySalesByDateRange(startDate, endDate);
      
      // Get cash in and cash out
      final cashIn = await dbHelper.getTotalCashInByDateRange(startDate, endDate);
      final cashOut = await dbHelper.getTotalCashOutByDateRange(startDate, endDate);

      // Calculate profit/loss
      // Hospitality sales are added to expenses (losses), not income
      final totalIncome = salesTotal + cashIn;
      final totalExpenses = cashOut + hospitalitySales; // Add hospitality sales to expenses
      final netResult = totalIncome - totalExpenses;

      if (!mounted) return;
      
      // Close loading indicator
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => _ProfitLossDialog(
          salesTotal: salesTotal,
          hospitalitySales: hospitalitySales,
          cashIn: cashIn,
          cashOut: cashOut,
          netResult: netResult,
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating profit/loss: $e'),
          backgroundColor: AppColors.error,
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
        title: Text(l10n.profitLoss),
      ),
      body: Column(
        children: [
          _buildDateRangeSelector(l10n),
          Expanded(
            child: BlocBuilder<FinancialBloc, FinancialState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.error != null) {
                  return Center(
                    child: Text(
                      state.error!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildSummaryCards(state, l10n),
                    ),
                    Expanded(
                      flex: 3,
                      child: _buildTransactionsList(state, l10n),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedStartDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedStartDate = DateTime(date.year, date.month, date.day);
                          _loadTransactions();
                        });
                      }
                    },
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _selectedStartDate != null
                                ? '${l10n.fromDate}: ${_formatDate(_selectedStartDate!)}'
                                : l10n.selectDate,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedEndDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedEndDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
                          _loadTransactions();
                        });
                      }
                    },
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _selectedEndDate != null
                                ? '${l10n.toDate}: ${_formatDate(_selectedEndDate!)}'
                                : l10n.selectDate,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AppButton(
            label: l10n.profitLoss,
            onPressed: _calculateProfitLoss,
            icon: Icons.calculate,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(FinancialState state, AppLocalizations l10n) {
    final cashIn = state.transactions
        .where((t) => t.type == TransactionType.cashIn)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    
    final cashOut = state.transactions
        .where((t) => t.type == TransactionType.cashOut)
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.summary,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSummaryItem(
                  l10n.totalCashIn,
                  CurrencyFormatter.format(cashIn),
                  Icons.arrow_downward,
                  AppColors.secondary,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSummaryItem(
                  l10n.totalCashOut,
                  CurrencyFormatter.format(cashOut),
                  Icons.arrow_upward,
                  AppColors.error,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSummaryItem(
                  l10n.balance,
                  CurrencyFormatter.format(cashIn - cashOut),
                  Icons.account_balance,
                  cashIn - cashOut >= 0 ? AppColors.primary : AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(FinancialState state, AppLocalizations l10n) {
    if (state.transactions.isEmpty) {
      return Center(
        child: Text(
          l10n.noTransactionsFound,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.transactions,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.builder(
              itemCount: state.transactions.length,
              itemBuilder: (context, index) {
                final transaction = state.transactions[index];
                final isCashIn = transaction.type == TransactionType.cashIn;
                
                return AppCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: (isCashIn ? AppColors.secondary : AppColors.error)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        child: Icon(
                          isCashIn ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCashIn ? AppColors.secondary : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.description,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '${_formatDate(transaction.createdAt)} ${_formatTime(transaction.createdAt)}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isCashIn ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isCashIn ? AppColors.secondary : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Removed - moved to PurchaseInvoiceScreen

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ProfitLossDialog extends StatelessWidget {
  final double salesTotal;
  final double hospitalitySales;
  final double cashIn;
  final double cashOut;
  final double netResult;
  final DateTime startDate;
  final DateTime endDate;

  const _ProfitLossDialog({
    required this.salesTotal,
    required this.hospitalitySales,
    required this.cashIn,
    required this.cashOut,
    required this.netResult,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isProfit = netResult >= 0;

    return AlertDialog(
      title: Text(l10n.profitLoss),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow(l10n.totalSales, CurrencyFormatter.format(salesTotal), AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          if (hospitalitySales > 0)
            _buildRow('Hospitality Sales (Loss)', CurrencyFormatter.format(hospitalitySales), AppColors.error),
          if (hospitalitySales > 0) const SizedBox(height: AppSpacing.sm),
          _buildRow(l10n.totalCashIn, CurrencyFormatter.format(cashIn), AppColors.secondary),
          const SizedBox(height: AppSpacing.sm),
          _buildRow(l10n.totalCashOut, CurrencyFormatter.format(cashOut), AppColors.error),
          const Divider(),
          _buildRow(
            isProfit ? l10n.netProfit : l10n.netLoss,
            CurrencyFormatter.format(netResult.abs()),
            isProfit ? AppColors.secondary : AppColors.error,
            isBold: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Optionally export or print the report
          },
          child: Text('Export'),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

