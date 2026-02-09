import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/models/team_member.dart';
import 'package:admin/services/crm_service.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  _TeamMembersScreenState createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  final CRMService _crmService = CRMService();
  List<TeamMember> _allMembers = [];
  List<TeamMember> _filteredMembers = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _departmentFilter = 'All';
  String _statusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamMembers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final members = await _crmService.getAllTeamMembers();
      setState(() {
        _allMembers = members;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _applyFilters() {
    _filteredMembers = _allMembers.where((m) {
      final matchesSearch = _searchQuery.isEmpty ||
          m.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (m.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (m.designation?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesDept = _departmentFilter == 'All' ||
          (m.department ?? 'Unassigned') == _departmentFilter;
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Active' && m.isActive == true) ||
          (_statusFilter == 'Inactive' && m.isActive != true);
      return matchesSearch && matchesDept && matchesStatus;
    }).toList();
  }

  List<String> get _departments {
    final depts = _allMembers
        .map((m) => m.department ?? 'Unassigned')
        .toSet()
        .toList();
    depts.sort();
    return ['All', ...depts];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Team Members", style: Theme.of(context).textTheme.headlineMedium),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadTeamMembers,
                      tooltip: 'Refresh',
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(null),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text("Add Member"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),

            // Search & Filters
            Container(
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: containerBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, or designation...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() { _searchQuery = ''; _applyFilters(); });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() { _searchQuery = v; _applyFilters(); }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _departmentFilter,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() { _departmentFilter = v ?? 'All'; _applyFilters(); }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _statusFilter,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      items: ['All', 'Active', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() { _statusFilter = v ?? 'All'; _applyFilters(); }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: defaultPadding),

            // Stats bar
            Row(
              children: [
                _buildStatChip('Total', _allMembers.length, primaryColor),
                const SizedBox(width: 8),
                _buildStatChip('Active', _allMembers.where((m) => m.isActive == true).length, successColor),
                const SizedBox(width: 8),
                _buildStatChip('Inactive', _allMembers.where((m) => m.isActive != true).length, Colors.grey),
                const SizedBox(width: 8),
                _buildStatChip('Showing', _filteredMembers.length, infoColor),
              ],
            ),
            const SizedBox(height: defaultPadding),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: errorColor),
                              const SizedBox(height: 8),
                              Text('Failed to load team members', style: TextStyle(color: errorColor)),
                              const SizedBox(height: 4),
                              Text(_error!, style: const TextStyle(fontSize: 12, color: textSecondary)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadTeamMembers, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _filteredMembers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isNotEmpty ? 'No members match your search' : 'No team members found',
                                    style: const TextStyle(color: textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: containerBorder),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SingleChildScrollView(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(boxSecondary),
                                      columnSpacing: 16,
                                      horizontalMargin: 16,
                                      columns: const [
                                        DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Designation', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                      ],
                                      rows: _filteredMembers.map((m) => _buildDataRow(m)).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  DataRow _buildDataRow(TeamMember m) {
    return DataRow(
      cells: [
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Text(
                m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : '?',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.fullName.isNotEmpty ? m.fullName : 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
                if (m.employeeId != null)
                  Text(m.employeeId!, style: const TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
          ],
        )),
        DataCell(Text(m.designation ?? '-', style: const TextStyle(fontSize: 13))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: boxInfo,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(m.department ?? 'Unassigned', style: const TextStyle(fontSize: 12)),
          ),
        ),
        DataCell(Text(m.email ?? '-', style: const TextStyle(fontSize: 13))),
        DataCell(Text(m.phone ?? '-', style: const TextStyle(fontSize: 13))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: m.isActive == true ? boxSuccess : boxError,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: m.isActive == true ? boxBorderSuccess : boxBorderError),
            ),
            child: Text(
              m.isActive == true ? 'Active' : 'Inactive',
              style: TextStyle(fontSize: 12, color: m.isActive == true ? successColor : errorColor),
            ),
          ),
        ),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => _showAddEditDialog(m),
              tooltip: 'Edit',
              color: infoColor,
              splashRadius: 18,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _confirmDelete(m),
              tooltip: 'Delete',
              color: errorColor,
              splashRadius: 18,
            ),
          ],
        )),
      ],
    );
  }

  void _showAddEditDialog(TeamMember? member) {
    final isEdit = member != null;
    final firstNameCtrl = TextEditingController(text: member?.firstName ?? '');
    final lastNameCtrl = TextEditingController(text: member?.lastName ?? '');
    final emailCtrl = TextEditingController(text: member?.email ?? '');
    final phoneCtrl = TextEditingController(text: member?.phone ?? '');
    final whatsappCtrl = TextEditingController(text: member?.whatsapp ?? '');
    final designationCtrl = TextEditingController(text: member?.designation ?? '');
    final departmentCtrl = TextEditingController(text: member?.department ?? '');
    bool isActive = member?.isActive ?? true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Team Member' : 'Add Team Member'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: firstNameCtrl,
                            decoration: const InputDecoration(labelText: 'First Name *', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: lastNameCtrl,
                            decoration: const InputDecoration(labelText: 'Last Name *', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: phoneCtrl,
                            decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: whatsappCtrl,
                            decoration: const InputDecoration(labelText: 'WhatsApp', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: designationCtrl,
                            decoration: const InputDecoration(labelText: 'Designation', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: departmentCtrl,
                            decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: isActive,
                      onChanged: (v) => setDialogState(() => isActive = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final tm = TeamMember(
                  id: member?.id,
                  firstName: firstNameCtrl.text.trim(),
                  lastName: lastNameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                  whatsapp: whatsappCtrl.text.trim().isNotEmpty ? whatsappCtrl.text.trim() : null,
                  designation: designationCtrl.text.trim().isNotEmpty ? designationCtrl.text.trim() : null,
                  department: departmentCtrl.text.trim().isNotEmpty ? departmentCtrl.text.trim() : null,
                  isActive: isActive,
                );
                try {
                  if (isEdit) {
                    await _crmService.updateTeamMember(member.id ?? '', tm);
                  } else {
                    await _crmService.saveTeamMember(tm);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadTeamMembers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Team member updated' : 'Team member added'), backgroundColor: successColor),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: errorColor),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(TeamMember m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Team Member'),
        content: Text('Are you sure you want to delete ${m.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _crmService.deleteTeamMember(m.id!);
                _loadTeamMembers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Team member deleted'), backgroundColor: successColor),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: errorColor),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: errorColor, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
