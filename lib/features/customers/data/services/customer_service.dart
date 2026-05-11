import 'package:admin/features/customers/data/models/customer.dart';
import 'package:admin/models/customer_role.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/models/pagination_params.dart';
import 'package:admin/services/api_service.dart';

class CustomerService {
  final ApiService _apiService = ApiService();

  Future<List<Customer>> getAllCustomers() async {
    final response = await _apiService.get('/customers');
    return _apiService.unwrapList<Customer>(response, (json) => Customer.fromJson(json));
  }

  Future<PaginatedResponse<Customer>> getCustomersPaginated(PaginationParams params) async {
    final queryParams = params.toQueryParams();
    final response = await _apiService.get('/customers/paginated', queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<Customer>>(response, (json) => PaginatedResponse.fromJson(json as Map<String, dynamic>, Customer.fromJson));
  }

  Future<Customer> getCustomerById(int id) async {
    final response = await _apiService.get('/customers/$id');
    return _apiService.unwrap<Customer>(response, (json) => Customer.fromJson(json as Map<String, dynamic>));
  }

  Future<Customer> createCustomer(Customer customer) async {
    final response = await _apiService.post('/customers', data: customer.toCreateJson());
    return _apiService.unwrap<Customer>(response, (json) => Customer.fromJson(json as Map<String, dynamic>));
  }

  Future<Customer> updateCustomer(int id, Customer customer) async {
    final response = await _apiService.put('/customers/$id', data: customer.toUpdateJson());
    return _apiService.unwrap<Customer>(response, (json) => Customer.fromJson(json as Map<String, dynamic>));
  }

  /// Hard-delete. Throws when the customer is still referenced (the caller
  /// should fall back to [setEnabled] to deactivate instead).
  Future<void> deleteCustomer(int id) async {
    await _apiService.delete('/customers/$id');
  }

  /// Toggle the customer's active state without touching FK references.
  Future<void> setEnabled(int id, bool enabled) async {
    await _apiService.patch('/customers/$id/enabled', data: {'enabled': enabled});
  }

  Future<List<CustomerRole>> getCustomerRoles() async {
    final response = await _apiService.get('/customers/roles');
    return _apiService.unwrapList<CustomerRole>(response, (json) => CustomerRole.fromJson(json));
  }

  /// Triggers a password-reset email to the customer via the portal API.
  /// Uses a separate portal endpoint — not the customer API's /auth/forgot-password.
  Future<void> sendPasswordResetEmail(int customerId) async {
    final response =
        await _apiService.post('/customers/$customerId/send-password-reset');
    _apiService.unwrap<void>(response, (_) {});
  }
}
