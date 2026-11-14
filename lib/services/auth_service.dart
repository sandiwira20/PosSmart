import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Stream auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current Firebase user
  User? get currentUser => _auth.currentUser;

  // Login
  Future<UserModel?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user?.uid;
    if (uid == null) return null;
    return await getUserData(uid);
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get user data from Realtime DB
  Future<UserModel?> getUserData(String uid) async {
    final ref = _db.ref('${AppConstants.usersPath}/$uid');
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.value == null) return null;
    final map = Map<dynamic, dynamic>.from(snapshot.value as Map);
    return UserModel.fromMap(uid, map);
  }

  // Create user in Realtime DB (called after Firebase Auth registration)
  Future<void> createUserRecord(UserModel user) async {
    await _db
        .ref('${AppConstants.usersPath}/${user.uid}')
        .set(user.toMap());
  }

  // Update user profile
  Future<void> updateUserRecord(UserModel user) async {
    await _db
        .ref('${AppConstants.usersPath}/${user.uid}')
        .update(user.toMap());
  }

  // Stream all users (admin only)
  Stream<List<UserModel>> streamAllUsers() {
    return _db.ref(AppConstants.usersPath).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final map = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      return map.entries
          .map((e) => UserModel.fromMap(
                e.key as String,
                Map<dynamic, dynamic>.from(e.value as Map),
              ))
          .toList();
    });
  }
}
