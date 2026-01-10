import 'package:uuid/uuid.dart';
import '../models/sale.dart';
import '../models/cart_item.dart';
import '../models/financial_transaction.dart';
import '../../bloc/sales/sales_bloc.dart';
import '../../bloc/sales/sales_event.dart';
import '../../bloc/financial/financial_bloc.dart';
import '../../bloc/financial/financial_event.dart';
import '../../l10n/app_localizations.dart';

/// Service class for handling payment processing
class PaymentService {
  final SalesBloc _salesBloc;
  final FinancialBloc _financialBloc;

  PaymentService({
    required SalesBloc salesBloc,
    required FinancialBloc financialBloc,
  })  : _salesBloc = salesBloc,
        _financialBloc = financialBloc;

  /// Process payment and save sale to database
  Future<Sale> processPayment({
    required List<CartItem> items,
    required double total,
    String? tableNumber,
    String paymentMethod = 'cash',
    double discountPercentage = 0.0,
    double discountAmount = 0.0,
    double serviceCharge = 0.0,
    double deliveryTax = 0.0,
    double hospitalityTax = 0.0,
    required AppLocalizations l10n,
  }) async {
    // Create sale record
    final saleId = const Uuid().v4();
    final now = DateTime.now();
    
    final saleItems = items.map((cartItem) {
      return SaleItem(
        id: const Uuid().v4(),
        saleId: saleId,
        itemId: cartItem.id,
        itemName: cartItem.name,
        price: cartItem.price,
        quantity: cartItem.quantity,
        total: cartItem.total,
      );
    }).toList();

    final sale = Sale(
      id: saleId,
      tableNumber: tableNumber,
      total: total,
      paymentMethod: paymentMethod.toLowerCase(),
      createdAt: now,
      items: saleItems,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      serviceCharge: serviceCharge,
      deliveryTax: deliveryTax,
      hospitalityTax: hospitalityTax,
    );

    // Save sale to database via BLoC
    _salesBloc.add(AddSale(sale));
    
    // Record financial transaction (cash in)
    final transaction = FinancialTransaction(
      id: const Uuid().v4(),
      type: TransactionType.cashIn,
      amount: total,
      description: l10n.saleRecorded,
      createdAt: now,
    );
    _financialBloc.add(AddFinancialTransaction(transaction));
    
    return sale;
  }
}

