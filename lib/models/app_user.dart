class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.avatarText,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final String avatarText;
  final bool isActive;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      department: json['department'] as String? ?? '',
      avatarText: json['avatarText'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'avatarText': avatarText,
      'isActive': isActive,
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? department,
    String? avatarText,
    bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      avatarText: avatarText ?? this.avatarText,
      isActive: isActive ?? this.isActive,
    );
  }
}
