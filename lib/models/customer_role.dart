class CustomerRole {
  final int id;
  final String name;
  final String description;

  CustomerRole({
    required this.id,
    required this.name,
    required this.description,
  });

  factory CustomerRole.fromJson(Map<String, dynamic> json) {
    return CustomerRole(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

