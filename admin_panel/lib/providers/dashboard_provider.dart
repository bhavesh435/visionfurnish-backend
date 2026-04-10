import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/dashboard_stats_model.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  DashboardStats? _stats;
  String? _error;

  bool get isLoading => _isLoading;
  DashboardStats? get stats => _stats;
  String? get error => _error;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConfig.dashboard);
      if (res['success'] == true) {
        _stats = DashboardStats.fromJson(res['data']);
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load dashboard data.';
    }

    _isLoading = false;
    notifyListeners();
  }
}
