
import 'package:admin/features/customers/data/models/customer.dart';
import 'package:admin/models/customer_role.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/models/pagination_params.dart';
import 'package:admin/services/api_service.dart';

class CustomerService {
  final ApiService _apiService = ApiService();

  Future<List<Customer>> getAllCustomers() async {
    try {
      final response = await _apiService.get('/customers');
      final List<dynamic> data = response.data;
      return data.map((json) => Customer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  Future<PaginatedResponse<Customer>> getCustomersPaginated(PaginationParams params) async {
    try {
      final queryParams = params.toQueryParams();
      final response = await _apiService.get('/customers/paginated', queryParams: queryParams);
      return PaginatedResponse.fromJson(response.data, Customer.fromJson);
    } catch (e) {
      throw Exception('Failed to fetch paginated customers: $e');
    }
  }

  Future<Customer> getCustomerById(int id) async {
    try {
      final response = await _apiService.get('/customers/$id');
      return Customer.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch customer: $e');
    }
  }

  Future<Customer> createCustomer(Customer customer) async {
    try {
      final response = await _apiService.post('/customers', data: customer.toCreateJson());
      return Customer.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  Future<Customer> updateCustomer(int id, Customer customer) async {
    try {
      final response = await _apiService.put('/customers/$id', data: customer.toUpdateJson());
      return Customer.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      await _apiService.delete('/customers/$id');
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  Future<List<CustomerRole>> getCustomerRoles() async {
    try {
      final response = await _apiService.get('/customers/roles');
      final List<dynamic> data = response.data;
      return data.map((json) => CustomerRole.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customer roles: $e');
    }
  }
}
