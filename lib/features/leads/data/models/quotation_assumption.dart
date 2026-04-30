/// Site / customer-side assumption attached to a quotation (V76).
///
/// Common Kerala examples: plot is levelled, motorable road access exists,
/// single-phase electricity available at site, customer supplies water
/// during construction.
class QuotationAssumption {
  final int? id;
  final int? quotationId;
  final int displayOrder;
  final String text;
  final DateTime? createdAt;

  const QuotationAssumption({
    this.id,
    this.quotationId,
    required this.displayOrder,
    required this.text,
    this.createdAt,
  });

  factory QuotationAssumption.fromJson(Map<String, dynamic> json) {
    return QuotationAssumption(
      id: json['id'] as int?,
      quotationId: (json['quotationId'] ?? json['quotation_id']) as int?,
      displayOrder: (json['displayOrder'] ?? json['display_order']) as int,
      text: json['text'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      if (displayOrder >= 0) 'displayOrder': displayOrder,
      'text': text,
    };
  }

  QuotationAssumption copyWith({int? displayOrder, String? text}) {
    return QuotationAssumption(
      id: id,
      quotationId: quotationId,
      displayOrder: displayOrder ?? this.displayOrder,
      text: text ?? this.text,
      createdAt: createdAt,
    );
  }
}
