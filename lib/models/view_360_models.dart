import 'package:intl/intl.dart';

class View360 {
  final int? id;
  final int projectId;
  final String title;
  final String? description;
  final String? location;
  final String panoramaUrl;
  final String thumbnailUrl;
  final DateTime captureDate;
  final String? uploadedByName;
  final DateTime? createdAt;

  View360({
    this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.location,
    required this.panoramaUrl,
    required this.thumbnailUrl,
    required this.captureDate,
    this.uploadedByName,
    this.createdAt,
  });

  factory View360.fromJson(Map<String, dynamic> json) {
    return View360(
      id: json['id'],
      projectId: json['project'] != null ? json['project']['id'] : 0,
      title: json['title'],
      description: json['description'],
      location: json['location'],
      panoramaUrl: json['panoramaUrl'],
      thumbnailUrl: json['thumbnailUrl'] ?? json['panoramaUrl'],
      captureDate: DateTime.parse(json['captureDate'] ?? json['createdAt']),
      uploadedByName: json['uploadedBy'] != null 
          ? '${json['uploadedBy']['firstName']} ${json['uploadedBy']['lastName']}'
          : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  String get formattedCaptureDate => DateFormat('dd MMM yyyy, hh:mm a').format(captureDate);
}
