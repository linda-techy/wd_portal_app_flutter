import 'package:admin/services/api_service.dart';
import 'package:admin/models/payment_models.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;

  final ApiService _apiService = ApiService();

  PaymentService._internal();

  /// Create a new design package payment
  Future<DesignPackagePayment> createDesignPayment(CreateDesignPaymentRequest request) async {
    final response = await _apiService.post('/payments/design', request.toJson());
    
    if (response.data != null && response.data['data'] != null) {
      return DesignPackagePayment.fromJson(response.data['data']);
    }
    throw Exception('Failed to create design payment');
  }

  /// Get design payment details for a project
  Future<DesignPackagePayment?> getDesignPaymentByProject(int projectId) async {
    try {
      final response = await _apiService.get('/payments/design/project/$projectId');
      
      if (response.data != null && response.data['data'] != null) {
        return DesignPackagePayment.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      // Return null if no payment exists (404)
      if (e.toString().contains('not found') || e.toString().contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  /// Get all payments (for dashboard) with pagination and search
  Future<Map<String, dynamic>> getAllPayments({
    int page = 0,
    int size = 10,
    String? search,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'size': size,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _apiService.get('/payments/all', queryParams: queryParams);
    
    if (response.data != null && response.data['data'] != null) {
      final data = response.data['data'];
      final content = (data['content'] as List)
          .map((json) => DesignPackagePayment.fromJson(json))
          .toList();
      
      return {
        'content': content,
        'totalPages': data['totalPages'],
        'totalElements': data['totalElements'],
        'last': data['last'],
      };
    }
    return {'content': <DesignPackagePayment>[], 'totalPages': 0, 'last': true};
  }

  /// Get pending payments (for dashboard)
  Future<Map<String, dynamic>> getPendingPayments({
    int page = 0,
    int size = 10,
    String? search,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'size': size,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _apiService.get('/payments/pending', queryParams: queryParams);
    
    if (response.data != null && response.data['data'] != null) {
      final data = response.data['data'];
      final content = (data['content'] as List)
          .map((json) => DesignPackagePayment.fromJson(json))
          .toList();
      
      return {
        'content': content,
        'totalPages': data['totalPages'],
        'totalElements': data['totalElements'],
        'last': data['last'],
      };
    }
    return {'content': <DesignPackagePayment>[], 'totalPages': 0, 'last': true};
  }

  /// Record a payment transaction against a schedule
  Future<PaymentTransactionItem> recordTransaction(
    int scheduleId, 
    RecordTransactionRequest request
  ) async {
    final response = await _apiService.post(
      '/payments/schedule/$scheduleId/transactions', 
      request.toJson()
    );
    
    if (response.data != null && response.data['data'] != null) {
      return PaymentTransactionItem.fromJson(response.data['data']);
    }
    throw Exception('Failed to record transaction');
  }

  /// Get transaction history (Financial Ledger) with advanced filtering
  Future<Map<String, dynamic>> getTransactionHistory({
    int page = 0,
    int size = 15,
    String? search,
    String? method,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'size': size,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (method != null && method.isNotEmpty) queryParams['method'] = method;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    final response = await _apiService.get('/payments/history', queryParams: queryParams);
    
    if (response.data != null && response.data['data'] != null) {
      final data = response.data['data'];
      final content = (data['content'] as List)
          .map((json) => PaymentTransactionItem.fromJson(json))
          .toList();
      
      return {
        'content': content,
        'totalPages': data['totalPages'],
        'totalElements': data['totalElements'],
        'last': data['last'],
      };
    }
    return {'content': <PaymentTransactionItem>[], 'totalPages': 0, 'last': true};
  }
}

