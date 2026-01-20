import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../../../core/services/product_service.dart';
import '../../../core/models/category.dart';
import '../../../core/models/sub_category.dart';
import '../../../core/models/item.dart';
import '../../../core/models/note.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductService _productService;

  ProductBloc({ProductService? productService})
      : _productService = productService ?? ProductService(),
        super(const ProductState()) {
    on<LoadProducts>(_onLoadProducts);
    on<ImportCategories>(_onImportCategories);
    on<ImportSubCategories>(_onImportSubCategories);
    on<ImportItems>(_onImportItems);
    on<ImportNotes>(_onImportNotes);
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<ProductState> emit) async {
    // Reload from database to get latest data
    await _productService.reloadFromDatabase();
    final List<Category> categories = List<Category>.from(_productService.categories);
    final List<SubCategory> subCategories = List<SubCategory>.from(_productService.subCategories);
    final List<Item> items = List<Item>.from(_productService.items);
    final List<Note> notes = List<Note>.from(_productService.notes);
    emit(state.copyWith(
      categories: categories,
      subCategories: subCategories,
      items: items,
      notes: notes,
    ));
  }

  Future<void> _onImportCategories(
    ImportCategories event,
    Emitter<ProductState> emit,
  ) async {
    await _productService.importCategories(event.categories);
    emit(state.copyWith(
      categories: List<Category>.from(_productService.categories),
      subCategories: List<SubCategory>.from(_productService.subCategories),
      items: List<Item>.from(_productService.items),
    ));
  }

  Future<void> _onImportSubCategories(
    ImportSubCategories event,
    Emitter<ProductState> emit,
  ) async {
    await _productService.importSubCategories(event.subCategories);
    emit(state.copyWith(
      subCategories: _productService.subCategories,
      items: _productService.items,
    ));
  }

  Future<void> _onImportItems(ImportItems event, Emitter<ProductState> emit) async {
    await _productService.importItems(event.items);
    // Reload from database to ensure we have the latest data including all items
    await _productService.reloadFromDatabase();
    
    // Emit new state with all data from database
    final List<Category> categories = List<Category>.from(_productService.categories);
    final List<SubCategory> subCategories = List<SubCategory>.from(_productService.subCategories);
    final List<Item> items = List<Item>.from(_productService.items);
    final List<Note> notes = List<Note>.from(_productService.notes);
    final newState = state.copyWith(
      categories: categories,
      subCategories: subCategories,
      items: items,
      notes: notes,
    );
    
    emit(newState);
    
    // Debug: Print item count
    debugPrint('Imported ${event.items.length} items. Total items in state: ${newState.items.length}');
    debugPrint('POS-only items: ${newState.items.where((item) => item.isPosOnly).length}');
  }

  Future<void> _onImportNotes(ImportNotes event, Emitter<ProductState> emit) async {
    await _productService.importNotes(event.notes);
    emit(state.copyWith(
      notes: _productService.notes,
    ));
    // Relink notes to items
    await _productService.importItems(_productService.items);
    emit(state.copyWith(
      items: _productService.items,
    ));
  }
}

