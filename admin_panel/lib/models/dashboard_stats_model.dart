class DashboardStats {
  final int totalUsers;
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;
  final int pendingOrders;
  final List<MonthlyRevenue> monthlyRevenue;
  final List<RecentOrder> recentOrders;

  DashboardStats({
    required this.totalUsers,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalRevenue,
    required this.pendingOrders,
    required this.monthlyRevenue,
    required this.recentOrders,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['total_users'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] is String)
          ? double.parse(json['total_revenue'])
          : (json['total_revenue'] ?? 0).toDouble(),
      pendingOrders: json['pending_orders'] ?? 0,
      monthlyRevenue: (json['monthly_revenue'] as List?)
              ?.map((e) => MonthlyRevenue.fromJson(e))
              .toList() ??
          [],
      recentOrders: (json['recent_orders'] as List?)
              ?.map((e) => RecentOrder.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class MonthlyRevenue {
  final String month;
  final double revenue;
  final int orders;

  MonthlyRevenue({
    required this.month,
    required this.revenue,
    required this.orders,
  });

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenue(
      month: json['month'] ?? '',
      revenue: (json['revenue'] is String)
          ? double.parse(json['revenue'])
          : (json['revenue'] ?? 0).toDouble(),
      orders: json['orders'] ?? 0,
    );
  }
}

class RecentOrder {
  final int id;
  final double total;
  final String status;
  final String createdAt;
  final String userName;
  final String userEmail;

  RecentOrder({
    required this.id,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.userName,
    required this.userEmail,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      id: json['id'],
      total: (json['total'] is String)
          ? double.parse(json['total'])
          : (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      userName: json['user_name'] ?? '',
      userEmail: json['user_email'] ?? '',
    );
  }
}
