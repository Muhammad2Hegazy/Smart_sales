import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/cart_item.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddItemToCart>(_onAddItemToCart);
    on<RemoveItemFromCart>(_onRemoveItemFromCart);
    on<UpdateItemQuantity>(_onUpdateItemQuantity);
    on<ClearCart>(_onClearCart);
    on<SetOrderNumber>(_onSetOrderNumber);
  }

  void _onAddItemToCart(AddItemToCart event, Emitter<CartState> emit) {
    final existingIndex = state.items.indexWhere(
      (item) => item.id == event.item.id,
    );

    if (existingIndex != -1) {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = CartItem(
        id: updatedItems[existingIndex].id,
        name: updatedItems[existingIndex].name,
        price: updatedItems[existingIndex].price,
        quantity: updatedItems[existingIndex].quantity + 1,
      );
      emit(state.copyWith(items: updatedItems));
    } else {
      emit(state.copyWith(items: [...state.items, event.item]));
    }
  }

  void _onRemoveItemFromCart(
    RemoveItemFromCart event,
    Emitter<CartState> emit,
  ) {
    final updatedItems = state.items.where(
      (item) => item.id != event.itemId,
    ).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void _onUpdateItemQuantity(
    UpdateItemQuantity event,
    Emitter<CartState> emit,
  ) {
    final updatedItems = List<CartItem>.from(state.items);
    final index = updatedItems.indexWhere((item) => item.id == event.itemId);
    
    if (index != -1) {
      if (event.quantity <= 0) {
        updatedItems.removeAt(index);
      } else {
        updatedItems[index] = CartItem(
          id: updatedItems[index].id,
          name: updatedItems[index].name,
          price: updatedItems[index].price,
          quantity: event.quantity,
        );
      }
      emit(state.copyWith(items: updatedItems));
    }
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState());
  }

  void _onSetOrderNumber(SetOrderNumber event, Emitter<CartState> emit) {
    emit(state.copyWith(orderNumber: event.orderNumber));
  }
}

