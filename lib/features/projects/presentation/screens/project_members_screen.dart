import 'package:flutter/material.dart';

import 'package:admin/constants.dart';
import 'package:admin/features/customers/data/models/customer.dart';
import 'package:admin/features/customers/data/services/customer_service.dart';
import 'package:admin/services/customer_project_service.dart';
import 'package:admin/utils/error_handler.dart';

/// Manage the customer users associated with a project.
///
/// A project's `customer_id` is its primary contract holder; this screen
/// manages the **secondary** customer users (family, spouse, additional
/// signatories) tracked in the `project_members` join table. The same row
/// is also what the BoQ customer-approve flow checks via
/// `ProjectAccessGuard.verifyCustomerMembership`.
class ProjectMembersScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const ProjectMembersScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectMembersScreen> createState() => _ProjectMembersScreenState();
}

class _ProjectMembersScreenState extends State<ProjectMembersScreen> {
  final CustomerProjectService _projectService = CustomerProjectService();
  final CustomerService _customerService = CustomerService();

  List<Map<String, dynamic>> _members = [];
  Customer? _primaryOwner;
  int? _primaryOwnerCustomerId;
  bool _loading = true;
  String? _error;

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
      // Fan out: project (for customer_id), members list, and the primary
      // owner customer record once we know its id.
      final projectFuture =
          _projectService.getProjectById(widget.projectId);
      final membersFuture =
          _projectService.getProjectMembers(widget.projectId);
      final results = await Future.wait([projectFuture, membersFuture]);
      final project = results[0] as dynamic; // CustomerProject?
      final members = results[1] as List<Map<String, dynamic>>;

      Customer? owner;
      final ownerId = project?.customerId as int?;
      if (ownerId != null) {
        try {
          owner = await _customerService.getCustomerById(ownerId);
        } catch (_) {
          // Owner customer record may have been soft-deleted; render id-only.
          owner = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _members = members;
        _primaryOwner = owner;
        _primaryOwnerCustomerId = ownerId;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorHandler.getErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _openAddDialog() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _AddMemberDialog(projectId: widget.projectId),
    );
    if (added == true) {
      await _load();
    }
  }

  Future<void> _confirmRemove(Map<String, dynamic> member) async {
    final id = member['id'];
    if (id == null) return;
    final name = member['fullName'] ?? member['email'] ?? 'this member';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text(
            'Remove "$name" from ${widget.projectName}? They will lose access in the customer app and can no longer sign off on customer approvals for this project.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: errorColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _projectService.removeProjectMember(widget.projectId, id as int);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Member removed'),
            backgroundColor: successColor),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Members — ${widget.projectName}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add Member'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: errorColor),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(defaultPadding),
      children: [
        _buildPrimaryOwnerSection(),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'ADDITIONAL MEMBERS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Spouse, family, signatories — anyone besides the primary owner who can view this project in the customer app or sign off on BoQ approvals.',
            style: TextStyle(color: textMuted, fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        if (_members.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: containerBorder),
            ),
            child: const Text(
              'No additional members yet — tap "+ Add Member" to add one.',
              style: TextStyle(color: textMuted),
            ),
          )
        else
          ..._members.map(_buildMemberCard),
        const SizedBox(height: 80), // breathing room for the FAB
      ],
    );
  }

  Widget _buildPrimaryOwnerSection() {
    final hasOwner = _primaryOwnerCustomerId != null;
    final owner = _primaryOwner;
    final name = owner == null
        ? (hasOwner
            ? 'Customer #$_primaryOwnerCustomerId'
            : 'Not assigned')
        : ('${owner.firstName} ${owner.lastName}').trim().isNotEmpty
            ? '${owner.firstName} ${owner.lastName}'
            : owner.email;
    final email = owner?.email ?? '';
    final initials = _initialsFor(name.isEmpty ? '?' : name);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasOwner
            ? primaryColor.withOpacity(0.05)
            : warningColor.withOpacity(0.06),
        border: Border.all(
            color: hasOwner
                ? primaryColor.withOpacity(0.25)
                : warningColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: hasOwner
                ? primaryColor.withOpacity(0.15)
                : warningColor.withOpacity(0.15),
            child: hasOwner
                ? Text(initials,
                    style: const TextStyle(
                        color: primaryColor, fontWeight: FontWeight.bold))
                : const Icon(Icons.person_off_outlined,
                    color: warningColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasOwner
                            ? primaryColor.withOpacity(0.15)
                            : warningColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hasOwner ? 'PRIMARY OWNER' : 'NOT ASSIGNED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color:
                              hasOwner ? primaryColor : warningColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Tooltip(
                      message:
                          'Linked via customer_projects.customer_id — set during lead conversion or via project edit. Not managed on this screen.',
                      child: Icon(Icons.info_outline,
                          size: 14, color: textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                if (email.isNotEmpty)
                  Text(email,
                      style: const TextStyle(
                          color: textSecondary, fontSize: 13)),
                if (!hasOwner)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'No primary customer is linked to this project. The customer app will not surface it for any user via the primary-owner path.',
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> m) {
    final name = (m['fullName'] as String?) ??
        (m['email'] as String?) ??
        'Member #${m['id']}';
    final email = m['email'] as String?;
    final role = m['roleInProject'] as String?;
    final initials = _initialsFor(name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: containerBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.12),
              child: Text(initials,
                  style: const TextStyle(
                      color: primaryColor, fontWeight: FontWeight.bold)),
            ),
            title: Text(name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (email != null && email.isNotEmpty) Text(email),
                if (role != null && role.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: boxInfo,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(role,
                          style: const TextStyle(
                              fontSize: 11, color: infoColor)),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline, color: errorColor),
              onPressed: () => _confirmRemove(m),
            ),
          )),
    );
  }

  String _initialsFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

