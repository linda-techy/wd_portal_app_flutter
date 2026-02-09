import 'package:flutter/material.dart';
import 'package:admin/models/finance_models.dart';
import 'package:admin/services/finance_service.dart';

class FinanceProvider with ChangeNotifier {
  final FinanceService _financeService = FinanceService();

  List<ProjectInvoice> _projectInvoices = [];
  final List<PurchaseInvoice> _purchaseInvoices = [];
  final List<LabourPayment> _labourPayments = [];
  bool _isLoading = false;

  List<ProjectInvoice> get projectInvoices => _projectInvoices;
  List<PurchaseInvoice> get purchaseInvoices => _purchaseInvoices;
  List<LabourPayment> get labourPayments => _labourPayments;
  bool get isLoading => _isLoading;

  Future<void> fetchProjectInvoices(int projectId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _projectInvoices = await _financeService.getProjectInvoices(projectId);
    } catch (e) {
      debugPrint("Error fetching invoices: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createInvoice(ProjectInvoice invoice) async {
    try {
      final newInvoice = await _financeService.createProjectInvoice(invoice);
      _projectInvoices.add(newInvoice);
      notifyListeners();
    } catch (e) {
      debugPrint("Error creating invoice: $e");
      rethrow;
    }
  }

  Future<void> recordVendorBill(PurchaseInvoice invoice) async {
    try {
      final newInvoice = await _financeService.recordPurchaseInvoice(invoice);
      _purchaseInvoices.add(newInvoice);
      notifyListeners();
    } catch (e) {
      debugPrint("Error recording vendor bill: $e");
      rethrow;
    }
  }

  Future<void> recordLabourPayment(LabourPayment payment) async {
    try {
      final newPayment = await _financeService.recordLabourPayment(payment);
      _labourPayments.add(newPayment);
      notifyListeners();
    } catch (e) {
      debugPrint("Error recording labour payment: $e");
      rethrow;
    }
  }
}
