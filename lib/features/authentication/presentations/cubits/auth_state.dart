part of 'auth_cubit.dart';

sealed class AuthState extends Equatable {}

final class AuthInitial extends AuthState {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

final class AuthLoading extends AuthState {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

final class Unauthenticated extends AuthState {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

final class AuthSuccess extends AuthState {
  final UserEntity user;
  AuthSuccess(this.user);

  @override
  // TODO: implement props
  List<Object?> get props => [user];
}


final class AuthError extends AuthState {
  final String message;
  AuthError(this.message);

  @override
  // TODO: implement props
  List<Object?> get props => [message];
}

///authlogged ?!!
