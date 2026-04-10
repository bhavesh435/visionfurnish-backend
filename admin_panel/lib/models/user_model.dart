class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isBlocked;
  final String? avatarUrl;
  final String createdAt;

  // NOTE: Password is NEVER included in this model — by design.

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.isBlocked,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'user',
      isBlocked: json['is_blocked'] == 1 || json['is_blocked'] == true,
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
