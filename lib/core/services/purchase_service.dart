import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/purchase.dart';
import '../models/inventory_movement.dart';
import '../models/financial_transaction.dart';
import '../models/raw_material.dart';
import '../models/raw_material_batch.dart';
import '../database/database_helper.dart';

/// Service class for handling purchase invoice processing
class PurchaseService {
  final DatabaseHelper _dbHelper;

  PurchaseService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Save purchase invoice and update inventory, supplier balance, and item cost prices
  Future<Purchase> savePurchaseInvoice({
    required String supplierId,
    required DateTime purchaseDate,
    required String paymentType, // 'cash' or 'credit'
    required List<PurchaseItem> items,
    required double totalAmount,
    required double paidAmount,
    double? discountAmount,
    String? supplierInvoiceNumber,
    String? notes,
  }) async {
    try {
      // Get master device ID
      final master = await _dbHelper.getMaster();
      final masterDeviceId = master?.masterDeviceId ?? '';
      final now = DateTime.now();

      // Generate invoice number
      final invoiceNumber = await _dbHelper.getNextPurchaseInvoiceNumber();

      // Create purchase ID
      final purchaseId = const Uuid().v4();

      // Create purchase items with IDs
      final purchaseItems = items.map((item) {
        return PurchaseItem(
          id: const Uuid().v4(),
          purchaseId: purchaseId,
          itemId: item.itemId,
          itemName: item.itemName,
          unit: item.unit,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          discount: item.discount,
          total: item.total,
          masterDeviceId: masterDeviceId,
          syncStatus: 'pending',
          updatedAt: now,
        );
      }).toList();

      // Create purchase object
      final purchase = Purchase(
        id: purchaseId,
        invoiceNumber: invoiceNumber,
        supplierId: supplierId,
        supplierInvoiceNumber: supplierInvoiceNumber,
        purchaseDate: purchaseDate,
        paymentType: paymentType,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        discountAmount: discountAmount,
        notes: notes,
        createdAt: now,
        masterDeviceId: masterDeviceId,
        syncStatus: 'pending',
        updatedAt: now,
        items: purchaseItems,
      );

      // Save purchase to database
      await _dbHelper.insertPurchase(purchase);

      // Update inventory for each item
      for (var item in purchaseItems) {
        await _updateItemInventory(
          itemId: item.itemId,
          quantity: item.quantity,
          unit: item.unit,
          unitPrice: item.unitPrice,
          purchaseId: purchaseId,
        );
        
        // Check if this item is a raw material and add to raw material batches
        await _addRawMaterialToInventory(
          itemName: item.itemName,
          itemId: item.itemId,
          quantity: item.quantity,
          unit: item.unit,
          purchaseId: purchaseId,
        );
      }

      // Update supplier balance if credit
      if (paymentType == 'credit') {
        await _updateSupplierBalance(
          supplierId: supplierId,
          amount: totalAmount - (paidAmount),
        );
      }

      // Register cash outflow if cash payment
      if (paymentType == 'cash' && paidAmount > 0) {
        await _registerCashOutflow(
          amount: paidAmount,
          purchaseId: purchaseId,
          notes: notes,
        );
      }

      debugPrint('Purchase invoice saved successfully: $invoiceNumber');
      return purchase;
    } catch (e, stackTrace) {
      debugPrint('Error saving purchase invoice: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Update item inventory (increase stock and update cost price)
  Future<void> _updateItemInventory({
    required String itemId,
    required double quantity,
    required String unit,
    required double unitPrice,
    required String purchaseId,
  }) async {
    try {
      // Get current item
      final item = await _dbHelper.getItemById(itemId);
      if (item == null) {
        debugPrint('Item not found: $itemId');
        return;
      }

      // Calculate new stock quantity
      double newStockQuantity = item.stockQuantity + quantity;

      // Update item stock
      await _dbHelper.updateItemStock(itemId, newStockQuantity, unit);

      // Record inventory movement
      final master = await _dbHelper.getMaster();
      final masterDeviceId = master?.masterDeviceId ?? '';
      final now = DateTime.now();

      final movement = InventoryMovement(
        id: const Uuid().v4(),
        itemId: itemId,
        movementType: 'purchase',
        quantity: quantity,
        unitPrice: unitPrice,
        totalValue: quantity * unitPrice,
        referenceId: purchaseId,
        referenceType: 'purchase',
        notes: 'Purchase invoice',
        createdAt: now,
        masterDeviceId: masterDeviceId,
        syncStatus: 'pending',
        updatedAt: now,
      );

      await _dbHelper.insertInventoryMovement(movement);

      debugPrint('Inventory updated for item $itemId: +$quantity $unit');
    } catch (e) {
      debugPrint('Error updating item inventory: $e');
      rethrow;
    }
  }

  /// Update supplier balance (increase payable)
  Future<void> _updateSupplierBalance({
    required String supplierId,
    required double amount,
  }) async {
    try {
      final supplier = await _dbHelper.getSupplierById(supplierId);
      if (supplier == null) {
        debugPrint('Supplier not found: $supplierId');
        return;
      }

      final currentBalance = supplier.balance ?? 0.0;
      final newBalance = currentBalance + amount;

      final updatedSupplier = supplier.copyWith(
        balance: newBalance,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.insertSupplier(updatedSupplier);
      debugPrint('Supplier balance updated: $supplierId, new balance: $newBalance');
    } catch (e) {
      debugPrint('Error updating supplier balance: $e');
      rethrow;
    }
  }

  /// Register cash outflow transaction
  Future<void> _registerCashOutflow({
    required double amount,
    required String purchaseId,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();

      final transaction = FinancialTransaction(
        id: const Uuid().v4(),
        type: TransactionType.cashOut,
        amount: amount,
        description: notes ?? 'Purchase invoice payment',
        createdAt: now,
      );

      await _dbHelper.insertFinancialTransaction(transaction);
      debugPrint('Cash outflow registered: $amount');
    } catch (e) {
      debugPrint('Error registering cash outflow: $e');
      // Don't rethrow - cash outflow registration failure shouldn't prevent purchase from being saved
    }
  }

  /// Add raw material to inventory when purchased
  /// Checks if the item matches a raw material by name or ID and adds it to batches
  Future<void> _addRawMaterialToInventory({
    required String itemName,
    required String itemId,
    required double quantity,
    required String unit,
    required String purchaseId,
  }) async {
    try {
      // First, try to find raw material by item ID (if item ID matches raw material ID)
      RawMaterial? rawMaterial = await _dbHelper.getRawMaterialById(itemId);
      
      // If not found by ID, try to find by name
      if (rawMaterial == null) {
        final allRawMaterials = await _dbHelper.getAllRawMaterials();
        rawMaterial = allRawMaterials.firstWhere(
          (rm) => rm.name.toLowerCase() == itemName.toLowerCase(),
          orElse: () => throw Exception('Raw material not found'),
        );
      }
      
      // If raw material found, create a new batch
      // Use purchase date + 30 days as default expiry (can be adjusted)
      final expiryDate = DateTime.now().add(const Duration(days: 30));
      final now = DateTime.now();
      
      final batch = RawMaterialBatch(
        id: const Uuid().v4(),
        rawMaterialId: rawMaterial.id,
        quantity: quantity,
        expiryDate: expiryDate,
        createdAt: now,
        updatedAt: now,
      );
      
      await _dbHelper.insertRawMaterialBatch(batch);
      debugPrint('Raw material batch added: ${rawMaterial.name}, quantity: $quantity $unit');
    } catch (e) {
      // If raw material not found, it's not a raw material - that's okay
      // Only log if it's a different error
      if (e.toString().contains('Raw material not found')) {
        debugPrint('Item "$itemName" is not a raw material, skipping raw material batch creation');
      } else {
        debugPrint('Error adding raw material to inventory: $e');
      }
    }
  }
}

