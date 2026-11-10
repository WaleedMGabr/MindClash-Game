import 'package:dartz/dartz.dart';
import 'package:mindclash/core/errors/failures.dart';
import 'package:mindclash/features/authentication/domain/entities/user_entity.dart';
import 'package:mindclash/features/authentication/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository authRepo;

  LoginUseCase(this.authRepo);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
  }) {
    return authRepo.login(
      email: email,
      password: password,
    );
  }
}

class SignupUseCase {
  final AuthRepository authRepo;

  SignupUseCase(this.authRepo);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required String username
  }) {
    return authRepo.signup(
      email: email,
      password: password,
      username: username,
    );
  }
}

class LogoutUseCase {
  final AuthRepository authRepo;

  LogoutUseCase(this.authRepo);

  Future<Either<Failure, void>> call() {
    return authRepo.logout();
  }
}

class GetCurrentUserUseCase {
  final AuthRepository authRepo;

  GetCurrentUserUseCase(this.authRepo);

  Future<Either<Failure, UserEntity?>> call() {
    return authRepo.getCurrentUser();
  }
}