import 'package:dio/dio.dart';
import '../models/vendor_payment_models.dart';
import 'api_service.dart';

/// Vendor Payment Service
/// Handles all API calls for vendor payments and accounts payable
class VendorPaymentService {
  final ApiService _apiService;

  VendorPaymentService(this._apiService);

  // ===== PAYMENTS =====

  /// Record a vendor payment
  Future<VendorPayment> recordPayment(VendorPayment payment) async {
    try {
      final response = await _apiService.post(
        '/api/accounts-payable/payments',
        data: payment.toJson(),
      );
      return VendorPayment.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get payment history for an invoice
  Future<List<VendorPayment>> getInvoicePayments(int invoiceId) async {
    try {
      final response = await _apiService.get('/api/accounts-payable/invoices/$invoiceId/payments');
      return (response.data as List)
          .map((json) => VendorPayment.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all payments for a vendor
  Future<List<VendorPayment>> getVendorPayments(int vendorId) async {
    try {
      final response = await _apiService.get('/api/accounts-payable/vendors/$vendorId/payments');
      return (response.data as List)
          .map((json) => VendorPayment.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get payments by date range
  Future<List<VendorPayment>> getPaymentsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _apiService.get(
        '/api/accounts-payable/payments',
        queryParams: {
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
        },
      );
      return (response.data as List)
          .map((json) => VendorPayment.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ===== ACCOUNTS PAYABLE AGING =====

  /// Get accounts payable aging report
  Future<AccountsPayableAging> getAccountsPayableAging() async {
    try {
      final response = await _apiService.get('/api/accounts-payable/aging');
      return AccountsPayableAging.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get vendor outstanding summaries
  Future<List<VendorOutstanding>> getVendorOutstanding() async {
    try {
      final response = await _apiService.get('/api/accounts-payable/vendor-outstanding');
      return (response.data as List)
          .map((json) => VendorOutstanding.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get outstanding for specific vendor
  Future<VendorOutstanding> getVendorOutstandingDetail(int vendorId) async {
    try {
      final response = await _apiService.get('/api/accounts-payable/vendors/$vendorId/outstanding');
      return VendorOutstanding.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ===== PENDING & OVERDUE =====

  /// Get pending invoices
  Future<List> getPendingInvoices() async {
    try {
      final response = await _apiService.get('/api/accounts-payable/invoices/pending');
      return response.data as List;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get overdue invoices
  Future<List> getOverdueInvoices() async {
    try {
      final response = await _apiService.get('/api/accounts-payable/invoices/overdue');
      return response.data as List;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ===== STATISTICS =====

  /// Get total paid in period
  Future<double> getTotalPaidInPeriod(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _apiService.get(
        '/api/accounts-payable/statistics/total-paid',
        queryParams: {
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
        },
      );
      return (response.data as num).toDouble();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get total TDS deducted in period
  Future<double> getTotalTdsDeducted(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _apiService.get(
        '/api/accounts-payable/statistics/total-tds',
        queryParams: {
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
        },
      );
      return (response.data as num).toDouble();
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
