import 'package:equatable/equatable.dart';
import '../../../core/models/item.dart';
import '../../../core/models/category.dart';
import '../../../core/models/sub_category.dart';

class InventoryState extends Equatable {
  final List<Item> items;
  final List<Category> categories;
  final List<SubCategory> subCategories;
  final String? selectedCategoryId;
  final String? selectedSubCategoryId;
  final bool isLoading;
  final String? error;

  const InventoryState({
    this.items = const [],
    this.categories = const [],
    this.subCategories = const [],
    this.selectedCategoryId,
    this.selectedSubCategoryId,
    this.isLoading = false,
    this.error,
  });

  List<Item> get filteredItems {
    if (selectedSubCategoryId != null) {
      return items.where((item) => item.subCategoryId == selectedSubCategoryId).toList();
    }
    if (selectedCategoryId != null) {
      final subCategoryIds = subCategories
          .where((sub) => sub.categoryId == selectedCategoryId)
          .map((sub) => sub.id)
          .toSet();
      return items.where((item) => subCategoryIds.contains(item.subCategoryId)).toList();
    }
    return items;
  }

  List<SubCategory> get filteredSubCategories {
    if (selectedCategoryId == null) {
      return [];
    }
    return subCategories.where((sub) => sub.categoryId == selectedCategoryId).toList();
  }

  InventoryState copyWith({
    List<Item>? items,
    List<Category>? categories,
    List<SubCategory>? subCategories,
    String? selectedCategoryId,
    String? selectedSubCategoryId,
    bool? isLoading,
    String? error,
  }) {
    return InventoryState(
      items: items ?? this.items,
      categories: categories ?? this.categories,
      subCategories: subCategories ?? this.subCategories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedSubCategoryId: selectedSubCategoryId ?? this.selectedSubCategoryId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        items,
        categories,
        subCategories,
        selectedCategoryId,
        selectedSubCategoryId,
        isLoading,
        error,
      ];
}

