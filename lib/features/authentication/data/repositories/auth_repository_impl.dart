import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindclash/core/errors/failures.dart';
import 'package:mindclash/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:mindclash/features/authentication/domain/entities/user_entity.dart';
import 'package:mindclash/features/authentication/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource authRemoteDatasource;

  AuthRepositoryImpl(this.authRemoteDatasource);

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await authRemoteDatasource.login(
        email: email,
        password: password,
      );
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailures(e.message ?? 'Authentication failed'));
    } catch (e) {
      return Left(ServerFailures(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signup({
    required String email,
    required String password,
    required String username
  }) async {
    try {
      final user = await authRemoteDatasource.signup(
        email: email,
        password: password,
        username: username
      );
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailures(e.message ?? 'Sign up failed'));
    } on FirebaseException catch (e) {
      return Left(ServerFailures(e.message ?? e.code));
    } catch (e, stackTrace) {
      print("🚨 REAL ERROR: $e");
      print("🚨 STACK: $stackTrace");
      return Left(ServerFailures(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await authRemoteDatasource.logout();
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailures(e.message ?? 'Logout failed'));
    } catch (e) {
      return Left(ServerFailures(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = authRemoteDatasource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(ServerFailures(e.toString()));
    }
  }

  @override
  // TODO: implement authStateChanges
  Stream<UserEntity?> get authStateChanges => authRemoteDatasource.authStateChanges;
}