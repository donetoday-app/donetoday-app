import 'package:flutter/foundation.dart';

@immutable
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthLoggedIn extends AuthState {
  final String token;
  final Map<String, dynamic> userDetails;

  AuthLoggedIn({required this.token, required this.userDetails});
}

class AuthLoggedOut extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}
