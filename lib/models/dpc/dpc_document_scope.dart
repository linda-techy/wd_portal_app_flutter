import 'dpc_scope_option.dart';

/// DTO for a single scope row inside a DPC document.
///
/// Mirrors `DpcDocumentScopeDto` from the backend.
class DpcDocumentScope {
  final int id;
  final int? scopeTemplateId;
  final String scopeCode;
  final String scopeTitle;
  final int? selectedOptionId;
  final String? selectedOptionCode;
  final String? selectedOptionDisplayName;
  final String? selectedOptionRationale;
  final Map<String, String> brandsResolved;
  final List<String> whatYouGetResolved;
  final bool includedInPdf;
  final int displayOrder;
  final double originalAmount;
  final double customizedAmount;
  final List<DpcScopeOption> availableOptions;

  DpcDocumentScope({
    required this.id,
    this.scopeTemplateId,
    required this.scopeCode,
    required this.scopeTitle,
    this.selectedOptionId,
    this.selectedOptionCode,
    this.selectedOptionDisplayName,
    this.selectedOptionRationale,
    this.brandsResolved = const {},
    this.whatYouGetResolved = const [],
    this.includedInPdf = true,
    required this.displayOrder,
    this.originalAmount = 0,
    this.customizedAmount = 0,
    this.availableOptions = const [],
  });

  factory DpcDocumentScope.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    Map<String, String> parseStringMap(dynamic v) {
      if (v == null) return const {};
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? ''));
      }
      return const {};
    }

    List<String> parseStringList(dynamic v) {
      if (v == null) return const [];
      if (v is List) return v.map((e) => e?.toString() ?? '').toList();
      return const [];
    }

    final rawOptions = json['availableOptions'] as List? ?? [];

    return DpcDocumentScope(
      id: parseInt(json['id']) ?? 0,
      scopeTemplateId: parseInt(json['scopeTemplateId']),
      scopeCode: json['scopeCode'] as String? ?? '',
      scopeTitle: json['scopeTitle'] as String? ?? '',
      selectedOptionId: parseInt(json['selectedOptionId']),
      selectedOptionCode: json['selectedOptionCode'] as String?,
      selectedOptionDisplayName: json['selectedOptionDisplayName'] as String?,
      selectedOptionRationale: json['selectedOptionRationale'] as String?,
      brandsResolved: parseStringMap(json['brandsResolved']),
      whatYouGetResolved: parseStringList(json['whatYouGetResolved']),
      includedInPdf: json['includedInPdf'] as bool? ?? true,
      displayOrder: parseInt(json['displayOrder']) ?? 0,
      originalAmount: parseDouble(json['originalAmount']),
      customizedAmount: parseDouble(json['customizedAmount']),
      availableOptions: rawOptions
          .whereType<Map<String, dynamic>>()
          .map(DpcScopeOption.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scopeTemplateId': scopeTemplateId,
        'scopeCode': scopeCode,
        'scopeTitle': scopeTitle,
        'selectedOptionId': selectedOptionId,
        'selectedOptionCode': selectedOptionCode,
        'selectedOptionDisplayName': selectedOptionDisplayName,
        'selectedOptionRationale': selectedOptionRationale,
        'brandsResolved': brandsResolved,
        'whatYouGetResolved': whatYouGetResolved,
        'includedInPdf': includedInPdf,
        'displayOrder': displayOrder,
        'originalAmount': originalAmount,
        'customizedAmount': customizedAmount,
        'availableOptions': availableOptions.map((o) => o.toJson()).toList(),
      };
}
