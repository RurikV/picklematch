class Player {
  final String uid;
  final String? email;
  final double? rating;
  final bool active;
  final String? name;

  Player({
    required this.uid,
    this.email,
    this.rating,
    this.active = false,
    this.name,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      uid: json['uid'],
      email: json['email'],
      rating: json['rating'] != null ? double.parse(json['rating'].toString()) : null,
      active: json['active'] ?? false,
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'rating': rating,
      'active': active,
      'name': name,
    };
  }

  Player copyWith({
    String? uid,
    String? email,
    double? rating,
    bool? active,
    String? name,
  }) {
    return Player(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      active: active ?? this.active,
      name: name ?? this.name,
    );
  }

  String getDisplayName() {
    // Prioritize the user's profile name if available
    if (name != null && name!.isNotEmpty) {
      return name!;
    }

    // Fallback to email-based name
    return email != null ? email!.split('@').first : 'Anonymous';
  }
}
