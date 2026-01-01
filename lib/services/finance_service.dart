import 'package:admin/services/api_service.dart';
import 'package:admin/models/finance_models.dart';
import 'package:dio/dio.dart';

class FinanceService {
  final ApiService _apiService = ApiService();

  Future<ProjectInvoice> createProjectInvoice(ProjectInvoice invoice) async {
    final response = await _apiService.post('/finance/invoice/create', invoice.toJson());
    return ProjectInvoice.fromJson(response.data);
  }

  Future<PurchaseInvoice> recordPurchaseInvoice(PurchaseInvoice invoice) async {
    final response = await _apiService.post('/finance/purchase-invoice/record', invoice.toJson());
    return PurchaseInvoice.fromJson(response.data);
  }

  Future<LabourPayment> recordLabourPayment(LabourPayment payment) async {
    final response = await _apiService.post('/finance/labour-payment/record', payment.toJson());
    return LabourPayment.fromJson(response.data);
  }

  Future<List<ProjectInvoice>> getProjectInvoices(int projectId) async {
    final response = await _apiService.get('/finance/invoices/project/$projectId');
    return (response.data as List).map((i) => ProjectInvoice.fromJson(i)).toList();
  }
}
