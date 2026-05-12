import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/models/variation_order_models.dart';
import 'package:admin/services/variation_order_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'vo_detail_screen.dart';
import 'vo_create_screen.dart';

class VOListScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const VOListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<VOListScreen> createState() => _VOListScreenState();
}

class _VOListScreenState extends State<VOListScreen> {
  final VariationOrderService _service = VariationOrderService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  List<VariationOrderSummary> _orders = [];
  bool _isLoading = true;
  String? _filterStatus;

  static const _statusColors = {
    'DRAFT':           Colors.grey,
    'SUBMITTED':       Colors.orange,
    'CUSTOMER_REVIEW': Colors.blue,
    'APPROVED':        Colors.green,
    'REJECTED':        Colors.red,
    'IN_PROGRESS':     Colors.teal,
    'COMPLETED':       Colors.indigo,
    'CLOSED':          Colors.black54,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await _service.listByProject(widget.projectId);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  List<VariationOrderSummary> get _filtered => _filterStatus == null
      ? _orders
      : _orders.where((o) => o.status == _filterStatus).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.deepSlate,
        foregroundColor: Colors.white,
        title: Text('Variation Orders — ${widget.projectName}',
            style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _load();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.coralRed,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New VO', style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => VOCreateScreen(projectId: widget.projectId),
            ),
          );
          if (created == true) _load();
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                Expanded(child: _buildList()),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    const statuses = [
      'DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED', 'COMPLETED'
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _filterChip('All', null),
          ...statuses.map((s) => _filterChip(s, s)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12,
            color: selected ? Colors.white : AppTheme.deepSlate)),
        selected: selected,
        selectedColor: AppTheme.coralRed,
        checkmarkColor: Colors.white,
        onSelected: (_) => setState(() => _filterStatus = value),
      ),
    );
  }

  Widget _buildList() {
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No variation orders',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildCard(items[i]),
      ),
    );
  }

  Widget _buildCard(VariationOrderSummary vo) {
    final statusColor = _statusColors[vo.status] ?? Colors.grey;
    final amount = vo.approvedCost ?? vo.netAmountInclGst;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VODetailScreen(
              projectId: widget.projectId,
              voId: vo.id,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(vo.referenceNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13,
                            color: AppTheme.deepSlate)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(vo.status,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(vo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (vo.voCategory != null)
                    _tag(vo.voCategory!, Colors.teal),
                  if (vo.coType != null)
                    _tag(vo.coType!, Colors.indigo),
                  const Spacer(),
                  if (amount != null)
                    Text(_currency.format(amount),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.coralRed)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}
