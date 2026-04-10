import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  List<OrderModel> _orders = [];
  int _total = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _error;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  List<OrderModel> get orders => _orders;
  int get total => _total;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  /// Returns orders filtered by the current search query (customer name or order ID).
  List<OrderModel> get filteredOrders {
    if (_searchQuery.isEmpty) return _orders;
    final q = _searchQuery.toLowerCase();
    return _orders.where((o) {
      return o.id.toString().contains(q) ||
          (o.userName ?? '').toLowerCase().contains(q) ||
          (o.userEmail ?? '').toLowerCase().contains(q);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchOrders({int page = 1, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': '15',
      };
      if (status != null && status.isNotEmpty) {
        params['status'] = status;
      }

      final res = await _api.get(ApiConfig.allOrders, queryParams: params);
      if (res['success'] == true) {
        final data = res['data'];
        _orders = (data['orders'] as List)
            .map((e) => OrderModel.fromJson(e))
            .toList();
        final pag = data['pagination'];
        _currentPage = pag['page'];
        _totalPages = pag['totalPages'];
        _total = pag['total'];
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load orders.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateOrderStatus(int id, String status) async {
    try {
      final res = await _api.put(
        ApiConfig.orderStatus(id),
        body: {'status': status},
      );
      if (res['success'] == true) {
        // Update local state
        final idx = _orders.indexWhere((o) => o.id == id);
        if (idx != -1) {
          await fetchOrders(page: _currentPage);
        }
        return true;
      }
      _error = res['message'];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to update order status.';
    }
    notifyListeners();
    return false;
  }
}
