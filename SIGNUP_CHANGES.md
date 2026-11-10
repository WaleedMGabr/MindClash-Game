# 📋 Sign-Up Feature: What Changes & Impact on `UserModel`

This document details exactly what changes across each layer of the application when you add the **Sign-Up** feature in the future, with a deep dive into **what happens to `UserModel`**.

---

## 📑 Table of Contents
1. [What Happens to `UserModel`?](#1-what-happens-to-usermodel)
   - [Scenario A: Basic Sign-Up (Email & Password only)](#scenario-a-basic-sign-up-email--password-only)
   - [Scenario B: Extended Sign-Up (Username, Firestore Profile, etc.)](#scenario-b-extended-sign-up-username-firestore-profile-etc)
2. [What Changes Across Every Layer?](#2-what-changes-across-every-layer)
   - [Domain Layer](#a-domain-layer)
   - [Data Layer](#b-data-layer)
   - [Presentation Layer](#c-presentation-layer)
   - [Core & Utilities](#d-core--utilities)
   - [Dependency Injection (`main.dart`)](#e-dependency-injection-maindart)
3. [Summary Table of Changes](#3-summary-table-of-changes)

---

## 1. What Happens to `UserModel`?

The impact on `UserModel` depends on whether you only register in Firebase Authentication or also store extra profile data in Cloud Firestore:

### Scenario A: Basic Sign-Up (Email & Password only)
> **Verdict:** `UserModel` needs **ZERO changes**.

When a user signs up using only `FirebaseAuth.instance.createUserWithEmailAndPassword(email, password)`:
- Firebase Auth creates the user and returns a `UserCredential` with a `User` object.
- That `User` object contains `uid`, `email`, and `displayName` (null initially).
- Your existing `UserModel.fromFirebaseUser(credential.user!)` works directly:

```dart
// ALREADY EXISTS IN YOUR CODE — WORKS AS-IS:
factory UserModel.fromFirebaseUser(fb.User user) {
  return UserModel(
    uid: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
  );
}
```

---

### Scenario B: Extended Sign-Up (Username, Firestore Profile, etc.)
> **Verdict:** If you collect extra fields at registration (e.g. `username`, `createdAt`, `score`), both `UserEntity` and `UserModel` will be extended.

For a game like **MindClash**, you usually want a `username`, `avatarUrl`, and initial `score`/`rank` stored in a **Firestore `users` collection**.

Here is what changes:

#### 1. In Domain: `UserEntity` ([user_entity.dart](lib/features/auth/domain/entities/user_entity.dart))
Add the new business fields:
```dart
class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String username;      // ➕ NEW
  final int score;            // ➕ NEW
  final DateTime? createdAt;  // ➕ NEW

  const UserEntity({
    required this.uid,
    required this.email,
    this.displayName,
    required this.username,   // ➕ NEW
    this.score = 0,           // ➕ NEW
    this.createdAt,           // ➕ NEW
  });

  @override
  List<Object?> get props => [uid, email, displayName, username, score, createdAt];
}
```

#### 2. In Data: `UserModel` ([user_model.dart](lib/features/auth/data/models/user_model.dart))
Add serialization for the new fields and Firestore document mapping:
```dart
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    super.displayName,
    required super.username,
    super.score,
    super.createdAt,
  });

  // 1. Convert from Firestore DocumentSnapshot
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      username: data['username'] as String? ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // 2. Convert to Firestore Document Map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'score': score,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }

  // 3. JSON mapping for local caching (optional)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      username: json['username'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'username': username,
      'score': score,
    };
  }
}
```

---

## 2. What Changes Across Every Layer?

Because Clean Architecture is modular, adding Sign-Up is **purely additive**. You do **not** need to rewrite login code.

---

### A. Domain Layer

#### 1. [auth_repository.dart](lib/features/auth/domain/repositories/auth_repository.dart)
Uncomment / add the contract method:
```dart
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> logout();

  // ➕ UNCOMMENT THIS:
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? username, // optional if collecting username
  });
}
```

#### 2. Create `lib/features/auth/domain/usecases/signup_usecase.dart` [NEW FILE]
```dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) async {
    return await repository.signUpWithEmailAndPassword(
      email: params.email,
      password: params.password,
      username: params.username,
    );
  }
}

class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String? username;

  const SignUpParams({
    required this.email,
    required this.password,
    this.username,
  });

  @override
  List<Object?> get props => [email, password, username];
}
```

---

### B. Data Layer

#### 1. [auth_remote_datasource.dart](lib/features/auth/data/datasources/auth_remote_datasource.dart)
Uncomment / add `signUpWithEmailAndPassword`:
```dart
// In AuthRemoteDataSource interface:
Future<UserModel> signUpWithEmailAndPassword({
  required String email,
  required String password,
  String? username,
});

// In AuthRemoteDataSourceImpl:
@override
Future<UserModel> signUpWithEmailAndPassword({
  required String email,
  required String password,
  String? username,
}) async {
  // 1. Create auth user in Firebase Auth
  final credential = await _firebaseAuth.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );

  if (credential.user == null) {
    throw FirebaseAuthException(
      code: 'user-null',
      message: 'Firebase user creation failed',
    );
  }

  // 2. (Optional) If storing profile in Firestore:
  // await FirebaseFirestore.instance
  //     .collection('users')
  //     .doc(credential.user!.uid)
  //     .set({'email': email, 'username': username, 'createdAt': FieldValue.serverTimestamp()});

  return UserModel.fromFirebaseUser(credential.user!);
}
```

#### 2. [auth_repository_impl.dart](lib/features/auth/data/repositories/auth_repository_impl.dart)
Uncomment the implementation of `signUpWithEmailAndPassword`:
```dart
@override
Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword({
  required String email,
  required String password,
  String? username,
}) async {
  try {
    final userModel = await remoteDataSource.signUpWithEmailAndPassword(
      email: email,
      password: password,
      username: username,
    );
    return Right(userModel);
  } on FirebaseAuthException catch (e) {
    return Left(ServerFailure(_mapFirebaseAuthException(e)));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```
*(Notice: The error mapping `_mapFirebaseAuthException` in `AuthRepositoryImpl` ALREADY handles `email-already-in-use` and `weak-password`!)*

---

### C. Presentation Layer

#### 1. [auth_state.dart](lib/features/auth/presentation/cubit/auth_state.dart)
> **No changes needed!**
> `AuthLoading`, `AuthSuccess(user)`, and `AuthFailure(message)` apply equally to sign-up.

#### 2. [auth_cubit.dart](lib/features/auth/presentation/cubit/auth_cubit.dart)
Inject `SignUpUseCase` and add the `signUp` method:
```dart
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final SignUpUseCase signUpUseCase; // ➕ Inject

  AuthCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.signUpUseCase,     // ➕ Require in constructor
  }) : super(const AuthInitial());

  // ➕ New method:
  Future<void> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    emit(const AuthLoading());

    final result = await signUpUseCase(
      SignUpParams(email: email, password: password, username: username),
    );

    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => emit(AuthSuccess(user)),
    );
  }
}
```

#### 3. Create `lib/features/auth/presentation/screens/signup_screen.dart` [NEW FILE]
A screen mirroring `login_screen.dart` that contains the sign-up form and navigates to `HomeScreen` on `AuthSuccess`.

#### 4. Create `lib/features/auth/presentation/widgets/signup_form.dart` [NEW FILE]
A form containing:
- Email field
- Password field
- Confirm Password field
- (Optional) Username field
- "Sign Up" button
- "Already have an account? Log In" link to pop back.

#### 5. [login_form.dart](lib/features/auth/presentation/widgets/login_form.dart)
Enable the bottom button so it navigates to `SignUpScreen`:
```dart
// BEFORE (DISABLED):
TextButton(
  onPressed: null,
  child: const Text('Sign Up (Coming Soon)'),
)

// AFTER (ENABLED):
TextButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  },
  child: const Text('Sign Up'),
)
```

---

### D. Core & Utilities

#### 1. [validators.dart](lib/core/utils/validators.dart)
Add confirm-password validation:
```dart
static String? validateConfirmPassword(String? value, String originalPassword) {
  if (value == null || value.isEmpty) {
    return 'Please confirm your password';
  }
  if (value != originalPassword) {
    return 'Passwords do not match';
  }
  return null;
}
```

---

### E. Dependency Injection (`main.dart`)

#### In [main.dart](lib/main.dart)
Instantiate `SignUpUseCase` and pass it to `AuthCubit`:
```dart
void main() async {
  // ...
  final authRemoteDataSource = AuthRemoteDataSourceImpl();
  final authRepository = AuthRepositoryImpl(remoteDataSource: authRemoteDataSource);
  
  final loginUseCase = LoginUseCase(authRepository);
  final logoutUseCase = LogoutUseCase(authRepository);
  final signUpUseCase = SignUpUseCase(authRepository); // ➕ NEW

  runApp(
    MyApp(
      loginUseCase: loginUseCase,
      logoutUseCase: logoutUseCase,
      signUpUseCase: signUpUseCase,                    // ➕ NEW
    ),
  );
}
```

---

## 3. Summary Table of Changes

| Component / File | What Happens? | Action Needed |
|---|---|---|
| **`UserModel`** (Basic Auth) | **Unchanged**. Uses `fromFirebaseUser`. | None |
| **`UserModel`** (with Firestore Profile) | Extended with `username`, `score`, `fromFirestore`, `toFirestore`. | Add fields & methods |
| **`UserEntity`** | Unchanged (or extended if adding username/score). | Optional fields |
| **`auth_repository.dart`** | Add `signUpWithEmailAndPassword` method signature. | Uncomment contract |
| **`signup_usecase.dart`** | New usecase implementing `UseCase<UserEntity, SignUpParams>`. | Create new file |
| **`auth_remote_datasource.dart`** | Add `createUserWithEmailAndPassword`. | Uncomment method |
| **`auth_repository_impl.dart`** | Implement `signUpWithEmailAndPassword` + error handling. | Uncomment method |
| **`auth_state.dart`** | **Unchanged**. `AuthLoading`, `AuthSuccess`, `AuthFailure` handle both. | None |
| **`auth_cubit.dart`** | Inject `SignUpUseCase` and add `signUp(...)` method. | Add method |
| **`signup_screen.dart`** | New screen containing the sign-up form. | Create new file |
| **`signup_form.dart`** | New widget with Email, Password, and Confirm Password fields. | Create new file |
| **`login_form.dart`** | Enable navigation on the "Sign Up" button. | Replace `onPressed: null` |
| **`validators.dart`** | Add password match validator. | Add helper method |
| **`main.dart`** | Instantiate `SignUpUseCase` and inject into `AuthCubit`. | Wire dependency |

> [!TIP]
> **Key Clean Architecture Takeaway**: 
> Because the login architecture is completely decoupled, adding Sign-Up is **100% additive**. You never have to touch or risk breaking existing Login functionality!
