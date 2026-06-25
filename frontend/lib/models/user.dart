class User {
  final String id;
  final String tenantId;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final bool isSuperuser;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.tenantId,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.isActive,
    required this.isSuperuser,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool,
      isSuperuser: json['is_superuser'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'is_superuser': isSuperuser,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
