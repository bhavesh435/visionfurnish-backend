class ColorVariant {
  final String name;
  final String hex;
  final List<String> images;

  ColorVariant({required this.name, required this.hex, this.images = const []});

  factory ColorVariant.fromJson(Map<String, dynamic> j) => ColorVariant(
        name: j['name'] ?? '',
        hex: j['hex'] ?? '#AAAAAA',
        images: j['images'] != null ? List<String>.from(j['images']) : [],
      );

  Map<String, dynamic> toJson() => {'name': name, 'hex': hex, 'images': images};
}

class ProductModel {
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
  final List<ColorVariant> colorVariants;
  final String? arModel;
  final String? material;
  final String? dimensions;
  final String? color;
  final bool isFeatured;
  final String createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.discountPrice,
    required this.stock,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.images = const [],
    this.images360 = const [],
    this.colorVariants = const [],
    this.arModel,
    this.material,
    this.dimensions,
    this.color,
    required this.isFeatured,
    required this.createdAt,
  });

  static List<T> _parseJsonList<T>(
      dynamic raw, T Function(dynamic) fromItem) {
    if (raw == null) return [];
    if (raw is List) return raw.map(fromItem).toList();
    return [];
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      price: (json['price'] is String)
          ? double.parse(json['price'])
          : (json['price'] ?? 0).toDouble(),
      discountPrice: json['discount_price'] != null
          ? (json['discount_price'] is String
              ? double.parse(json['discount_price'])
              : json['discount_price'].toDouble())
          : null,
      stock: json['stock'] ?? 0,
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      imageUrl: json['image_url'],
      images: _parseJsonList(json['images'], (e) => e.toString()),
      images360: _parseJsonList(json['images_360'], (e) => e.toString()),
      colorVariants: _parseJsonList(json['color_variants'],
          (e) => ColorVariant.fromJson(e as Map<String, dynamic>)),
      arModel: json['ar_model'],
      material: json['material'],
      dimensions: json['dimensions'],
      color: json['color'],
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      if (discountPrice != null) 'discount_price': discountPrice,
      'stock': stock,
      if (categoryId != null) 'category_id': categoryId,
      if (imageUrl != null) 'image_url': imageUrl,
      if (images.isNotEmpty) 'images': images,
      if (images360.isNotEmpty) 'images_360': images360,
      if (colorVariants.isNotEmpty)
        'color_variants': colorVariants.map((c) => c.toJson()).toList(),
      if (arModel != null) 'ar_model': arModel,
      if (material != null) 'material': material,
      if (dimensions != null) 'dimensions': dimensions,
      if (color != null) 'color': color,
      'is_featured': isFeatured,
    };
  }
}
