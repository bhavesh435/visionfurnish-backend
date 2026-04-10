import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  String? _token;

  Future<String?> get token async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<Map<String, String>> _headers() async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  // ── HTTP Methods ────────────────────────────────────────

  Future<Map<String, dynamic>> get(String url, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: await _headers());
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> post(String url, {Map<String, dynamic>? body}) async {
    final res = await http.post(
      Uri.parse(url),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> put(String url, {Map<String, dynamic>? body}) async {
    final res = await http.put(
      Uri.parse(url),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> delete(String url) async {
    final res = await http.delete(Uri.parse(url), headers: await _headers());
    return _handleResponse(res);
  }

  // ── Response handler ──────────────────────────────────────

  Map<String, dynamic> _handleResponse(http.Response res) {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    // Build detailed error message from validation errors if available
    String message = data['message'] ?? 'Something went wrong';
    if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
      final details = (data['errors'] as List)
          .map((e) => '${e['field']}: ${e['message']}')
          .join(', ');
      message = '$message ($details)';
    }

    throw ApiException(message, res.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
