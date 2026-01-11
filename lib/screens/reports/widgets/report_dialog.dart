import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/sales/sales_bloc.dart';
import '../../../bloc/product/product_bloc.dart';
import '../../../bloc/financial/financial_bloc.dart';
import '../../../l10n/app_localizations.dart';

class ReportDialog {
  static void show(
    BuildContext context,
    String title,
    Widget content, {
    VoidCallback? onPrint,
  }) {
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
          builder: (builderContext) {
            final l10n = AppLocalizations.of(builderContext)!;
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: content,
              ),
              actions: [
                if (onPrint != null)
                  IconButton(
                    icon: const Icon(Icons.print),
                    tooltip: 'طباعة',
                    onPressed: () {
                      onPrint();
                    },
                  ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.close),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

