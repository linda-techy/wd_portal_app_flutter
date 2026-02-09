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
  BoqSummary? _summary;
  int? _selectedWorkTypeId;
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
        _service.getProjectSummary(widget.projectId),
      ]);
      if (mounted) {
        setState(() {
          _items = results[0] as List<BoqItem>;
          _workTypes = results[1] as List<BoqWorkType>;
          _summary = results[2] as BoqSummary;
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
    if (_selectedWorkTypeId == null) return _items;
    return _items.where((i) => i.workTypeId == _selectedWorkTypeId).toList();
  }

  Map<String, List<BoqItem>> get _groupedItems {
    final map = <String, List<BoqItem>>{};
    for (final item in _filteredItems) {
      final key = item.workTypeName ?? 'Uncategorized';
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
                  // Summary section
                  if (_showSummary && _summary != null)
                    SliverToBoxAdapter(child: _buildSummaryCard()),
                  // Work type filter
                  if (_workTypes.isNotEmpty)
                    SliverToBoxAdapter(child: _buildWorkTypeFilter()),
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

  Widget _buildSummaryCard() {
    final summary = _summary!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
                'Project BoQ Summary',
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
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(summary.totalAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (summary.workTypeBreakdown.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            ...summary.workTypeBreakdown.map((wt) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(wt.workType,
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(_currencyFormat.format(wt.total),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkTypeFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', _selectedWorkTypeId == null, () {
              setState(() => _selectedWorkTypeId = null);
            }),
            ..._workTypes.map((wt) => _buildFilterChip(
                  wt.name,
                  _selectedWorkTypeId == wt.id,
                  () => setState(() => _selectedWorkTypeId = wt.id),
                )),
          ],
        ),
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
      final groupTotal =
          entry.value.fold(0.0, (sum, item) => sum + (item.totalAmount ?? 0));
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
          (context, index) => _buildItemCard(entry.value[index]),
          childCount: entry.value.length,
        ),
      ));
    }
    return slivers;
  }

  Widget _buildItemCard(BoqItem item) {
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
              Text(
                item.description,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMetric('Qty', '${item.quantity} ${item.unit}'),
                  const SizedBox(width: 16),
                  _buildMetric('Rate', _currencyFormat.format(item.unitRate)),
                  const Spacer(),
                  Text(
                    _currencyFormat.format(item.totalAmount ?? 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                ],
              ),
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.notes!,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(item.description,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            if (item.workTypeName != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.deepSlate.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(item.workTypeName!,
                    style: const TextStyle(fontSize: 12, color: AppTheme.deepSlate)),
              ),
            ],
            const SizedBox(height: 16),
            _buildDetailRow('Quantity', '${item.quantity} ${item.unit}'),
            _buildDetailRow('Unit Rate', _currencyFormat.format(item.unitRate)),
            _buildDetailRow('Total Amount',
                _currencyFormat.format(item.totalAmount ?? 0),
                bold: true),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Notes', item.notes!),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditDialog(item);
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.deepSlate,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(item);
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    final descController = TextEditingController();
    final unitController = TextEditingController();
    final qtyController = TextEditingController();
    final rateController = TextEditingController();
    final notesController = TextEditingController();
    int? selectedWorkTypeId;

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
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedWorkTypeId,
                  decoration: const InputDecoration(labelText: 'Work Type'),
                  items: _workTypes
                      .map((wt) =>
                          DropdownMenuItem(value: wt.id, child: Text(wt.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedWorkTypeId = v),
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
                        decoration: const InputDecoration(labelText: 'Quantity *'),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepSlate),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
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
          description: descController.text,
          unit: unitController.text,
          quantity: double.parse(qtyController.text),
          unitRate: double.parse(rateController.text),
          workTypeId: selectedWorkTypeId,
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
    final descController = TextEditingController(text: item.description);
    final unitController = TextEditingController(text: item.unit);
    final qtyController = TextEditingController(text: item.quantity.toString());
    final rateController = TextEditingController(text: item.unitRate.toString());
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
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateController,
                decoration:
                    const InputDecoration(labelText: 'Unit Rate (₹)', prefixText: '₹ '),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepSlate),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await _service.updateBoqItem(item.id, {
          'description': descController.text,
          'unit': unitController.text,
          'quantity': double.tryParse(qtyController.text) ?? item.quantity,
          'unitRate': double.tryParse(rateController.text) ?? item.unitRate,
          'notes': notesController.text.isNotEmpty ? notesController.text : null,
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
