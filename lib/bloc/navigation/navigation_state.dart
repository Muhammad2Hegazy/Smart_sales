import 'package:equatable/equatable.dart';
import 'navigation_event.dart';

class NavigationState extends Equatable {
  final MenuItem selectedItem;

  const NavigationState({this.selectedItem = MenuItem.pos});

  NavigationState copyWith({MenuItem? selectedItem}) {
    return NavigationState(
      selectedItem: selectedItem ?? this.selectedItem,
    );
  }

  @override
  List<Object?> get props => [selectedItem];
}

