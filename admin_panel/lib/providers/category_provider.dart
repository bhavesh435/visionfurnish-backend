import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  List<CategoryModel> _categories = [];
  String? _error;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  List<CategoryModel> get categories => _categories;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  /// Returns categories filtered by the current search query (name or ID).
  List<CategoryModel> get filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    final q = _searchQuery.toLowerCase();
    return _categories.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.id.toString().contains(q);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConfig.categories);
      if (res['success'] == true) {
        _categories = (res['data']['categories'] as List)
            .map((e) => CategoryModel.fromJson(e))
            .toList();
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load categories.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCategory(Map<String, dynamic> body) async {
    try {
      final res = await _api.post(ApiConfig.categories, body: body);
      if (res['success'] == true) {
        await fetchCategories();
        return true;
      }
      _error = res['message'];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to create category.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> updateCategory(int id, Map<String, dynamic> body) async {
    try {
      final res = await _api.put(ApiConfig.category(id), body: body);
      if (res['success'] == true) {
        await fetchCategories();
        return true;
      }
      _error = res['message'];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to update category.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final res = await _api.delete(ApiConfig.category(id));
      if (res['success'] == true) {
        await fetchCategories();
        return true;
      }
      _error = res['message'];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to delete category.';
    }
    notifyListeners();
    return false;
  }
}
