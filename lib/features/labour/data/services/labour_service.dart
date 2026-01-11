import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:admin/services/api_service.dart';
import 'package:admin/features/labour/data/models/labour_models.dart';

class LabourService {
  final ApiService _apiService = ApiService();

  Future<WageSheet> generateWageSheet(int projectId, DateTime start, DateTime end) async {
    final response = await _apiService.post(
      '/labour/wagesheet/generate',
      queryParams: {
        'projectId': projectId,
        'start': start.toIso8601String().split('T')[0],
        'end': end.toIso8601String().split('T')[0],
      },
    );

    if (response.statusCode == 200) {
      return WageSheet.fromJson(response.data);
    } else {
      throw Exception('Failed to generate wage sheet');
    }
  }

  Future<LabourAdvance> createAdvance(int labourId, double amount, String notes) async {
    final response = await _apiService.post(
      '/labour/advance',
      queryParams: {
        'labourId': labourId,
        'amount': amount,
        'notes': notes,
      },
    );

    if (response.statusCode == 200) {
      return LabourAdvance.fromJson(response.data);
    } else {
      throw Exception('Failed to create advance');
    }
  }
  
  // Placeholder for fetching all labour if needed for dropdowns
  Future<List<Labour>> getAllLabour() async {
    final response = await _apiService.get('/labour');
     if (response.statusCode == 200) {
      var list = response.data as List;
      return list.map((i) => Labour.fromJson(i)).toList();
    } else {
      throw Exception('Failed to load labour list');
    }
  }
}
