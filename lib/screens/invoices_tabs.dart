import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import 'pos_screen.dart';
import '../bloc/sales/sales_bloc.dart';
import '../bloc/sales/sales_event.dart';
import '../bloc/financial/financial_bloc.dart';
import '../bloc/financial/financial_event.dart';

class InvoicesTabs extends StatelessWidget {
  const InvoicesTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.salesInvoice),
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider<SalesBloc>(
            create: (context) => SalesBloc()..add(const LoadSales()),
          ),
          BlocProvider<FinancialBloc>(
            create: (context) => FinancialBloc()..add(const LoadFinancialTransactions()),
          ),
        ],
        child: const POSScreen(),
      ),
    );
  }
}

