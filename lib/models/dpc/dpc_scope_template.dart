import 'dpc_scope_option.dart';

/// DTO for a DPC scope template (admin-managed content library row).
class DpcScopeTemplate {
  final int id;
  final String code;
  final int displayOrder;
  final String title;
  final String? subtitle;
  final String? introParagraph;
  final List<String> whatYouGet;
  final List<String> qualityProcedures;
  final List<String> documentsYouGet;
  final List<String> boqCategoryPatterns;
  final Map<String, String> defaultBrands;
  final bool isActive;
  final List<DpcScopeOption> options;

  DpcScopeTemplate({
    required this.id,
    required this.code,
    required this.displayOrder,
    required this.title,
    this.subtitle,
    this.introParagraph,
    this.whatYouGet = const [],
    this.qualityProcedures = const [],
    this.documentsYouGet = const [],
    this.boqCategoryPatterns = const [],
    this.defaultBrands = const {},
    this.isActive = true,
    this.options = const [],
  });

  factory DpcScopeTemplate.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      if (v is num) return v.toInt();
      return null;
    }

    List<String> parseStringList(dynamic v) {
      if (v == null) return const [];
      if (v is List) {
        return v.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    Map<String, String> parseStringMap(dynamic v) {
      if (v == null) return const {};
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? ''));
      }
      return const {};
    }

    final rawOptions = json['options'] as List? ?? [];

    return DpcScopeTemplate(
      id: parseInt(json['id']) ?? 0,
      code: json['code'] as String? ?? '',
      displayOrder: parseInt(json['displayOrder']) ?? 0,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      introParagraph: json['introParagraph'] as String?,
      whatYouGet: parseStringList(json['whatYouGet']),
      qualityProcedures: parseStringList(json['qualityProcedures']),
      documentsYouGet: parseStringList(json['documentsYouGet']),
      boqCategoryPatterns: parseStringList(json['boqCategoryPatterns']),
      defaultBrands: parseStringMap(json['defaultBrands']),
      isActive: json['isActive'] as bool? ?? true,
      options: rawOptions
          .whereType<Map<String, dynamic>>()
          .map(DpcScopeOption.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'displayOrder': displayOrder,
        'title': title,
        'subtitle': subtitle,
        'introParagraph': introParagraph,
        'whatYouGet': whatYouGet,
        'qualityProcedures': qualityProcedures,
        'documentsYouGet': documentsYouGet,
        'boqCategoryPatterns': boqCategoryPatterns,
        'defaultBrands': defaultBrands,
        'isActive': isActive,
        'options': options.map((o) => o.toJson()).toList(),
      };
}
