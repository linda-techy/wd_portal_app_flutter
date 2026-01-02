import 'package:http/http.dart' as http;
import 'package:admin/services/api_service.dart';
import 'package:admin/features/change_orders/data/models/change_order.dart';

class ChangeOrderService {
  final ApiService _apiService = ApiService();

  Future<List<ChangeOrder>> getChangeOrders(int projectId) async {
    final response = await _apiService.get('/api/projects/$projectId/variations');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ChangeOrder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load change orders');
    }
  }

  Future<ChangeOrder> createChangeOrder(ChangeOrder order) async {
    final response = await _apiService.post(
      '/api/projects/${order.projectId}/variations',
      order.toJson(),
    );

    if (response.statusCode == 200) {
      return ChangeOrder.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create change order');
    }
  }

  Future<ChangeOrder> updateChangeOrder(int projectId, int id, ChangeOrder order) async {
    final response = await _apiService.put(
      '/api/projects/$projectId/variations/$id',
      order.toJson(),
    );

    if (response.statusCode == 200) {
      return ChangeOrder.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update change order');
    }
  }

  Future<void> deleteChangeOrder(int projectId, int id) async {
    final response = await _apiService.delete('/api/projects/$projectId/variations/$id');

    if (response.statusCode != 204) {
      throw Exception('Failed to delete change order');
    }
  }

  Future<ChangeOrder> submitForApproval(int projectId, int id) async {
    final response = await _apiService.post(
      '/api/projects/$projectId/variations/$id/submit',
      {},
    );

    if (response.statusCode == 200) {
      return ChangeOrder.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to submit change order');
    }
  }

  Future<ChangeOrder> approveChangeOrder(int projectId, int id) async {
    final response = await _apiService.post(
      '/api/projects/$projectId/variations/$id/approve',
      {},
    );

    if (response.statusCode == 200) {
      return ChangeOrder.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to approve change order');
    }
  }

  Future<ChangeOrder> rejectChangeOrder(int projectId, int id, String reason) async {
    final response = await _apiService.post(
      '/api/projects/$projectId/variations/$id/reject',
      {'reason': reason},
    );

    if (response.statusCode == 200) {
      return ChangeOrder.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to reject change order');
    }
  }
}
