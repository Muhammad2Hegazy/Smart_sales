import '../../core/base/base_model.dart';
import '../../domain/entities/item_entity.dart';

class ItemModel extends ItemEntity implements BaseModel {
  const ItemModel({
    required super.id,
    required super.name,
    required super.subCategoryId,
    required super.price,
    super.imageUrl,
    super.stockQuantity,
    super.stockUnit,
    super.conversionRate,
    super.isPosOnly,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      subCategoryId: map['sub_category_id']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['image_url']?.toString(),
      stockQuantity: (map['stock_quantity'] as num?)?.toDouble() ?? 0.0,
      stockUnit: map['stock_unit']?.toString() ?? 'number',
      conversionRate: (map['conversion_rate'] as num?)?.toDouble(),
      isPosOnly: (map['is_pos_only'] as int? ?? 0) == 1,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sub_category_id': subCategoryId,
      'price': price,
      'image_url': imageUrl,
      'stock_quantity': stockQuantity,
      'stock_unit': stockUnit,
      'conversion_rate': conversionRate,
      'is_pos_only': isPosOnly ? 1 : 0,
    };
  }
}
