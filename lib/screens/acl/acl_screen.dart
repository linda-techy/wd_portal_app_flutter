import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/models/acl_models.dart';
import 'package:admin/services/acl_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/utils/motion_toast.dart';

/// ACL (Access Control List) Management Screen
///
/// Allows ADMIN users to:
///   • View all portal roles and their current permission sets
///   • Edit permissions per role using a screen/module-wise matrix
///   • Apply predefined permission templates with one click
///
/// Layout:
///   Desktop (>900px): Two-panel (role list | permission matrix)
///   Mobile (<=900px): Single-panel with role selector
class AclScreen extends StatefulWidget {
  const AclScreen({super.key});

  @override
  State<AclScreen> createState() => _AclScreenState();
}

class _AclScreenState extends State<AclScreen> {
  final AclService _aclService = AclService();

  // ── Data ──────────────────────────────────────────────────────────────────
  List<AclRole> _roles = [];
  List<AclModuleGroup> _moduleGroups = [];
  List<AclRoleTemplate> _templates = [];

  // ── UI state ──────────────────────────────────────────────────────────────
  bool _isLoadingData = true;
  bool _isLoadingDetail = false;
  bool _isSaving = false;
  String? _error;

  // ── Selection ─────────────────────────────────────────────────────────────
  AclRole? _selectedRole;
  Set<int> _selectedPermissionIds = {};
  bool _hasUnsavedChanges = false;

  // ── Search ────────────────────────────────────────────────────────────────
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // ── Module expansion ──────────────────────────────────────────────────────
  final Set<String> _expandedModules = {};

