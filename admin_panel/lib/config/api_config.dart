class ApiConfig {
  // Connect to the live Render cloud backend
  static const String baseUrl = 'https://visionfurnish-api.onrender.com/api';

  // Auth
  static const String login          = '$baseUrl/auth/login';
  static const String profile        = '$baseUrl/auth/profile';

  // Admin
  static const String dashboard      = '$baseUrl/admin/dashboard';
  static const String adminUsers     = '$baseUrl/admin/users';
  static String blockUser(int id)    => '$baseUrl/admin/users/$id/block';
  static String deleteUser(int id)   => '$baseUrl/admin/users/$id';

  // Products
  static const String products       = '$baseUrl/products';
  static String product(int id)      => '$baseUrl/products/$id';

  // Categories
  static const String categories     = '$baseUrl/categories';
  static String category(int id)     => '$baseUrl/categories/$id';

  // Orders
  static const String allOrders      = '$baseUrl/orders/all';
  static String orderStatus(int id)  => '$baseUrl/orders/$id/status';

  // Chat
  static const String chat           = '$baseUrl/chat';

  // Upload
  static const String uploadModel    = '$baseUrl/upload/model';

  // AI 2D → 3D Generation (Meshy.ai)
  static String generate3dStart(int productId)                  => '$baseUrl/products/$productId/generate-3d';
  static String generate3dStatus(int productId, String taskId)  => '$baseUrl/products/$productId/generate-3d/$taskId';
}

