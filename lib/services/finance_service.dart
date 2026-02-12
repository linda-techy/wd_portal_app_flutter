import 'package:admin/services/api_service.dart';
import 'package:admin/models/finance_models.dart';
import 'package:admin/features/finance/data/models/billing_models.dart';

class FinanceService {
  final ApiService _apiService = ApiService();

  Future<ProjectInvoice> createProjectInvoice(ProjectInvoice invoice) async {
    final response = await _apiService.post('/api/finance/invoice/create',
        data: invoice.toJson());
    return ProjectInvoice.fromJson(response.data);
  }

  Future<PurchaseInvoice> recordPurchaseInvoice(PurchaseInvoice invoice) async {
    final response = await _apiService.post('/api/finance/purchase-invoice/record',
        data: invoice.toJson());
    return PurchaseInvoice.fromJson(response.data);
  }

  Future<LabourPayment> recordLabourPayment(LabourPayment payment) async {
    final response = await _apiService.post('/api/finance/labour-payment/record',
        data: payment.toJson());
    return LabourPayment.fromJson(response.data);
  }

  Future<List<ProjectInvoice>> getProjectInvoices(int projectId) async {
    final response =
        await _apiService.get('/api/finance/invoices/project/$projectId');
    return (response.data as List)
        .map((i) => ProjectInvoice.fromJson(i))
        .toList();
  }

  // Milestones
  Future<ProjectMilestone> createMilestone(ProjectMilestone milestone) async {
    final response =
        await _apiService.post('/api/finance/milestone', data: milestone.toJson());
    return ProjectMilestone.fromJson(response.data);
  }

  Future<ProjectMilestone> updateMilestone(ProjectMilestone milestone) async {
    final response = await _apiService.put('/api/finance/milestone/${milestone.id}',
        data: milestone.toJson());
    return ProjectMilestone.fromJson(response.data);
  }

  Future<ProjectInvoice> generateInvoiceForMilestone(int milestoneId) async {
    final response = await _apiService
        .post('/api/finance/milestone/$milestoneId/generate-invoice');
    return ProjectInvoice.fromJson(response.data);
  }

  Future<List<ProjectMilestone>> getProjectMilestones(int projectId) async {
    final response =
        await _apiService.get('/api/finance/milestones/project/$projectId');
    return (response.data as List)
        .map((i) => ProjectMilestone.fromJson(i))
        .toList();
  }

  // Receipts
  Future<Receipt> recordReceipt(Receipt receipt) async {
    final response =
        await _apiService.post('/api/finance/receipt', data: receipt.toJson());
    return Receipt.fromJson(response.data);
  }

  Future<List<Receipt>> getProjectReceipts(int projectId) async {
    final response =
        await _apiService.get('/api/finance/receipts/project/$projectId');
    return (response.data as List).map((i) => Receipt.fromJson(i)).toList();
  }
}
