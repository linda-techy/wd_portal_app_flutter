import 'package:flutter/material.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/models/site_visit_violation.dart';
import 'package:admin/services/site_visit_violation_service.dart';
import 'package:admin/theme/app_theme.dart';

/// Portal admin / project-manager view of geofence violations.
/// Customer never sees this — there is no equivalent customer-api endpoint.
class SiteVisitViolationsScreen extends StatefulWidget {
  const SiteVisitViolationsScreen({super.key});

  @override
  State<SiteVisitViolationsScreen> createState() =>
      _SiteVisitViolationsScreenState();
}

class _SiteVisitViolationsScreenState
    extends State<SiteVisitViolationsScreen> {
  final _service = SiteVisitViolationService();

  PaginatedResponse<SiteVisitViolation>? _page;
  bool _loading = true;
  String? _error;
  int _currentPage = 0;
  static const _pageSize = 20;

  // Filter
  String _attemptFilter = 'ALL'; // ALL | CHECK_IN | CHECK_OUT

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.list(
        page: _currentPage,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _page = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<SiteVisitViolation> get _filtered {
    final items = _page?.content ?? const <SiteVisitViolation>[];
    if (_attemptFilter == 'ALL') return items;
    return items.where((v) => v.attemptType == _attemptFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Violations'),
        backgroundColor: AppTheme.coralRed,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          if (_page != null && !_loading) _buildSummary(),
          Expanded(child: _buildBody()),
          if (_page != null && (_page!.totalPages > 1)) _buildPager(),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _chip('All', 'ALL'),
          const SizedBox(width: 8),
          _chip('Check-in', 'CHECK_IN'),
          const SizedBox(width: 8),
          _chip('Check-out', 'CHECK_OUT'),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _attemptFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _attemptFilter = value),
    );
  }

  Widget _buildSummary() {
    final total = _page!.totalElements;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.gpp_bad_outlined, size: 18, color: AppTheme.coralRed),
          const SizedBox(width: 6),
          Text(
            '$total violation${total == 1 ? '' : 's'} recorded',
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user, size: 48, color: Colors.green),
              SizedBox(height: 12),
              Text(
                'No geofence violations.',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _buildRow(items[i]),
    );
  }

  Widget _buildRow(SiteVisitViolation v) {
    final isCheckOut = v.attemptType == 'CHECK_OUT';
    return Card(
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isCheckOut ? Colors.orange.shade100 : Colors.red.shade100,
          child: Icon(
            isCheckOut ? Icons.logout : Icons.login,
            color: isCheckOut ? Colors.orange.shade800 : Colors.red.shade700,
          ),
        ),
        title: Text(
          v.userName?.isNotEmpty == true
              ? v.userName!
              : (v.userEmail ?? 'Unknown user'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${isCheckOut ? "Check-out" : "Check-in"} attempt at '
              '${v.projectName ?? "project #${v.projectId ?? "?"}"}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              '${v.formattedDistance} away · '
              'allowed ${v.formattedAllowedRadius} · '
              '${_formatTime(v.attemptedAt)}',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Text(
            'OUT OF RANGE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildPager() {
    final p = _page!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: p.hasPrevious
                ? () {
                    setState(() => _currentPage -= 1);
                    _load();
                  }
                : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                'Page ${p.currentPage + 1} of ${p.totalPages}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: p.hasNext
                ? () {
                    setState(() => _currentPage += 1);
                    _load();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final local = t.toLocal();
    final d = local.toString().split('.').first; // "2026-05-17 14:30:21"
    return d;
  }
}
