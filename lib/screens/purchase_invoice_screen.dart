import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/models/purchase.dart';
import '../core/models/raw_material.dart';
import '../core/models/supplier.dart';
import '../core/services/purchase_service.dart';
import '../core/database/database_helper.dart';
import '../core/utils/currency_formatter.dart';

class PurchaseInvoiceScreen extends StatefulWidget {
  const PurchaseInvoiceScreen({super.key});

  @override
  State<PurchaseInvoiceScreen> createState() => _PurchaseInvoiceScreenState();
}

class _PurchaseInvoiceScreenState extends State<PurchaseInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final PurchaseService _purchaseService = PurchaseService();
  
  // Header fields
  String? _invoiceNumber;
  DateTime _purchaseDate = DateTime.now();
  String? _selectedSupplierId;
  String? _supplierInvoiceNumber;
  String _paymentType = 'cash'; // 'cash' or 'credit'
  String? _notes;
  
  // Items
  final List<PurchaseItemRow> _items = [];
  
  // Suppliers and Raw Materials cache
  List<Supplier> _suppliers = [];
  List<RawMaterial> _rawMaterialsList = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load suppliers
      _suppliers = await _dbHelper.getAllSuppliers();
      
      // Load raw materials (from inventory)
      _rawMaterialsList = await _dbHelper.getAllRawMaterials();
      
      // Generate invoice number
      _invoiceNumber = await _dbHelper.getNextPurchaseInvoiceNumber();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _addItem() {
    setState(() {
      _items.add(PurchaseItemRow());
    });
  }
  
  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }
  
  double _calculateItemValue(PurchaseItemRow item) {
    return item.quantity * item.unitPrice;
  }
  
  double _calculateItemTotal(PurchaseItemRow item) {
    final subtotal = item.quantity * item.unitPrice;
    return subtotal - item.discount;
  }
  
  double _getTotalBeforeDiscount() {
    return _items.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
  }
  
  double _getTotalDiscount() {
    return _items.fold(0.0, (sum, item) => sum + item.discount);
  }
  
  double _getNetTotal() {
    return _getTotalBeforeDiscount() - _getTotalDiscount();
  }
  
  double? _paidAmount;
  
  Future<void> _saveInvoice({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validate items
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // Validate quantities
    for (var item in _items) {
      if (item.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All items must have quantity greater than 0'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      if (item.itemId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select item for all rows'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    
    // Validate supplier
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a supplier'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // Validate paid amount for credit
    if (_paymentType == 'credit') {
      if (_paidAmount == null || _paidAmount! < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter paid amount'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Convert PurchaseItemRow to PurchaseItem
      final purchaseItems = _items.map((row) {
        final rawMaterial = _rawMaterialsList.firstWhere((m) => m.id == row.itemId);
        return PurchaseItem(
          id: const Uuid().v4(),
          purchaseId: '', // Will be set by service
          itemId: row.itemId!,
          itemName: rawMaterial.name,
          unit: row.unit,
          quantity: row.quantity,
          unitPrice: row.unitPrice,
          discount: row.discount,
          total: _calculateItemTotal(row),
          masterDeviceId: '', // Will be set by service
          syncStatus: 'pending',
          updatedAt: DateTime.now(),
        );
      }).toList();
      
      // Save purchase invoice
      await _purchaseService.savePurchaseInvoice(
        supplierId: _selectedSupplierId!,
        purchaseDate: _purchaseDate,
        paymentType: _paymentType,
        items: purchaseItems,
        totalAmount: _getNetTotal(),
        paidAmount: _paymentType == 'cash' ? _getNetTotal() : (_paidAmount ?? 0.0),
        discountAmount: _getTotalDiscount() > 0 ? _getTotalDiscount() : null,
        supplierInvoiceNumber: _supplierInvoiceNumber?.isEmpty ?? true ? null : _supplierInvoiceNumber,
        notes: _notes?.isEmpty ?? true ? null : _notes,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase invoice saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        
        if (saveAndNew) {
          _resetForm();
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving invoice: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _resetForm() {
    setState(() {
      _purchaseDate = DateTime.now();
      _selectedSupplierId = null;
      _supplierInvoiceNumber = null;
      _paymentType = 'cash';
      _notes = null;
      _items.clear();
      _paidAmount = null;
      _invoiceNumber = null;
    });
    _loadData(); // Reload to get new invoice number
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading && _suppliers.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final dateFormat = DateFormat('d/M/yyyy');
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Title
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'المشتريات',
                style: AppTextStyles.displaySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column - Purchase Details
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Document Number
                          TextFormField(
                            initialValue: _invoiceNumber,
                            decoration: const InputDecoration(
                              labelText: 'رقم السند',
                              border: OutlineInputBorder(),
                              enabled: false,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Purchase Date
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _purchaseDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => _purchaseDate = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'تاريخ الشراء',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(dateFormat.format(_purchaseDate)),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Notes
                          TextFormField(
                            initialValue: _notes,
                            decoration: const InputDecoration(
                              labelText: 'ملاحظات',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 4,
                            onChanged: (value) {
                              _notes = value.isEmpty ? null : value;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    // Right Column - Supplier and Payment
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Supplier Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedSupplierId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'المورد',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            items: _suppliers.map((supplier) {
                              return DropdownMenuItem(
                                value: supplier.id,
                                child: Text(supplier.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedSupplierId = value);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a supplier';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Supplier Invoice Number
                          TextFormField(
                            initialValue: _supplierInvoiceNumber,
                            decoration: const InputDecoration(
                              labelText: 'رقم فاتورة الشراء',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _supplierInvoiceNumber = value.isEmpty ? null : value;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Payment Type
                          Text(
                            'طريقة السداد',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment<String>(
                                value: 'cash',
                                label: Text('نقدى'),
                              ),
                              ButtonSegment<String>(
                                value: 'credit',
                                label: Text('اجل'),
                              ),
                              ButtonSegment<String>(
                                value: 'partial',
                                label: Text('دفعه'),
                              ),
                            ],
                            selected: {_paymentType},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _paymentType = newSelection.first;
                                if (_paymentType != 'partial') {
                                  _paidAmount = null;
                                }
                              });
                            },
                          ),
                          if (_paymentType == 'partial' || _paymentType == 'credit') ...[
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              initialValue: _paidAmount?.toString(),
                              decoration: const InputDecoration(
                                labelText: 'قيمة الدفعة',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              onChanged: (value) {
                                _paidAmount = double.tryParse(value);
                                setState(() {});
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Items Table
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Add Item Button
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الأصناف',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addItem,
                            tooltip: 'إضافة صنف',
                          ),
                        ],
                      ),
                    ),
                    // DataTable2
                    Expanded(
                      child: _items.isEmpty
                          ? Center(
                              child: Text(
                                'اضغط على + لإضافة صنف',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : DataTable2(
                              columnSpacing: 12,
                              horizontalMargin: 12,
                              minWidth: 1200,
                              headingRowColor: WidgetStateProperty.all(AppColors.background),
                              headingRowHeight: 50,
                              dataRowHeight: 50,
                              columns: [
                                DataColumn2(
                                  label: Text(
                                    'باركود',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  size: ColumnSize.M,
                                ),
                                DataColumn2(
                                  label: Text(
                                    'اسم الصنف',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  size: ColumnSize.L,
                                ),
                                DataColumn2(
                                  label: Text(
                                    'الوحده',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  size: ColumnSize.S,
                                ),
                                DataColumn2(
                                  label: Text(
                                    'الكميه',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  size: ColumnSize.S,
                                ),
                                DataColumn2(
                                  label: Text(
                                    'السعر',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  size: ColumnSize.M,
                                ),
                                DataColumn2(
                                  label: Text(
                                    'القيمه',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  size: ColumnSize.M,
                                ),
                                DataColumn2(
                                  label: Text(
                                    'الخصم',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  size: ColumnSize.M,
                                ),
                                DataColumn2(
                                  label: Text(
                                    'صافي القيمه',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  size: ColumnSize.M,
                                ),
                                const DataColumn2(
                                  label: Text(''),
                                  size: ColumnSize.S,
                                ),
                              ],
                              rows: _items.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final selectedMaterial = item.itemId != null
                                    ? _rawMaterialsList.firstWhere(
                                        (m) => m.id == item.itemId,
                                        orElse: () => _rawMaterialsList.first,
                                      )
                                    : null;
                                
                                return DataRow2(
                                  cells: [
                                    DataCell(
                                      Text(
                                        item.barcode ?? '',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ),
                                    DataCell(
                                      InkWell(
                                        onTap: () => _showItemSelectionDialog(index),
                                        child: Text(
                                          selectedMaterial?.name ?? 'اختر الصنف',
                                          style: selectedMaterial == null
                                              ? AppTextStyles.bodySmall.copyWith(
                                                  color: AppColors.textSecondary,
                                                )
                                              : AppTextStyles.bodySmall,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        item.unit,
                                        style: AppTextStyles.bodySmall,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    DataCell(
                                      TextFormField(
                                        initialValue: item.quantity > 0 ? item.quantity.toString() : '',
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                        ],
                                        onChanged: (value) {
                                          final qty = double.tryParse(value) ?? 0.0;
                                          item.quantity = qty;
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      TextFormField(
                                        initialValue: item.unitPrice > 0 ? item.unitPrice.toString() : '',
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                        ],
                                        onChanged: (value) {
                                          final price = double.tryParse(value) ?? 0.0;
                                          item.unitPrice = price;
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        CurrencyFormatter.format(_calculateItemValue(item)),
                                        style: AppTextStyles.bodySmall,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    DataCell(
                                      TextFormField(
                                        initialValue: item.discount > 0 ? item.discount.toString() : '',
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                        ],
                                        onChanged: (value) {
                                          final discount = double.tryParse(value) ?? 0.0;
                                          item.discount = discount;
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        CurrencyFormatter.format(_calculateItemTotal(item)),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                                        onPressed: () => _removeItem(index),
                                        tooltip: 'حذف',
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer Section - Summary and Save Button
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Summary Section
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'اجمالي القيمه',
                              style: AppTextStyles.bodyMedium,
                            ),
                            SizedBox(
                              width: 150,
                              child: TextFormField(
                                initialValue: CurrencyFormatter.format(_getTotalBeforeDiscount()),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                readOnly: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'اجمالي الخصم',
                              style: AppTextStyles.bodyMedium,
                            ),
                            SizedBox(
                              width: 150,
                              child: TextFormField(
                                initialValue: CurrencyFormatter.format(_getTotalDiscount()),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                readOnly: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'صافي الفاتورة',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: TextFormField(
                                initialValue: CurrencyFormatter.format(_getNetTotal()),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                readOnly: true,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _saveInvoice(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    child: Text(
                      'حفظ',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  
  Future<void> _showItemSelectionDialog(int index) async {
    String searchQuery = '';
    List<RawMaterial> filteredMaterials = _rawMaterialsList;
    
    final selectedMaterial = await showDialog<RawMaterial>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            child: Container(
              width: 600,
              height: 500,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'بحث عن مادة خام',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        searchQuery = value.toLowerCase();
                        filteredMaterials = _rawMaterialsList.where((material) {
                          return material.name.toLowerCase().contains(searchQuery);
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: filteredMaterials.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد مواد خام',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredMaterials.length,
                            itemBuilder: (context, i) {
                              final material = filteredMaterials[i];
                              return ListTile(
                                title: Text(material.name),
                                subtitle: Text('الوحدة: ${material.unit}'),
                                trailing: Text(
                                  'الكمية: ${material.totalQuantity.toStringAsFixed(2)}',
                                  style: AppTextStyles.bodySmall,
                                ),
                                onTap: () => Navigator.of(context).pop(material),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    
    if (selectedMaterial != null) {
      // Get last purchase price for this raw material
      double lastPrice = 0.0;
      try {
        final allPurchases = await _dbHelper.getAllPurchases();
        for (var purchase in allPurchases) {
          final matchingItem = purchase.items.firstWhere(
            (item) => item.itemId == selectedMaterial.id,
            orElse: () => purchase.items.first,
          );
          if (matchingItem.itemId == selectedMaterial.id) {
            lastPrice = matchingItem.unitPrice;
            break; // Found the most recent purchase
          }
        }
      } catch (e) {
        // If no previous purchase found, keep price as 0.0
        debugPrint('No previous purchase found for ${selectedMaterial.name}: $e');
      }
      
      setState(() {
        _items[index].itemId = selectedMaterial.id;
        _items[index].unit = selectedMaterial.unit;
        _items[index].unitPrice = lastPrice; // Use last purchase price or 0.0
        _items[index].barcode = selectedMaterial.id; // Using ID as barcode placeholder
      });
    }
  }
}

/// Helper class for purchase item row
class PurchaseItemRow {
  String? itemId;
  String? barcode;
  String unit = 'number';
  double quantity = 0.0;
  double unitPrice = 0.0;
  double discount = 0.0;
}
