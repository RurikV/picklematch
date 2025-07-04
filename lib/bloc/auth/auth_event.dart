import 'package:equatable/equatable.dart';
import '../../models/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final User user;
  final String token;

  const LoggedIn({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

class LoggedOut extends AuthEvent {}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;

  const RegisterRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class VerifyEmailRequested extends AuthEvent {}

class GoogleSignInRequested extends AuthEvent {}

class EmailLinkRequested extends AuthEvent {
  final String email;

  const EmailLinkRequested({required this.email});

  @override
  List<Object?> get props => [email];
}
