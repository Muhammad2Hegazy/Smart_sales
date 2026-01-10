import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/database/database_helper.dart';
import 'financial_event.dart';
import 'financial_state.dart';

class FinancialBloc extends Bloc<FinancialEvent, FinancialState> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  FinancialBloc() : super(const FinancialState()) {
    on<LoadFinancialTransactions>(_onLoadFinancialTransactions);
    on<LoadFinancialTransactionsByDateRange>(_onLoadFinancialTransactionsByDateRange);
    on<AddFinancialTransaction>(_onAddFinancialTransaction);
  }

  Future<void> _onLoadFinancialTransactions(
    LoadFinancialTransactions event,
    Emitter<FinancialState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final transactions = await _dbHelper.getAllFinancialTransactions();
      emit(state.copyWith(transactions: transactions, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadFinancialTransactionsByDateRange(
    LoadFinancialTransactionsByDateRange event,
    Emitter<FinancialState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final transactions = await _dbHelper.getFinancialTransactionsByDateRange(
        event.startDate,
        event.endDate,
      );
      emit(state.copyWith(transactions: transactions, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onAddFinancialTransaction(
    AddFinancialTransaction event,
    Emitter<FinancialState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _dbHelper.insertFinancialTransaction(event.transaction);
      
      // Reload transactions based on current state
      // If we have date range filters, reload with those dates
      final transactions = await _dbHelper.getAllFinancialTransactions();
      emit(state.copyWith(
        transactions: transactions,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
}

