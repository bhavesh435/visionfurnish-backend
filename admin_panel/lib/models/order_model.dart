class OrderModel {
  final int id;
  final int userId;
  final String? userName;
  final String? userEmail;
  final double total;
  final String status;
  final String shippingAddress;
  final String phone;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? paymentMethod;
  final String? notes;
  final String createdAt;
  final List<OrderItemModel>? items;

  OrderModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.total,
    required this.status,
    required this.shippingAddress,
    required this.phone,
    this.city,
    this.state,
    this.zipCode,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userEmail: json['user_email'],
      total: (json['total'] is String)
          ? double.parse(json['total'])
          : (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      shippingAddress: json['shipping_address'] ?? '',
      phone: json['phone'] ?? '',
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class OrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final String? imageUrl;
  final int quantity;
  final double unitPrice;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      productId: json['product_id'],
      productName: json['name'] ?? '',
      imageUrl: json['image_url'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] is String)
          ? double.parse(json['unit_price'])
          : (json['unit_price'] ?? 0).toDouble(),
    );
  }
}
