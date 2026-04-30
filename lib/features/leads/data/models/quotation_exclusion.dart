/// "What is NOT included" row attached to a quotation (V76).
///
/// Mirrors the backend `quotation_exclusions` table. The optional
/// [costImplicationNote] is the honest-range copy ("Earth filling: ₹40k–60k
/// extra") that pre-empts scope disputes on Kerala residential work.
class QuotationExclusion {
  final int? id;
  final int? quotationId;
  final int displayOrder;
  final String text;
  final String? costImplicationNote;
  final DateTime? createdAt;

  const QuotationExclusion({
    this.id,
    this.quotationId,
    required this.displayOrder,
    required this.text,
    this.costImplicationNote,
    this.createdAt,
  });

  factory QuotationExclusion.fromJson(Map<String, dynamic> json) {
    return QuotationExclusion(
      id: json['id'] as int?,
      quotationId: (json['quotationId'] ?? json['quotation_id']) as int?,
      displayOrder: (json['displayOrder'] ?? json['display_order']) as int,
      text: json['text'] as String,
      costImplicationNote: (json['costImplicationNote'] ??
          json['cost_implication_note']) as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      if (displayOrder >= 0) 'displayOrder': displayOrder,
      'text': text,
      if (costImplicationNote != null && costImplicationNote!.isNotEmpty)
        'costImplicationNote': costImplicationNote,
    };
  }

  QuotationExclusion copyWith({
    int? displayOrder,
    String? text,
    String? costImplicationNote,
  }) {
    return QuotationExclusion(
      id: id,
      quotationId: quotationId,
      displayOrder: displayOrder ?? this.displayOrder,
      text: text ?? this.text,
      costImplicationNote: costImplicationNote ?? this.costImplicationNote,
      createdAt: createdAt,
    );
  }
}
