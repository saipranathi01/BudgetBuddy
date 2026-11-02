import 'package:flutter/foundation.dart';

import '../models/profile.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  UserModel? _currentUser;
  UserProfile? _profile;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  UserModel? get currentUser => _currentUser;
  UserProfile? get profile => _profile;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final email = await AuthService.getSessionEmail();
    if (email != null && email.isNotEmpty) {
      _currentUser = await DatabaseService.getUserByEmail(email);
      _profile = await DatabaseService.getProfile() ??
          UserProfile(
            id: _currentUser?.id ?? 'local-user',
            name: _currentUser?.name ?? 'Student',
            email: _currentUser?.email ?? email,
          );
      _isAuthenticated = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.signUp(name: name, email: email, password: password);
      _currentUser = await DatabaseService.getUserByEmail(email.trim());
      _profile = UserProfile(
        id: _currentUser?.id ?? 'local-user',
        name: name.trim(),
        email: email.trim(),
      );
      await DatabaseService.upsertProfile(_profile!);
      _isAuthenticated = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await AuthService.login(email: email, password: password);
      if (user == null) {
        throw Exception('Invalid email or password.');
      }
      _currentUser = user;
      _profile = await DatabaseService.getProfile() ??
          UserProfile(
            id: user.id,
            name: user.name,
            email: user.email,
          );
      if (_profile!.email.isEmpty) {
        _profile = UserProfile(
          id: user.id,
          name: user.name,
          email: user.email,
        );
      }
      _isAuthenticated = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _isAuthenticated = false;
    _currentUser = null;
    _profile = null;
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    _profile = profile;
    await DatabaseService.upsertProfile(profile);
    notifyListeners();
  }
}
