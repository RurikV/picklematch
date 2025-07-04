class User {
  final String uid;
  final String email;
  final String? role;
  final bool isActive;
  final double? rating;
  final String? name;

  User({
    required this.uid,
    required this.email,
    this.role = 'user',
    this.isActive = false,
    this.rating,
    this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'],
      email: json['email'],
      role: json['role'] ?? 'user',
      isActive: json['active'] ?? false,
      rating: json['rating'] != null ? double.parse(json['rating'].toString()) : null,
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'active': isActive,
      'rating': rating,
      'name': name,
    };
  }

  User copyWith({
    String? uid,
    String? email,
    String? role,
    bool? isActive,
    double? rating,
    String? name,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      name: name ?? this.name,
    );
  }
}
