import 'package:equatable/equatable.dart';

enum MenuItem { pos, inventory, items, reports, profitLoss, settings }

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class NavigateToMenuItem extends NavigationEvent {
  final MenuItem item;

  const NavigateToMenuItem(this.item);

  @override
  List<Object?> get props => [item];
}

