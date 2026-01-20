import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/database_helper.dart';
import 'sales_event.dart';
import 'sales_state.dart';

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  SalesBloc() : super(const SalesState()) {
    on<LoadSales>(_onLoadSales);
    on<LoadSalesByDateRange>(_onLoadSalesByDateRange);
    on<AddSale>(_onAddSale);
  }

  Future<void> _onLoadSales(
    LoadSales event,
    Emitter<SalesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final sales = await _dbHelper.getAllSales();
      emit(state.copyWith(sales: sales, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadSalesByDateRange(
    LoadSalesByDateRange event,
    Emitter<SalesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final sales = await _dbHelper.getSalesByDateRange(
        event.startDate,
        event.endDate,
      );
      emit(state.copyWith(sales: sales, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onAddSale(
    AddSale event,
    Emitter<SalesState> emit,
  ) async {
    try {
      await _dbHelper.insertSale(event.sale);
      final sales = await _dbHelper.getAllSales();
      emit(state.copyWith(sales: sales));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}

