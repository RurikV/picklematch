class User {
  final String uid;
  final String email;
  final String? role;
  final bool isActive;

  User({
    required this.uid,
    required this.email,
    this.role = 'user',
    this.isActive = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'],
      email: json['email'],
      role: json['role'] ?? 'user',
      isActive: json['active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'active': isActive,
    };
  }

  User copyWith({
    String? uid,
    String? email,
    String? role,
    bool? isActive,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}