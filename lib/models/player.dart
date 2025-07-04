class Player {
  final String uid;
  final String? email;
  final double? rating;
  final bool active;

  Player({
    required this.uid,
    this.email,
    this.rating,
    this.active = false,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      uid: json['uid'],
      email: json['email'],
      rating: json['rating'] != null ? double.parse(json['rating'].toString()) : null,
      active: json['active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'rating': rating,
      'active': active,
    };
  }

  Player copyWith({
    String? uid,
    String? email,
    double? rating,
    bool? active,
  }) {
    return Player(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      active: active ?? this.active,
    );
  }

  String getDisplayName() {
    return email != null ? email!.split('@').first : 'Anonymous';
  }
}