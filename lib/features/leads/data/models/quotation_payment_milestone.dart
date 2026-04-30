/// One row of the milestone-linked payment schedule on a quotation (V76).
///
/// Kerala default 8-stage residential schedule:
///   1. Booking 10%   2. Foundation 15%   3. Plinth 15%   4. Walls 15%
///   5. Slab 15%      6. Plaster 10%      7. Flooring 10% 8. Handover 10%
///
/// [amount] is null for BUDGETARY parents (the rupee figure isn't locked
/// yet — only percentages are meaningful at the budgetary stage).
class QuotationPaymentMilestone {
  final int? id;
  final int? quotationId;
  final int milestoneNumber;
  final String triggerEvent;
  final double percentage;
  final double? amount;
  final String? notes;
  final DateTime? createdAt;

  const QuotationPaymentMilestone({
    this.id,
    this.quotationId,
    required this.milestoneNumber,
    required this.triggerEvent,
    required this.percentage,
    this.amount,
    this.notes,
    this.createdAt,
  });

  factory QuotationPaymentMilestone.fromJson(Map<String, dynamic> json) {
    return QuotationPaymentMilestone(
      id: json['id'] as int?,
      quotationId: (json['quotationId'] ?? json['quotation_id']) as int?,
      milestoneNumber:
          (json['milestoneNumber'] ?? json['milestone_number']) as int,
      triggerEvent: (json['triggerEvent'] ?? json['trigger_event']) as String,
      percentage: (json['percentage'] as num).toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'milestoneNumber': milestoneNumber,
      'triggerEvent': triggerEvent,
      'percentage': percentage,
      if (amount != null) 'amount': amount,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  QuotationPaymentMilestone copyWith({
    int? milestoneNumber,
    String? triggerEvent,
    double? percentage,
    double? amount,
    String? notes,
  }) {
    return QuotationPaymentMilestone(
      id: id,
      quotationId: quotationId,
      milestoneNumber: milestoneNumber ?? this.milestoneNumber,
      triggerEvent: triggerEvent ?? this.triggerEvent,
      percentage: percentage ?? this.percentage,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  /// The Kerala-default 8-stage schedule. Used as an "auto-populate" seed
  /// when staff opens an empty payment-milestone editor on a fresh quote.
  static List<QuotationPaymentMilestone> defaultKeralaSchedule() {
    const stages = [
      ('On agreement', 10.0),
      ('Foundation complete', 15.0),
      ('Plinth beam complete', 15.0),
      ('Walls up to lintel', 15.0),
      ('Roof slab cast', 15.0),
      ('Plastering complete', 10.0),
      ('Flooring & finishes', 10.0),
      ('Handover', 10.0),
    ];
    return [
      for (var i = 0; i < stages.length; i++)
        QuotationPaymentMilestone(
          milestoneNumber: i + 1,
          triggerEvent: stages[i].$1,
          percentage: stages[i].$2,
        ),
    ];
  }
}
