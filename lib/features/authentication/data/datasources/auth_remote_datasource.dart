import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindclash/features/authentication/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AuthRemoteDatasource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> signup({required String email, required String password , required String username});
  Future<void> logout();
  UserModel? getCurrentUser();
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDatasourceImpl(this.firebaseAuth);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user found for these credentials.',
      );
    }

    return UserModel.fromFirebaseUser(user);
  }

  @override
  Future<UserModel> signup({
    required String email,
    required String password,
    required String username
  }) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    print("👉 Step 1: Checking username uniqueness in Firestore...");
    final isUnique = await isUsernameUnique(username, firestore);
    print("👉 Step 1 result: isUnique = $isUnique");
    if (!isUnique) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
        message: 'This username is already taken. Please choose another.',
      );
    }

    print("👉 Step 2: Creating user in Firebase Auth ($email)...");
    UserCredential credential;
    try {
      credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("👉 Step 2 result: User created successfully! UID: ${credential.user?.uid}");
    } catch (e) {
      print("❌ Step 2 FAILED!");
      print("❌ Error runtimeType: ${e.runtimeType}");
      print("❌ Error details: $e");
      if (e is FirebaseAuthException) {
        print("❌ FirebaseAuth code: ${e.code}");
        print("❌ FirebaseAuth message: ${e.message}");
      }
      rethrow;
    }

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'Failed to create user account.',
      );
    }

    print("👉 Step 3: Updating display name...");
    try {
      await user.updateDisplayName(username.toLowerCase());
    } catch (e) {
      print("⚠️ Warning: updateDisplayName failed: $e");
    }

    final userModel = UserModel(
      userId: user.uid,
      email: user.email ?? email,
      username: username,
    );
    
    print("👉 Step 4: Writing user profile to Firestore collection 'users'...");
    await firestore.collection('users').doc(user.uid).set(userModel.toMap());
    print("👉 Step 4 result: User profile successfully written to Firestore!");

    return userModel;
  }

  @override
  UserModel? getCurrentUser() {
    final user = firebaseAuth.currentUser;
    return user != null ? UserModel.fromFirebaseUser(user) : null;
  }

  @override
  Future<void> logout() {
    return firebaseAuth.signOut();
  }

  @override
  // TODO: implement authStateChanges
  Stream<UserModel?> get authStateChanges => firebaseAuth.authStateChanges()
      .map((user) => user != null ? UserModel.fromFirebaseUser(user) : null);
}


Future<bool> isUsernameUnique(String username , FirebaseFirestore firestore) async{
  final usernameQuery = await firestore.collection('users')
      .where('username' , isEqualTo: username.toLowerCase()).limit(1).get();
  if(usernameQuery.docs.isEmpty){
    return true;
  }
  return false;
}