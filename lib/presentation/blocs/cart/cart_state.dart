import 'package:equatable/equatable.dart';
import '../../../core/models/cart_item.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final int? orderNumber;

  const CartState({
    this.items = const [],
    this.orderNumber,
  });

  double get total {
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  CartState copyWith({
    List<CartItem>? items,
    int? orderNumber,
  }) {
    return CartState(
      items: items ?? this.items,
      orderNumber: orderNumber ?? this.orderNumber,
    );
  }

  @override
  List<Object?> get props => [items, orderNumber];
}

