import 'package:equatable/equatable.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadInventory extends InventoryEvent {
  const LoadInventory();
}

class FilterByCategory extends InventoryEvent {
  final String? categoryId;
  const FilterByCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class FilterBySubCategory extends InventoryEvent {
  final String? subCategoryId;
  const FilterBySubCategory(this.subCategoryId);

  @override
  List<Object?> get props => [subCategoryId];
}

