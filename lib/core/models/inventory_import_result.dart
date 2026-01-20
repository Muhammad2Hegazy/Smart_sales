import 'raw_material_category.dart';
import 'raw_material_sub_category.dart';
import 'raw_material.dart';

/// Result of importing inventory items (raw materials) with categories and subcategories
class InventoryImportResult {
  final List<RawMaterialCategory> categories;
  final List<RawMaterialSubCategory> subCategories;
  final List<RawMaterial> rawMaterials;

  InventoryImportResult({
    required this.categories,
    required this.subCategories,
    required this.rawMaterials,
  });

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((e) => e.toMap()).toList(),
      'subCategories': subCategories.map((e) => e.toMap()).toList(),
      'rawMaterials': rawMaterials.map((e) => e.toMap()).toList(),
    };
  }

  factory InventoryImportResult.fromJson(Map<String, dynamic> json) {
    return InventoryImportResult(
      categories: (json['categories'] as List)
          .map((e) => RawMaterialCategory.fromMap(e as Map<String, dynamic>))
          .toList(),
      subCategories: (json['subCategories'] as List)
          .map((e) => RawMaterialSubCategory.fromMap(e as Map<String, dynamic>))
          .toList(),
      rawMaterials: (json['rawMaterials'] as List)
          .map((e) => RawMaterial.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
