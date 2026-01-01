class LeadDocument {
  final int id;
  final int leadId;
  final String filename;
  final String filePath;
  final String? fileType;
  final int? fileSize;
  final String? description;
  final String? category;
  final int? uploadedById;
  final DateTime uploadedAt;
  final bool isActive;

  LeadDocument({
    required this.id,
    required this.leadId,
    required this.filename,
    required this.filePath,
    this.fileType,
    this.fileSize,
    this.description,
    this.category,
    this.uploadedById,
    required this.uploadedAt,
    this.isActive = true,
  });

  factory LeadDocument.fromJson(Map<String, dynamic> json) {
    return LeadDocument(
      id: json['id'],
      leadId: json['lead'] != null ? json['lead']['id'] : (json['lead_id'] ?? 0),
      filename: json['filename'],
      filePath: json['filePath'] ?? json['file_path'],
      fileType: json['fileType'] ?? json['file_type'],
      fileSize: json['fileSize'] ?? json['file_size'],
      description: json['description'],
      category: json['category'],
      uploadedById: json['uploadedBy'] != null ? json['uploadedBy']['id'] : json['uploaded_by_id'],
      uploadedAt: DateTime.parse(json['uploadedAt'] ?? json['uploaded_at']),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
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
      'category': category,
      'uploaded_by_id': uploadedById,
      'uploaded_at': uploadedAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}
