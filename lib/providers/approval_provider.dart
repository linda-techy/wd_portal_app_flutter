import 'package:flutter/material.dart';
import 'package:admin/models/approval_models.dart';
import 'package:admin/services/approval_service.dart';

class ApprovalProvider with ChangeNotifier {
  final ApprovalService _approvalService = ApprovalService();

  List<ApprovalRequest> _pendingRequests = [];
  bool _isLoading = false;

  List<ApprovalRequest> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;

  Future<void> fetchPendingApprovals(int approverId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _pendingRequests = await _approvalService.getPendingApprovals(approverId);
    } catch (e) {
      debugPrint("Error fetching approvals: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestApproval(ApprovalRequest request) async {
    try {
      await _approvalService.createRequest(request);
      notifyListeners();
    } catch (e) {
      debugPrint("Error requesting approval: $e");
      rethrow;
    }
  }

  Future<void> processApproval(int requestId, String status, String comments, int approverId) async {
    try {
      await _approvalService.processRequest(requestId, status, comments, approverId);
      _pendingRequests.removeWhere((r) => r.id == requestId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error processing approval: $e");
      rethrow;
    }
  }
}
