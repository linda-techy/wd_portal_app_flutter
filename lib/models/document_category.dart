class DocumentCategory {
  final int id;
  final String name;
  final String? description;
  final int? displayOrder;

  DocumentCategory({
    required this.id,
    required this.name,
    this.description,
    this.displayOrder,
  });

  factory DocumentCategory.fromJson(Map<String, dynamic> json) {
    return DocumentCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      displayOrder: json['displayOrder'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'displayOrder': displayOrder,
    };
  }
}

