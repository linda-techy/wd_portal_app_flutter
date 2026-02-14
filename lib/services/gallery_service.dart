import 'package:admin/constants.dart';
import 'package:admin/services/api_service.dart';

class GalleryImage {
  final int id;
  final int projectId;
  final String? caption;
  final String? locationTag;
  final String? imageUrl;
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
    this.imageUrl,
    this.imagePath,
    this.thumbnailPath,
    this.tags = const [],
    this.uploadedByName,
    this.takenDate,
    this.createdAt,
  });

  /// Full URL for loading the image (prepends API base URL to relative path).
  String get fullImageUrl {
    final url = imageUrl ?? (imagePath != null ? '/api/storage/$imagePath' : '');
    if (url.startsWith('http')) return url;
    return '${ApiConfig.fullApiUrl}$url';
  }

  /// Full URL for loading the thumbnail (falls back to full image).
  String get fullThumbnailUrl {
    if (thumbnailPath != null) {
      final url = '/api/storage/$thumbnailPath';
      return '${ApiConfig.fullApiUrl}$url';
    }
    return fullImageUrl;
  }

  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    return GalleryImage(
      id: json['id'],
      projectId: json['projectId'] ?? 0,
      caption: json['caption'],
      locationTag: json['locationTag'],
      imageUrl: json['imageUrl'],
      imagePath: json['imagePath'],
      thumbnailPath: json['thumbnailPath'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
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
    final response = await _api.dio.get('/api/gallery/project/$projectId');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => GalleryImage.fromJson(e)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to load gallery');
  }

  Future<void> deleteImage(int imageId) async {
    final response = await _api.dio.delete('/api/gallery/$imageId');
    if (response.statusCode != 200 || response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to delete image');
    }
  }

  Future<int> getImageCount(int projectId) async {
    final response =
        await _api.dio.get('/api/gallery/project/$projectId/count');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['data'] as int;
    }
    return 0;
  }
}
