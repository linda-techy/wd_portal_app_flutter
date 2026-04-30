/// One row of "what is included" attached to a quotation (V76).
///
/// Mirrors the backend `quotation_inclusions` table. Category is optional
/// and free-form (common values: Civil, Finishes, MEP, Sanitary, External).
class QuotationInclusion {
  final int? id;
  final int? quotationId;
  final int displayOrder;
  final String? category;
  final String text;
  final DateTime? createdAt;

  const QuotationInclusion({
    this.id,
    this.quotationId,
    required this.displayOrder,
    this.category,
    required this.text,
    this.createdAt,
  });

  factory QuotationInclusion.fromJson(Map<String, dynamic> json) {
    return QuotationInclusion(
      id: json['id'] as int?,
      quotationId: (json['quotationId'] ?? json['quotation_id']) as int?,
      displayOrder: (json['displayOrder'] ?? json['display_order']) as int,
      category: json['category'] as String?,
      text: json['text'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Body used for both POST (create) and PUT (update). `displayOrder` may
  /// be null on create — the server appends to the end of the list.
  Map<String, dynamic> toRequestJson() {
    return {
      if (displayOrder >= 0) 'displayOrder': displayOrder,
      if (category != null && category!.isNotEmpty) 'category': category,
      'text': text,
    };
  }

  QuotationInclusion copyWith({
    int? displayOrder,
    String? category,
    String? text,
  }) {
    return QuotationInclusion(
      id: id,
      quotationId: quotationId,
      displayOrder: displayOrder ?? this.displayOrder,
      category: category ?? this.category,
      text: text ?? this.text,
      createdAt: createdAt,
    );
  }
}
