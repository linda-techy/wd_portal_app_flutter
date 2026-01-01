import 'dart:io';
import 'package:flutter/material.dart';
import 'package:admin/models/payment_models.dart';
import 'package:admin/services/payment_service.dart';
import 'package:admin/services/challan_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/motion_toast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  final ScrollController _scrollController = ScrollController();
  
  List<PaymentTransactionItem> _transactions = [];
  bool _isLoading = true;
  int _currentPage = 0;
  bool _isLastPage = false;
  
  // Filters
  String _searchQuery = '';
  String? _selectedMethod;
  String? _selectedStatus;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        !_isLastPage) {
      _loadHistory(loadMore: true);
    }
  }

  Future<void> _loadHistory({bool loadMore = false, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _isLastPage = false;
      _transactions.clear();
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final page = loadMore ? _currentPage + 1 : _currentPage;
      final result = await _paymentService.getTransactionHistory(
        page: page,
        search: _searchQuery,
        method: _selectedMethod,
        status: _selectedStatus,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
      );

      if (!mounted) return;
      
      setState(() {
        final newItems = result['content'] as List<PaymentTransactionItem>;
        if (loadMore) {
          _transactions.addAll(newItems);
        } else {
          _transactions = newItems;
        }
        _currentPage = page;
        _isLastPage = result['last'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading history: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Payment History & Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadHistory(refresh: true),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _transactions.isEmpty && !_isLoading
                ? _buildEmptyState()
                : _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Receipt / Ref...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onSubmitted: (value) {
                _searchQuery = value;
                _loadHistory(refresh: true);
              },
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          if (_dateRange != null)
            Chip(
              label: Text('${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}'),
              onDeleted: () {
                setState(() => _dateRange = null);
                _loadHistory(refresh: true);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      itemCount: _transactions.length + (_isLoading ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingSM),
      itemBuilder: (context, index) {
        if (index == _transactions.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final tx = _transactions[index];
        return _buildTransactionCard(tx);
      },
    );
  }

  Widget _buildTransactionCard(PaymentTransactionItem tx) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(AppTheme.spacingMD),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tx.customerName ?? 'Direct Payment',
                      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '₹${NumberFormat('#,##,###').format(tx.amount)}',
                      style: AppTheme.headlineSmall.copyWith(color: AppTheme.walldotGold),
                    ),
                  ],
                ),
                Text(
                  tx.projectName ?? 'System Transaction',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.receipt, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(tx.receiptNumber ?? 'No Receipt', style: AppTheme.bodySmall),
                    const SizedBox(width: 12),
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd MMM yyyy').format(tx.paymentDate), style: AppTheme.bodySmall),
                    const SizedBox(width: 12),
                    Icon(Icons.payment, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(tx.paymentMethod ?? 'N/A', style: AppTheme.bodySmall),
                  ],
                ),
                if (tx.referenceNumber != null) ...[
                  const SizedBox(height: 4),
                  Text('Ref: ${tx.referenceNumber}', style: AppTheme.bodySmall),
                ],
                if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(tx.notes!, style: AppTheme.bodySmall.copyWith(fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (tx.challanId != null)
                  TextButton.icon(
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download Receipt'),
                    onPressed: () => _downloadChallan(tx),
                  )
                else
                  TextButton.icon(
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Generate Receipt'),
                    onPressed: () => _generateChallan(tx),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: AppTheme.spacingMD),
          Text('No transactions found', style: AppTheme.bodyLarge),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    // Basic implementation for filters
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Advanced Filters', style: AppTheme.headlineSmall),
            const SizedBox(height: AppTheme.spacingMD),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Date Range'),
              subtitle: Text(_dateRange == null ? 'All Time' : 'Selected'),
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (range != null) {
                  setState(() => _dateRange = range);
                  Navigator.pop(context);
                  _loadHistory(refresh: true);
                }
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedMethod,
                      decoration: const InputDecoration(labelText: 'Method'),
                      items: ['CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE']
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList()
                        ..insert(0, const DropdownMenuItem(value: null, child: Text('All Methods'))),
                      onChanged: (val) {
                        setState(() => _selectedMethod = val);
                        _loadHistory(refresh: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: ['COMPLETED', 'PENDING', 'FAILED']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList()
                        ..insert(0, const DropdownMenuItem(value: null, child: Text('All Status'))),
                      onChanged: (val) {
                        setState(() => _selectedStatus = val);
                        _loadHistory(refresh: true);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedMethod = null;
                    _selectedStatus = null;
                    _dateRange = null;
                    _searchQuery = '';
                  });
                  Navigator.pop(context);
                  _loadHistory(refresh: true);
                },
                child: const Text('Reset All Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadChallan(PaymentTransactionItem transaction) async {
    try {
      final bytes = await ChallanService().downloadChallan(transaction.challanId!);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Challan_${transaction.challanNumber?.replaceAll("/", "_")}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      MotionToast.show(context, message: 'Failed to download challan', isError: true);
    }
  }

  Future<void> _generateChallan(PaymentTransactionItem transaction) async {
    try {
      await ChallanService().generateChallan(transaction.id);
      MotionToast.show(context, message: 'Challan generated successfully');
      _loadHistory(refresh: true);
    } catch (e) {
      MotionToast.show(context, message: 'Failed to generate challan', isError: true);
    }
  }
}
