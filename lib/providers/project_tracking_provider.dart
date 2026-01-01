import 'package:flutter/foundation.dart';
import '../models/project_phase.dart';
import '../models/delay_log.dart';
import '../models/project_variation.dart';
import '../models/budget_models.dart';
import '../services/project_tracking_service.dart';

/// Provider for project tracking state management
class ProjectTrackingProvider extends ChangeNotifier {
  final ProjectTrackingService _service;

  ProjectTrackingProvider(this._service);

  // State
  List<ProjectPhase> _phases = [];
  List<DelayLog> _delayLogs = [];
  List<ProjectVariation> _variations = [];
  ProjectHealthSummary? _healthSummary;
  BudgetSummary? _budgetSummary;
  ProjectPLSummary? _plSummary;

  bool _isLoading = false;
  String? _error;
  int? _currentProjectId;

  // Getters
  List<ProjectPhase> get phases => _phases;
  List<DelayLog> get delayLogs => _delayLogs;
  List<ProjectVariation> get variations => _variations;
  ProjectHealthSummary? get healthSummary => _healthSummary;
  BudgetSummary? get budgetSummary => _budgetSummary;
  ProjectPLSummary? get plSummary => _plSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed properties
  int get completedPhases => _phases.where((p) => p.status == 'COMPLETED').length;
  int get delayedPhases => _phases.where((p) => p.isDelayed).length;
  int get pendingVariations =>
      _variations.where((v) => v.status == 'PENDING_APPROVAL').length;

  // ===== LOAD ALL DATA =====

  Future<void> loadAllData(int projectId) async {
    _currentProjectId = projectId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadPhases(projectId),
        _loadDelayLogs(projectId),
        _loadVariations(projectId),
        _loadHealthSummary(projectId),
        _loadBudgetSummary(projectId),
        _loadPLSummary(projectId),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPhases(int projectId) async {
    _phases = await _service.getPhases(projectId);
  }

  Future<void> _loadDelayLogs(int projectId) async {
    _delayLogs = await _service.getDelayLogs(projectId);
  }

  Future<void> _loadVariations(int projectId) async {
    _variations = await _service.getVariations(projectId);
  }

  Future<void> _loadHealthSummary(int projectId) async {
    _healthSummary = await _service.getProjectHealth(projectId);
  }

  Future<void> _loadBudgetSummary(int projectId) async {
    _budgetSummary = await _service.getBudgetSummary(projectId);
  }

  Future<void> _loadPLSummary(int projectId) async {
    _plSummary = await _service.getProjectPL(projectId);
  }

  // ===== PHASE OPERATIONS =====

  Future<void> createPhase(ProjectPhase phase) async {
    if (_currentProjectId == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final created = await _service.createPhase(_currentProjectId!, phase);
      _phases.add(created);
      _phases.sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));
      await _loadHealthSummary(_currentProjectId!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePhaseStatus(int phaseId, String status) async {
    if (_currentProjectId == null) return;

    try {
      final updated = await _service.updatePhase(
        _currentProjectId!,
        phaseId,
        status: status,
        actualStart: status == 'IN_PROGRESS' ? DateTime.now() : null,
        actualEnd: status == 'COMPLETED' ? DateTime.now() : null,
      );
      
      final index = _phases.indexWhere((p) => p.id == phaseId);
      if (index >= 0) {
        _phases[index] = updated;
      }
      await _loadHealthSummary(_currentProjectId!);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ===== DELAY LOG OPERATIONS =====

  Future<void> logDelay(DelayLog delay) async {
    if (_currentProjectId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final created = await _service.logDelay(_currentProjectId!, delay);
      _delayLogs.insert(0, created);
      await _loadHealthSummary(_currentProjectId!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== VARIATION OPERATIONS =====

  Future<void> createVariation(ProjectVariation variation) async {
    if (_currentProjectId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final created = await _service.createVariation(_currentProjectId!, variation);
      _variations.insert(0, created);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitVariation(int variationId) async {
    if (_currentProjectId == null) return;

    try {
      final updated = await _service.submitVariation(_currentProjectId!, variationId);
      final index = _variations.indexWhere((v) => v.id == variationId);
      if (index >= 0) {
        _variations[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> approveVariation(int variationId, int approvedById, bool approve) async {
    if (_currentProjectId == null) return;

    try {
      final updated = await _service.approveVariation(
        _currentProjectId!,
        variationId,
        approvedById,
        approve,
      );
      final index = _variations.indexWhere((v) => v.id == variationId);
      if (index >= 0) {
        _variations[index] = updated;
      }
      await _loadHealthSummary(_currentProjectId!);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ===== REFRESH =====

  Future<void> refresh() async {
    if (_currentProjectId != null) {
      await loadAllData(_currentProjectId!);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
