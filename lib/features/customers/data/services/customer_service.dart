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

  Future<void> deleteCustomer(int id) async {
    final response = await _apiService.delete('/customers/$id');
    _apiService.unwrap<void>(response, (_) {});
  }

  Future<List<CustomerRole>> getCustomerRoles() async {
    final response = await _apiService.get('/customers/roles');
    return _apiService.unwrapList<CustomerRole>(response, (json) => CustomerRole.fromJson(json));
  }
}
