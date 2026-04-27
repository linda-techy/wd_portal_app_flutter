/// DTO for one "options considered" card under a DPC scope.
///
/// Mirrors the backend `DpcScopeOptionDto` record.
class DpcScopeOption {
  final int id;
  final int? scopeTemplateId;
  final String code;
  final String displayName;
  final String? imagePath;
  final int displayOrder;

  DpcScopeOption({
    required this.id,
    this.scopeTemplateId,
    required this.code,
    required this.displayName,
    this.imagePath,
    required this.displayOrder,
  });

  factory DpcScopeOption.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      if (v is num) return v.toInt();
      return null;
    }

    return DpcScopeOption(
      id: parseInt(json['id']) ?? 0,
      scopeTemplateId: parseInt(json['scopeTemplateId']),
      code: json['code'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      displayOrder: parseInt(json['displayOrder']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scopeTemplateId': scopeTemplateId,
        'code': code,
        'displayName': displayName,
        'imagePath': imagePath,
        'displayOrder': displayOrder,
      };
}
