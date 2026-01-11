import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../models/cart_item.dart';
import '../models/financial_transaction.dart';
import '../database/database_helper.dart';
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

    // Save sale to database directly first (to ensure it's saved)
    final dbHelper = DatabaseHelper();
    await dbHelper.insertSale(sale);
    
    // Save sale to database via BLoC (for state management)
    _salesBloc.add(AddSale(sale));
    
    // Deduct inventory for each item in the sale
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('Starting inventory deduction for sale ${sale.id}');
      debugPrint('═══════════════════════════════════════════════════════');
      
      for (var saleItem in saleItems) {
        debugPrint('');
        debugPrint('Processing item: ${saleItem.itemName}');
        debugPrint('  - Item ID: ${saleItem.itemId}');
        debugPrint('  - Quantity: ${saleItem.quantity}');
        
        final recipe = await dbHelper.getRecipeByItemId(saleItem.itemId);
        if (recipe == null) {
          debugPrint('  ⚠️  WARNING: No recipe found for item "${saleItem.itemName}"');
          debugPrint('  → To enable inventory deduction, please add a recipe for this item in the Items screen');
          continue; // Skip this item
        }
        
        if (recipe.ingredients.isEmpty) {
          debugPrint('  ⚠️  WARNING: Recipe found but has no ingredients');
          debugPrint('  → Please add ingredients to the recipe in the Items screen');
          continue; // Skip this item
        }
        
        debugPrint('  ✓ Recipe found with ${recipe.ingredients.length} ingredient(s)');
        
        // Deduct inventory
        await dbHelper.deductInventoryForSale(saleItem.itemId, saleItem.quantity);
        debugPrint('  ✓ Inventory deduction completed for ${saleItem.itemName}');
      }
      
      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('Inventory deduction process completed for sale ${sale.id}');
      debugPrint('═══════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      // Log error but don't fail the sale - inventory deduction is important but shouldn't block sales
      debugPrint('');
      debugPrint('❌ ERROR deducting inventory for sale ${sale.id}: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    
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

