import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/models.dart';

class CartProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  int get itemCount => _items.length;
  double get total => _items.fold(0, (sum, i) => sum + i.total);

  Future<void> fetchCart() async {
    _isLoading = true; notifyListeners();
    try {
      final res = await _api.get(ApiConfig.cart);
      if (res['success'] == true && res['data'] != null) {
        // Backend: { data: { items: [...], summary: {...} } }
        final list = res['data']['items'] ?? [];
        _items = (list as List).map((i) => CartItem.fromJson(i)).toList();
      }
    } catch (e) {
      debugPrint('fetchCart error: $e');
    }
    _isLoading = false; notifyListeners();
  }

  Future<bool> addToCart(int productId, {int quantity = 1}) async {
    try {
      final res = await _api.post(ApiConfig.cart, body: {'product_id': productId, 'quantity': quantity});
      if (res['success'] == true) { await fetchCart(); return true; }
    } catch (e) {
      debugPrint('addToCart error: $e');
    }
    return false;
  }

  Future<void> updateQuantity(int cartItemId, int quantity) async {
    try {
      await _api.put(ApiConfig.cartItem(cartItemId), body: {'quantity': quantity});
      await fetchCart();
    } catch (e) {
      debugPrint('updateQuantity error: $e');
    }
  }

  Future<void> removeItem(int cartItemId) async {
    try {
      await _api.delete(ApiConfig.cartItem(cartItemId));
      _items.removeWhere((i) => i.id == cartItemId);
      notifyListeners();
    } catch (e) {
      debugPrint('removeItem error: $e');
    }
  }

  Future<void> clearCart() async {
    try {
      await _api.delete(ApiConfig.cart);
      _items.clear(); notifyListeners();
    } catch (e) {
      debugPrint('clearCart error: $e');
    }
  }
}

class WishlistProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Product> _items = [];
  final Set<int> _wishlistIds = {};
  bool _isLoading = false;

  List<Product> get items => _items;
  bool get isLoading => _isLoading;
  bool isWishlisted(int productId) => _wishlistIds.contains(productId);

  Future<void> fetchWishlist() async {
    _isLoading = true; notifyListeners();
    try {
      final res = await _api.get(ApiConfig.wishlist);
      if (res['success'] == true && res['data'] != null) {
        // Backend: { data: { items: [...] } }
        final list = res['data']['items'] ?? [];
        _items = (list as List).map((i) {
          // Wishlist items have product_id, name, price etc. at top level
          final p = Product(
            id: i['product_id'] ?? i['id'] ?? 0,
            name: i['name'] ?? '',
            slug: i['slug'] ?? '',
            price: Product.toDouble(i['price']),
            discountPrice: i['discount_price'] != null ? Product.toDouble(i['discount_price']) : null,
            stock: i['stock'] ?? 0,
            imageUrl: i['image_url'],
          );
          return p;
        }).toList();
        _wishlistIds.clear();
        for (final p in _items) { _wishlistIds.add(p.id); }
      }
    } catch (e) {
      debugPrint('fetchWishlist error: $e');
    }
    _isLoading = false; notifyListeners();
  }

  Future<void> toggle(int productId) async {
    try {
      if (_wishlistIds.contains(productId)) {
        await _api.delete(ApiConfig.wishlistRemove(productId));
        _wishlistIds.remove(productId);
        _items.removeWhere((p) => p.id == productId);
      } else {
        await _api.post(ApiConfig.wishlist, body: {'product_id': productId});
        _wishlistIds.add(productId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('toggle wishlist error: $e');
    }
  }
}

class OrderProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Order> _orders = [];
  bool _isLoading = false;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchOrders() async {
    _isLoading = true; notifyListeners();
    try {
      final res = await _api.get(ApiConfig.orders);
      if (res['success'] == true && res['data'] != null) {
        // Backend: { data: { orders: [...], pagination: {...} } }
        final list = res['data']['orders'] ?? [];
        _orders = (list as List).map((o) => Order.fromJson(o)).toList();
      }
    } catch (e) {
      debugPrint('fetchOrders error: $e');
    }
    _isLoading = false; notifyListeners();
  }

  Future<Order?> fetchOrderById(int id) async {
    try {
      final res = await _api.get(ApiConfig.order(id));
      if (res['success'] == true && res['data'] != null) {
        // Backend: { data: { order: {...}, items: [...] } }
        final orderData = res['data']['order'] ?? res['data'];
        final items = res['data']['items'] as List?;
        final order = Order.fromJson({
          ...orderData,
          'items': items,
        });
        return order;
      }
    } catch (e) {
      debugPrint('fetchOrderById error: $e');
    }
    return null;
  }

  Future<bool> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final res = await _api.post(ApiConfig.orders, body: orderData);
      if (res['success'] == true) { await fetchOrders(); return true; }
    } catch (e) {
      debugPrint('placeOrder error: $e');
    }
    return false;
  }
}

class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  List<Map<String, String>> _buildHistory() {
    return _messages.take(8).map((m) => {'role': m.role, 'content': m.content})
        .toList().reversed.take(4).toList();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _messages.insert(0, ChatMessage(role: 'user', content: text.trim()));
    _isLoading = true; notifyListeners();
    try {
      final res = await _api.post(ApiConfig.chat, body: {'message': text.trim(), 'history': _buildHistory()});
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final products = (data['products'] as List? ?? []).map((p) => Product.fromJson(p)).toList();
        _messages.insert(0, ChatMessage(role: 'assistant', content: data['reply'] ?? '', products: products.isNotEmpty ? products : null));
      } else {
        _messages.insert(0, ChatMessage(role: 'assistant', content: 'Something went wrong.'));
      }
    } catch (e) {
      debugPrint('sendMessage error: $e');
      _messages.insert(0, ChatMessage(role: 'assistant', content: 'Connection error. Please try again.'));
    }
    _isLoading = false; notifyListeners();
  }

  void clearChat() { _messages.clear(); notifyListeners(); }
}

class ChatMessage {
  final String role;
  final String content;
  final List<Product>? products;
  ChatMessage({required this.role, required this.content, this.products});
}
