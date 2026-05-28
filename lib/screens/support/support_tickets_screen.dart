import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:admin/models/support_ticket.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/services/support_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/constants.dart';
import 'package:intl/intl.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  final SupportService _service = SupportService();

  bool _isLoading = false;
  String? _error;
  PaginatedResponse<PortalSupportTicket>? _response;

  int _page = 0;
  static const int _pageSize = 20;

  String? _selectedStatus;
  String? _selectedCategory;

  static const List<String> _statusOptions = [
    'OPEN',
    'IN_PROGRESS',
    'RESOLVED',
    'CLOSED',
  ];

  static const List<String> _categoryOptions = [
    'GENERAL',
    'BILLING',
    'PROJECT_QUALITY',
    'DOCUMENTS',
    'TECHNICAL',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets({bool reset = false}) async {
    if (reset) {
      setState(() => _page = 0);
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.getTickets(
        page: _page,
        size: _pageSize,
        status: _selectedStatus,
        category: _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _response = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // ── Derived counts from current page data ────────────────────────────────
  int _countByStatus(String status) =>
      _response?.content.where((t) => t.status == status).length ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text(
          'Support Tickets',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadTickets(reset: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(),
          _buildFilterRow(),
          Expanded(child: _buildBody()),
          if (_response != null && _response!.totalPages > 1)
            _buildPagination(),
        ],
      ),
    );
  }

  // ── Stats header ─────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final total = _response?.totalElements ?? 0;
    final open = _countByStatus('OPEN');
    final inProgress = _countByStatus('IN_PROGRESS');
    final resolved = _countByStatus('RESOLVED');

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(
          defaultPadding, defaultPadding / 2, defaultPadding, defaultPadding),
      child: Row(
        children: [
          _buildStatCard('Total', total, AppTheme.primaryBlue),
          const SizedBox(width: 12),
          _buildStatCard('Open', open, AppTheme.skyBlue),
          const SizedBox(width: 12),
          _buildStatCard('In Progress', inProgress, AppTheme.warningAmber),
          const SizedBox(width: 12),
          _buildStatCard('Resolved', resolved, AppTheme.successGreen),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter row ────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(
          defaultPadding, 0, defaultPadding, defaultPadding),
      child: Row(
        children: [
          // Status dropdown
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Statuses')),
                ..._statusOptions.map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(_formatLabel(s)),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() => _selectedStatus = val);
                _loadTickets(reset: true);
              },
            ),
          ),
          const SizedBox(width: 12),
          // Category dropdown
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('All Categories')),
                ..._categoryOptions.map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(_formatLabel(c)),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() => _selectedCategory = val);
                _loadTickets(reset: true);
              },
            ),
          ),
          const SizedBox(width: 12),
          // Clear filters
          if (_selectedStatus != null || _selectedCategory != null)
            TextButton.icon(
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear'),
              onPressed: () {
                setState(() {
                  _selectedStatus = null;
                  _selectedCategory = null;
                });
                _loadTickets(reset: true);
              },
            ),
        ],
      ),
    );
  }

  // ── Body: loading / error / list ─────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading && _response == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _response == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => _loadTickets(),
            ),
          ],
        ),
      );
    }

    final tickets = _response?.content ?? [];
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No tickets found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadTickets(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Wide layout — DataTable
          if (constraints.maxWidth > 700) {
            return _buildDataTable(tickets);
          }
          // Narrow — card list
          return _buildCardList(tickets);
        },
      ),
    );
  }

  // ── DataTable ─────────────────────────────────────────────────────────────
  Widget _buildDataTable(List<PortalSupportTicket> tickets) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(defaultPadding),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppTheme.surfaceElevated,
              ),
              columnSpacing: 20,
              columns: const [
                DataColumn(
                    label: Text('Ticket #',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Subject',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Category',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Priority',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Status',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(
                    label: Text('Updated',
                        style: TextStyle(fontWeight: FontWeight.w700))),
              ],
              rows: tickets.map((t) {
                return DataRow(
                  onSelectChanged: (_) => _openDetail(context, t.id),
                  cells: [
                    DataCell(
                      Text(
                        t.ticketNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          t.subject,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(_buildCategoryChip(t.category)),
                    DataCell(_buildPriorityBadge(t.priority)),
                    DataCell(_buildStatusBadge(t.status)),
                    DataCell(Text(
                      _formatDate(t.updatedAt),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Card list (mobile) ────────────────────────────────────────────────────
  Widget _buildCardList(List<PortalSupportTicket> tickets) {
    return ListView.builder(
      padding: const EdgeInsets.all(defaultPadding),
      itemCount: tickets.length,
      itemBuilder: (context, i) {
        final t = tickets[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _openDetail(context, t.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        t.ticketNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const Spacer(),
                      _buildPriorityBadge(t.priority),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.subject,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildCategoryChip(t.category),
                      const SizedBox(width: 8),
                      _buildStatusBadge(t.status),
                      const Spacer(),
                      Text(
                        _formatDate(t.updatedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  Widget _buildPagination() {
    final totalPages = _response!.totalPages;
    final current = _page + 1; // display as 1-based
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(
          vertical: 12, horizontal: defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 0
                ? () {
                    setState(() => _page--);
                    _loadTickets();
                  }
                : null,
          ),
          Text(
            'Page $current of $totalPages',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < totalPages - 1
                ? () {
                    setState(() => _page++);
                    _loadTickets();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void _openDetail(BuildContext context, int ticketId) {
    context.push('/support/$ticketId');
  }

  // ── Badge / chip helpers ─────────────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'OPEN':
        color = AppTheme.skyBlue;
        break;
      case 'IN_PROGRESS':
        color = AppTheme.warningAmber;
        break;
      case 'RESOLVED':
        color = AppTheme.successGreen;
        break;
      default:
        color = AppTheme.textTertiary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        _formatLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color == AppTheme.warningAmber
              ? const Color(0xFF8B6300)
              : color,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'HIGH':
        color = AppTheme.errorRed;
        break;
      case 'MEDIUM':
        color = AppTheme.constructionOrange;
        break;
      default:
        color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Chip(
      label: Text(
        _formatLabel(category),
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: AppTheme.surfaceElevated,
      side: const BorderSide(color: AppTheme.borderLight),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  // ── Formatting helpers ───────────────────────────────────────────────────
  String _formatLabel(String raw) {
    return raw
        .split('_')
        .map((w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yy, HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
