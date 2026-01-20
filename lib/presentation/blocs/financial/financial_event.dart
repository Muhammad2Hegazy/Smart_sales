import 'package:equatable/equatable.dart';
import '../../../core/models/financial_transaction.dart';

abstract class FinancialEvent extends Equatable {
  const FinancialEvent();

  @override
  List<Object?> get props => [];
}

class LoadFinancialTransactions extends FinancialEvent {
  const LoadFinancialTransactions();
}

class LoadFinancialTransactionsByDateRange extends FinancialEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadFinancialTransactionsByDateRange({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class AddFinancialTransaction extends FinancialEvent {
  final FinancialTransaction transaction;

  const AddFinancialTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

