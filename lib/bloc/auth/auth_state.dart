import 'package:equatable/equatable.dart';
import '../../models/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final String token;

  const AuthAuthenticated({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

class AuthUnauthenticated extends AuthState {}

class AuthVerificationNeeded extends AuthState {
  final User user;
  final String token;

  const AuthVerificationNeeded({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class RegistrationSuccess extends AuthState {
  final User user;
  final String token;

  const RegistrationSuccess({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

class RegistrationFailure extends AuthState {
  final String error;

  const RegistrationFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class VerificationSuccess extends AuthState {
  final User user;
  final String token;

  const VerificationSuccess({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

class VerificationFailure extends AuthState {
  final String error;

  const VerificationFailure({required this.error});

  @override
  List<Object?> get props => [error];
}