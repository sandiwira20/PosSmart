import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isKasir => _currentUser?.isKasir ?? false;

  AuthProvider() {
    _checkCurrentUser();
  }

  /// Cek session user saat aplikasi baru dibuka
  Future<void> _checkCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseService.usersRef.child(user.uid).get();
        if (snapshot.exists && snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
          _currentUser = UserModel.fromMap(data.cast<String, dynamic>(), user.uid);
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error restoring user session: $e');
      }
    }
  }

  /// Login menggunakan Firebase Authentication
  Future<bool> login({
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCredential;
      try {
        // Coba login dengan kredensial yang ada
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        // Jika user belum terdaftar di Firebase Console, daftarkan otomatis agar praktis
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final user = userCredential.user;
      if (user == null) {
        _errorMessage = 'Gagal mendapatkan data user';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Cek apakah data user sudah ada di Realtime Database
      final snapshot = await FirebaseService.usersRef.child(user.uid).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        _currentUser = UserModel.fromMap(data.cast<String, dynamic>(), user.uid);

        // Update role jika diperlukan agar sesuai role yang dipilih saat login
        if (_currentUser?.role.toLowerCase() != selectedRole.toLowerCase()) {
          _currentUser = UserModel(
            id: user.uid,
            name: _currentUser?.name ?? (selectedRole == 'admin' ? 'Admin' : 'Kasir'),
            email: email,
            role: selectedRole,
            avatarUrl: _currentUser?.avatarUrl,
          );
          await FirebaseService.usersRef.child(user.uid).set(_currentUser!.toMap());
        }
      } else {
        // Buat profil user baru di Realtime Database
        final name = selectedRole == 'admin' ? 'Administrator' : 'Kasir PosSmart';
        final avatar = selectedRole == 'admin'
            ? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80'
            : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&q=80';

        _currentUser = UserModel(
          id: user.uid,
          name: name,
          email: email,
          role: selectedRole,
          avatarUrl: avatar,
        );
        await FirebaseService.usersRef.child(user.uid).set(_currentUser!.toMap());
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      switch (e.code) {
        case 'wrong-password':
          _errorMessage = 'Password salah, silakan coba lagi.';
          break;
        case 'invalid-email':
          _errorMessage = 'Format email tidak valid.';
          break;
        case 'user-disabled':
          _errorMessage = 'Akun ini telah dinonaktifkan.';
          break;
        default:
          _errorMessage = e.message ?? 'Terjadi kesalahan saat login.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Logout dari Firebase Auth
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
