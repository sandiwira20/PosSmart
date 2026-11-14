import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isKasir => _user?.isKasir ?? false;

  Future<void> init() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _user = await _authService.getUserData(firebaseUser.uid);
      _status = _user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(email, password);
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Akun tidak ditemukan di sistem.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } on Exception catch (e) {
      _errorMessage = _parseFirebaseError(e.toString());
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _parseFirebaseError(String error) {
    if (error.contains('user-not-found') ||
        error.contains('wrong-password') ||
        error.contains('invalid-credential')) {
      return 'Email atau password salah.';
    } else if (error.contains('too-many-requests')) {
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    } else if (error.contains('network-request-failed')) {
      return 'Tidak ada koneksi internet.';
    }
    return 'Login gagal. Coba lagi.';
  }
}
