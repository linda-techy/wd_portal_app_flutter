import 'package:admin/services/api_service.dart';

class LabourService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getLabour() async {
    final response = await _apiService.get('/api/labour');
    return response.data;
  }

  Future<dynamic> createLabour(Map<String, dynamic> labourData) async {
    final response = await _apiService.post('/api/labour', data: labourData);
    return response.data;
  }

  Future<List<dynamic>> recordAttendance(List<Map<String, dynamic>> attendanceList) async {
    final response = await _apiService.post('/api/labour/attendance', data: attendanceList);
    return response.data;
  }

  Future<dynamic> createMBEntry(Map<String, dynamic> mbData) async {
    final response = await _apiService.post('/api/labour/mb', data: mbData);
    return response.data;
  }

  Future<List<dynamic>> getMBEntries(int projectId) async {
    final response = await _apiService.get('/api/labour/mb/project/$projectId');
    return response.data;
  }
}
