import 'package:equatable/equatable.dart';
import '../../core/models/category.dart';
import '../../core/models/sub_category.dart';
import '../../core/models/item.dart';
import '../../core/models/note.dart';

class ProductState extends Equatable {
  final List<Category> categories;
  final List<SubCategory> subCategories;
  final List<Item> items;
  final List<Note> notes;
  final bool isLoading;
  final String? error;

  const ProductState({
    this.categories = const [],
    this.subCategories = const [],
    this.items = const [],
    this.notes = const [],
    this.isLoading = false,
    this.error,
  });

  ProductState copyWith({
    List<Category>? categories,
    List<SubCategory>? subCategories,
    List<Item>? items,
    List<Note>? notes,
    bool? isLoading,
    String? error,
  }) {
    return ProductState(
      categories: categories ?? this.categories,
      subCategories: subCategories ?? this.subCategories,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        subCategories,
        items,
        notes,
        isLoading,
        error,
      ];
}

