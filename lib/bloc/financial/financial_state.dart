import 'package:equatable/equatable.dart';
import '../../core/models/financial_transaction.dart';

class FinancialState extends Equatable {
  final List<FinancialTransaction> transactions;
  final bool isLoading;
  final String? error;

  const FinancialState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  FinancialState copyWith({
    List<FinancialTransaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return FinancialState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [transactions, isLoading, error];
}

