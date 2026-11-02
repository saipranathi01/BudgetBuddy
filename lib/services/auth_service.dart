import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthService {
  static const String _sessionKey = 'budgetbuddy_session_email';

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final existing = await DatabaseService.getUserByEmail(normalizedEmail);
    if (existing != null) {
      throw Exception('An account with this email already exists.');
    }

    final user = UserModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: hashPassword(password),
    );

    await DatabaseService.insertUser(user);
    await saveSessionEmail(normalizedEmail);
    return true;
  }

  static Future<UserModel?> login({required String email, required String password}) async {
    final normalizedEmail = email.trim();
    final user = await DatabaseService.getUserByEmail(normalizedEmail);
    if (user == null) return null;

    final inputHash = hashPassword(password);
    if (user.passwordHash != inputHash) {
      return null;
    }

    await saveSessionEmail(normalizedEmail);
    return user;
  }

  static Future<void> saveSessionEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, email);
  }

  static Future<String?> getSessionEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
