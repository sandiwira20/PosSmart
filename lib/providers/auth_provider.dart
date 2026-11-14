import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isKasir => _currentUser?.isKasir ?? false;

  Future<bool> login({
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    // Demo accounts for role testing
    if (selectedRole == 'admin') {
      _currentUser = const UserModel(
        id: 'usr-admin-1',
        name: 'Sandi Wira (Admin)',
        email: 'admin@possmart.com',
        role: 'admin',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
      );
    } else {
      _currentUser = const UserModel(
        id: 'usr-kasir-1',
        name: 'Budi Santoso',
        email: 'kasir@possmart.com',
        role: 'kasir',
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&q=80',
      );
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