// ────────────────────────────────────────────────────────────────────────
// Add member dialog
// ────────────────────────────────────────────────────────────────────────

class _AddMemberDialog extends StatefulWidget {
  final int projectId;
  const _AddMemberDialog({required this.projectId});

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final CustomerService _customerService = CustomerService();
  final CustomerProjectService _projectService = CustomerProjectService();

  List<Customer> _allCustomers = [];
  List<Customer> _filtered = [];
  Customer? _selected;
  String _query = '';
  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  // Common project-side roles. Free text is allowed via the "Other" entry.
  static const List<String> _commonRoles = [
    'OWNER',
    'SPOUSE',
    'FAMILY',
    'GUARANTOR',
    'SIGNATORY',
    'OTHER',
  ];
  String _role = 'OWNER';
  final TextEditingController _customRoleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customRoleCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await _customerService.getAllCustomers();
      if (!mounted) return;
      setState(() {
        _allCustomers = list;
        _filtered = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = ErrorHandler.getErrorMessage(e);
        _loading = false;
      });
    }
  }

  void _applySearch(String q) {
    final ql = q.toLowerCase();
    setState(() {
      _query = q;
      if (ql.isEmpty) {
        _filtered = _allCustomers;
      } else {
        _filtered = _allCustomers.where((c) {
          final hay =
              '${c.firstName} ${c.lastName} ${c.email} ${c.phone ?? ''}'
                  .toLowerCase();
          return hay.contains(ql);
        }).toList();
      }
    });
  }

  Future<void> _submit() async {
    if (_selected?.id == null) return;
    final role =
        _role == 'OTHER' ? _customRoleCtrl.text.trim() : _role;
    if (role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Role is required'),
            backgroundColor: warningColor),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _projectService.addProjectMember(
          widget.projectId, _selected!.id!, role);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add_alt, color: primaryColor),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Add project member',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Pick the customer user to grant project access. They will be able to view this project in the customer app and act as a customer signatory for BoQ approvals.',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
              const Divider(height: 24),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 20),
                  hintText: 'Search by name, email or phone',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                onChanged: _applySearch,
              ),
              const SizedBox(height: 12),
              Flexible(child: _buildCustomerList()),
              const SizedBox(height: 12),
              const Text('Role',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _commonRoles.map((r) {
                  final selected = _role == r;
                  return ChoiceChip(
                    label: Text(r),
                    selected: selected,
                    onSelected: (_) => setState(() => _role = r),
                  );
                }).toList(),
              ),
              if (_role == 'OTHER')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: _customRoleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Custom role',
                      hintText: 'e.g. CO_OWNER, ACCOUNTANT',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed:
                        _saving || _selected == null ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 18),
                    label:
                        Text(_saving ? 'Adding…' : 'Add Member'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerList() {
    if (_loading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load customers: $_loadError',
              style: const TextStyle(color: errorColor)),
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          _query.isEmpty
              ? 'No customers in the system yet — create one from CRM → Customers first.'
              : 'No matching customers.',
          style: const TextStyle(color: textMuted),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: containerBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _filtered.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: containerBorder),
        itemBuilder: (_, i) {
          final c = _filtered[i];
          final name =
              ('${c.firstName} ${c.lastName}').trim().isNotEmpty
                  ? '${c.firstName} ${c.lastName}'
                  : c.email;
          final selected = _selected?.id == c.id;
          return ListTile(
            dense: true,
            selected: selected,
            selectedTileColor: primaryColor.withOpacity(0.06),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor.withOpacity(0.12),
              child: const Icon(Icons.person,
                  color: primaryColor, size: 18),
            ),
            title: Text(name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              [
                c.email,
                if (c.phone != null && c.phone!.isNotEmpty) c.phone!,
              ].where((s) => s.isNotEmpty).join('  ·  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: selected
                ? const Icon(Icons.check_circle, color: primaryColor)
                : null,
            onTap: () => setState(() => _selected = c),
          );
        },
      ),
    );
  }
}
