import 'package:equatable/equatable.dart';
import '../../../core/models/category.dart';
import '../../../core/models/sub_category.dart';
import '../../../core/models/item.dart';
import '../../../core/models/note.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  const LoadProducts();
}

class ImportCategories extends ProductEvent {
  final List<Category> categories;
  const ImportCategories(this.categories);

  @override
  List<Object?> get props => [categories];
}

class ImportSubCategories extends ProductEvent {
  final List<SubCategory> subCategories;
  const ImportSubCategories(this.subCategories);

  @override
  List<Object?> get props => [subCategories];
}

class ImportItems extends ProductEvent {
  final List<Item> items;
  const ImportItems(this.items);

  @override
  List<Object?> get props => [items];
}

class ImportNotes extends ProductEvent {
  final List<Note> notes;
  const ImportNotes(this.notes);

  @override
  List<Object?> get props => [notes];
}

