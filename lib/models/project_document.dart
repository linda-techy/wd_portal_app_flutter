class ProjectDocument {
  final int? id;
  final int? projectId;
  final int? categoryId;
  final String categoryName;
  final String filename;
  final String filePath;
  final String downloadUrl;
  final int? fileSize;
  final String? fileType;
  final int? uploadedById;
  final String uploadedByName;
  final DateTime uploadDate;
  final String? description;
  final int? version;
  final bool? isActive;

  ProjectDocument({
    this.id,
    this.projectId,
    this.categoryId,
    required this.categoryName,
    required this.filename,
    required this.filePath,
    required this.downloadUrl,
    this.fileSize,
    this.fileType,
    this.uploadedById,
    required this.uploadedByName,
    required this.uploadDate,
    this.description,
    this.version,
    this.isActive,
  });

  factory ProjectDocument.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse int from dynamic (handles both int and null)
    int? parseIntSafe(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Helper to safely parse DateTime
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return ProjectDocument(
      id: parseIntSafe(json['id']),
      // Map referenceId to projectId (backend uses referenceId for project documents)
      projectId: parseIntSafe(json['reference_id'] ?? json['referenceId']),
      categoryId: parseIntSafe(json['category_id'] ?? json['categoryId']),
      categoryName: json['category_name'] as String? ?? json['categoryName'] as String? ?? 'Uncategorized',
      filename: json['filename'] as String? ?? 'Unknown File',
      filePath: json['file_path'] as String? ?? json['filePath'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ?? json['downloadUrl'] as String? ?? '',
      fileSize: parseIntSafe(json['file_size'] ?? json['fileSize']),
      fileType: json['file_type'] as String? ?? json['fileType'] as String?,
      uploadedById: parseIntSafe(json['uploaded_by_id'] ?? json['uploadedById']),
      uploadedByName: json['uploaded_by_name'] as String? ?? json['uploadedByName'] as String? ?? 'Unknown',
      // Backend sends created_at instead of uploadDate
      uploadDate: parseDateTime(json['created_at'] ?? json['createdAt'] ?? json['uploadDate']),
      description: json['description'] as String?,
      version: parseIntSafe(json['version']),
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
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

