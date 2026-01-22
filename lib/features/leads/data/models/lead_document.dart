class LeadDocument {
  final int id;
  final int leadId;
  final String filename;
  final String filePath;
  final String? fileType;
  final int? fileSize;
  final String? description;
  final int? categoryId;
  final String? categoryName;
  final int? uploadedById;
  final String? uploadedByName;
  final DateTime uploadedAt;
  final bool isActive;
  final String? downloadUrl;

  LeadDocument({
    required this.id,
    required this.leadId,
    required this.filename,
    required this.filePath,
    this.fileType,
    this.fileSize,
    this.description,
    this.categoryId,
    this.categoryName,
    this.uploadedById,
    this.uploadedByName,
    required this.uploadedAt,
    this.isActive = true,
    this.downloadUrl,
  });

  factory LeadDocument.fromJson(Map<String, dynamic> json) {
    // Handle both old and new API response formats
    int? leadIdValue;
    if (json['lead'] != null && json['lead'] is Map) {
      leadIdValue = json['lead']['id'];
    } else if (json['lead_id'] != null) {
      leadIdValue = json['lead_id'];
    } else if (json['reference_id'] != null) {
      leadIdValue = json['reference_id'];
    } else {
      leadIdValue = 0;
    }

    DateTime uploadedAtValue;
    if (json['uploadedAt'] != null) {
      uploadedAtValue = DateTime.parse(json['uploadedAt']);
    } else if (json['uploaded_at'] != null) {
      uploadedAtValue = DateTime.parse(json['uploaded_at']);
    } else if (json['created_at'] != null) {
      uploadedAtValue = DateTime.parse(json['created_at']);
    } else {
      uploadedAtValue = DateTime.now();
    }

    return LeadDocument(
      id: json['id'],
      leadId: leadIdValue ?? 0,
      filename: json['filename'] ?? '',
      filePath: json['filePath'] ?? json['file_path'] ?? '',
      fileType: json['fileType'] ?? json['file_type'],
      fileSize: json['fileSize'] ?? json['file_size'],
      description: json['description'],
      categoryId: json['categoryId'] ?? json['category_id'],
      categoryName: json['categoryName'] ?? json['category_name'] ?? json['category'],
      uploadedById: json['uploadedBy'] != null && json['uploadedBy'] is Map
          ? json['uploadedBy']['id']
          : (json['uploadedById'] ?? json['uploaded_by_id']),
      uploadedByName: json['uploadedByName'] ?? json['uploaded_by_name'],
      uploadedAt: uploadedAtValue,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      downloadUrl: json['downloadUrl'] ?? json['download_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_id': leadId,
      'filename': filename,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'uploaded_by_id': uploadedById,
      'uploaded_by_name': uploadedByName,
      'uploaded_at': uploadedAt.toIso8601String(),
      'is_active': isActive,
      'download_url': downloadUrl,
    };
  }
}
