import 'package:flutter/foundation.dart';
import '../models/vendor_payment_models.dart';
import '../services/vendor_payment_service.dart';

/// Vendor Payment Provider
/// State management for vendor payments and accounts payable
class VendorPaymentProvider with ChangeNotifier {
  final VendorPaymentService _vendorPaymentService;

  VendorPaymentProvider(this._vendorPaymentService);

  // State
  List<VendorPayment> _payments = [];
  AccountsPayableAging? _apAging;
  List<VendorOutstanding> _vendorOutstanding = [];
  List _pendingInvoices = [];
  List _overdueInvoices = [];
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<VendorPayment> get payments => _payments;
  AccountsPayableAging? get apAging => _apAging;
  List<VendorOutstanding> get vendorOutstanding => _vendorOutstanding;
  List get pendingInvoices => _pendingInvoices;
  List get overdueInvoices => _overdueInvoices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed getters
  bool get hasOverduePayments => _apAging?.hasOverduePayments ?? false;
  int get overdueInvoiceCount => _apAging?.overdueInvoiceCount ?? 0;
  double get totalOutstanding => _apAging?.totalOutstanding ?? 0;
  double get overdueAmount => _apAging?.overdue ?? 0;

  List<VendorOutstanding> get criticalVendors =>
      _vendorOutstanding.where((v) => v.hasOverduePayments).toList();

  // ===== PAYMENTS =====

  Future<void> recordPayment(VendorPayment payment) async {
    _setLoading(true);
    
    try {
      final recorded = await _vendorPaymentService.recordPayment(payment);
      _payments.add(recorded);
      _error = null;
      
      // Refresh aging after payment
      await loadAccountsPayableAging();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadInvoicePayments(int invoiceId) async {
    _setLoading(true);
    
    try {
      _payments = await _vendorPaymentService.getInvoicePayments(invoiceId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadVendorPayments(int vendorId) async {
    _setLoading(true);
    
    try {
      _payments = await _vendorPaymentService.getVendorPayments(vendorId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ===== ACCOUNTS PAYABLE AGING =====

  Future<void> loadAccountsPayableAging() async {
    _setLoading(true);
    
    try {
      _apAging = await _vendorPaymentService.getAccountsPayableAging();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadVendorOutstanding() async {
    _setLoading(true);
    
    try {
      _vendorOutstanding = await _vendorPaymentService.getVendorOutstanding();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadVendorOutstandingDetail(int vendorId) async {
    _setLoading(true);
    
    try {
      final detail = await _vendorPaymentService.getVendorOutstandingDetail(vendorId);
      
      // Update in list if exists
      final index = _vendorOutstanding.indexWhere((v) => v.vendorId == vendorId);
      if (index != -1) {
        _vendorOutstanding[index] = detail;
      } else {
        _vendorOutstanding.add(detail);
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ===== PENDING & OVERDUE =====

  Future<void> loadPendingInvoices() async {
    _setLoading(true);
    
    try {
      _pendingInvoices = await _vendorPaymentService.getPendingInvoices();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadOverdueInvoices() async {
    _setLoading(true);
    
    try {
      _overdueInvoices = await _vendorPaymentService.getOverdueInvoices();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ===== DASHBOARD DATA =====

  /// Load all data for dashboard
  Future<void> loadDashboardData() async {
    await Future.wait([
      loadAccountsPayableAging(),
      loadVendorOutstanding(),
      loadOverdueInvoices(),
    ]);
  }

  // ===== STATISTICS =====

  Future<double> getTotalPaid(DateTime startDate, DateTime endDate) async {
    try {
      return await _vendorPaymentService.getTotalPaidInPeriod(startDate, endDate);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  Future<double> getTotalTds(DateTime startDate, DateTime endDate) async {
    try {
      return await _vendorPaymentService.getTotalTdsDeducted(startDate, endDate);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  // ===== HELPERS =====

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _payments = [];
    _apAging = null;
    _vendorOutstanding = [];
    _pendingInvoices = [];
    _overdueInvoices = [];
    _error = null;
    notifyListeners();
  }
}
