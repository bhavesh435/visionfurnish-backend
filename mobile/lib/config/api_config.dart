class ApiConfig {
  // Use your PC's local network IP so physical devices can reach the server
  // PC IP: 192.168.43.233  (update if your WiFi changes)
  static const String baseUrl = 'http://192.168.43.233:5000/api';


  // Auth
  static const String register       = '$baseUrl/auth/register';
  static const String login          = '$baseUrl/auth/login';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String verifyOtp      = '$baseUrl/auth/verify-otp';
  static const String resetPassword  = '$baseUrl/auth/reset-password';
  static const String profile        = '$baseUrl/auth/profile';

  // Products
  static const String products       = '$baseUrl/products';
  static const String productSearch  = '$baseUrl/products/search';
  static String product(int id)      => '$baseUrl/products/$id';

  // Categories
  static const String categories     = '$baseUrl/categories';
  static String category(int id)     => '$baseUrl/categories/$id';

  // Cart
  static const String cart           = '$baseUrl/cart';
  static String cartItem(int id)     => '$baseUrl/cart/$id';

  // Wishlist
  static const String wishlist          = '$baseUrl/wishlist';
  static String wishlistRemove(int pid) => '$baseUrl/wishlist/$pid';

  // Orders
  static const String orders         = '$baseUrl/orders';
  static String order(int id)        => '$baseUrl/orders/$id';

  // Reviews
  static String productReviews(int pid)  => '$baseUrl/reviews/product/$pid';
  static const String reviews            = '$baseUrl/reviews';
  static String review(int id)           => '$baseUrl/reviews/$id';

  // Chat
  static const String chat           = '$baseUrl/chat';
}
