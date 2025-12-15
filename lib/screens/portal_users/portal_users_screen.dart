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
  final TextEditingController _searchController = TextEditingController();
  List<PortalUser> _users = [];
  List<PortalRole> _roles = [];
  bool _isLoading = false;
  
  // Pagination state
  int _currentPage = 0;
  int _pageSize = 10;
  int _totalPages = 0;
  int _totalElements = 0;
  String _sortBy = 'id';
  String _sortDirection = 'asc';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadRoles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _crmService.getPortalUsersPaginated(
        page: _currentPage,
        size: _pageSize,
        sort: _sortBy,
        direction: _sortDirection,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      
      if (mounted) {
        setState(() {
          _users = response.data;
          _totalPages = response.totalPages;
          _totalElements = response.totalItems;
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

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 0; // Reset to first page on search
    });
    _loadUsers();
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      setState(() => _currentPage = page);
      _loadUsers();
    }
  }

  void _changePageSize(int newSize) {
    setState(() {
      _pageSize = newSize;
      _currentPage = 0; // Reset to first page
    });
    _loadUsers();
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
            Wrap(
              spacing: AppTheme.spacingMD,
              runSpacing: AppTheme.spacingMD,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
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
            // Search Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  filled: true,
                  fillColor: AppTheme.surface,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMD),
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
                child: Column(
                  children: [
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
                    // Pagination Controls
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLG,
                        vertical: AppTheme.spacingMD,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        border: Border(
                          top: BorderSide(color: AppTheme.borderLight, width: 1),
                        ),
                      ),
                      child: Wrap(
                        spacing: AppTheme.spacingMD,
                        runSpacing: AppTheme.spacingMD,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Page size selector
                          Row(
                            children: [
                              Text(
                                'Show',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingSM),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.borderLight),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                ),
                                child: DropdownButton<int>(
                                  value: _pageSize,
                                  underline: const SizedBox(),
                                  isDense: true,
                                  items: [10, 25, 50, 100]
                                      .map((size) => DropdownMenuItem(
                                            value: size,
                                            child: Text(
                                              size.toString(),
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (newSize) {
                                    if (newSize != null) {
                                      _changePageSize(newSize);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingSM),
                              Text(
                                'entries',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          // Page info and navigation
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Showing ${_users.isEmpty ? 0 : _currentPage * _pageSize + 1}-${(_currentPage + 1) * _pageSize > _totalElements ? _totalElements : (_currentPage + 1) * _pageSize} of $_totalElements',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingLG),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.borderLight),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                ),
                                child: Row(
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _currentPage > 0
                                            ? () => _goToPage(_currentPage - 1)
                                            : null,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(AppTheme.radiusSM),
                                          bottomLeft: Radius.circular(AppTheme.radiusSM),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: Icon(
                                            Icons.chevron_left,
                                            size: 20,
                                            color: _currentPage > 0
                                                ? AppTheme.textPrimary
                                                : AppTheme.textTertiary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 32,
                                      color: AppTheme.borderLight,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Flexible(
                                        child: Text(
                                          'Page ${_currentPage + 1} of $_totalPages',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 32,
                                      color: AppTheme.borderLight,
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _currentPage < _totalPages - 1
                                            ? () => _goToPage(_currentPage + 1)
                                            : null,
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(AppTheme.radiusSM),
                                          bottomRight: Radius.circular(AppTheme.radiusSM),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: Icon(
                                            Icons.chevron_right,
                                            size: 20,
                                            color: _currentPage < _totalPages - 1
                                                ? AppTheme.textPrimary
                                                : AppTheme.textTertiary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PortalUsersTable extends StatefulWidget {
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
  State<_PortalUsersTable> createState() => _PortalUsersTableState();
}

class _PortalUsersTableState extends State<_PortalUsersTable> {
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Left Side: Scrollable Data
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width > 720 ? 720 : MediaQuery.of(context).size.width - 90, // Responsive width
                      child: Column(
                        children: [
                          // Header Row (Left part)
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                            ),
                            child: Row(
                              children: [
                                _buildHeaderCell('Name', 200),
                                _buildHeaderCell('Email', 250),
                                _buildHeaderCell('Role', 150),
                                _buildHeaderCell('Status', 120),
                              ],
                            ),
                          ),
                          // Body Rows (Left part)
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _verticalController,
                              child: Column(
                                children: widget.users.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final user = entry.value;
                                  final isEven = index % 2 == 0;
                                  return Container(
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: isEven ? Colors.transparent : AppTheme.surfaceElevated.withOpacity(0.3),
                                      border: Border(bottom: BorderSide(color: AppTheme.borderLight.withOpacity(0.5))),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildDataCell(Text(user.fullName), 200),
                                        _buildDataCell(Text(user.email), 250),
                                        _buildDataCell(Text(widget.getRoleName(user.roleId)), 150),
                                        _buildDataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: user.enabled ? AppTheme.statusSuccessBg : AppTheme.statusErrorBg,
                                              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                            ),
                                            child: Text(
                                              user.enabled ? 'Enabled' : 'Disabled',
                                              style: TextStyle(
                                                color: user.enabled ? AppTheme.statusSuccess : AppTheme.statusError,
                                                fontSize: 12, 
                                                fontWeight: FontWeight.w500
                                              ),
                                            ),
                                          ), 
                                          120
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Right Side: Fixed Actions
                Container(
                  width: 90,
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: AppTheme.borderLight)),
                    color: AppTheme.surface,
                  ),
                  child: Column(
                    children: [
                      // Actions Header
                      Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                        ),
                        child: Text(
                          'Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.w600, 
                            fontSize: 14, 
                            color: AppTheme.textPrimary
                          ),
                        ),
                      ),
                      // Actions Body
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _verticalController,
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            children: widget.users.asMap().entries.map((entry) {
                              final index = entry.key;
                              final user = entry.value;
                              final isEven = index % 2 == 0;
                              return Container(
                                height: 64,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isEven ? Colors.transparent : AppTheme.surfaceElevated.withOpacity(0.3),
                                  border: Border(bottom: BorderSide(color: AppTheme.borderLight.withOpacity(0.5))),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      color: AppTheme.primaryBlue,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () => widget.onEdit(user),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18),
                                      color: AppTheme.statusError,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () => widget.onDelete(user),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDataCell(Widget child, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
