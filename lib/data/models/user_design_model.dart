class UserDesign {
  final String id;
  final String userId;
  final String packageId;
  final Map<String, dynamic>? customizations;
  final DateTime createdAt;
  final Map<String, dynamic>? package;

  UserDesign({
    required this.id,
    required this.userId,
    required this.packageId,
    this.customizations,
    required this.createdAt,
    this.package,
  });

  factory UserDesign.fromJson(Map<String, dynamic> json) {
    return UserDesign(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      packageId: json['package_id'] as String,
      customizations: json['customizations'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      package: json['design_packages'] as Map<String, dynamic>?,
    );
  }
}
