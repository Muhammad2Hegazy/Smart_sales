import 'package:equatable/equatable.dart';
import '../../core/models/sale.dart';

class SalesState extends Equatable {
  final List<Sale> sales;
  final bool isLoading;
  final String? error;

  const SalesState({
    this.sales = const [],
    this.isLoading = false,
    this.error,
  });

  SalesState copyWith({
    List<Sale>? sales,
    bool? isLoading,
    String? error,
  }) {
    return SalesState(
      sales: sales ?? this.sales,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [sales, isLoading, error];
}

