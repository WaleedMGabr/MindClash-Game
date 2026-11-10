import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String msg;
  String get message => msg;

  const Failure(this.msg);

  @override
  List<Object?> get props => [msg];
}

class AuthFailures extends Failure {
  const AuthFailures(super.msg);
}

class ServerFailures extends Failure {
  const ServerFailures(super.msg);
}

// Aliases for singular naming convention
typedef AuthFailure = AuthFailures;
typedef ServerFailure = ServerFailures;