class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final int? parentId;
  final int? productCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.parentId,
    this.productCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'],
      parentId: json['parent_id'],
      productCount: json['product_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (parentId != null) 'parent_id': parentId,
    };
  }
}
