# Frontend Integration Guide
## Connecting 22 Backend Search/Filter/Pagination Modules to Flutter UI

### Overview

This guide demonstrates how to integrate the 22 standardized backend modules with the Flutter frontend using the `BasePaginatedProvider` pattern.

---

## Pattern Components

### 1. Service Method
Every module needs a search method in its service:

```dart
Future<PaginatedResponse<Entity>> searchEntities({
  required int page,  // 0-based
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
  
  final response = await _apiService.get('/endpoint/search', queryParams: queryParams);
  return _apiService.unwrap<PaginatedResponse<Entity>>(
    response,
    (json) => PaginatedResponse.fromJson(json, Entity.fromJson),
  );
}
```

### 2. Provider Class
Create a provider that extends `BasePaginatedProvider`:

```dart
class EntityProvider extends BasePaginatedProvider<Entity> {
  final EntityService _service = EntityService();
  
  @override
  Future<PaginatedResponse<Entity>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchEntities(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }
  
  // Module-specific filter methods
  void filterByStatus(String? status) {
    updateFilter('status', status);
  }
}
```

### 3. Screen Usage
Use the provider with `ChangeNotifierProvider` and `Consumer`:

```dart
class EntityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EntityProvider()..fetch(),
      child: Consumer<EntityProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !provider.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          return Column(
            children: [
              // Search
              TextField(
                onSubmitted: provider.search,
              ),
              
              // List
              Expanded(
                child: ListView.builder(
                  itemCount: provider.items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(provider.items[index].name),
                    );
                  },
                ),
              ),
              
              // Pagination
              Row(
                children: [
                  TextButton(
                    onPressed: provider.hasPrevious ? provider.previousPage : null,
                    child: Text('Previous'),
                  ),
                  Text('Page ${provider.currentPage + 1} of ${provider.totalPages}'),
                  TextButton(
                    onPressed: provider.hasNext ? provider.nextPage : null,
                    child: Text('Next'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
```

---

## Example: Lead Module (Complete Implementation)

See [`lib/features/leads/presentation/screens/leads_screen_new.dart`](lib/features/leads/presentation/screens/leads_screen_new.dart) for a complete, production-ready example with:

- ✅ Search bar with debouncing
- ✅ Filter panel with 6+ filters
- ✅ Active filter chips
- ✅ Pagination controls
- ✅ Loading states
- ✅ Empty states
- ✅ Error handling
- ✅ Page size selection
- ✅ Refresh functionality

---

## Module Implementation Status

### ✅ Complete
1. **Leads** - Service, Provider, Screen (new)

### 🔄 In Progress
The following modules need service methods and providers created:

2. **Customers**
3. **Lead Interactions**
4. **Lead Quotations**
5. **Customer Projects** (refactor existing)
6. **Tasks**
7. **Site Visits**
8. **Delay Logs**
9. **Project Variations**
10. **Purchase Orders**
11. **Material Indents**
12. **Vendor Quotations**
13. **BOQ**
14. **Materials (Inventory)**
15. **Inventory Stock**
16. **Quality Checks**
17. **Site Reports**
18. **Labour**
19. **Subcontracts**
20. **Project Warranties**
21. **Payments**
22. **Approvals**

---

## Quick Reference: Filter Fields by Module

| Module | Available Filters |
|--------|------------------|
| Leads | status, source, priority, customerType, projectType, assignedTeam, state, district, minBudget, maxBudget, startDate, endDate |
| Customers | customerType, city, state, active |
| Customer Projects | projectPhase, projectType, contractType, managerId, customerId, location, city, state, minBudget, maxBudget, minProgress, maxProgress |
| Tasks | priority, assignedToId, projectId, leadId, status, minDueDate, maxDueDate |
| Purchase Orders | vendorId, projectId, poNumber, status, minAmount, maxAmount |
| Material Indents | projectId, requestedById, approvedById, indentNumber, materialName, status |
| Inventory | materialName, materialCode, materialCategory, projectId, lowStock, minQuantity, maxQuantity |
| Payments | invoiceNumber, customerId, projectId, paymentType, status, minAmount, maxAmount |
| Quality Checks | projectId, checkType, result, inspectorId, area |
| Site Reports | projectId, reportType, reportedBy, location |
| Labour | projectId, workerId, contractorName, role, employmentType |
| Subcontracts | projectId, workOrderNumber, contractorName, workType, minAmount, maxAmount |
| Vendor Quotations | vendorId, projectId, quotationNumber, status, minAmount, maxAmount |
| Approvals | approverType, moduleType, approverId, requesterId, status |
| BOQ | projectId, workTypeId, itemCode, minAmount, maxAmount |
| Site Visits | projectId, visitedBy, visitType, status, activeOnly |
| Delay Logs | projectId, delayType, severity, resolved |
| Project Variations | projectId, variationType, approvalStatus, requestedBy, approvedBy, minAmount, maxAmount |
| Lead Interactions | leadId, interactionType, userId, outcome, followUpRequired |
| Lead Quotations | leadId, quotationNumber, preparedBy, status, validityStatus, minAmount, maxAmount |
| Project Warranties | projectId, warrantyType, activeOnly, expiredOnly |

---

## Next Steps

1. Systematically implement service methods for all 21 remaining modules
2. Create providers for all modules
3. Update screens to use providers (can be gradual)
4. Test each module's search/filter/pagination

---

## Benefits

- **Consistent UX** across all 22 modules
- **Reusable code** - less maintenance
- **Performance** - optimized queries, pagination
- **Scalability** - handles 100,000+ records
- **Developer productivity** - clear patterns to follow

---

Generated: January 14, 2026

