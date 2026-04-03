import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:admin/features/partnerships/data/models/partner_model.dart';
import 'package:admin/features/partnerships/data/services/partnership_admin_service.dart';
import 'package:admin/theme/app_theme.dart';

class PartnerAdminDetailScreen extends StatefulWidget {
  final int partnerId;
  const PartnerAdminDetailScreen({super.key, required this.partnerId});

  @override
  State<PartnerAdminDetailScreen> createState() => _PartnerAdminDetailScreenState();
}

class _PartnerAdminDetailScreenState extends State<PartnerAdminDetailScreen>
    with SingleTickerProviderStateMixin {
  final _service = PartnershipAdminService();
  late TabController _tabController;

  PartnerDetail? _partner;
  List<PartnerReferral> _referrals = [];
  bool _isLoading = true;
  bool _isReferralsLoading = false;
  String? _error;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _referrals.isEmpty && !_isReferralsLoading) {
        _loadReferrals();
      }
    });
    _loadDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final detail = await _service.getPartnerDetail(widget.partnerId);
      setState(() { _partner = detail; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadReferrals() async {
    setState(() => _isReferralsLoading = true);
    try {
      final refs = await _service.getPartnerReferrals(widget.partnerId);
      setState(() { _referrals = refs; _isReferralsLoading = false; });
    } catch (e) {
      setState(() => _isReferralsLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${_actionLabel(newStatus)} Partner?'),
        content: Text(
          'Are you sure you want to ${newStatus == 'approved' ? 'approve' : newStatus == 'rejected' ? 'reject' : 'set to $newStatus'} '
          '${_partner?.fullName}\'s account?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(_actionLabel(newStatus), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isUpdatingStatus = true);
    try {
      await _service.updateStatus(widget.partnerId, newStatus);
      await _loadDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to $newStatus'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _isUpdatingStatus = false);
    }
  }

  String _actionLabel(String status) {
    switch (status) {
      case 'approved': return 'Approve';
      case 'rejected': return 'Reject';
      case 'suspended': return 'Suspend';
      case 'active': return 'Reactivate';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partner Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _partner == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partner Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error ?? 'Partner not found'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadDetail, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final partner = _partner!;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(partner.fullName, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.deepSlate,
        elevation: 1,
        actions: [
          if (_isUpdatingStatus)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            _buildStatusMenu(partner),
        ],
      ),
      body: Column(
        children: [
          _buildPartnerHeader(partner),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(partner),
                _buildReferralsTab(),
                _buildActivityTab(partner),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMenu(PartnerDetail partner) {
    final List<Map<String, dynamic>> actions = [];
    if (partner.status == 'pending') {
      actions.addAll([
        {'label': 'Approve', 'status': 'approved', 'color': Colors.green},
        {'label': 'Reject', 'status': 'rejected', 'color': Colors.red},
      ]);
    } else if (partner.status == 'approved' || partner.status == 'active') {
      actions.addAll([
        {'label': 'Suspend', 'status': 'suspended', 'color': Colors.orange},
        {'label': 'Reject', 'status': 'rejected', 'color': Colors.red},
      ]);
    } else if (partner.status == 'rejected' || partner.status == 'suspended') {
      actions.add({'label': 'Reactivate', 'status': 'approved', 'color': Colors.green});
    }
    if (actions.isEmpty) return const SizedBox();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: _updateStatus,
      itemBuilder: (_) => actions.map((a) => PopupMenuItem<String>(
        value: a['status'] as String,
        child: Row(
          children: [
            Icon(Icons.circle, size: 10, color: a['color'] as Color),
            const SizedBox(width: 8),
            Text(a['label'] as String),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPartnerHeader(PartnerDetail partner) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
            child: Text(
              partner.fullName.isNotEmpty ? partner.fullName[0].toUpperCase() : 'P',
              style: const TextStyle(
                  color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(partner.fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        color: AppTheme.deepSlate)),
                if (partner.displayFirmName.isNotEmpty)
                  Text(partner.displayFirmName,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    _TypeBadge(type: partner.partnershipType),
                    _StatusBadgeLarge(status: partner.status),
                  ],
                ),
              ],
            ),
          ),
          // Quick stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${partner.stats['totalReferrals'] ?? 0}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue)),
              Text('Referrals', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const SizedBox(height: 4),
              Text('${partner.stats['convertedReferrals'] ?? 0}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: Colors.green)),
              Text('Converted', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
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
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: AppTheme.primaryBlue,
        tabs: const [
          Tab(text: 'Profile'),
          Tab(text: 'Referrals'),
          Tab(text: 'Activity'),
        ],
      ),
    );
  }

  // ── PROFILE TAB ─────────────────────────────────────────────────────────

  Widget _buildProfileTab(PartnerDetail partner) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Contact Information',
          icon: Icons.person_outline,
          children: [
            _DetailRow('Full Name', partner.fullName),
            _DetailRow('Email', partner.email, copyable: true),
            _DetailRow('Phone', partner.phone, copyable: true),
            if (partner.designation?.isNotEmpty == true)
              _DetailRow('Designation', partner.designation!),
            if (partner.additionalContact?.isNotEmpty == true)
              _DetailRow('Additional Contact', partner.additionalContact!),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Business Information',
          icon: Icons.business_outlined,
          children: [
            if (partner.firmName?.isNotEmpty == true) _DetailRow('Firm Name', partner.firmName!),
            if (partner.companyName?.isNotEmpty == true) _DetailRow('Company', partner.companyName!),
            if (partner.businessName?.isNotEmpty == true) _DetailRow('Business Name', partner.businessName!),
            if (partner.gstNumber?.isNotEmpty == true) _DetailRow('GST', partner.gstNumber!, copyable: true),
            if (partner.licenseNumber?.isNotEmpty == true) _DetailRow('License No.', partner.licenseNumber!),
            if (partner.reraNumber?.isNotEmpty == true) _DetailRow('RERA No.', partner.reraNumber!),
            if (partner.cinNumber?.isNotEmpty == true) _DetailRow('CIN', partner.cinNumber!),
            if (partner.ifscCode?.isNotEmpty == true) _DetailRow('IFSC Code', partner.ifscCode!),
            if (partner.employeeId?.isNotEmpty == true) _DetailRow('Employee ID', partner.employeeId!),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Professional Details',
          icon: Icons.work_outline,
          children: [
            if (partner.specialization?.isNotEmpty == true)
              _DetailRow('Specialization', partner.specialization!),
            if (partner.experience != null) _DetailRow('Experience', '${partner.experience} years'),
            if (partner.yearsOfPractice != null)
              _DetailRow('Years of Practice', '${partner.yearsOfPractice} years'),
            if (partner.certifications?.isNotEmpty == true)
              _DetailRow('Certifications', partner.certifications!),
            if (partner.portfolioLink?.isNotEmpty == true)
              _DetailRow('Portfolio', partner.portfolioLink!, copyable: true),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Operational Coverage',
          icon: Icons.map_outlined,
          children: [
            if (partner.location?.isNotEmpty == true) _DetailRow('Location', partner.location!),
            if (partner.areaOfOperation?.isNotEmpty == true)
              _DetailRow('Area of Operation', partner.areaOfOperation!),
            if (partner.areasCovered?.isNotEmpty == true)
              _DetailRow('Areas Covered', partner.areasCovered!),
            if (partner.areaServed?.isNotEmpty == true)
              _DetailRow('Area Served', partner.areaServed!),
            if (partner.industry?.isNotEmpty == true) _DetailRow('Industry', partner.industry!),
            if (partner.projectType?.isNotEmpty == true)
              _DetailRow('Project Type', partner.projectType!),
            if (partner.projectScale?.isNotEmpty == true)
              _DetailRow('Project Scale', partner.projectScale!),
            if (partner.businessSize?.isNotEmpty == true)
              _DetailRow('Business Size', partner.businessSize!),
            if (partner.landTypes?.isNotEmpty == true)
              _DetailRow('Land Types', partner.landTypes!),
            if (partner.materialsSupplied?.isNotEmpty == true)
              _DetailRow('Materials Supplied', partner.materialsSupplied!),
            if (partner.timeline?.isNotEmpty == true) _DetailRow('Timeline', partner.timeline!),
          ],
        ),
        if (partner.message?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Application Message',
            icon: Icons.message_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(partner.message!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── REFERRALS TAB ────────────────────────────────────────────────────────

  Widget _buildReferralsTab() {
    if (_isReferralsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_referrals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No referrals yet', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadReferrals, child: const Text('Load Referrals')),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _referrals.length,
      itemBuilder: (_, i) => _ReferralCard(referral: _referrals[i]),
    );
  }

  // ── ACTIVITY TAB ─────────────────────────────────────────────────────────

  Widget _buildActivityTab(PartnerDetail partner) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Account Timeline',
          icon: Icons.timeline,
          children: [
            _TimelineItem(
              icon: Icons.person_add_outlined,
              color: AppTheme.primaryBlue,
              label: 'Application submitted',
              date: partner.createdAt,
              subtitle: partner.createdBy != null ? 'By ${partner.createdBy}' : null,
            ),
            if (partner.approvedAt != null)
              _TimelineItem(
                icon: Icons.check_circle_outline,
                color: Colors.green,
                label: 'Account approved',
                date: partner.approvedAt,
                subtitle: partner.updatedBy != null ? 'By ${partner.updatedBy}' : null,
              ),
            if (partner.lastLogin != null)
              _TimelineItem(
                icon: Icons.login,
                color: Colors.teal,
                label: 'Last login',
                date: partner.lastLogin,
              ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Referral Performance',
          icon: Icons.bar_chart,
          children: [
            _StatRow('Total Referrals', '${partner.stats['totalReferrals'] ?? 0}', AppTheme.primaryBlue),
            _StatRow('Pending Follow-up', '${partner.stats['pendingReferrals'] ?? 0}', Colors.orange),
            _StatRow('Qualified', '${partner.stats['qualifiedReferrals'] ?? 0}', Colors.blue),
            _StatRow('Converted / Won', '${partner.stats['convertedReferrals'] ?? 0}', Colors.green),
            _StatRow('Lost', '${partner.stats['lostReferrals'] ?? 0}', Colors.red),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Account Management',
          icon: Icons.manage_accounts_outlined,
          children: [
            _DetailRow('Current Status', partner.status.toUpperCase()),
            if (partner.updatedBy?.isNotEmpty == true)
              _DetailRow('Last Updated By', partner.updatedBy!),
            if (partner.updatedAt != null)
              _DetailRow('Last Updated', _formatDate(partner.updatedAt!)),
          ],
        ),
      ],
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox();
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.deepSlate)),
            ]),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;

  const _DetailRow(this.label, this.value, {this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: GestureDetector(
              onLongPress: copyable
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$label copied'), duration: const Duration(seconds: 1)),
                      );
                    }
                  : null,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.deepSlate,
                      decoration: copyable ? TextDecoration.underline : null)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final DateTime? date;
  final String? subtitle;

  const _TimelineItem({
    required this.icon, required this.color, required this.label, this.date, this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppTheme.deepSlate)),
                if (date != null)
                  Text(_formatDate(date!), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralCard extends StatelessWidget {
  final PartnerReferral referral;
  const _ReferralCard({required this.referral});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(referral.clientName ?? 'Unknown Client',
                      style: const TextStyle(fontWeight: FontWeight.w600,
                          fontSize: 14, color: AppTheme.deepSlate)),
                ),
                _LeadStatusBadge(status: referral.status),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              children: [
                if (referral.clientPhone?.isNotEmpty == true)
                  _InfoChipSmall(icon: Icons.phone, label: referral.clientPhone!),
                if (referral.projectType?.isNotEmpty == true)
                  _InfoChipSmall(icon: Icons.construction, label: referral.projectType!),
                if (referral.location?.isNotEmpty == true)
                  _InfoChipSmall(icon: Icons.location_on, label: referral.location!),
              ],
            ),
            if (referral.dateOfEnquiry != null) ...[
              const SizedBox(height: 4),
              Text('Enquiry: ${referral.dateOfEnquiry}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeadStatusBadge extends StatelessWidget {
  final String status;
  const _LeadStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'new_inquiry' => ('New', Colors.blue),
      'contacted' => ('Contacted', Colors.teal),
      'qualified' => ('Qualified', Colors.indigo),
      'proposal_sent' => ('Proposal', Colors.purple),
      'project_won' || 'converted' => ('Won', Colors.green),
      'lost' => ('Lost', Colors.red),
      _ => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _InfoChipSmall extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChipSmall({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  String get _label {
    switch (type) {
      case 'architect': return 'Architect';
      case 'interior_designer': return 'Interior Designer';
      case 'real_estate': return 'Real Estate';
      case 'financial': return 'Financial';
      case 'material_supplier': return 'Supplier';
      case 'land_consultant': return 'Land Consultant';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(_label,
          style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusBadgeLarge extends StatelessWidget {
  final String status;
  const _StatusBadgeLarge({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

String _formatDate(DateTime dt) {
  return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
