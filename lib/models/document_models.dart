class ProjectDocument {
  final int id;
  final int projectId;
  final int categoryId;
  final String categoryName;
  final String filename;
  final String filePath;
  final String downloadUrl;
  final int fileSize;
  final String fileType;
  final int uploadedById;
  final String uploadedByName;
  final String uploadDate;
  final String? description;
  final int version;
  final bool isActive;

  ProjectDocument({
    required this.id,
    required this.projectId,
    required this.categoryId,
    required this.categoryName,
    required this.filename,
    required this.filePath,
    required this.downloadUrl,
    required this.fileSize,
    required this.fileType,
    required this.uploadedById,
    required this.uploadedByName,
    required this.uploadDate,
    this.description,
    required this.version,
    required this.isActive,
  });

  factory ProjectDocument.fromJson(Map<String, dynamic> json) {
    return ProjectDocument(
      id: json['id'],
      projectId: json['projectId'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      filename: json['filename'],
      filePath: json['filePath'],
      downloadUrl: json['downloadUrl'],
      fileSize: json['fileSize'],
      fileType: json['fileType'],
      uploadedById: json['uploadedById'],
      uploadedByName: json['uploadedByName'],
      uploadDate: json['uploadDate'],
      description: json['description'],
      version: json['version'],
      isActive: json['isActive'],
    );
  }
}

class DocumentCategory {
  final int id;
  final String name;
  final String? description;
  final int displayOrder;

  DocumentCategory({
    required this.id,
    required this.name,
    this.description,
    required this.displayOrder,
  });

  factory DocumentCategory.fromJson(Map<String, dynamic> json) {
    return DocumentCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      displayOrder: json['displayOrder'],
    );
  }
}
