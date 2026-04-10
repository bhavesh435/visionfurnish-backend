import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  String? _userName;
  String? _userEmail;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  /// Returns the stored JWT token (async — stored in secure storage).
  Future<String?> get token => _api.token;


  /// Check if a stored token exists and is valid.
  Future<bool> tryAutoLogin() async {
    final token = await _api.token;
    if (token == null) return false;

    try {
      final res = await _api.get(ApiConfig.profile);
      if (res['success'] == true) {
        final user = res['data']['user'];
        if (user['role'] != 'admin') {
          await _api.clearToken();
          return false;
        }
        _userName = user['name'];
        _userEmail = user['email'];
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
    } catch (_) {
      await _api.clearToken();
    }
    return false;
  }

  /// Login with email + password.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.post(ApiConfig.login, body: {
        'email': email,
        'password': password,
      });

      if (res['success'] == true) {
        final user = res['data']['user'];
        final token = res['data']['token'];

        if (user['role'] != 'admin') {
          _error = 'Access denied. Admin privileges required.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await _api.setToken(token);
        _userName = user['name'];
        _userEmail = user['email'];
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = res['message'] ?? 'Login failed.';
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Connection error. Please check your network.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Logout and clear stored token.
  Future<void> logout() async {
    await _api.clearToken();
    _isAuthenticated = false;
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }
}
