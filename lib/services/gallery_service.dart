import 'package:admin/services/api_service.dart';

class GalleryImage {
  final int id;
  final int projectId;
  final String? caption;
  final String? locationTag;
  final String? imagePath;
  final String? thumbnailPath;
  final List<String> tags;
  final String? uploadedByName;
  final DateTime? takenDate;
  final DateTime? createdAt;

  GalleryImage({
    required this.id,
    required this.projectId,
    this.caption,
    this.locationTag,
    this.imagePath,
    this.thumbnailPath,
    this.tags = const [],
    this.uploadedByName,
    this.takenDate,
    this.createdAt,
  });

  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    return GalleryImage(
      id: json['id'],
      projectId: json['projectId'] ?? 0,
      caption: json['caption'],
      locationTag: json['locationTag'],
      imagePath: json['imagePath'],
      thumbnailPath: json['thumbnailPath'],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [],
      uploadedByName: json['uploadedByName'],
      takenDate: json['takenDate'] != null
          ? DateTime.tryParse(json['takenDate'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class GalleryService {
  final ApiService _api = ApiService();

  Future<List<GalleryImage>> getProjectImages(int projectId) async {
    final response = await _api.dio.get('/gallery/project/$projectId');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => GalleryImage.fromJson(e)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to load gallery');
  }

  Future<void> deleteImage(int imageId) async {
    final response = await _api.dio.delete('/gallery/$imageId');
    if (response.statusCode != 200 || response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to delete image');
    }
  }

  Future<int> getImageCount(int projectId) async {
    final response = await _api.dio.get('/gallery/project/$projectId/count');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['data'] as int;
    }
    return 0;
  }
}
