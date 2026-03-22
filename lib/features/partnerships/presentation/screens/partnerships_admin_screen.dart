import 'package:flutter/material.dart';
import 'package:admin/features/partnerships/data/models/partner_model.dart';
import 'package:admin/features/partnerships/data/services/partnership_admin_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'partner_admin_detail_screen.dart';

class PartnershipsAdminScreen extends StatefulWidget {
  const PartnershipsAdminScreen({super.key});

  @override
  State<PartnershipsAdminScreen> createState() => _PartnershipsAdminScreenState();
}

class _PartnershipsAdminScreenState extends State<PartnershipsAdminScreen>
    with SingleTickerProviderStateMixin {
  final _service = PartnershipAdminService();
  final _searchController = TextEditingController();

  late TabController _tabController;

  final List<String> _statusTabs = ['all', 'pending', 'active', 'approved', 'rejected', 'suspended'];
  final List<String> _statusLabels = ['All', 'Pending', 'Active', 'Approved', 'Rejected', 'Suspended'];

  String _selectedType = 'all';
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  bool _isLoading = false;
  List<PartnerSummary> _partners = [];
  Map<String, dynamic> _counts = {};
  String? _searchQuery;

  final List<Map<String, String>> _typeOptions = [
    {'value': 'all', 'label': 'All Types'},
    {'value': 'architect', 'label': 'Architect'},
    {'value': 'interior_designer', 'label': 'Interior Designer'},
    {'value': 'real_estate', 'label': 'Real Estate'},
    {'value': 'financial', 'label': 'Financial'},
    {'value': 'material_supplier', 'label': 'Material Supplier'},
    {'value': 'vastu', 'label': 'Vastu'},
    {'value': 'land_consultant', 'label': 'Land Consultant'},
    {'value': 'corporate', 'label': 'Corporate'},
    {'value': 'referral_client', 'label': 'Referral Client'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _currentPage = 0;
        _loadPartners();
      }
    });
    _loadPartners();
    _loadCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String get _currentStatus => _statusTabs[_tabController.index];

  Future<void> _loadPartners() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await _service.getPartners(
        status: _currentStatus,
        partnershipType: _selectedType,
        search: _searchQuery,
        page: _currentPage,
        size: 20,
      );
      final contentList = (result['content'] as List<dynamic>? ?? []);
      setState(() {
        _partners = contentList
            .map((e) => PartnerSummary.fromJson(e as Map<String, dynamic>))
            .toList();
        _totalPages = result['totalPages'] ?? 1;
        _totalElements = result['totalElements'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load partners: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadCounts() async {
    try {
      final counts = await _service.getStatusCounts();
      setState(() => _counts = counts);
    } catch (_) {}
  }

  void _onSearch(String query) {
    _searchQuery = query.trim().isEmpty ? null : query.trim();
    _currentPage = 0;
    _loadPartners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSummaryCards(),
          _buildSearchAndFilter(),
          _buildTabBar(),
          Expanded(child: _buildPartnerList()),
          if (_totalPages > 1) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.handshake_rounded, color: AppTheme.primaryBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Partnership & Referral Management',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.deepSlate)),
                Text('Manage partners, approve applications, track referrals',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          Text('$_totalElements partners',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final cards = [
      {'label': 'Total', 'key': 'total', 'color': AppTheme.primaryBlue, 'icon': Icons.people},
      {'label': 'Pending', 'key': 'pending', 'color': Colors.orange, 'icon': Icons.hourglass_empty},
      {'label': 'Active', 'key': 'active', 'color': Colors.green, 'icon': Icons.check_circle},
      {'label': 'Rejected', 'key': 'rejected', 'color': Colors.red, 'icon': Icons.cancel},
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        children: cards.map((card) {
          final count = _counts[card['key']] ?? 0;
          final color = card['color'] as Color;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(card['icon'] as IconData, color: color, size: 16),
                    const SizedBox(width: 4),
                    Text(card['label'] as String,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ]),
                  const SizedBox(height: 4),
                  Text('$count',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onSubmitted: _onSearch,
                onChanged: (v) { if (v.isEmpty) _onSearch(''); },
                decoration: InputDecoration(
                  hintText: 'Search by name, email, phone, firm…',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          })
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryBlue)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: DropdownButton<String>(
                value: _selectedType,
                style: const TextStyle(fontSize: 13, color: AppTheme.deepSlate),
                items: _typeOptions.map((t) => DropdownMenuItem(
                    value: t['value'], child: Text(t['label']!))).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedType = v ?? 'all';
                    _currentPage = 0;
                  });
                  _loadPartners();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: AppTheme.primaryBlue,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: List.generate(_statusTabs.length, (i) {
          final count = _counts[_statusTabs[i]];
          return Tab(
            child: Row(
              children: [
                Text(_statusLabels[i]),
                if (count != null && count != 0 && _statusTabs[i] != 'all') ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _statusTabs[i] == 'pending' ? Colors.orange : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count',
                        style: TextStyle(
                            fontSize: 10,
                            color: _statusTabs[i] == 'pending' ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPartnerList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_partners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No partners found',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Try adjusting your filters or search query',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await _loadPartners();
        await _loadCounts();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _partners.length,
        itemBuilder: (context, i) => _PartnerCard(
          partner: _partners[i],
          onTap: () => _openDetail(_partners[i]),
          onStatusChange: (status) => _quickUpdateStatus(_partners[i], status),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0
                ? () { setState(() => _currentPage--); _loadPartners(); }
                : null,
          ),
          Text('Page ${_currentPage + 1} of $_totalPages',
              style: const TextStyle(fontSize: 13)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages - 1
                ? () { setState(() => _currentPage++); _loadPartners(); }
                : null,
          ),
        ],
      ),
    );
  }

  void _openDetail(PartnerSummary partner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartnerAdminDetailScreen(partnerId: partner.id),
      ),
    ).then((_) {
      _loadPartners();
      _loadCounts();
    });
  }

  Future<void> _quickUpdateStatus(PartnerSummary partner, String newStatus) async {
    try {
      await _service.updateStatus(partner.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${partner.fullName} status updated to $newStatus'),
          backgroundColor: Colors.green,
        ));
        _loadPartners();
        _loadCounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}

// ── Partner Card Widget ────────────────────────────────────────────────────

class _PartnerCard extends StatelessWidget {
  final PartnerSummary partner;
  final VoidCallback onTap;
  final Function(String) onStatusChange;

  const _PartnerCard({
    required this.partner,
    required this.onTap,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _typeColor(partner.partnershipType).withOpacity(0.15),
                    child: Text(
                      partner.fullName.isNotEmpty ? partner.fullName[0].toUpperCase() : 'P',
                      style: TextStyle(
                          color: _typeColor(partner.partnershipType),
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + firm
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(partner.fullName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppTheme.deepSlate)),
                        if (partner.firmName?.isNotEmpty == true)
                          Text(partner.firmName!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  // Status badge + actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusBadge(status: partner.status),
                      if (partner.status == 'pending') ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _ActionButton(
                                label: 'Approve',
                                color: Colors.green,
                                onTap: () => onStatusChange('approved')),
                            const SizedBox(width: 4),
                            _ActionButton(
                                label: 'Reject',
                                color: Colors.red,
                                onTap: () => onStatusChange('rejected')),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Info row
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _InfoChip(icon: Icons.badge_outlined,
                      label: _typeLabel(partner.partnershipType)),
                  _InfoChip(icon: Icons.phone_outlined, label: partner.phone),
                  if (partner.location?.isNotEmpty == true)
                    _InfoChip(icon: Icons.location_on_outlined, label: partner.location!),
                ],
              ),
              const SizedBox(height: 8),
              // Stats row
              Row(
                children: [
                  _StatPill(
                      label: '${partner.totalReferrals} Referrals',
                      color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  _StatPill(
                      label: '${partner.convertedReferrals} Converted',
                      color: Colors.green),
                  const Spacer(),
                  if (partner.lastLogin != null)
                    Text(
                      'Last login ${_timeAgo(partner.lastLogin!)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'architect': return Colors.indigo;
      case 'interior_designer': return Colors.purple;
      case 'real_estate': return Colors.teal;
      case 'financial': return Colors.green;
      case 'material_supplier': return Colors.brown;
      case 'land_consultant': return Colors.orange;
      case 'referral_client': return AppTheme.primaryBlue;
      default: return Colors.grey;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'architect': return 'Architect';
      case 'interior_designer': return 'Interior Designer';
      case 'real_estate': return 'Real Estate';
      case 'financial': return 'Financial';
      case 'material_supplier': return 'Material Supplier';
      case 'vastu': return 'Vastu';
      case 'land_consultant': return 'Land Consultant';
      case 'corporate': return 'Corporate';
      case 'referral_client': return 'Referral Client';
      default: return type;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = switch (status) {
      'active' => (Colors.green[700]!, Colors.green[50]!),
      'approved' => (Colors.blue[700]!, Colors.blue[50]!),
      'pending' => (Colors.orange[700]!, Colors.orange[50]!),
      'rejected' => (Colors.red[700]!, Colors.red[50]!),
      'suspended' => (Colors.grey[700]!, Colors.grey[100]!),
      _ => (Colors.grey[600]!, Colors.grey[100]!),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
