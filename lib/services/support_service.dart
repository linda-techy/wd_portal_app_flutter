import 'package:admin/models/support_ticket.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/services/api_service.dart';

class SupportService {
  static final SupportService _instance = SupportService._internal();
  factory SupportService() => _instance;
  SupportService._internal();

  final ApiService _apiService = ApiService();

  /// GET /api/support/tickets — paginated list with optional filters.
  Future<PaginatedResponse<PortalSupportTicket>> getTickets({
    int page = 0,
    int size = 20,
    String? status,
    String? category,
    int? assignedTo,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    if (assignedTo != null) queryParams['assignedTo'] = assignedTo.toString();

    final response = await _apiService.get(
      '/api/support/tickets',
      queryParams: queryParams,
    );
    return _apiService.unwrap<PaginatedResponse<PortalSupportTicket>>(
      response,
      (json) => PaginatedResponse.fromJson(
        json as Map<String, dynamic>,
        PortalSupportTicket.fromJson,
      ),
    );
  }

  /// GET /api/support/tickets/{id}
  Future<PortalSupportTicket> getTicketDetail(int ticketId) async {
    final response = await _apiService.get('/api/support/tickets/$ticketId');
    return _apiService.unwrap<PortalSupportTicket>(
      response,
      (json) => PortalSupportTicket.fromJson(json as Map<String, dynamic>),
    );
  }

  /// PUT /api/support/tickets/{id}/assign
  Future<PortalSupportTicket> assignTicket(int ticketId, int assignedTo) async {
    final response = await _apiService.put(
      '/api/support/tickets/$ticketId/assign',
      data: {'assignedTo': assignedTo},
    );
    return _apiService.unwrap<PortalSupportTicket>(
      response,
      (json) => PortalSupportTicket.fromJson(json as Map<String, dynamic>),
    );
  }

  /// PUT /api/support/tickets/{id}/status
  Future<PortalSupportTicket> updateStatus(int ticketId, String status) async {
    final response = await _apiService.put(
      '/api/support/tickets/$ticketId/status',
      data: {'status': status},
    );
    return _apiService.unwrap<PortalSupportTicket>(
      response,
      (json) => PortalSupportTicket.fromJson(json as Map<String, dynamic>),
    );
  }

  /// POST /api/support/tickets/{id}/replies
  Future<PortalTicketReply> addReply(
    int ticketId,
    String message, {
    String? staffName,
  }) async {
    final body = <String, dynamic>{'message': message};
    if (staffName != null && staffName.isNotEmpty) {
      body['staffName'] = staffName;
    }
    final response = await _apiService.post(
      '/api/support/tickets/$ticketId/replies',
      data: body,
    );
    return _apiService.unwrap<PortalTicketReply>(
      response,
      (json) => PortalTicketReply.fromJson(json as Map<String, dynamic>),
    );
  }
}
