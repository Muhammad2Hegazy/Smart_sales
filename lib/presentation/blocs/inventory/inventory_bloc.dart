import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/product_service.dart';
import '../../../core/models/category.dart';
import '../../../core/models/sub_category.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final ProductService _productService;

  InventoryBloc({ProductService? productService})
      : _productService = productService ?? ProductService(),
        super(const InventoryState()) {
    on<LoadInventory>(_onLoadInventory);
    on<FilterByCategory>(_onFilterByCategory);
    on<FilterBySubCategory>(_onFilterBySubCategory);
  }

  Future<void> _onLoadInventory(LoadInventory event, Emitter<InventoryState> emit) async {
    // Ensure ProductService is initialized
    await _productService.initialize();
    
    // Preserve current selections
    final currentCategoryId = state.selectedCategoryId;
    final currentSubCategoryId = state.selectedSubCategoryId;
    
    // Filter out POS-only items (only show items that are in inventory)
    final inventoryItems = _productService.items.where((item) => !item.isPosOnly).toList();
    
    // Update all data from ProductService
    final List<Category> categories = List<Category>.from(_productService.categories);
    final List<SubCategory> subCategories = List<SubCategory>.from(_productService.subCategories);
    emit(state.copyWith(
      items: inventoryItems,
      categories: categories,
      subCategories: subCategories,
      selectedCategoryId: currentCategoryId,
      selectedSubCategoryId: currentSubCategoryId,
    ));
  }

  void _onFilterByCategory(
    FilterByCategory event,
    Emitter<InventoryState> emit,
  ) {
    final filteredSubCategories = event.categoryId == null
        ? <SubCategory>[]
        : _productService.getSubCategoriesByCategoryId(event.categoryId!);

    emit(state.copyWith(
      selectedCategoryId: event.categoryId,
      selectedSubCategoryId: null, // Reset subcategory when category changes
      subCategories: filteredSubCategories,
    ));
  }

  void _onFilterBySubCategory(
    FilterBySubCategory event,
    Emitter<InventoryState> emit,
  ) {
    emit(state.copyWith(
      selectedSubCategoryId: event.subCategoryId,
    ));
  }
}

