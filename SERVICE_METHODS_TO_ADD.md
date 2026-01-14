# Service Methods to Add for All 22 Modules

This document lists all search methods that need to be added to services.

## 1. CRMService - Add searchCustomers

Add after line 129:

```dart
/// NEW: Standardized search endpoint for customers
Future<PaginatedResponse<Customer>> searchCustomers({
  required int page,
  required int size,
  required String sortBy,
  required String sortDirection,
  String? search,
  Map<String, dynamic>? filters,
}) async {
  final queryParams = <String, dynamic>{
    'page': page,
    'size': size,
    'sortBy': sortBy,
    'sortDirection': sortDirection,
  };
  
  if (search != null && search.isNotEmpty) {
    queryParams['search'] = search;
  }
  
  if (filters != null) {
    filters.forEach((key, value) {
      if (value != null) {
        if (value is DateTime) {
          queryParams[key] = value.toIso8601String().split('T')[0];
        } else {
          queryParams[key] = value.toString();
        }
      }
    });
  }
  
  final response = await _apiService.get('/customers/search', queryParams: queryParams);
  return _apiService.unwrap<PaginatedResponse<Customer>>(
    response,
    (json) => PaginatedResponse.fromJson(json as Map<String, dynamic>, Customer.fromJson),
  );
}
```

## 2. LeadService - Add searchLeadInteractions (already has searchLeads)

```dart
Future<PaginatedResponse<LeadInteraction>> searchLeadInteractions({
  required int page,
  required int size,
  required String sortBy,
  required String sortDirection,
  String? search,
  Map<String, dynamic>? filters,
}) async {
  final queryParams = <String, dynamic>{
    'page': page,
    'size': size,
    'sortBy': sortBy,
    'sortDirection': sortDirection,
  };
  
  if (search != null && search.isNotEmpty) {
    queryParams['search'] = search;
  }
  
  if (filters != null) {
    filters.forEach((key, value) {
      if (value != null) {
        queryParams[key] = value.toString();
      }
    });
  }
  
  final response = await _apiService.get('/leads/interactions/search', queryParams: queryParams);
  return _apiService.unwrap<PaginatedResponse<LeadInteraction>>(
    response,
    (json) => PaginatedResponse.fromJson(json as Map<String, dynamic>, LeadInteraction.fromJson),
  );
}
```

## 3. LeadQuotationService - Add searchLeadQuotations

```dart
Future<PaginatedResponse<LeadQuotation>> searchLeadQuotations({
  required int page,
  required int size,
  required String sortBy,
  required String sortDirection,
  String? search,
  Map<String, dynamic>? filters,
}) async {
  final queryParams = <String, dynamic>{
    'page': page,
    'size': size,
    'sortBy': sortBy,
    'sortDirection': sortDirection,
  };
  
  if (search != null && search.isNotEmpty) {
    queryParams['search'] = search;
  }
  
  if (filters != null) {
    filters.forEach((key, value) {
      if (value != null) {
        queryParams[key] = value.toString();
      }
    });
  }
  
  final response = await _apiService.get('/leads/quotations/search', queryParams: queryParams);
  return _apiService.unwrap<PaginatedResponse<LeadQuotation>>(
    response,
    (json) => PaginatedResponse.fromJson(json as Map<String, dynamic>, LeadQuotation.fromJson),
  );
}
```

## 4. CustomerProjectService - Add searchProjects

```dart
Future<PaginatedResponse<CustomerProject>> searchProjects({
  required int page,
  required int size,
  required String sortBy,
  required String sortDirection,
  String? search,
  Map<String, dynamic>? filters,
}) async {
  final queryParams = <String, dynamic>{
    'page': page,
    'size': size,
    'sortBy': sortBy,
    'sortDirection': sortDirection,
  };
  
  if (search != null && search.isNotEmpty) {
    queryParams['search'] = search;
  }
  
  if (filters != null) {
    filters.forEach((key, value) {
      if (value != null) {
        if (value is DateTime) {
          queryParams[key] = value.toIso8601String().split('T')[0];
        } else {
          queryParams[key] = value.toString();
        }
      }
    });
  }
  
  final response = await _apiService.get('/customer-projects/search', queryParams: queryParams);
  return _apiService.unwrap<PaginatedResponse<CustomerProject>>(
    response,
    (json) => PaginatedResponse.fromJson(json as Map<String, dynamic>, CustomerProject.fromJson),
  );
}
```

## 5. TaskService - Add searchTasks

```dart
Future<PaginatedResponse<Task>> searchTasks({
  required int page,
  required int size,
  required String sortBy,
  required String sortDirection,
  String? search,
  Map<String, dynamic>? filters,
}) async {
  final queryParams = <String, dynamic>{
    'page': page,
    'size': size,
    'sortBy': sortBy,
    'sortDirection': sortDirection,
  };
  
  if (search != null && search.isNotEmpty) {
    queryParams['search'] = search;
  }
  
  if (filters != null) {
    filters.forEach((key, value) {
      if (value != null) {
        if (value is DateTime) {
          queryParams[key] = value.toIso8601String().split('T')[0];
        } else {
          queryParams[key] = value.toString();
        }
      }
    });
  }
  
  final response = await _apiService.get('/api/tasks/search', queryParams: queryParams);
  return _apiService.unwrap<PaginatedResponse<Task>>(
    response,
    (json) => PaginatedResponse.fromJson(json as Map<String, dynamic>, Task.fromJson),
  );
}
```

## Summary

All 22 modules follow the same pattern:

1. Accept pagination params (page, size, sortBy, sortDirection)
2. Accept optional search string
3. Accept optional filters map
4. Build query params
5. Call `/endpoint/search` endpoint
6. Return `PaginatedResponse<Entity>`

Once service methods are added, create corresponding providers that extend `BasePaginatedProvider<Entity>`.

See `LeadProvider` as the reference implementation.

