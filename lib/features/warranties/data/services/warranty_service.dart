import 'package:admin/services/api_service.dart';
import 'package:admin/features/warranties/data/models/project_warranty.dart';

class WarrantyService {
  final ApiService _apiService = ApiService();

  Future<List<ProjectWarranty>> getWarranties(int projectId) async {
    final response = await _apiService.get('/api/projects/$projectId/warranties');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => ProjectWarranty.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load warranties');
    }
  }

  Future<ProjectWarranty> createWarranty(ProjectWarranty warranty) async {
    final response = await _apiService.post(
      '/api/projects/${warranty.projectId}/warranties',
      warranty.toJson(),
    );

    if (response.statusCode == 200) {
      return ProjectWarranty.fromJson(response.data);
    } else {
      throw Exception('Failed to create warranty');
    }
  }

  Future<void> deleteWarranty(int projectId, int warrantyId) async {
    final response = await _apiService.delete('/api/projects/$projectId/warranties/$warrantyId');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete warranty');
    }
  }
}
