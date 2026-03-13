import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  static Future<AuthResponse?> login(String username, String password) async {
    try {
      final response = await ApiService.dio.post('login/', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final authData = AuthResponse.fromJson(response.data);
        await _saveAuthData(authData);
        return authData;
      }
      return null;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<void> _saveAuthData(AuthResponse data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, data.token);
    await prefs.setString(_userKey, jsonEncode({
      'username': data.username,
      'role': data.role,
    }));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
