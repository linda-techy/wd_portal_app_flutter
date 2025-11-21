class PortalRole {
  final int id;
  final String name;
  final String? description;
  final String? code;

  PortalRole({
    required this.id,
    required this.name,
    this.description,
    this.code,
  });

  factory PortalRole.fromJson(Map<String, dynamic> json) {
    return PortalRole(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (code != null) 'code': code,
    };
  }
}
