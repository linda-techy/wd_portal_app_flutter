class LeadScoreHistory {
  final int id;
  final int leadId;
  final int? previousScore;
  final int newScore;
  final String? previousCategory;
  final String newCategory;
  final String? scoreFactors;
  final String? reason;
  final DateTime scoredAt;
  final int? scoredById;
  final String? scoredByName;

  LeadScoreHistory({
    required this.id,
    required this.leadId,
    this.previousScore,
    required this.newScore,
    this.previousCategory,
    required this.newCategory,
    this.scoreFactors,
    this.reason,
    required this.scoredAt,
    this.scoredById,
    this.scoredByName,
  });

  factory LeadScoreHistory.fromJson(Map<String, dynamic> json) {
    return LeadScoreHistory(
      id: json['id'],
      leadId: json['leadId'],
      previousScore: json['previousScore'],
      newScore: json['newScore'],
      previousCategory: json['previousCategory'],
      newCategory: json['newCategory'],
      scoreFactors: json['scoreFactors'],
      reason: json['reason'],
      scoredAt: DateTime.parse(json['scoredAt']),
      scoredById: json['scoredById'],
      scoredByName: json['scoredByName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leadId': leadId,
      'previousScore': previousScore,
      'newScore': newScore,
      'previousCategory': previousCategory,
      'newCategory': newCategory,
      'scoreFactors': scoreFactors,
      'reason': reason,
      'scoredAt': scoredAt.toIso8601String(),
      'scoredById': scoredById,
      'scoredByName': scoredByName,
    };
  }

  /// Get the score change (new - previous)
  int get scoreChange {
    if (previousScore == null) {
      return newScore;
    }
    return newScore - previousScore!;
  }

  /// Get a formatted string for the score change
  String get scoreChangeText {
    if (previousScore == null) {
      return 'Initial: $newScore';
    }
    int change = scoreChange;
    if (change > 0) {
      return '+$change ($previousScore → $newScore)';
    } else if (change < 0) {
      return '$change ($previousScore → $newScore)';
    } else {
      return 'No change ($newScore)';
    }
  }

  /// Get a formatted string for category change
  String get categoryChangeText {
    if (previousCategory == null) {
      return 'Initial: $newCategory';
    }
    if (previousCategory == newCategory) {
      return newCategory;
    }
    return '$previousCategory → $newCategory';
  }
}
