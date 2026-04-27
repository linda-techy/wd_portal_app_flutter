/// DTO for one row of the DPC payment-milestones page.
class DpcPaymentMilestone {
  final int stageNumber;
  final String stageName;
  final double stagePercentage;
  final double stageAmountInclGst;
  final String? milestoneDescription;
  final double cumulativePercentage;

  DpcPaymentMilestone({
    required this.stageNumber,
    required this.stageName,
    required this.stagePercentage,
    required this.stageAmountInclGst,
    this.milestoneDescription,
    required this.cumulativePercentage,
  });

  factory DpcPaymentMilestone.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return DpcPaymentMilestone(
      stageNumber: parseInt(json['stageNumber']),
      stageName: json['stageName'] as String? ?? '',
      stagePercentage: parseDouble(json['stagePercentage']),
      stageAmountInclGst: parseDouble(json['stageAmountInclGst']),
      milestoneDescription: json['milestoneDescription'] as String?,
      cumulativePercentage: parseDouble(json['cumulativePercentage']),
    );
  }

  Map<String, dynamic> toJson() => {
        'stageNumber': stageNumber,
        'stageName': stageName,
        'stagePercentage': stagePercentage,
        'stageAmountInclGst': stageAmountInclGst,
        'milestoneDescription': milestoneDescription,
        'cumulativePercentage': cumulativePercentage,
      };
}
