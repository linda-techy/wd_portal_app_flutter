# Screen Implementation Guide
## Quick Reference for All 22 Modules

**Status:** Tasks screen completed as reference  
**Pattern:** Established and tested  
**Remaining:** 20 screens to implement

---

## ✅ **Completed Screens (2/22)**

1. ✅ **Leads** - `leads_screen_new.dart` (template)
2. ✅ **Tasks** - `tasks_screen_new.dart` (just created)

---

## 📋 **Screen Implementation Pattern**

### Standard Screen Structure (Copy-Paste Template)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/providers/[MODULE]_provider.dart';
import 'package:admin/models/[MODULE]_models.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';

class [Module]ScreenNew extends StatelessWidget {
  const [Module]ScreenNew({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => [Module]Provider()..fetch(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('[Module Name]'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () { /* TODO: Create */ },
            ),
          ],
        ),
        body: Consumer<[Module]Provider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                // 1. Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SearchBarWidget(
                    onSearch: provider.search,
                    hintText: 'Search [module]...',
                  ),
                ),

                // 2. Filter Chips
                _buildFilterChips(context, provider),

                // 3. List View
                Expanded(child: _buildList(context, provider)),

                // 4. Pagination
                if (provider.totalPages > 1)
                  _buildPaginationControls(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, [Module]Provider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Add module-specific filter chips here
          // Example: Status, Priority, Date Range, etc.
          if (provider.filters.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
              onPressed: provider.clearFilters,
            ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, [Module]Provider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${provider.error}'),
            ElevatedButton(
              onPressed: () => provider.fetch(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.[icon], size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No items found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetch(refresh: true),
      child: ListView.builder(
        itemCount: provider.items.length,
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, index) {
          final item = provider.items[index];
          return _buildCard(context, item);
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, [Model] item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(item.name), // Adapt to your model
        subtitle: Text(item.description), // Adapt to your model
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () { /* Navigate to details */ },
      ),
    );
  }

  Widget _buildPaginationControls([Module]Provider provider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
            onPressed: provider.hasPrevious ? provider.previousPage : null,
          ),
          Text('Page ${provider.currentPage + 1} of ${provider.totalPages}'),
          ElevatedButton.icon(
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
            onPressed: provider.hasNext ? provider.nextPage : null,
          ),
        ],
      ),
    );
  }
}
```

---

## 📝 **Remaining Screens to Implement (20)**

### High Priority (8 screens)
1. ❌ **Customer Projects** - Update existing with `CustomerProjectProviderPaginated`
2. ❌ **Site Visits** - Use `SiteVisitProvider`
3. ❌ **Purchase Orders** - Use `PurchaseOrderProvider`
4. ❌ **Materials** - Use `MaterialProvider`
5. ❌ **Material Indents** - Use `MaterialIndentProvider`
6. ❌ **Quality Checks** - Use `QualityCheckProvider`
7. ❌ **Site Reports** - Use `SiteReportProvider`
8. ❌ **Customers** - Update existing with `CustomerProvider`

### Medium Priority (8 screens)
9. ❌ **Delay Logs** - Use `DelayLogProvider`
10. ❌ **Vendor Quotations** - Use `VendorQuotationProvider`
11. ❌ **BOQ** - Use `BoqProvider`
12. ❌ **Inventory Stock** - Use `InventoryStockProvider`
13. ❌ **Labour** - Use `LabourProvider`
14. ❌ **Subcontracts** - Use `SubcontractProvider`
15. ❌ **Lead Interactions** - Use `LeadInteractionProvider`
16. ❌ **Lead Quotations** - Use `LeadQuotationProvider`

### Lower Priority (4 screens)
17. ❌ **Project Variations** - Use `ProjectVariationProvider`
18. ❌ **Project Warranties** - Use `ProjectWarrantyProvider`
19. ❌ **Payments** - Use `PaymentProvider`
20. ❌ **Approvals** - Use `ApprovalProvider`

---

## 🎯 **Quick Implementation Checklist**

For each screen:
- [ ] Create new file: `lib/screens/[module]/[module]_screen_new.dart`
- [ ] Import correct provider and model
- [ ] Wrap with `ChangeNotifierProvider`
- [ ] Add `Consumer<Provider>`
- [ ] Implement search bar
- [ ] Add module-specific filter chips
- [ ] Create list view with cards
- [ ] Add pagination controls
- [ ] Handle loading/error/empty states
- [ ] Test basic functionality

**Time per screen:** 20-40 minutes  
**Total remaining time:** 7-13 hours for all 20 screens

---

## 💡 **Module-Specific Adaptations**

### Customer Projects
- Filter by: Phase, Type, Contract Type, Manager, Location, Progress
- Display: Project name, phase, budget, progress bar

### Site Visits
- Filter by: Project, Visit Type, Status, Visitor
- Display: Project, visit type, check-in/out times, status

### Purchase Orders
- Filter by: Vendor, Project, Status, Amount range
- Display: PO number, vendor, project, total amount, status

### Materials
- Filter by: Category, Low stock, Project
- Display: Material name, code, category, quantity, unit

### Material Indents
- Filter by: Project, Status, Requester
- Display: Indent number, project, material, quantity, status

### Quality Checks
- Filter by: Project, Check type, Result
- Display: Title, project, check type, result, date

### Site Reports
- Filter by: Project, Report type, Reporter
- Display: Title, project, report type, date, reporter

### Customers
- Filter by: Customer type, City, State, Active status
- Display: Name, type, contact, location, projects count

---

## 🚀 **Next Steps**

1. Use `tasks_screen_new.dart` as your primary reference
2. Copy the structure for each new screen
3. Update provider and model imports
4. Adapt card display to show relevant fields
5. Configure module-specific filters
6. Test each screen individually

**Current Progress:** 2/22 screens (9%)  
**Target:** 22/22 screens (100%)

---

## 📞 **Need Help?**

- **Reference Screens:** `tasks_screen_new.dart`, `leads_screen_new.dart`
- **Provider Pattern:** Check any provider in `lib/providers/`
- **Filter Examples:** See `TaskProvider` for filter methods
- **Model Structure:** Check model files in `lib/models/`

**Remember:** The pattern is established and consistent across all modules. Just adapt the details to each specific module!

