class Location {
  final String id;
  final String name;
  final String? address;
  final String? description;

  Location({
    required this.id,
    required this.name,
    this.address,
    this.description,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'description': description,
    };
  }

  Location copyWith({
    String? id,
    String? name,
    String? address,
    String? description,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
    );
  }
}