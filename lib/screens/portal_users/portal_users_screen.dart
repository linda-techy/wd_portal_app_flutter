import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../models/portal_user.dart';
import '../../models/role.dart';
import '../../services/crm_service.dart';
import 'add_portal_user_screen.dart';
import 'edit_portal_user_screen.dart';

class PortalUsersScreen extends StatefulWidget {
  const PortalUsersScreen({super.key});

  @override
  State<PortalUsersScreen> createState() => _PortalUsersScreenState();
}

class _PortalUsersScreenState extends State<PortalUsersScreen> {
  final CRMService _crmService = CRMService();
  List<PortalUser> _users = [];
  List<PortalRole> _roles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadRoles();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _crmService.getAllPortalUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: $e'),
            backgroundColor: AppTheme.statusError,
          ),
        );
      }
    }
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await _crmService.getPortalRoles();
      if (mounted) {
        setState(() {
          _roles = roles;
        });
      }
    } catch (e) {
      // Silently fail - roles are not critical for display
    }
  }

  String _getRoleName(int? roleId) {
    if (roleId == null) return 'N/A';
    try {
      final role = _roles.firstWhere((r) => r.id == roleId);
      return role.name;
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _deleteUser(PortalUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.statusError),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && user.id != null) {
      try {
        await _crmService.deletePortalUser(user.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: AppTheme.statusSuccess,
            ),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete user: $e'),
              backgroundColor: AppTheme.statusError,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdaptiveContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Portal Users',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddPortalUserScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadUsers();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add User'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLG),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_users.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingXL),
                  child: Text(
                    'No users found',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ),
              )
            else
              Expanded(
                child: _PortalUsersTable(
                  users: _users,
                  roles: _roles,
                  getRoleName: _getRoleName,
                  onEdit: (user) async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPortalUserScreen(user: user),
                      ),
                    );
                    if (result == true) {
                      _loadUsers();
                    }
                  },
                  onDelete: _deleteUser,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PortalUsersTable extends StatelessWidget {
  final List<PortalUser> users;
  final List<PortalRole> roles;
  final String Function(int?) getRoleName;
  final Function(PortalUser) onEdit;
  final Function(PortalUser) onDelete;

  const _PortalUsersTable({
    required this.users,
    required this.roles,
    required this.getRoleName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scrollable table columns
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: AppTheme.spacingMD,
                    headingRowHeight: 48,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 72,
                    columns: const [
                      DataColumn(
                          label: Text('ID',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Name',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Email',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Role',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Status',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: users.map((user) {
                      return DataRow(
                        cells: [
                          DataCell(Text(user.id?.toString() ?? 'N/A')),
                          DataCell(Text(user.fullName)),
                          DataCell(Text(user.email)),
                          DataCell(Text(getRoleName(user.roleId))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: user.enabled
                                    ? AppTheme.statusSuccessBg
                                    : AppTheme.statusErrorBg,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSM),
                              ),
                              child: Text(
                                user.enabled ? 'Enabled' : 'Disabled',
                                style: TextStyle(
                                  color: user.enabled
                                      ? AppTheme.statusSuccess
                                      : AppTheme.statusError,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Fixed Actions Column
              Container(
                width: 92,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: AppTheme.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      height: 48,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceElevated,
                      ),
                      child: const Text(
                        'Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Rows
                    ...users.asMap().entries.map((entry) {
                      final user = entry.value;
                      return Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 2,
                          runSpacing: 2,
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                color: AppTheme.primaryBlue,
                                tooltip: 'Edit',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => onEdit(user),
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                color: AppTheme.statusError,
                                tooltip: 'Delete',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => onDelete(user),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
