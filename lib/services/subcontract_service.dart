import 'package:dio/dio.dart';
import '../models/subcontract_models.dart';
import 'api_service.dart';

/// Subcontract Service
/// Handles all API calls for subcontractor work order management
class SubcontractService {
  final ApiService _apiService;

  SubcontractService(this._apiService);

  // ===== WORK ORDERS =====

  /// Create a new work order
  Future<SubcontractWorkOrder> createWorkOrder(SubcontractWorkOrder workOrder) async {
    try {
      final response = await _apiService.post(
        '/subcontracts/work-orders',
        data: workOrder.toJson(),
      );
      return SubcontractWorkOrder.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all work orders for a project
  Future<List<SubcontractWorkOrder>> getProjectWorkOrders(int projectId) async {
    try {
      final response = await _apiService.get('/subcontracts/projects/$projectId/work-orders');
      return (response.data as List)
          .map((json) => SubcontractWorkOrder.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get active work orders
  Future<List<SubcontractWorkOrder>> getActiveWorkOrders() async {
    try {
      final response = await _apiService.get('/subcontracts/work-orders/active');
      return (response.data as List)
          .map((json) => SubcontractWorkOrder.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Issue a work order
  Future<SubcontractWorkOrder> issueWorkOrder(int workOrderId) async {
    try {
      final response = await _apiService.post('/subcontracts/work-orders/$workOrderId/issue', data: {});
      return SubcontractWorkOrder.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Complete a work order
  Future<SubcontractWorkOrder> completeWorkOrder(int workOrderId, DateTime completionDate) async {
    try {
      final response = await _apiService.post(
        '/subcontracts/work-orders/$workOrderId/complete',
        data: {},
        queryParams: {'completionDate': completionDate.toIso8601String()},
      );
      return SubcontractWorkOrder.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Terminate a work order
  Future<SubcontractWorkOrder> terminateWorkOrder(int workOrderId, String reason) async {
    try {
      final response = await _apiService.post(
        '/subcontracts/work-orders/$workOrderId/terminate',
        data: reason,
      );
      return SubcontractWorkOrder.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ===== MEASUREMENTS =====

  /// Record a new measurement
  Future<SubcontractMeasurement> recordMeasurement(
    int workOrderId,
    SubcontractMeasurement measurement,
  ) async {
    try {
      final response = await _apiService.post(
        '/subcontracts/work-orders/$workOrderId/measurements',
        data: measurement.toJson(),
      );
      return SubcontractMeasurement.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get measurements for a work order
  Future<List<SubcontractMeasurement>> getWorkOrderMeasurements(int workOrderId) async {
    try {
      final response = await _apiService.get('/subcontracts/work-orders/$workOrderId/measurements');
      return (response.data as List)
          .map((json) => SubcontractMeasurement.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Approve a measurement
  Future<SubcontractMeasurement> approveMeasurement(int measurementId, int approvedById) async {
    try {
      final response = await _apiService.post(
        '/subcontracts/measurements/$measurementId/approve',
        data: {},
        queryParams: {'approvedById': approvedById},
      );
      return SubcontractMeasurement.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Reject a measurement
  Future<SubcontractMeasurement> rejectMeasurement(
    int measurementId,
    int rejectedById,
    String reason,
  ) async {
    try {
      final response = await _apiService.post(
        '/subcontracts/measurements/$measurementId/reject',
        data: reason,
        queryParams: {'rejectedById': rejectedById},
      );
      return SubcontractMeasurement.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get pending measurements
  Future<List<SubcontractMeasurement>> getPendingMeasurements() async {
    try {
      final response = await _apiService.get('/subcontracts/measurements/pending');
      return (response.data as List)
          .map((json) => SubcontractMeasurement.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ===== PAYMENTS =====

  /// Record a payment
  Future<SubcontractPayment> recordPayment(SubcontractPayment payment) async {
    try {
      final response = await _apiService.post(
        '/subcontracts/work-orders/${payment.workOrderId}/payments',
        data: payment.toJson(),
      );
      return SubcontractPayment.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get payments for a work order
  Future<List<SubcontractPayment>> getWorkOrderPayments(int workOrderId) async {
    try {
      final response = await _apiService.get('/subcontracts/work-orders/$workOrderId/payments');
      return (response.data as List)
          .map((json) => SubcontractPayment.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get payments for a project
  Future<List<SubcontractPayment>> getProjectPayments(int projectId) async {
    try {
      final response = await _apiService.get('/subcontracts/projects/$projectId/payments');
      return (response.data as List)
          .map((json) => SubcontractPayment.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ===== SUMMARIES =====

  /// Get work order financial summary
  Future<SubcontractSummary> getWorkOrderSummary(int workOrderId) async {
    try {
      final response = await _apiService.get('/subcontracts/work-orders/$workOrderId/summary');
      return SubcontractSummary.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all summaries for a project
  Future<List<SubcontractSummary>> getProjectSummaries(int projectId) async {
    try {
      final response = await _apiService.get('/subcontracts/projects/$projectId/summaries');
      return (response.data as List)
          .map((json) => SubcontractSummary.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ===== ERROR HANDLING =====

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        return error.response?.data ?? 'Server error occurred';
      }
      return 'Network error: ${error.message}';
    }
    return error.toString();
  }
}
