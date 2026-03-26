import 'package:dio/dio.dart';
import 'package:admin/models/dashboard_models.dart';
import 'package:admin/services/api_service.dart';

class DashboardService {
  final Dio _dio;

  DashboardService(ApiService apiService) : _dio = apiService.dio;

  /// Load all 5 dashboard sections in parallel.
  Future<DashboardData> loadAll() async {
    final results = await Future.wait([
      getOverview(),
      getProjectStats(),
      getLeadStats(),
      getFinanceStats(),
      getOperationsStats(),
    ]);
    return DashboardData(
      overview: results[0] as DashboardOverview,
      projects: results[1] as DashboardProjects,
      leads: results[2] as DashboardLeads,
      finance: results[3] as DashboardFinance,
      operations: results[4] as DashboardOperations,
    );
  }

  Future<DashboardOverview> getOverview() async {
    final response = await _dio.get('/api/dashboard/overview');
    return DashboardOverview.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DashboardProjects> getProjectStats() async {
    final response = await _dio.get('/api/dashboard/projects');
    return DashboardProjects.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DashboardLeads> getLeadStats() async {
    final response = await _dio.get('/api/dashboard/leads');
    return DashboardLeads.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DashboardFinance> getFinanceStats() async {
    final response = await _dio.get('/api/dashboard/finance');
    return DashboardFinance.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DashboardOperations> getOperationsStats() async {
    final response = await _dio.get('/api/dashboard/operations');
    return DashboardOperations.fromJson(response.data as Map<String, dynamic>);
  }
}
