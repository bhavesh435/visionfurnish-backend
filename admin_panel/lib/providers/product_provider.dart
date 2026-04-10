import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  List<ProductModel> _products = [];
  int _total = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _error;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  List<ProductModel> get products => _products;
  int get total => _total;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  /// Returns products filtered by the current search query (name or ID).
  List<ProductModel> get filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    final q = _searchQuery.toLowerCase();
    return _products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.id.toString().contains(q);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchProducts({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConfig.products, queryParams: {
        'page': page.toString(),
        'limit': '15',
      });

      if (res['success'] == true) {
        final data = res['data'];
        _products = (data['products'] as List)
            .map((e) => ProductModel.fromJson(e))
            .toList();
        final pag = data['pagination'];
        _currentPage = pag['page'];
        _totalPages = pag['totalPages'];
        _total = pag['total'];
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load products.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createProduct(Map<String, dynamic> body) async {
    try {
      final res = await _api.post(ApiConfig.products, body: body);
      if (res['success'] == true) {
        await fetchProducts(page: _currentPage);
        return true;
      }
      _error = res['message'];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to create product.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> body) async {
    try {
      final res = await _api.put(ApiConfig.product(id), body: body);
      if (res['success'] == true) {
        await fetchProducts(page: _currentPage);
        return true;
      }
      _error = res['message'];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to update product.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final res = await _api.delete(ApiConfig.product(id));
      if (res['success'] == true) {
        await fetchProducts(page: _currentPage);
        return true;
      }
      _error = res['message'];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to delete product.';
    }
    notifyListeners();
    return false;
  }
}
