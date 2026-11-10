# MindClash: Authentication Architecture Guide & Review

This document provides a breakdown of the fixes applied to the `data` and `domain` layers of the `authentication` feature, explains the mistakes identified in the original code, and outlines professional techniques to improve code quality.

---

## 1. Summary of Changes

| File | Changes Made |
| :--- | :--- |
| `domain/entities/user_entity.dart` | Renamed folder from `entites` to `entities`. Switched constructor parameters to clean named parameters (`{required this.userId, this.email}`). |
| `domain/repositories/auth_repository.dart` | Standardized methods to `camelCase` (`login`, `signup`). Updated `getCurrentUser()` to return `Future<Either<Failure, UserEntity?>>` and `logout()` to return `Future<Either<Failure, void>>`. |
| `domain/use_cases/auth_usecases.dart` | Renamed `getCurrentUserUseCase` to PascalCase `GetCurrentUserUseCase`. Removed duplicated/case-sensitive imports. Updated signatures to match the repository. |
| `data/models/user_model.dart` | Inherited from `UserEntity` with `super.userId` and `super.email`. Added `fromFirebaseUser(User user)` that takes the actual Firebase `User` object, plus serialization methods (`toMap`, `fromMap`). |
| `data/datasources/auth_remote_datasource.dart` | Removed `await` from the synchronous `firebaseAuth.currentUser` getter. Fixed `getCurrentUser` to return `null` when logged out instead of a dummy user. Added null checks for `credential.user`. |
| `data/repositories/auth_repository_impl.dart` | Added `async`/`await` in `login` and `signup`. Added `try/catch` blocks mapping `FirebaseAuthException` to `AuthFailures` and generic errors to `ServerFailures`. |
| `core/errors/failures.dart` | Added aliases `AuthFailure` and `ServerFailure` to support both singular and plural naming conventions cleanly. |

---

## 2. In-Depth Breakdown of Mistakes

### ❌ Mistake 1: The Case-Sensitive Import Trap
* **What happened:** Some files imported `Entites/user_entity.dart` (capital `E`), while others imported `entites/user_entity.dart` (lowercase `e`).
* **Why it broke:** Even though Windows file paths are case-insensitive, **the Dart Analyzer treats different casing in package URIs as two completely different libraries**. Dart considered `Entites/...:UserEntity` and `entites/...:UserEntity` as distinct, incompatible types, generating the error:
  `A value of type 'Future<UserModel>' can't be returned from the method 'Login' because it has a return type of 'Future<UserEntity>'`.
* **Fix:** Renamed the directory to standard `entities` and standardized all imports to lowercase.

---

### ❌ Mistake 2: Missing `async`/`await` in the Repository
* **What happened:**
  ```dart
  // Original
  Future<Either<Failure, UserEntity>> Login(...) {
    try {
      final user = authRemoteDatasource.login(...); // user is a Future<UserModel>!
      return Right(user); // Returns Right<Future<UserModel>>, NOT Future<Either>!
    } catch(e) { ... }
  }
  ```
* **Why it broke:** `authRemoteDatasource.login(...)` is asynchronous and returns a `Future`. Without `await`, `user` was wrapped inside `Right` while still unresolved. The method also lacked the `async` keyword, leading to compilation failures.
* **Fix:** Marked the method `async` and awaited the datasource call:
  ```dart
  final user = await authRemoteDatasource.login(email: email, password: password);
  return Right(user);
  ```

---

### ❌ Mistake 3: Logic Bug in `getCurrentUser()`
* **What happened:**
  ```dart
  // Original
  final user = await firebaseAuth.currentUser;
  return UserModel(user?.email ?? 'no user', userId: user?.uid ?? 'no user');
  ```
* **Why it was dangerous:**
  1. `firebaseAuth.currentUser` is an in-memory property (getter), not a `Future`. Using `await` was redundant.
  2. If the user was logged out, the code returned a valid `UserModel` with `userId = 'no user'`. Any subsequent code checking `if (user != null)` would consider the visitor logged in!
* **Fix:**
  ```dart
  @override
  UserModel? getCurrentUser() {
    final user = firebaseAuth.currentUser;
    return user != null ? UserModel.fromFirebaseUser(user) : null;
  }
  ```

---

### ❌ Mistake 4: Dangerous Force Unwrap (`!`) on User Credentials
* **What happened:**
  ```dart
  final credential = await firebaseAuth.signInWithEmailAndPassword(...);
  final user = credential.user!; // Force unwrap
  ```
* **Why it was dangerous:** Under edge cases (such as external auth providers, email link confirmations, or network interruptions), `credential.user` can be null. Force unwrapping with `!` triggers an unhandled `NullCheckCrash`.
* **Fix:** Validate nullability and throw a structured `FirebaseAuthException` if null:
  ```dart
  final user = credential.user;
  if (user == null) {
    throw FirebaseAuthException(code: 'user-not-found', message: 'User not found.');
  }
  ```

---

### ❌ Mistake 5: Dart Naming Convention Violations
* **What happened:**
  * Methods: `Login(...)`, `Signup(...)` (PascalCase).
  * Class: `getCurrentUserUseCase` (camelCase).
* **Fix:** In Dart:
  * Methods and functions should always use **lowerCamelCase**: `login()`, `signup()`.
  * Classes and types should always use **UpperCamelCase**: `GetCurrentUserUseCase`.

---

## 3. Techniques & Best Practices to Improve Quality

### 💡 1. The Separation Rule: Exceptions vs Failures
* **Data Layer (Datasource):** Should throw raw or typed **Exceptions** (`FirebaseAuthException`, `ServerException`). It should not know anything about `Either` or domain `Failure`.
* **Repository Layer:** Catches exceptions and converts them into domain **`Failure`** objects (`Left(AuthFailure(e.message))`).
* **Domain & Presentation:** Only handle `Either<Failure, T>`. Your UI never needs to handle raw platform exceptions or crash unexpectedly.

### 💡 2. Reactive Auth with `authStateChanges()`
Rather than only checking `getCurrentUser()` manually on app launch, Firebase provides a real-time auth stream:
```dart
Stream<UserEntity?> get authStateChanges;
```
By listening to this stream in an `AuthCubit` or `AppBloc`, your app automatically switches between the `LoginScreen` and `HomeScreen` whenever a user logs in, signs out, or has their session revoked.

### 💡 3. Separate Auth Credentials from Game Profile Data
For a game like **MindClash**:
* **Firebase Auth** stores credentials (`uid`, `email`).
* **Cloud Firestore** (`users/{uid}`) stores game profile data (username, avatar, rank, coins, match statistics).
* **Next Improvement:** In your `signup()` datasource method, write an initial document to Firestore immediately after creating the Firebase Auth account.

### 💡 4. Use a Base `UseCase<Type, Params>` Contract
To avoid duplicating the `call()` method signature across every usecase, define a base contract in `lib/core/usecases/usecase.dart`:
```dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
```

---

## 4. Verification
The `lib/features/authentication` directory currently passes `flutter analyze` with **0 issues found**.
