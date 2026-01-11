import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_border_radius.dart';
import '../core/models/raw_material.dart';
import '../core/models/raw_material_batch.dart';
import '../core/database/database_helper.dart';
import 'package:uuid/uuid.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<RawMaterial> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper = DatabaseHelper();
      final materials = await dbHelper.getAllRawMaterials();
      setState(() {
        _materials = materials;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading materials: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.inventory),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMaterials,
            tooltip: l10n.refresh,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: ElevatedButton.icon(
              onPressed: () => _showAddMaterialDialog(context, l10n),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(l10n.addNewMaterial),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _materials.isEmpty
              ? _buildEmptyState(context, l10n)
              : _buildMaterialsTable(context, l10n),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.rawMaterialsManagement,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.addNewRawMaterialsToInventory,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => _showAddMaterialDialog(context, l10n),
              icon: const Icon(Icons.add_circle, size: 24),
              label: Text(
                l10n.addNewMaterial,
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsTable(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(AppColors.primary.withValues(alpha: 0.1)),
            columns: [
              DataColumn(label: Text(l10n.materialNameColumn)),
              DataColumn(label: Text(l10n.quantityColumn)),
              DataColumn(label: Text(l10n.expiryDateColumn)),
              const DataColumn(label: Text('')),
            ],
            rows: _buildTableRows(context, l10n),
          ),
        ),
      ),
    );
  }

  List<DataRow> _buildTableRows(BuildContext context, AppLocalizations l10n) {
    final rows = <DataRow>[];
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (var material in _materials) {
      if (material.batches.isEmpty) {
        // Material with no batches
        rows.add(
          DataRow(
            cells: [
              DataCell(Text(material.name)),
              DataCell(
                Text(
                  l10n.outOfStock,
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const DataCell(Text('')),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditMaterialDialog(context, l10n, material),
                  tooltip: l10n.edit,
                ),
              ),
            ],
          ),
        );
      } else {
        // Material with batches - first row shows material name and total
        rows.add(
          DataRow(
            color: MaterialStateProperty.all(AppColors.primary.withValues(alpha: 0.05)),
            cells: [
              DataCell(
                Text(
                  material.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  '${material.totalQuantity.toStringAsFixed(2)} ${material.unit}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const DataCell(Text('')),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditMaterialDialog(context, l10n, material),
                  tooltip: l10n.edit,
                ),
              ),
            ],
          ),
        );

        // Sub-rows for each batch
        for (var batch in material.batches) {
          final isExpired = batch.isExpired;
          final isExpiringSoon = batch.isExpiringSoon;
          
          rows.add(
            DataRow(
              color: MaterialStateProperty.all(
                isExpired
                    ? AppColors.error.withValues(alpha: 0.1)
                    : isExpiringSoon
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : null,
              ),
              cells: [
                const DataCell(Padding(
                  padding: EdgeInsets.only(left: AppSpacing.lg),
                  child: Text('  └─', style: TextStyle(color: Colors.grey)),
                )),
                DataCell(
                  Text(
                    '${batch.quantity.toStringAsFixed(2)} ${material.unit}',
                    style: TextStyle(
                      color: isExpired ? AppColors.error : null,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    dateFormat.format(batch.expiryDate),
                    style: TextStyle(
                      color: isExpired
                          ? AppColors.error
                          : isExpiringSoon
                              ? AppColors.warning
                              : null,
                      fontWeight: isExpired || isExpiringSoon ? FontWeight.bold : null,
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showEditBatchDialog(context, l10n, material, batch),
                    tooltip: l10n.edit,
                  ),
                ),
              ],
            ),
          );
        }
      }
    }

    return rows;
  }

  Future<void> _showAddMaterialDialog(BuildContext context, AppLocalizations l10n) async {
    final nameController = TextEditingController();
    String selectedUnit = 'number';
    final units = ['number', 'kg', 'packet', 'carton', 'bottle', 'bag'];

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.addNewMaterial),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.materialName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    hintText: l10n.enterMaterialName,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.materialUnit,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  items: units.map((unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedUnit = value ?? 'number';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseEnterMaterialName),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                try {
                  final dbHelper = DatabaseHelper();
                  final now = DateTime.now();
                  final newMaterial = RawMaterial(
                    id: const Uuid().v4(),
                    name: nameController.text,
                    unit: selectedUnit,
                    createdAt: now,
                    updatedAt: now,
                  );

                  await dbHelper.insertRawMaterial(newMaterial);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    _loadMaterials();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.materialAddedSuccessfully),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorAddingMaterial(e.toString())),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
  }

  Future<void> _showEditMaterialDialog(
    BuildContext context,
    AppLocalizations l10n,
    RawMaterial material,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editMaterial),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.materialName),
                subtitle: Text(material.name),
              ),
              const Divider(),
              ListTile(
                title: Text(l10n.materialUnit),
                subtitle: Text(material.unit),
              ),
              const Divider(),
              ListTile(
                title: Text(l10n.quantityColumn),
                subtitle: Text(
                  material.isInStock
                      ? '${material.totalQuantity.toStringAsFixed(2)} ${material.unit}'
                      : l10n.outOfStock,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _showAddBatchDialog(context, l10n, material);
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addBatch),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddBatchDialog(
    BuildContext context,
    AppLocalizations l10n,
    RawMaterial material,
  ) async {
    final quantityController = TextEditingController();
    DateTime? selectedExpiryDate;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.addBatch),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.materialName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(material.name),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.quantityColumn,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    hintText: l10n.pleaseEnterQuantity,
                    suffixText: material.unit,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.expiryDate,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedExpiryDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedExpiryDate != null
                                ? DateFormat('yyyy-MM-dd').format(selectedExpiryDate!)
                                : l10n.pleaseSelectExpiryDate,
                            style: TextStyle(
                              color: selectedExpiryDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (quantityController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseEnterQuantity),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                if (selectedExpiryDate == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseSelectExpiryDate),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final quantity = double.tryParse(quantityController.text);
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseEnterValidQuantity),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                try {
                  final dbHelper = DatabaseHelper();
                  final now = DateTime.now();
                  final newBatch = RawMaterialBatch(
                    id: const Uuid().v4(),
                    rawMaterialId: material.id,
                    quantity: quantity,
                    expiryDate: selectedExpiryDate!,
                    createdAt: now,
                    updatedAt: now,
                  );

                  await dbHelper.insertRawMaterialBatch(newBatch);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    _loadMaterials();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.batchAddedSuccessfully),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    quantityController.dispose();
  }

  Future<void> _showEditBatchDialog(
    BuildContext context,
    AppLocalizations l10n,
    RawMaterial material,
    RawMaterialBatch batch,
  ) async {
    final quantityController = TextEditingController(text: batch.quantity.toStringAsFixed(2));
    DateTime? selectedExpiryDate = batch.expiryDate;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.editMaterial),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.materialName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(material.name),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.quantityColumn,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    hintText: l10n.pleaseEnterQuantity,
                    suffixText: material.unit,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.expiryDate,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedExpiryDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedExpiryDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedExpiryDate != null
                                ? DateFormat('yyyy-MM-dd').format(selectedExpiryDate!)
                                : l10n.pleaseSelectExpiryDate,
                            style: TextStyle(
                              color: selectedExpiryDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (quantityController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseEnterQuantity),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                if (selectedExpiryDate == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseSelectExpiryDate),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final quantity = double.tryParse(quantityController.text);
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseEnterValidQuantity),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                try {
                  final dbHelper = DatabaseHelper();
                  final updatedBatch = batch.copyWith(
                    quantity: quantity,
                    expiryDate: selectedExpiryDate!,
                    updatedAt: DateTime.now(),
                  );

                  await dbHelper.updateRawMaterialBatch(updatedBatch);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    _loadMaterials();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.batchUpdatedSuccessfully),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    quantityController.dispose();
  }

}
