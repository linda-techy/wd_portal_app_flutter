import 'package:flutter/foundation.dart';
import '../models/subcontract_models.dart';
import '../services/subcontract_service.dart';

/// Subcontract Provider
/// State management for subcontractor work orders
class SubcontractProvider with ChangeNotifier {
  final SubcontractService _subcontractService;

  SubcontractProvider(this._subcontractService);

  // State
  List<SubcontractWorkOrder> _workOrders = [];
  List<SubcontractMeasurement>  _measurements = [];
  List<SubcontractPayment> _payments = [];
  List<SubcontractSummary> _summaries = [];
  SubcontractSummary? _currentSummary;
  
  bool _isLoading = false;
  String? _error;
  int? _currentProjectId;

  // Getters
  List<SubcontractWorkOrder> get workOrders => _workOrders;
  List<SubcontractMeasurement> get measurements => _measurements;
  List<SubcontractPayment> get payments => _payments;
  List<SubcontractSummary> get summaries => _summaries;
  SubcontractSummary? get currentSummary => _currentSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered getters
  List<SubcontractMeasurement> get pendingMeasurements =>
      _measurements.where((m) => m.isPending).toList();
      
  List<SubcontractWorkOrder> get activeWorkOrders =>
      _workOrders.where((wo) => wo.isActive).toList();

  // ===== WORK ORDERS =====

  Future<void> loadProjectWorkOrders(int projectId) async {
    _setLoading(true);
    _currentProjectId = projectId;
    
    try {
      _workOrders = await _subcontractService.getProjectWorkOrders(projectId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createWorkOrder(SubcontractWorkOrder workOrder) async {
    _setLoading(true);
    
    try {
      final created = await _subcontractService.createWorkOrder(workOrder);
      _workOrders.add(created);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> issueWorkOrder(int workOrderId) async {
    _setLoading(true);
    
    try {
      final updated = await _subcontractService.issueWorkOrder(workOrderId);
      _updateWorkOrderInList(updated);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeWorkOrder(int workOrderId, DateTime completionDate) async {
    _setLoading(true);
    
    try {
      final updated = await _subcontractService.completeWorkOrder(workOrderId, completionDate);
      _updateWorkOrderInList(updated);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ===== MEASUREMENTS =====

  Future<void> loadWorkOrderMeasurements(int workOrderId) async {
    _setLoading(true);
    
    try {
      _measurements = await _subcontractService.getWorkOrderMeasurements(workOrderId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> recordMeasurement(int workOrderId, SubcontractMeasurement measurement) async {
    _setLoading(true);
    
    try {
      final recorded = await _subcontractService.recordMeasurement(workOrderId, measurement);
      _measurements.add(recorded);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> approveMeasurement(int measurementId, int approvedById) async {
    _setLoading(true);
    
    try {
      final approved = await _subcontractService.approveMeasurement(measurementId, approvedById);
      _updateMeasurementInList(approved);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rejectMeasurement(int measurementId, int rejectedById, String reason) async {
    _setLoading(true);
    
    try {
      final rejected = await _subcontractService.rejectMeasurement(measurementId, rejectedById, reason);
      _updateMeasurementInList(rejected);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ===== PAYMENTS =====

  Future<void> loadWorkOrderPayments(int workOrderId) async {
    _setLoading(true);
    
    try {
      _payments = await _subcontractService.getWorkOrderPayments(workOrderId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> recordPayment(SubcontractPayment payment) async {
    _setLoading(true);
    
    try {
      final recorded = await _subcontractService.recordPayment(payment);
      _payments.add(recorded);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ===== SUMMARIES =====

  Future<void> loadWorkOrderSummary(int workOrderId) async {
    _setLoading(true);
    
    try {
      _currentSummary = await _subcontractService.getWorkOrderSummary(workOrderId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProjectSummaries(int projectId) async {
    _setLoading(true);
    
    try {
      _summaries = await _subcontractService.getProjectSummaries(projectId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ===== HELPERS =====

  void _updateWorkOrderInList(SubcontractWorkOrder updated) {
    final index = _workOrders.indexWhere((wo) => wo.id == updated.id);
    if (index != -1) {
      _workOrders[index] = updated;
      notifyListeners();
    }
  }

  void _updateMeasurementInList(SubcontractMeasurement updated) {
    final index = _measurements.indexWhere((m) => m.id == updated.id);
    if (index != -1) {
      _measurements[index] = updated;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _workOrders = [];
    _measurements = [];
    _payments = [];
    _summaries = [];
    _currentSummary = null;
    _error = null;
    _currentProjectId = null;
    notifyListeners();
  }
}
