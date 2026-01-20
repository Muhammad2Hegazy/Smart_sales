import '../../core/base/base_entity.dart';

class ItemEntity extends BaseEntity {
  final String id;
  final String name;
  final String subCategoryId;
  final double price;
  final String? imageUrl;
  final double stockQuantity;
  final String stockUnit;
  final double? conversionRate;
  final bool isPosOnly;

  const ItemEntity({
    required this.id,
    required this.name,
    required this.subCategoryId,
    required this.price,
    this.imageUrl,
    this.stockQuantity = 0.0,
    this.stockUnit = 'number',
    this.conversionRate,
    this.isPosOnly = false,
  });

  @override
  List<Object?> get props => [id, name, subCategoryId, price, imageUrl, stockQuantity, stockUnit, conversionRate, isPosOnly];
}
