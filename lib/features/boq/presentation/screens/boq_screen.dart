import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/services/boq_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/portal_auth_provider.dart';

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
  BoqFinancialSummary? _summary;
  int? _selectedWorkTypeId;
  int? _selectedCategoryId;
  String? _selectedStatus;
  bool _isLoading = true;
  bool _showSummary = true;

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
    setState(() => _isLoading = true);
    try {
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

  List<BoqItem> get _filteredItems {
    return _items.where((item) {
      if (_selectedWorkTypeId != null && item.workTypeId != _selectedWorkTypeId) return false;
      if (_selectedCategoryId != null && item.categoryId != _selectedCategoryId) return false;
      if (_selectedStatus != null && item.status != _selectedStatus) return false;
      return true;
    }).toList();
  }

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
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(),
        backgroundColor: AppTheme.deepSlate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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

  List<Widget> _buildGroupedItemSlivers() {
    final groups = _groupedItems;
    final slivers = <Widget>[];

    for (final entry in groups.entries) {
      final groupTotal = entry.value.fold(0.0, (sum, item) => sum + item.totalAmount);
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
                  _buildMetric('Qty', '${item.quantity} ${item.unit}'),
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
            value: percentage / 100,
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
                _buildDetailRow('Planned Quantity', '${item.quantity} ${item.unit}'),
                _buildDetailRow('Unit Rate', _currencyFormat.format(item.unitRate)),
                _buildDetailRow('Total Amount',
                    _currencyFormat.format(item.totalAmount),
                    bold: true),
                const SizedBox(height: 12),
                _buildDetailRow('Executed Quantity', '${item.executedQuantity} ${item.unit}'),
                _buildDetailRow('Billed Quantity', '${item.billedQuantity} ${item.unit}'),
                _buildDetailRow('Remaining Quantity', '${item.remainingQuantity} ${item.unit}'),
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
                // Action buttons based on status
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (item.canEdit)
                      _buildActionButton(
                        'Edit',
                        Icons.edit,
                        AppTheme.deepSlate,
                        () {
                          Navigator.pop(context);
                          _showEditDialog(item);
                        },
                      ),
                    if (item.canDelete)
                      _buildActionButton(
                        'Delete',
                        Icons.delete_outline,
                        AppTheme.errorRed,
                        () {
                          Navigator.pop(context);
                          _confirmDelete(item);
                        },
                      ),
                    if (item.canApprove)
                      _buildActionButton(
                        'Approve',
                        Icons.check_circle_outline,
                        Colors.blue,
                        () => _approveItem(item),
                      ),
                    if (item.canLock)
                      _buildActionButton(
                        'Lock',
                        Icons.lock_outline,
                        Colors.orange,
                        () => _lockItem(item),
                      ),
                    if (item.canExecute)
                      _buildActionButton(
                        'Record Execution',
                        Icons.construction,
                        Colors.deepOrange,
                        () {
                          Navigator.pop(context);
                          _showRecordExecutionDialog(item);
                        },
                      ),
                  ],
                ),
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
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepSlate),
            child: const Text('Record', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      if (qtyController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter quantity')),
        );
        return;
      }

      try {
        final qty = double.parse(qtyController.text);
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

  Future<void> _approveItem(BoqItem item) async {
    Navigator.pop(context);
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
    final descController = TextEditingController();
    final itemCodeController = TextEditingController();
    final unitController = TextEditingController();
    final qtyController = TextEditingController();
    final rateController = TextEditingController();
    final notesController = TextEditingController();
    int? selectedWorkTypeId;
    int? selectedCategoryId;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add BoQ Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: itemCodeController,
                  decoration: const InputDecoration(labelText: 'Item Code'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                if (_categories.isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories
                        .where((c) => c.isTopLevel)
                        .map((cat) => DropdownMenuItem(
                            value: cat.id, child: Text(cat.name)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedCategoryId = v),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedWorkTypeId,
                  decoration: const InputDecoration(labelText: 'Work Type'),
                  items: _workTypes
                      .map((wt) => DropdownMenuItem(
                          value: wt.id, child: Text(wt.name)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedWorkTypeId = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'Unit *'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        decoration:
                            const InputDecoration(labelText: 'Quantity *'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateController,
                  decoration: const InputDecoration(
                      labelText: 'Unit Rate (₹) *', prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepSlate),
              child:
                  const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      if (descController.text.isEmpty ||
          unitController.text.isEmpty ||
          qtyController.text.isEmpty ||
          rateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }

      try {
        await _service.createBoqItem(
          projectId: widget.projectId,
          categoryId: selectedCategoryId,
          workTypeId: selectedWorkTypeId,
          itemCode: itemCodeController.text.isNotEmpty
              ? itemCodeController.text
              : null,
          description: descController.text,
          unit: unitController.text,
          quantity: double.parse(qtyController.text),
          unitRate: double.parse(rateController.text),
          notes: notesController.text.isNotEmpty ? notesController.text : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('BoQ item added'),
                backgroundColor: AppTheme.successGreen),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to create item');
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

    final descController = TextEditingController(text: item.description);
    final itemCodeController = TextEditingController(text: item.itemCode);
    final unitController = TextEditingController(text: item.unit);
    final qtyController = TextEditingController(text: item.quantity.toString());
    final rateController =
        TextEditingController(text: item.unitRate.toString());
    final notesController = TextEditingController(text: item.notes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit BoQ Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemCodeController,
                decoration: const InputDecoration(labelText: 'Item Code'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      decoration:
                          const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateController,
                decoration: const InputDecoration(
                    labelText: 'Unit Rate (₹)', prefixText: '₹ '),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepSlate),
            child:
                const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
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
          'notes':
              notesController.text.isNotEmpty ? notesController.text : null,
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
