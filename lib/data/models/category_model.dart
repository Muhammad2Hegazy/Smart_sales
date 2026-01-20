import '../../core/base/base_model.dart';
import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity implements BaseModel {
  const CategoryModel({
    required super.id,
    required super.name,
    super.imageUrl,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      imageUrl: map['image_url']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
    };
  }
}
