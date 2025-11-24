class ProjectDocument {
  final int id;
  final int projectId;
  final int categoryId;
  final String categoryName;
  final String filename;
  final String filePath;
  final String downloadUrl;
  final int? fileSize;
  final String? fileType;
  final int uploadedById;
  final String uploadedByName;
  final DateTime uploadDate;
  final String? description;
  final int? version;
  final bool? isActive;

  ProjectDocument({
    required this.id,
    required this.projectId,
    required this.categoryId,
    required this.categoryName,
    required this.filename,
    required this.filePath,
    required this.downloadUrl,
    this.fileSize,
    this.fileType,
    required this.uploadedById,
    required this.uploadedByName,
    required this.uploadDate,
    this.description,
    this.version,
    this.isActive,
  });

  factory ProjectDocument.fromJson(Map<String, dynamic> json) {
    return ProjectDocument(
      id: json['id'] as int,
      projectId: json['projectId'] as int,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String? ?? '',
      filename: json['filename'] as String,
      filePath: json['filePath'] as String,
      downloadUrl: json['downloadUrl'] as String? ?? '',
      fileSize: json['fileSize'] as int?,
      fileType: json['fileType'] as String?,
      uploadedById: json['uploadedById'] as int,
      uploadedByName: json['uploadedByName'] as String? ?? '',
      uploadDate: DateTime.parse(json['uploadDate'] as String),
      description: json['description'] as String?,
      version: json['version'] as int?,
      isActive: json['isActive'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'filename': filename,
      'filePath': filePath,
      'downloadUrl': downloadUrl,
      'fileSize': fileSize,
      'fileType': fileType,
      'uploadedById': uploadedById,
      'uploadedByName': uploadedByName,
      'uploadDate': uploadDate.toIso8601String(),
      'description': description,
      'version': version,
      'isActive': isActive,
    };
  }
}

