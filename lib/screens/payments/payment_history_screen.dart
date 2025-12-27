import 'package:flutter/material.dart';
import 'package:admin/models/payment_models.dart';
import 'package:admin/services/payment_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:intl/intl.dart';

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
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.spacingMD),
        title: Row(
          children: [
            Text(
              tx.receiptNumber ?? 'No Receipt',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '₹${NumberFormat('#,##,###').format(tx.amount)}',
              style: AppTheme.headlineSmall.copyWith(color: AppTheme.walldotGold),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(DateFormat('dd MMM yyyy, hh:mm a').format(tx.paymentDate)),
                const SizedBox(width: 12),
                Icon(Icons.payment, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(tx.paymentMethod ?? 'N/A'),
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
            // More filters (Method, Status) can be added here
          ],
        ),
      ),
    );
  }
}
