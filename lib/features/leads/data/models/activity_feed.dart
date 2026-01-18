class ActivityFeed {
  final int id;
  final String title;
  final String description;
  final String activityType; // ActivityType name from ActivityFeedDTO
  final DateTime createdAt;
  final String? createdByName; // Created by name from ActivityFeedDTO

  ActivityFeed({
    required this.id,
    required this.title,
    required this.description,
    required this.activityType,
    required this.createdAt,
    this.createdByName,
  });

  factory ActivityFeed.fromJson(Map<String, dynamic> json) {
    return ActivityFeed(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      // ActivityFeedDTO returns activityType as String (ActivityType.name)
      activityType: json['activityType']?.toString() ?? 'UNKNOWN',
      createdAt: DateTime.parse(json['createdAt']),
      // ActivityFeedDTO returns createdByName as String
      createdByName: json['createdByName'],
    );
  }

  // Backward compatibility getter
  String? get createdBy => createdByName;
}
