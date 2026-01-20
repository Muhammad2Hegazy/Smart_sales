import '../../core/base/base_entity.dart';

class CategoryEntity extends BaseEntity {
  final String id;
  final String name;
  final String? imageUrl;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, name, imageUrl];
}
