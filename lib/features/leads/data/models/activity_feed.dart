class ActivityFeed {
  final int id;
  final String title;
  final String description;
  final String activityType; // Simplified mapping from ActivityType.name
  final DateTime createdAt;
  final String? createdBy;

  ActivityFeed({
    required this.id,
    required this.title,
    required this.description,
    required this.activityType,
    required this.createdAt,
    this.createdBy,
  });

  factory ActivityFeed.fromJson(Map<String, dynamic> json) {
    return ActivityFeed(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      // Handle nested ActivityType object
      activityType: json['activityType'] != null 
          ? (json['activityType'] is Map ? json['activityType']['name'] : json['activityType'].toString()) 
          : 'UNKNOWN',
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'] != null ? json['createdBy']['email'] : (json['portalUser'] != null ? json['portalUser']['email'] : 'System'),
    );
  }
}
