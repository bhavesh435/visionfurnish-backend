class ProductColorVariant {
  final String name;
  final String hex;
  final List<String> images;
  ProductColorVariant({required this.name, required this.hex, this.images = const []});
  factory ProductColorVariant.fromJson(Map<String, dynamic> j) => ProductColorVariant(
    name: j['name'] ?? '',
    hex: j['hex'] ?? '#AAAAAA',
    images: j['images'] != null ? List<String>.from(j['images']) : [],
  );
}

class Product {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? discountPrice;
  final int stock;
  final int? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final List<String> images;
  final List<String> images360;
  final List<ProductColorVariant> colorVariants;
  final String? arModel;
  final String? material;
  final String? dimensions;
  final String? color;
  final bool isFeatured;
  final double? avgRating;
  final int? reviewCount;

  Product({
    required this.id, required this.name, required this.slug,
    this.description, required this.price, this.discountPrice,
    required this.stock, this.categoryId, this.categoryName,
    this.imageUrl, this.images = const [], this.images360 = const [],
    this.colorVariants = const [], this.arModel,
    this.material, this.dimensions, this.color,
    this.isFeatured = false, this.avgRating, this.reviewCount,
  });

  static List<T> _parseList<T>(dynamic raw, T Function(dynamic) fromItem) {
    if (raw == null) return [];
    if (raw is List) return raw.map(fromItem).toList();
    return [];
  }

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] ?? 0,
    name: j['name'] ?? '',
    slug: j['slug'] ?? '',
    description: j['description'],
    price: Product.toDouble(j['price']),
    discountPrice: j['discount_price'] != null ? Product.toDouble(j['discount_price']) : null,
    stock: j['stock'] ?? 0,
    categoryId: j['category_id'],
    categoryName: j['category_name'],
    imageUrl: j['image_url'],
    images: Product._parseList(j['images'], (e) => e.toString()),
    images360: Product._parseList(j['images_360'], (e) => e.toString()),
    colorVariants: Product._parseList(j['color_variants'],
        (e) => ProductColorVariant.fromJson(e as Map<String, dynamic>)),
    arModel: j['ar_model'],
    material: j['material'],
    dimensions: j['dimensions'],
    color: j['color'],
    isFeatured: j['is_featured'] == 1 || j['is_featured'] == true,
    avgRating: j['avg_rating'] != null ? Product.toDouble(j['avg_rating']) : null,
    reviewCount: j['review_count'],
  );

  double get effectivePrice => discountPrice ?? price;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  int get discountPercent => hasDiscount ? (((price - discountPrice!) / price) * 100).round() : 0;

  static double toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;

}


class Category {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;

  Category({required this.id, required this.name, required this.slug, this.description, this.imageUrl});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: j['id'] ?? 0,
    name: j['name'] ?? '',
    slug: j['slug'] ?? '',
    description: j['description'],
    imageUrl: j['image_url'],
  );
}

class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String? imageUrl;
  final double price;
  final double? discountPrice;
  int quantity;

  CartItem({
    required this.id, required this.productId, required this.productName,
    this.imageUrl, required this.price, this.discountPrice, required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
    id: j['id'] ?? 0,
    productId: j['product_id'] ?? 0,
    productName: j['product_name'] ?? j['name'] ?? '',
    imageUrl: j['image_url'],
    price: Product.toDouble(j['price']),
    discountPrice: j['discount_price'] != null ? Product.toDouble(j['discount_price']) : null,
    quantity: j['quantity'] ?? 1,
  );

  double get effectivePrice => discountPrice ?? price;
  double get total => effectivePrice * quantity;
}

class Order {
  final int id;
  final double total;
  final String status;
  final String? shippingAddress;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? phone;
  final String? paymentMethod;
  final String createdAt;
  final List<OrderItem>? items;

  Order({
    required this.id, required this.total, required this.status,
    this.shippingAddress, this.city, this.state, this.zipCode,
    this.phone, this.paymentMethod, required this.createdAt, this.items,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'] ?? 0,
    total: Product.toDouble(j['total']),
    status: j['status'] ?? 'pending',
    shippingAddress: j['shipping_address'],
    city: j['city'],
    state: j['state'],
    zipCode: j['zip_code'],
    phone: j['phone'],
    paymentMethod: j['payment_method'],
    createdAt: j['created_at']?.toString() ?? '',
    items: j['items'] != null ? (j['items'] as List).map((i) => OrderItem.fromJson(i)).toList() : null,
  );
}

class OrderItem {
  final int id;
  final int productId;
  final String? productName;
  final String? imageUrl;
  final int quantity;
  final double unitPrice;

  OrderItem({required this.id, required this.productId, this.productName, this.imageUrl, required this.quantity, required this.unitPrice});

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    id: j['id'] ?? 0,
    productId: j['product_id'] ?? 0,
    productName: j['product_name'] ?? j['name'],
    imageUrl: j['image_url'],
    quantity: j['quantity'] ?? 1,
    unitPrice: Product.toDouble(j['unit_price']),
  );
}

class Review {
  final int id;
  final int userId;
  final String? userName;
  final int productId;
  final int rating;
  final String? comment;
  final String createdAt;

  Review({required this.id, required this.userId, this.userName, required this.productId, required this.rating, this.comment, required this.createdAt});

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    id: j['id'] ?? 0,
    userId: j['user_id'] ?? 0,
    userName: j['user_name'] ?? j['name'],
    productId: j['product_id'] ?? 0,
    rating: j['rating'] ?? 0,
    comment: j['comment'],
    createdAt: j['created_at']?.toString() ?? '',
  );
}

class AppUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? avatarUrl;

  AppUser({required this.id, required this.name, required this.email, this.phone, required this.role, this.avatarUrl});

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'] ?? 0,
    name: j['name'] ?? '',
    email: j['email'] ?? '',
    phone: j['phone'],
    role: j['role'] ?? 'user',
    avatarUrl: j['avatar_url'],
  );
}
