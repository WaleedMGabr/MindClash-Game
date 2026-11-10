// Dartz functional programming types (Either, Right, Left).
import 'package:dartz/dartz.dart';

// Flutter test framework for widget testing and assertions.
import 'package:flutter_test/flutter_test.dart';

// Domain-level failure classes.
import 'package:mindclash/core/errors/failures.dart';

// Domain entities and abstract contracts.
import 'package:mindclash/features/auth/domain/entities/user_entity.dart';
import 'package:mindclash/features/auth/domain/repositories/auth_repository.dart';

// Domain use cases tested with the UI.
import 'package:mindclash/features/auth/domain/usecases/login_usecase.dart';
import 'package:mindclash/features/auth/domain/usecases/logout_usecase.dart';

// Root app entry widget.
import 'package:mindclash/main.dart';

/// [FakeAuthRepository] is a test double (Fake) used for widget testing.
///
/// Why use a FakeRepository instead of real Firebase?
/// 1. **No External Network/Firebase Calls**: Tests run completely offline and in milliseconds.
/// 2. **Clean Architecture Benefit**: Because the domain layer depends only on the abstract [AuthRepository],
///    we can inject this fake repository into [LoginUseCase] and [LogoutUseCase] seamlessly.
class FakeAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, UserEntity>> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return const Right(UserEntity(uid: '123', email: 'test@example.com'));
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return const Right(null);
  }
}

void main() {
  testWidgets('Login screen renders title and login button', (WidgetTester tester) async {
    // 1. Arrange: Instantiate fake repository and use cases.
    final fakeRepo = FakeAuthRepository();
    final loginUseCase = LoginUseCase(fakeRepo);
    final logoutUseCase = LogoutUseCase(fakeRepo);

    // 2. Act: Pump the MyApp widget tree into the tester.
    await tester.pumpWidget(
      MyApp(
        loginUseCase: loginUseCase,
        logoutUseCase: logoutUseCase,
      ),
    );

    // 3. Assert: Verify the expected UI widgets are rendered on the screen.
    expect(find.text('MindClash'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
