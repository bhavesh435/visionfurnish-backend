import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/models.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Product> _products = [];
  List<Product> _featured = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  int _page = 1;
  int _totalPages = 1;

  List<Product> get products => _products;
  List<Product> get featured => _featured;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasMore => _page < _totalPages;

  Future<void> fetchCategories() async {
    try {
      final res = await _api.get(ApiConfig.categories);
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        // Backend returns { data: { categories: [...] } }
        final list = data['categories'] ?? (data is List ? data : []);
        _categories = (list as List).map((c) => Category.fromJson(c)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchCategories error: $e');
    }
  }

  Future<void> fetchProducts({int? categoryId, bool reset = false}) async {
    if (reset) { _page = 1; _products = []; }
    _isLoading = true; notifyListeners();
    try {
      final params = <String, String>{'page': '$_page', 'limit': '15'};
      // Backend uses category_id not category
      if (categoryId != null) params['category_id'] = '$categoryId';
      // On reset/refresh, randomize product order
      if (reset) params['sort'] = 'random';
      final res = await _api.get(ApiConfig.products, queryParams: params);
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        // Backend returns { data: { products: [...], pagination: {...} } }
        final list = data['products'] ?? (data is List ? data : []);
        final newProducts = (list as List).map((p) => Product.fromJson(p)).toList();
        if (reset) { _products = newProducts; } else { _products.addAll(newProducts); }
        if (data['pagination'] != null) {
          _totalPages = data['pagination']['totalPages'] ?? 1;
        }
      }
    } catch (e) {
      debugPrint('fetchProducts error: $e');
    }
    _isLoading = false; notifyListeners();
  }

  Future<void> fetchFeatured() async {
    try {
      // Backend uses is_featured not featured
      final res = await _api.get(ApiConfig.products, queryParams: {'is_featured': 'true', 'limit': '10'});
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final list = data['products'] ?? (data is List ? data : []);
        _featured = (list as List).map((p) => Product.fromJson(p)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchFeatured error: $e');
    }
  }

  Future<void> loadMore({int? categoryId}) async {
    if (!hasMore || _isLoading) return;
    _page++;
    await fetchProducts(categoryId: categoryId);
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final res = await _api.get(ApiConfig.productSearch, queryParams: {'q': query});
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final list = data['products'] ?? (data is List ? data : []);
        return (list as List).map((p) => Product.fromJson(p)).toList();
      }
    } catch (e) {
      debugPrint('searchProducts error: $e');
    }
    return [];
  }

  Future<Product?> fetchProductById(int id) async {
    try {
      final res = await _api.get(ApiConfig.product(id));
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        // Backend returns { data: { product: {...} } }
        final productData = data['product'] ?? data;
        return Product.fromJson(productData);
      }
    } catch (e) {
      debugPrint('fetchProductById error: $e');
    }
    return null;
  }
}