  // ── Mobile panel ─────────────────────────────────────────────────────────
  bool _showPermissionsPanel = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _aclService.getRoles(),
        _aclService.getPermissionsGrouped(),
        _aclService.getRoleTemplates(),
      ]);
      if (!mounted) return;
      setState(() {
        _roles = results[0] as List<AclRole>;
        _moduleGroups = results[1] as List<AclModuleGroup>;
        _templates = results[2] as List<AclRoleTemplate>;
        // Expand all modules by default
        _expandedModules.addAll(_moduleGroups.map((g) => g.module));
        _isLoadingData = false;
      });
      // Auto-select first role
      if (_roles.isNotEmpty) {
        _selectRole(_roles.first);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load ACL data: $e';
        _isLoadingData = false;
      });
    }
  }

  Future<void> _selectRole(AclRole role) async {
    if (_hasUnsavedChanges && _selectedRole != null) {
      final confirm = await _confirmDiscardChanges();
      if (!confirm) return;
    }
    setState(() {
      _selectedRole = role;
      _isLoadingDetail = true;
      _hasUnsavedChanges = false;
    });
    try {
      final detail = await _aclService.getRoleDetail(role.id);
      if (!mounted) return;
      setState(() {
        _selectedPermissionIds = _buildPermissionIdSet(detail.permissionNames);
        _isLoadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDetail = false);
      MotionToast.show(context, message: 'Failed to load role details', variant: ToastVariant.error);
    }
  }

  Set<int> _buildPermissionIdSet(List<String> permNames) {
    final nameSet = Set<String>.from(permNames);
    return _moduleGroups
        .expand((g) => g.permissions)
        .where((p) => nameSet.contains(p.name))
        .map((p) => p.id)
        .toSet();
  }

  // ── Permission editing ────────────────────────────────────────────────────

  void _togglePermission(int permId) {
    if (_selectedRole?.isAdmin ?? false) return; // ADMIN is read-only
    setState(() {
      if (_selectedPermissionIds.contains(permId)) {
        _selectedPermissionIds.remove(permId);
      } else {
        _selectedPermissionIds.add(permId);
      }
      _hasUnsavedChanges = true;
    });
  }

  void _toggleModule(AclModuleGroup group, bool selectAll) {
    if (_selectedRole?.isAdmin ?? false) return;
    setState(() {
      if (selectAll) {
        _selectedPermissionIds.addAll(group.permissions.map((p) => p.id));
      } else {
        _selectedPermissionIds.removeAll(group.permissions.map((p) => p.id));
      }
      _hasUnsavedChanges = true;
    });
  }

  void _applyTemplate(AclRoleTemplate template) {
    if (_selectedRole?.isAdmin ?? false) return;
    final nameSet = Set<String>.from(template.permissionNames);
    final newIds = _moduleGroups
        .expand((g) => g.permissions)
        .where((p) => nameSet.contains(p.name))
        .map((p) => p.id)
        .toSet();
    setState(() {
      _selectedPermissionIds = newIds;
      _hasUnsavedChanges = true;
    });
    MotionToast.show(context,
        message: 'Applied "${template.displayName}" template — tap Save to confirm',
        variant: ToastVariant.info);
  }

  Future<void> _savePermissions() async {
    if (_selectedRole == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _aclService.updateRolePermissions(
          _selectedRole!.id, _selectedPermissionIds.toList());
      // Refresh role list to update permission counts
      final updatedRoles = await _aclService.getRoles();
      if (!mounted) return;
      setState(() {
        _roles = updatedRoles;
        _hasUnsavedChanges = false;
        _isSaving = false;
        // Update selected role count
        _selectedRole = _roles.firstWhere((r) => r.id == _selectedRole!.id,
            orElse: () => _selectedRole!);
      });
      MotionToast.show(context,
          message: 'Permissions saved for "${_selectedRole!.name}"',
          variant: ToastVariant.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      MotionToast.show(context,
          message: 'Failed to save: $e', variant: ToastVariant.error);
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
                'You have unsaved permission changes. Discard them and switch role?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Filtered roles ────────────────────────────────────────────────────────

  List<AclRole> get _filteredRoles {
    if (_searchQuery.isEmpty) return _roles;
    return _roles
        .where((r) =>
            r.name.toLowerCase().contains(_searchQuery) ||
            r.code.toLowerCase().contains(_searchQuery) ||
            (r.description?.toLowerCase().contains(_searchQuery) ?? false))
        .toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final permissions = context.watch<PermissionProvider>();
    if (!permissions.canViewPortalUsers) {
      return _buildAccessDenied();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: AppTheme.coralRed))
          : _error != null
              ? _buildError()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    return isWide
                        ? _buildWideLayout()
                        : _buildNarrowLayout();
                  },
                ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.coralRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_outlined,
                color: AppTheme.coralRed, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'Access Control',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          const SizedBox(width: 8),
          if (_hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warningAmber.withOpacity(0.4)),
              ),
              child: const Text(
                'Unsaved changes',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warningAmber,
                ),
              ),
            ),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppTheme.borderLight),
      ),
      actions: [
        if (_hasUnsavedChanges && !_isSaving)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _savePermissions,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save Changes'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: AppTheme.coralRed),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Wide layout ───────────────────────────────────────────────────────────

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel: Role list
        SizedBox(
          width: 300,
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(right: BorderSide(color: AppTheme.borderLight)),
            ),
            child: _buildRoleList(),
          ),
        ),
        // Right panel: Permission matrix
        Expanded(child: _buildPermissionPanel()),
      ],
    );
  }

  // ── Narrow layout ─────────────────────────────────────────────────────────

  Widget _buildNarrowLayout() {
    if (_showPermissionsPanel && _selectedRole != null) {
      return Column(
        children: [
          // Back button bar
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _showPermissionsPanel = false),
                ),
                Expanded(
                  child: Text(
                    _selectedRole!.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.deepSlate),
                  ),
                ),
                if (_hasUnsavedChanges && !_isSaving)
                  TextButton(
                    onPressed: _savePermissions,
                    child: const Text('Save',
                        style: TextStyle(color: AppTheme.successGreen)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildPermissionPanel()),
        ],
      );
    }
    return _buildRoleList();
  }

  // ── Role list panel ───────────────────────────────────────────────────────

  Widget _buildRoleList() {
    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search roles…',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${_filteredRoles.length} roles',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Role items
        Expanded(
          child: ListView.builder(
            itemCount: _filteredRoles.length,
            itemBuilder: (context, index) =>
                _buildRoleItem(_filteredRoles[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleItem(AclRole role) {
    final isSelected = _selectedRole?.id == role.id;
    return InkWell(
      onTap: () {
        _selectRole(role);
        // On narrow, show permissions panel
        final isNarrow = MediaQuery.of(context).size.width <= 900;
        if (isNarrow) setState(() => _showPermissionsPanel = true);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.coralRed.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.coralRed.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Role icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.coralRed.withOpacity(0.15)
                    : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                role.isAdmin ? Icons.admin_panel_settings : Icons.group_outlined,
                color: isSelected ? AppTheme.coralRed : AppTheme.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            // Role info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected
                          ? AppTheme.coralRed
                          : AppTheme.deepSlate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          role.code.isNotEmpty ? role.code : '—',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Permission count badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: role.isAdmin
                    ? AppTheme.deepSlate.withOpacity(0.1)
                    : AppTheme.coralRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                role.isAdmin ? 'ALL' : '${role.permissionCount}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: role.isAdmin
                      ? AppTheme.deepSlate
                      : AppTheme.coralRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Permission panel ──────────────────────────────────────────────────────

  Widget _buildPermissionPanel() {
    if (_selectedRole == null) {
      return _buildNoRoleSelected();
    }
    return Column(
      children: [
        // Role header
        _buildRoleHeader(),
        // Content
        Expanded(
          child: _isLoadingDetail
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.coralRed))
              : _buildPermissionContent(),
        ),
        // Save bar
        if (_hasUnsavedChanges) _buildSaveBar(),
      ],
    );
  }

  Widget _buildRoleHeader() {
    final role = _selectedRole!;
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role name + ADMIN badge
          Row(
            children: [
              Expanded(
                child: Text(
                  role.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
              ),
              if (role.isAdmin)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.deepSlate,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'SUPER ADMIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (!role.isAdmin)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.coralRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppTheme.coralRed.withOpacity(0.2)),
                  ),
                  child: Text(
                    '${_selectedPermissionIds.length} permissions',
                    style: const TextStyle(
                      color: AppTheme.coralRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (role.isAdmin) ...[
            const SizedBox(height: 6),
            const Text(
              'The Administrator role always has all permissions. Permissions cannot be edited for this role.',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
          // Templates row (hidden for ADMIN)
          if (!role.isAdmin && _templates.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Quick apply template:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            _buildTemplateChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _templates.map((template) {
        return ActionChip(
          label: Text(template.displayName),
          avatar: const Icon(Icons.auto_fix_high, size: 14),
          onPressed: () => _showApplyTemplateDialog(template),
          backgroundColor: AppTheme.surfaceElevated,
          side: const BorderSide(color: AppTheme.borderLight),
          labelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.deepSlate),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        );
      }).toList(),
    );
  }

  void _showApplyTemplateDialog(AclRoleTemplate template) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_fix_high, color: AppTheme.coralRed, size: 20),
            const SizedBox(width: 8),
            Text('Apply "${template.displayName}"'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.description,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            Text(
              'This will replace all current permissions with ${template.permissionNames.length} predefined permissions.',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _applyTemplate(template);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.coralRed),
            child: const Text('Apply Template'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionContent() {
    if (_moduleGroups.isEmpty) {
      return const Center(child: Text('No permissions found in database'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _moduleGroups.length,
      itemBuilder: (context, index) =>
          _buildModuleCard(_moduleGroups[index]),
    );
  }

  Widget _buildModuleCard(AclModuleGroup group) {
    final isExpanded = _expandedModules.contains(group.module);
    final isAdmin = _selectedRole?.isAdmin ?? false;

    // Which permissions in this module are selected?
    final groupPermIds = group.permissions.map((p) => p.id).toSet();
    final selectedInGroup =
        _selectedPermissionIds.intersection(groupPermIds).length;
    final totalInGroup = group.permissions.length;
    final allSelected = selectedInGroup == totalInGroup;
    final someSelected = selectedInGroup > 0 && !allSelected;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selectedInGroup > 0
              ? AppTheme.coralRed.withOpacity(0.15)
              : AppTheme.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Module header (tappable to expand/collapse)
          InkWell(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedModules.remove(group.module);
              } else {
                _expandedModules.add(group.module);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Module icon
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: selectedInGroup > 0
                          ? AppTheme.coralRed.withOpacity(0.1)
                          : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _moduleIcon(group.module),
                      size: 16,
                      color: selectedInGroup > 0
                          ? AppTheme.coralRed
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppTheme.deepSlate,
                          ),
                        ),
                        Text(
                          '$selectedInGroup / $totalInGroup permissions',
                          style: TextStyle(
                            fontSize: 11,
                            color: selectedInGroup > 0
                                ? AppTheme.coralRed
                                : AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Select all toggle (hidden for ADMIN)
                  if (!isAdmin)
                    Tooltip(
                      message: allSelected ? 'Deselect all' : 'Select all',
                      child: InkWell(
                        onTap: () => _toggleModule(group, !allSelected),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                someSelected
                                    ? Icons.indeterminate_check_box_outlined
                                    : allSelected
                                        ? Icons.check_box_rounded
                                        : Icons.check_box_outline_blank_rounded,
                                size: 16,
                                color: allSelected || someSelected
                                    ? AppTheme.coralRed
                                    : AppTheme.textTertiary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                allSelected ? 'All' : 'None',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: allSelected
                                      ? AppTheme.coralRed
                                      : AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // Permissions checkboxes
          if (isExpanded) ...[
            const Divider(height: 1, color: AppTheme.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: group.permissions
                    .map((p) => _buildPermissionChip(p, isAdmin))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionChip(AclPermission perm, bool isAdmin) {
    final isChecked = isAdmin || _selectedPermissionIds.contains(perm.id);
    final actionLabel = perm.actionLabel;
    final color = _actionColor(actionLabel);

    return InkWell(
      onTap: isAdmin ? null : () => _togglePermission(perm.id),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isChecked ? color.withOpacity(0.1) : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isChecked ? color.withOpacity(0.35) : AppTheme.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isChecked
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 14,
              color: isChecked ? color : AppTheme.textTertiary,
            ),
            const SizedBox(width: 5),
            Text(
              actionLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isChecked ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Save bar ──────────────────────────────────────────────────────────────

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppTheme.warningAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You have unsaved changes to "${_selectedRole?.name}"',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (_selectedRole != null) {
                await _selectRole(_selectedRole!);
              }
            },
            child: const Text('Discard',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _isSaving ? null : _savePermissions,
            icon: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined, size: 16),
            label:
                Text(_isSaving ? 'Saving…' : 'Save Changes'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty / error states ──────────────────────────────────────────────────

  Widget _buildNoRoleSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined,
              size: 64, color: AppTheme.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Select a role',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose a role from the left panel to\nview and edit its permissions.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: AppTheme.errorRed),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.coralRed),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Access Control'),
        backgroundColor: AppTheme.surface,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: AppTheme.errorRed),
            SizedBox(height: 16),
            Text(
              'Access Denied',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepSlate),
            ),
            SizedBox(height: 8),
            Text(
              'You need Portal User View permission\nto access the ACL management screen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── Visual helpers ────────────────────────────────────────────────────────

  IconData _moduleIcon(String module) {
    return switch (module) {
      'DASHBOARD' => Icons.dashboard_outlined,
      'LEAD' => Icons.person_add_outlined,
      'PROJECT' => Icons.construction_outlined,
      'TASK' => Icons.task_alt_outlined,
      'CUSTOMER' => Icons.people_outline,
      'PORTAL_USER' => Icons.manage_accounts_outlined,
      'REPORT' => Icons.bar_chart_outlined,
      'FINANCE' => Icons.account_balance_outlined,
      'PAYMENT' => Icons.payments_outlined,
      'BOQ' => Icons.calculate_outlined,
      'SITE_REPORT' => Icons.assignment_outlined,
      'GALLERY' => Icons.photo_library_outlined,
      'LABOUR' => Icons.engineering_outlined,
      'PROCUREMENT' => Icons.shopping_bag_outlined,
      'INVENTORY' => Icons.inventory_2_outlined,
      'QC' => Icons.verified_outlined,
      'OBSERVATION' => Icons.remove_red_eye_outlined,
      'SNAG' => Icons.bug_report_outlined,
      'QUERY' => Icons.help_outline,
      'ATTENDANCE' => Icons.how_to_reg_outlined,
      'NOTIFICATION' => Icons.notifications_outlined,
      _ => Icons.settings_outlined,
    };
  }

  Color _actionColor(String action) {
    return switch (action) {
      'VIEW' => AppTheme.skyBlue,
      'CREATE' => AppTheme.successGreen,
      'EDIT' => AppTheme.constructionOrange,
      'DELETE' => AppTheme.errorRed,
      'APPROVE' => AppTheme.coralRed,
      'EXPORT' => const Color(0xFF8B5CF6),
      'FILTER' => AppTheme.deepSlate,
      _ => AppTheme.textSecondary,
    };
  }
}
