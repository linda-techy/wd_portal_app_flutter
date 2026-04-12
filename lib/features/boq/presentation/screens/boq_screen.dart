import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:admin/services/boq_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/providers/permission_provider.dart';

class BoqScreen extends StatefulWidget {
  final int projectId;

  const BoqScreen({super.key, required this.projectId});

  @override
  State<BoqScreen> createState() => _BoqScreenState();
}

class _BoqScreenState extends State<BoqScreen> {
  final BoqService _service = BoqService();
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  List<BoqItem> _items = [];
  List<BoqWorkType> _workTypes = [];
  List<BoqCategory> _categories = [];
  List<InventoryMaterial> _materials = [];
  BoqFinancialSummary? _summary;
  int? _selectedWorkTypeId;
  int? _selectedCategoryId;
  String? _selectedStatus;
  bool _isLoading = true;
  bool _isExporting = false; // controls AppBar export icon spinner
  bool _showSummary = true;
  static const int _pageSize = 50;
  int _displayLimit = _pageSize;

  @override
  void initState() {
    super.initState();
    _verifyAuthAndLoadData();
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider =
        Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
        await ErrorHandler.handleAuthError(context);
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _displayLimit = _pageSize;
    });
    try {
      // Materials are only needed when the create/edit dialog opens — load them lazily there.
      final results = await Future.wait([
        _service.getProjectBoq(widget.projectId),
        _service.getWorkTypes(),
        _service.getCategories(widget.projectId),
        _service.getFinancialSummary(widget.projectId),
      ]);
      if (mounted) {
        setState(() {
          _items = results[0] as List<BoqItem>;
          _workTypes = results[1] as List<BoqWorkType>;
          _categories = results[2] as List<BoqCategory>;
          _summary = results[3] as BoqFinancialSummary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to load BoQ');
      }
    }
  }

  /// Loads materials lazily — only called when the create/edit dialog is about to open.
  Future<void> _ensureMaterialsLoaded() async {
    if (_materials.isNotEmpty) return;
    final mats = await _service.getMaterials();
    if (mounted) setState(() => _materials = mats);
  }

  Future<void> _exportExcel() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final file = await _service.downloadBoqExcel(widget.projectId);
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  List<BoqItem> get _allFilteredItems {
    return _items.where((item) {
      if (_selectedWorkTypeId != null && item.workTypeId != _selectedWorkTypeId) return false;
      if (_selectedCategoryId != null && item.categoryId != _selectedCategoryId) return false;
      if (_selectedStatus != null && item.status != _selectedStatus) return false;
      return true;
    }).toList();
  }

  List<BoqItem> get _filteredItems {
    final all = _allFilteredItems;
    if (all.length <= _displayLimit) return all;
    return all.sublist(0, _displayLimit);
  }

  bool get _hasMoreItems => _allFilteredItems.length > _displayLimit;

  Map<String, List<BoqItem>> get _groupedItems {
    final map = <String, List<BoqItem>>{};
    for (final item in _filteredItems) {
      final key = item.categoryName ?? item.workTypeName ?? 'Uncategorized';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill of Quantities'),
        actions: [
          IconButton(
            icon: Icon(
              _showSummary ? Icons.bar_chart : Icons.bar_chart_outlined,
              color: _showSummary ? AppTheme.coralRed : null,
            ),
            onPressed: () => setState(() => _showSummary = !_showSummary),
            tooltip: 'Toggle summary',
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            onPressed: _isExporting ? null : _exportExcel,
            tooltip: 'Export to Excel',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: context.watch<PermissionProvider>().canCreateBoq
          ? FloatingActionButton(
              onPressed: () => _showCreateDialog(),
              backgroundColor: AppTheme.deepSlate,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Enhanced Summary section
                  if (_showSummary && _summary != null)
                    SliverToBoxAdapter(child: _buildEnhancedSummaryCard()),
                  // Filters
                  SliverToBoxAdapter(child: _buildFilters()),
                  // Grouped items
                  if (_filteredItems.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No BoQ items found',
                                style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._buildGroupedItemSlivers(),
                  if (_hasMoreItems)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _displayLimit += _pageSize),
                          icon: const Icon(Icons.expand_more),
                          label: Text('Show more (${_allFilteredItems.length - _displayLimit} remaining)'),
                        ),
                      ),
                    ),
                  // Bottom padding for FAB
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  Widget _buildEnhancedSummaryCard() {
    final summary = _summary!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.deepSlate, AppTheme.deepSlateLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Financial Summary',
                style: TextStyle(
                    color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${summary.totalItems} items',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Planned Cost', summary.totalPlannedCost, Colors.white),
          const SizedBox(height: 6),
          _buildSummaryRow('Executed Cost', summary.totalExecutedCost, Colors.orangeAccent),
          const SizedBox(height: 6),
          _buildSummaryRow('Billed Cost', summary.totalBilledCost, Colors.greenAccent),
          const SizedBox(height: 6),
          _buildSummaryRow('Cost to Complete', summary.totalCostToComplete, Colors.yellowAccent),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPercentageBadge(
                    'Execution', summary.overallExecutionPercentage, Colors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPercentageBadge(
                    'Billing', summary.overallBillingPercentage, Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.9), fontSize: 13)),
        Text(_currencyFormat.format(amount),
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPercentageBadge(String label, double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          Text('${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // Status filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', _selectedStatus == null, () {
                  setState(() => _selectedStatus = null);
                }),
                _buildFilterChip('Draft', _selectedStatus == 'DRAFT', () {
                  setState(() => _selectedStatus = 'DRAFT');
                }),
                _buildFilterChip('Approved', _selectedStatus == 'APPROVED', () {
                  setState(() => _selectedStatus = 'APPROVED');
                }),
                _buildFilterChip('Locked', _selectedStatus == 'LOCKED', () {
                  setState(() => _selectedStatus = 'LOCKED');
                }),
                _buildFilterChip('Completed', _selectedStatus == 'COMPLETED', () {
                  setState(() => _selectedStatus = 'COMPLETED');
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Category/Work Type filter
          if (_categories.isNotEmpty || _workTypes.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_categories.isNotEmpty) ...[
                    ..._categories.where((c) => c.isTopLevel).map((cat) => _buildFilterChip(
                          cat.name,
                          _selectedCategoryId == cat.id,
                          () => setState(() {
                            _selectedCategoryId = _selectedCategoryId == cat.id ? null : cat.id;
                            _selectedWorkTypeId = null;
                          }),
                        )),
                  ],
                  if (_workTypes.isNotEmpty) ...[
                    ..._workTypes.map((wt) => _buildFilterChip(
                          wt.name,
                          _selectedWorkTypeId == wt.id,
                          () => setState(() {
                            _selectedWorkTypeId = _selectedWorkTypeId == wt.id ? null : wt.id;
                            _selectedCategoryId = null;
                          }),
                        )),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.deepSlate,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  List<DropdownMenuItem<int>> _buildHierarchicalCategoryItems() {
    final items = <DropdownMenuItem<int>>[];
    
    // Get all top-level categories
    final topLevelCategories = _categories.where((c) => c.isTopLevel).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    
    for (final parent in topLevelCategories) {
      // Add parent category with folder icon
      items.add(
        DropdownMenuItem(
          value: parent.id,
          child: Row(
            children: [
              const Icon(Icons.folder, size: 18, color: AppTheme.deepSlate),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  parent.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (parent.itemCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.deepSlate.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${parent.itemCount}',
                    style: const TextStyle(fontSize: 10, color: AppTheme.deepSlate),
                  ),
                ),
            ],
          ),
        ),
      );
      
      // Add subcategories under this parent
      final subcategories = _categories
          .where((c) => c.parentId == parent.id)
          .toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      
      for (final sub in subcategories) {
        items.add(
          DropdownMenuItem(
            value: sub.id,
            child: Row(
              children: [
                const SizedBox(width: 12), // Indentation
                const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Icon(Icons.label, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sub.name,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (sub.itemCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${sub.itemCount}',
                      style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }
    
    return items;
  }

  /// Returns the pre-aggregated planned cost for a group from the backend summary,
  /// falling back to a client-side fold only when no matching entry is found.
  double _groupPlannedCost(String groupName, List<BoqItem> items) {
    if (_summary != null) {
      for (final c in _summary!.categoryBreakdown) {
        if (c.categoryName == groupName) return c.plannedCost;
      }
      for (final w in _summary!.workTypeBreakdown) {
        if (w.workTypeName == groupName) return w.plannedCost;
      }
    }
    return items.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  List<Widget> _buildGroupedItemSlivers() {
    final groups = _groupedItems;
    final slivers = <Widget>[];

    for (final entry in groups.entries) {
      final groupTotal = _groupPlannedCost(entry.key, entry.value);
      // Group header
      slivers.add(SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.surfaceElevated,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                _currencyFormat.format(groupTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.deepSlate,
                ),
              ),
            ],
          ),
        ),
      ));
      // Group items
      slivers.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildEnhancedItemCard(entry.value[index]),
          childCount: entry.value.length,
        ),
      ));
    }
    return slivers;
  }

  Widget _buildEnhancedItemCard(BoqItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showItemDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(item.status),
                ],
              ),
              if (item.itemCode != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Code: ${item.itemCode}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMetric('Qty', item.quantity.toString().replaceAll(RegExp(r'\.0$'), '')),
                  const SizedBox(width: 16),
                  _buildMetric('Unit', item.unit),
                  const SizedBox(width: 16),
                  _buildMetric('Rate', _currencyFormat.format(item.unitRate)),
                  const Spacer(),
                  Text(
                    _currencyFormat.format(item.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                ],
              ),
              // Execution Progress
              if (item.executedQuantity > 0 || item.billedQuantity > 0) ...[
                const SizedBox(height: 10),
                _buildProgressBar(
                    'Executed', item.executionPercentage, Colors.orange, item.executedQuantity, item.quantity),
                const SizedBox(height: 6),
                _buildProgressBar(
                    'Billed', item.billingPercentage, Colors.green, item.billedQuantity, item.executedQuantity),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'DRAFT':
        color = Colors.grey;
        break;
      case 'APPROVED':
        color = Colors.blue;
        break;
      case 'LOCKED':
        color = Colors.orange;
        break;
      case 'COMPLETED':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProgressBar(
      String label, double percentage, Color color, double current, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}% (${current.toStringAsFixed(2)}/${total.toStringAsFixed(2)})',
              style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showItemDetail(BoqItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item.description,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    _buildStatusBadge(item.status),
                  ],
                ),
                if (item.itemCode != null) ...[
                  const SizedBox(height: 6),
                  Text('Item Code: ${item.itemCode}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
                if (item.categoryName != null || item.workTypeName != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (item.categoryName != null)
                        _buildInfoChip(item.categoryName!, Icons.category),
                      if (item.workTypeName != null)
                        _buildInfoChip(item.workTypeName!, Icons.work),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildDetailRow('Planned Quantity', item.quantity.toString().replaceAll(RegExp(r'\.0$'), '')),
                _buildDetailRow('Unit', item.unit),
                _buildDetailRow('Unit Rate', _currencyFormat.format(item.unitRate)),
                _buildDetailRow('Total Amount',
                    _currencyFormat.format(item.totalAmount),
                    bold: true),
                const SizedBox(height: 12),
                _buildDetailRow('Executed Quantity', item.executedQuantity.toString().replaceAll(RegExp(r'\.0$'), '')),
                _buildDetailRow('Billed Quantity', item.billedQuantity.toString().replaceAll(RegExp(r'\.0$'), '')),
                _buildDetailRow('Remaining Quantity', item.remainingQuantity.toString().replaceAll(RegExp(r'\.0$'), '')),
                const SizedBox(height: 12),
                _buildDetailRow('Executed Amount', _currencyFormat.format(item.totalExecutedAmount)),
                _buildDetailRow('Billed Amount', _currencyFormat.format(item.totalBilledAmount)),
                _buildDetailRow('Cost to Complete', _currencyFormat.format(item.costToComplete)),
                if (item.specifications != null && item.specifications!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Specifications:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(item.specifications!,
                      style: const TextStyle(fontSize: 12)),
                ],
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Notes', item.notes!),
                ],
                const SizedBox(height: 20),
                // Action buttons based on status and permissions
                Builder(builder: (ctx) {
                  final perms = ctx.read<PermissionProvider>();
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.canEdit && perms.canEditBoq)
                        _buildActionButton(
                          'Edit',
                          Icons.edit,
                          AppTheme.deepSlate,
                          () {
                            Navigator.pop(context);
                            _showEditDialog(item);
                          },
                        ),
                      if (item.canDelete && perms.canDeleteBoq)
                        _buildActionButton(
                          'Delete',
                          Icons.delete_outline,
                          AppTheme.errorRed,
                          () {
                            Navigator.pop(context);
                            _confirmDelete(item);
                          },
                        ),
                      if (item.canApprove && perms.canApproveBoq)
                        _buildActionButton(
                          'Approve',
                          Icons.check_circle_outline,
                          Colors.blue,
                          () => _approveItem(item),
                        ),
                      if (item.canLock && perms.canApproveBoq)
                        _buildActionButton(
                          'Lock',
                          Icons.lock_outline,
                          Colors.orange,
                          () => _lockItem(item),
                        ),
                      if (item.canExecute && perms.canEditBoq)
                        _buildActionButton(
                          'Record Execution',
                          Icons.construction,
                          Colors.deepOrange,
                          () {
                            Navigator.pop(context);
                            _showRecordExecutionDialog(item);
                          },
                        ),
                      if (item.canExecute && perms.canEditBoq)
                        _buildActionButton(
                          'Record Billing',
                          Icons.receipt_long,
                          Colors.teal,
                          () {
                            Navigator.pop(context);
                            _showRecordBillingDialog(item);
                          },
                        ),
                      if (item.canExecute && item.remainingQuantity == 0 && perms.canApproveBoq)
                        _buildActionButton(
                          'Mark Complete',
                          Icons.done_all,
                          Colors.green,
                          () => _markComplete(item),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.deepSlate.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.deepSlate),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppTheme.deepSlate)),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecordExecutionDialog(BoqItem item) async {
    final qtyController = TextEditingController();
    final refController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Execution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Item: ${item.description}',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Text(
                'Remaining: ${item.remainingQuantity.toStringAsFixed(2)} ${item.unit}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              decoration: InputDecoration(
                  labelText: 'Executed Quantity *', suffixText: item.unit),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: refController,
              decoration:
                  const InputDecoration(labelText: 'Reference (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (qtyController.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter quantity')),
                );
                return;
              }
              final qty = double.tryParse(qtyController.text);
              if (qty == null || qty <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid positive quantity')),
                );
                return;
              }
              if (qty > item.remainingQuantity) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cannot execute $qty ${item.unit} — only ${item.remainingQuantity.toStringAsFixed(4)} ${item.unit} remaining.',
                    ),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepSlate),
            child: const Text('Record', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final qty = double.tryParse(qtyController.text)!;

      try {
        await _service.recordExecution(item.id, qty,
            reference: refController.text.isNotEmpty ? refController.text : null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Execution recorded'),
                backgroundColor: AppTheme.successGreen),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to record execution');
        }
      }
    }
  }

  Future<void> _showRecordBillingDialog(BoqItem item) async {
    final qtyController = TextEditingController();
    final refController = TextEditingController();
    final remainingBillable = item.executedQuantity - item.billedQuantity;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Billing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Item: ${item.description}',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Text(
                'Billable: ${remainingBillable.toStringAsFixed(2)} ${item.unit}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              decoration: InputDecoration(
                  labelText: 'Billed Quantity *', suffixText: item.unit),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: refController,
              decoration:
                  const InputDecoration(labelText: 'Reference (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text);
              if (qty == null || qty <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid positive quantity')),
                );
                return;
              }
              if (qty > remainingBillable) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cannot bill $qty ${item.unit} — only ${remainingBillable.toStringAsFixed(4)} ${item.unit} billable.',
                    ),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Record', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final qty = double.tryParse(qtyController.text)!;

      try {
        await _service.recordBilling(item.id, qty,
            reference: refController.text.isNotEmpty ? refController.text : null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Billing recorded'),
                backgroundColor: AppTheme.successGreen),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to record billing');
        }
      }
    }
  }

  Future<void> _markComplete(BoqItem item) async {
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: Text(
            'Mark "${item.description}" as completed? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child:
                const Text('Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service.markAsCompleted(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Item marked as completed'),
                backgroundColor: AppTheme.successGreen),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to mark as completed');
        }
      }
    }
  }

  Future<void> _approveItem(BoqItem item) async {
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve BOQ Item'),
        content: Text(
          'Approving "${item.description}" will:\n\n'
          '• Prevent further edits to this item\n'
          '• Allow execution and billing to be recorded\n'
          '• Make it immediately visible to the customer — they will see the description, quantity, and total cost\n\n'
          'The customer cannot see DRAFT items. Once approved, they can review and submit approval or request changes.\n\n'
          'Locking is a separate step after approval. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.approveBoqItem(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Item approved'),
              backgroundColor: AppTheme.successGreen),
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to approve item');
      }
    }
  }

  Future<void> _lockItem(BoqItem item) async {
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lock BOQ Item'),
        content: Text(
          'Locking "${item.description}" marks execution as in-progress.\n\n'
          'Once locked, the item cannot be reverted without admin correction. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Lock'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.lockBoqItem(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Item locked'),
              backgroundColor: AppTheme.successGreen),
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to lock item');
      }
    }
  }

  Future<void> _showCreateDialog() async {
    await _ensureMaterialsLoaded();
    final descController = TextEditingController();
    final itemCodeController = TextEditingController();
    final specsController = TextEditingController();
    final unitController = TextEditingController();
    final qtyController = TextEditingController();
    final rateController = TextEditingController();
    final notesController = TextEditingController();
    int? selectedWorkTypeId;
    int? selectedCategoryId;
    int? selectedMaterialId;
    String selectedItemKind = 'BASE';
    bool autoGenerateCode = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Auto-generate item code if enabled
          if (autoGenerateCode && descController.text.isNotEmpty) {
            final words = descController.text.trim().split(' ');
            final prefix = words.take(2).map((w) => w.substring(0, 1).toUpperCase()).join();
            final number = _items.length + 1;
            itemCodeController.text = '$prefix-${number.toString().padLeft(3, '0')}';
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_circle_outline, color: AppTheme.deepSlate, size: 24),
                SizedBox(width: 8),
                Text('Add BoQ Item', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Code Section with explanation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.deepSlate.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.deepSlate.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.qr_code, size: 16, color: AppTheme.deepSlate),
                              const SizedBox(width: 6),
                              const Text('Item Code', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('(Optional - Auto-generated)',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Unique identifier for this item (e.g., FND-001, WALL-EXC-005)',
                              style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: itemCodeController,
                                  enabled: !autoGenerateCode,
                                  decoration: InputDecoration(
                                    hintText: 'e.g., ITEM-001',
                                    isDense: true,
                                    filled: autoGenerateCode,
                                    fillColor: Colors.grey[100],
                                  ),
                                  style: TextStyle(fontSize: 13, color: autoGenerateCode ? Colors.grey[600] : null),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: autoGenerateCode ? 'Switch to manual' : 'Auto-generate code',
                                child: IconButton(
                                  icon: Icon(autoGenerateCode ? Icons.lock_outline : Icons.edit_outlined, size: 18),
                                  onPressed: () => setDialogState(() => autoGenerateCode = !autoGenerateCode),
                                  color: AppTheme.deepSlate,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description (Required)
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'e.g., Excavation for foundation',
                        prefixIcon: Icon(Icons.description, size: 20),
                      ),
                      maxLines: 2,
                      onChanged: (_) => setDialogState(() {}), // Trigger rebuild for auto-code generation
                    ),
                    const SizedBox(height: 12),

                    // Specifications
                    TextField(
                      controller: specsController,
                      decoration: const InputDecoration(
                        labelText: 'Specifications',
                        hintText: 'Technical details, dimensions, standards',
                        prefixIcon: Icon(Icons.article, size: 20),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Classification', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 12),

                    // Category Dropdown (Hierarchical)
                    if (_categories.isNotEmpty)
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category / Subcategory',
                          prefixIcon: Icon(Icons.account_tree, size: 20),
                          helperText: 'Select parent category or subcategory',
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('-- No Category --')),
                          ..._buildHierarchicalCategoryItems(),
                        ],
                        onChanged: (v) => setDialogState(() => selectedCategoryId = v),
                      ),
                    const SizedBox(height: 12),

                    // Work Type Dropdown (Enhanced)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _workTypes.isEmpty ? Colors.orange[300]! : Colors.grey[300]!,
                          width: _workTypes.isEmpty ? 1.5 : 1,
                        ),
                      ),
                      child: DropdownButtonFormField<int>(
                        value: selectedWorkTypeId,
                        decoration: InputDecoration(
                          labelText: 'Work Type',
                          prefixIcon: Icon(Icons.work, size: 20, color: _workTypes.isEmpty ? Colors.orange : null),
                          helperText: _workTypes.isEmpty ? '⚠️ No work types available' : 'Type of construction work',
                          helperStyle: TextStyle(color: _workTypes.isEmpty ? Colors.orange[700] : null),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: _workTypes.isEmpty
                            ? [const DropdownMenuItem(value: null, child: Text('-- No Work Types --'))]
                            : [
                                const DropdownMenuItem(value: null, child: Text('-- Select Work Type --')),
                                ..._workTypes.map((wt) => DropdownMenuItem(
                                      value: wt.id,
                                      child: Text(wt.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    )),
                              ],
                        onChanged: (v) => setDialogState(() => selectedWorkTypeId = v),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Material Dropdown (Add-ons)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.deepSlate.withOpacity(0.3)),
                      ),
                      child: DropdownButtonFormField<int>(
                        value: selectedMaterialId,
                        decoration: const InputDecoration(
                          labelText: 'Material / Add-on',
                          prefixIcon: Icon(Icons.inventory_2, size: 20),
                          helperText: 'Link to a material if applicable',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('-- No Material --')),
                          ..._materials.map((mat) => DropdownMenuItem(
                                value: mat.id,
                                child: Row(
                                  children: [
                                    Text(mat.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 8),
                                    Text('(${mat.unit})', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  ],
                                ),
                              )),
                        ],
                        onChanged: (v) => setDialogState(() => selectedMaterialId = v),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Item Kind Dropdown
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedItemKind,
                        decoration: const InputDecoration(
                          labelText: 'Scope Type',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
                          helperText: 'BASE = always included; ADDON/OPTIONAL = extra; EXCLUSION = out of scope',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'BASE',      child: Text('BASE — Always included')),
                          DropdownMenuItem(value: 'ADDON',     child: Text('ADDON — Charged extra')),
                          DropdownMenuItem(value: 'OPTIONAL',  child: Text('OPTIONAL — Customer may choose')),
                          DropdownMenuItem(value: 'EXCLUSION', child: Text('EXCLUSION — Out of scope')),
                        ],
                        onChanged: (v) => setDialogState(() => selectedItemKind = v ?? 'BASE'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Quantity & Pricing', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 12),

                    // Unit and Quantity Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit *',
                              hintText: 'sqm, cum, rft, nos',
                              prefixIcon: Icon(Icons.straighten, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: qtyController,
                            decoration: const InputDecoration(
                              labelText: 'Planned Quantity *',
                              hintText: 'e.g., 100.5',
                              prefixIcon: Icon(Icons.functions, size: 20),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Unit Rate
                    TextField(
                      controller: rateController,
                      decoration: const InputDecoration(
                        labelText: 'Unit Rate (₹) *',
                        hintText: 'e.g., 250.00',
                        prefixIcon: Icon(Icons.currency_rupee, size: 20),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),

                    // Calculated Total (Preview)
                    if (qtyController.text.isNotEmpty && rateController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calculate, size: 16, color: AppTheme.successGreen),
                            const SizedBox(width: 8),
                            const Text('Estimated Total: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            Text(
                              _currencyFormat.format((double.tryParse(qtyController.text) ?? 0) * (double.tryParse(rateController.text) ?? 0)),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Any additional remarks',
                        prefixIcon: Icon(Icons.note, size: 20),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Validate before closing the dialog
                  if (descController.text.trim().isEmpty ||
                      unitController.text.trim().isEmpty ||
                      qtyController.text.trim().isEmpty ||
                      rateController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Please fill all required fields (marked with *)'),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  final qty = double.tryParse(qtyController.text);
                  if (qty == null || qty <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Quantity must be a positive number'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  final rate = double.tryParse(rateController.text);
                  if (rate == null || rate <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Unit rate must be a positive number'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  // All valid — close dialog
                  Navigator.pop(ctx, true);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepSlate,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      final qty = double.tryParse(qtyController.text)!;
      final rate = double.tryParse(rateController.text)!;

      try {
        await _service.createBoqItem(
          projectId: widget.projectId,
          categoryId: selectedCategoryId,
          workTypeId: selectedWorkTypeId,
          materialId: selectedMaterialId,
          itemCode: itemCodeController.text.trim().isNotEmpty ? itemCodeController.text.trim() : null,
          description: descController.text.trim(),
          specifications: specsController.text.trim().isNotEmpty ? specsController.text.trim() : null,
          unit: unitController.text.trim(),
          quantity: qty,
          unitRate: rate,
          notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
          itemKind: selectedItemKind,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('BoQ item "${descController.text.trim()}" added successfully')),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to create BoQ item');
        }
      }
    }
  }

  Future<void> _showEditDialog(BoqItem item) async {
    if (!item.canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only DRAFT items can be edited')),
      );
      return;
    }

    await _ensureMaterialsLoaded();
    final descController = TextEditingController(text: item.description);
    final itemCodeController = TextEditingController(text: item.itemCode);
    final unitController = TextEditingController(text: item.unit);
    final qtyController = TextEditingController(text: item.quantity.toString());
    final rateController =
        TextEditingController(text: item.unitRate.toString());
    final notesController = TextEditingController(text: item.notes ?? '');
    int? selectedCategoryId = item.categoryId;
    int? selectedWorkTypeId = item.workTypeId;
    int? selectedMaterialId = item.materialId;
    String selectedItemKind = item.itemKind;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit BoQ Item'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: itemCodeController,
                    decoration: const InputDecoration(
                        labelText: 'Item Code',
                        prefixIcon: Icon(Icons.tag)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                        labelText: 'Description *',
                        prefixIcon: Icon(Icons.description)),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  // Category dropdown
                  DropdownButtonFormField<int?>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category)),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('No Category')),
                      ..._buildHierarchicalCategoryItems(),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedCategoryId = v),
                  ),
                  const SizedBox(height: 12),
                  // Work Type dropdown
                  DropdownButtonFormField<int?>(
                    value: selectedWorkTypeId,
                    decoration: const InputDecoration(
                        labelText: 'Work Type',
                        prefixIcon: Icon(Icons.work)),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('No Work Type')),
                      ..._workTypes.map((wt) => DropdownMenuItem<int?>(
                            value: wt.id,
                            child: Text(wt.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          )),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedWorkTypeId = v),
                  ),
                  const SizedBox(height: 12),
                  // Material dropdown
                  DropdownButtonFormField<int?>(
                    value: selectedMaterialId,
                    decoration: const InputDecoration(
                        labelText: 'Material (optional)',
                        prefixIcon: Icon(Icons.inventory_2)),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('No Material')),
                      ..._materials.map((m) => DropdownMenuItem<int?>(
                            value: m.id,
                            child: Text('${m.name} (${m.unit})'),
                          )),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedMaterialId = v),
                  ),
                  const SizedBox(height: 12),
                  // Scope type dropdown
                  DropdownButtonFormField<String>(
                    value: selectedItemKind,
                    decoration: const InputDecoration(
                      labelText: 'Scope Type',
                      prefixIcon: Icon(Icons.category_outlined, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'BASE',      child: Text('BASE — Always included')),
                      DropdownMenuItem(value: 'ADDON',     child: Text('ADDON — Charged extra')),
                      DropdownMenuItem(value: 'OPTIONAL',  child: Text('OPTIONAL — Customer may choose')),
                      DropdownMenuItem(value: 'EXCLUSION', child: Text('EXCLUSION — Out of scope')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedItemKind = v ?? 'BASE'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: unitController,
                          decoration:
                              const InputDecoration(labelText: 'Unit *'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          decoration: const InputDecoration(
                              labelText: 'Quantity *'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rateController,
                    decoration: const InputDecoration(
                        labelText: 'Unit Rate (₹) *',
                        prefixText: '₹ '),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration:
                        const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (descController.text.trim().isEmpty ||
                    unitController.text.trim().isEmpty ||
                    qtyController.text.trim().isEmpty ||
                    rateController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Please fill all required fields (marked with *)'),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                final qty = double.tryParse(qtyController.text);
                if (qty == null || qty <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Quantity must be a positive number'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                final rate = double.tryParse(rateController.text);
                if (rate == null || rate <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Unit rate must be a positive number'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepSlate),
              child: const Text('Save',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        await _service.updateBoqItem(item.id, {
          'itemCode': itemCodeController.text.isNotEmpty
              ? itemCodeController.text
              : null,
          'description': descController.text,
          'unit': unitController.text,
          'quantity': double.tryParse(qtyController.text) ?? item.quantity,
          'unitRate': double.tryParse(rateController.text) ?? item.unitRate,
          'categoryId': selectedCategoryId,
          'workTypeId': selectedWorkTypeId,
          'materialId': selectedMaterialId,
          'notes':
              notesController.text.isNotEmpty ? notesController.text : null,
          'itemKind': selectedItemKind,
          if (item.version != null) 'version': item.version,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('BoQ item updated'),
                backgroundColor: AppTheme.successGreen),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to update item');
        }
      }
    }
  }

  Future<void> _confirmDelete(BoqItem item) async {
    if (!item.canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only DRAFT items can be deleted')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete BoQ Item'),
        content: Text('Are you sure you want to delete "${item.description}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _service.deleteBoqItem(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('BoQ item deleted'),
                backgroundColor: AppTheme.successGreen),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to delete item');
        }
      }
    }
  }
}
