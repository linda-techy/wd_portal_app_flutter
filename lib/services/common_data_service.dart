import 'package:admin/services/api_service.dart';
import 'package:admin/models/enum_value.dart';

class CommonDataService {
  static final CommonDataService _instance = CommonDataService._internal();
  factory CommonDataService() => _instance;

  final ApiService _apiService = ApiService();

  CommonDataService._internal();

  /// Get all project phase enum values
  Future<List<EnumValue>> getProjectPhases() async {
    try {
      final response = await _apiService.get('/api/common/project-phases');

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> phases = response.data['data'];
        return phases.map((json) => EnumValue.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch project phases: $e');
    }
  }

  /// Get all contract type enum values
  Future<List<EnumValue>> getContractTypes() async {
    try {
      final response = await _apiService.get('/api/common/contract-types');

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> types = response.data['data'];
        return types.map((json) => EnumValue.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch contract types: $e');
    }
  }

  /// Get list of Indian state names
  Future<List<String>> getStates() async {
    try {
      final response = await _apiService.get('/api/common/state-names');

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> states = response.data['data'];
        return states.map((s) => s.toString()).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch states: $e');
    }
  }

  /// Get districts for a specific state
  Future<List<String>> getDistricts(String state) async {
    try {
      final response = await _apiService.get(
        '/api/common/districts',
        queryParams: {'state': state},
      );

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> districts = response.data['data'];
        return districts.map((d) => d.toString()).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch districts: $e');
    }
  }

  /// Get all project types
  Future<List<String>> getProjectTypes() async {
    try {
      final response = await _apiService.get('/api/common/project-types');

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> types = response.data['data'];
        return types.map((t) => t.toString()).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch project types: $e');
    }
  }

  /// Get design packages
  Future<List<String>> getDesignPackages() async {
    try {
      final response = await _apiService.get('/api/common/design-packages');

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> packages = response.data['data'];
        return packages.map((p) => p.toString()).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch design packages: $e');
    }
  }

  /// Get facing options
  Future<List<String>> getFacingOptions() async {
    try {
      final response = await _apiService.get('/api/common/facing-options');

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> options = response.data['data'];
        return options.map((o) => o.toString()).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch facing options: $e');
    }
  }
}
