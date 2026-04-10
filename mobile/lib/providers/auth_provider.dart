import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  bool _isAuthenticated = false;
  AppUser? _user;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  AppUser? get user => _user;
  String? get error => _error;

  Future<bool> tryAutoLogin() async {
    final t = await _api.token;
    if (t == null) return false;
    try {
      final res = await _api.get(ApiConfig.profile);
      if (res['success'] == true && res['data'] != null) {
        _user = AppUser.fromJson(res['data']);
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    await _api.clearToken();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await _api.post(ApiConfig.login, body: {'email': email, 'password': password});
      if (res['success'] == true && res['data'] != null) {
        await _api.setToken(res['data']['token']);
        _user = AppUser.fromJson(res['data']['user']);
        _isAuthenticated = true;
        _isLoading = false; notifyListeners();
        return true;
      }
      _error = res['message'] ?? 'Login failed';
    } on ApiException catch (e) { _error = e.message; }
    catch (e) { _error = 'Connection error.'; }
    _isLoading = false; notifyListeners();
    return false;
  }

  Future<bool> register(String name, String email, String password, String phone) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await _api.post(ApiConfig.register, body: {
        'name': name, 'email': email, 'password': password, 'phone': phone,
      });
      if (res['success'] == true && res['data'] != null) {
        await _api.setToken(res['data']['token']);
        _user = AppUser.fromJson(res['data']['user']);
        _isAuthenticated = true;
        _isLoading = false; notifyListeners();
        return true;
      }
      _error = res['message'] ?? 'Registration failed';
    } on ApiException catch (e) { _error = e.message; }
    catch (e) { _error = 'Connection error.'; }
    _isLoading = false; notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _api.clearToken();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }
}
