import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final List<ChatProduct>? products;

  ChatMessage({required this.role, required this.content, this.products});
}

class ChatProduct {
  final int id;
  final String name;
  final double price;
  final double? discountPrice;
  final String? image;
  final String? category;
  final String? material;
  final String? color;

  ChatProduct({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice,
    this.image,
    this.category,
    this.material,
    this.color,
  });

  factory ChatProduct.fromJson(Map<String, dynamic> json) {
    return ChatProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discountPrice'] != null ? (json['discountPrice']).toDouble() : null,
      image: json['image'],
      category: json['category'],
      material: json['material'],
      color: json['color'],
    );
  }
}

class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  /// Build history for API (last 4 messages, role + content only)
  List<Map<String, String>> _buildHistory() {
    return _messages
        .take(8)
        .map((m) => {'role': m.role, 'content': m.content})
        .toList()
        .reversed
        .take(4)
        .toList();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    _messages.insert(0, ChatMessage(role: 'user', content: text.trim()));
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.post(ApiConfig.chat, body: {
        'message': text.trim(),
        'history': _buildHistory(),
      });

      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final reply = data['reply'] ?? 'Sorry, I could not process that.';
        final productList = (data['products'] as List? ?? [])
            .map((p) => ChatProduct.fromJson(p))
            .toList();

        _messages.insert(
          0,
          ChatMessage(
            role: 'assistant',
            content: reply,
            products: productList.isNotEmpty ? productList : null,
          ),
        );
      } else {
        _messages.insert(
          0,
          ChatMessage(role: 'assistant', content: res['message'] ?? 'Something went wrong.'),
        );
      }
    } catch (e) {
      _messages.insert(
        0,
        ChatMessage(role: 'assistant', content: 'Connection error. Please try again.'),
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}
