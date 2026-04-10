import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  List<UserModel> _users = [];
  int _total = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _error;

  bool get isLoading => _isLoading;
  List<UserModel> get users => _users;
  int get total => _total;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String? get error => _error;

  Future<void> fetchUsers({int page = 1, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': '15',
      };
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final res = await _api.get(ApiConfig.adminUsers, queryParams: params);
      if (res['success'] == true) {
        final data = res['data'];
        // Password is NEVER returned by the API
        _users = (data['users'] as List)
            .map((e) => UserModel.fromJson(e))
            .toList();
        final pag = data['pagination'];
        _currentPage = pag['page'];
        _totalPages = pag['totalPages'];
        _total = pag['total'];
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load users.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> toggleBlockUser(int id) async {
    try {
      final res = await _api.put(ApiConfig.blockUser(id));
      if (res['success'] == true) {
        // Update local state
        final idx = _users.indexWhere((u) => u.id == id);
        if (idx != -1) {
          await fetchUsers(page: _currentPage);
        }
        return true;
      }
      _error = res['message'];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to update user status.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> deleteUser(int id) async {
    try {
      final res = await _api.delete(ApiConfig.deleteUser(id));
      if (res['success'] == true) {
        await fetchUsers(page: _currentPage);
        return true;
      }
      _error = res['message'];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to delete user.';
    }
    notifyListeners();
    return false;
  }
}
