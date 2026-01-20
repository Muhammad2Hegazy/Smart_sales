import 'package:equatable/equatable.dart';
import '../../../core/models/sale.dart';

abstract class SalesEvent extends Equatable {
  const SalesEvent();

  @override
  List<Object?> get props => [];
}

class LoadSales extends SalesEvent {
  const LoadSales();
}

class LoadSalesByDateRange extends SalesEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadSalesByDateRange({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class AddSale extends SalesEvent {
  final Sale sale;

  const AddSale(this.sale);

  @override
  List<Object?> get props => [sale];
}

