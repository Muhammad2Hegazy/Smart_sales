import 'package:equatable/equatable.dart';

/// Auth Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check authentication status
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Sign up event
class AuthSignUpRequested extends AuthEvent {
  final String username;
  final String password;
  final String? name;

  const AuthSignUpRequested({
    required this.username,
    required this.password,
    this.name,
  });

  @override
  List<Object?> get props => [username, password, name];
}

/// Sign in event
class AuthSignInRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthSignInRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

/// Sign out event
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

