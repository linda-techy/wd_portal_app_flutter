import 'package:admin/features/projects/data/models/project_model.dart';
import 'package:admin/features/projects/data/services/project_service.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';

class ProjectProvider extends BasePaginatedProvider<ProjectModel> {
  final ProjectService _projectService = ProjectService();

  @override
  Future<PaginatedResponse<ProjectModel>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _projectService.searchProjects(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  void filterByPhase(String? phase) {
    if (phase == null || phase == 'All') {
      updateFilter('projectPhase', null);
    } else {
      updateFilter('projectPhase', phase);
    }
  }

  void filterByStatus(String? status) {
    if (status == null || status == 'All') {
      updateFilter('projectStatus', null);
    } else {
      updateFilter('projectStatus', status);
    }
  }
}
