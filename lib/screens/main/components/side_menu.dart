import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/theme/app_theme.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({
    super.key,
    required this.onMenuItemClick,
    required this.selectedIndex,
    this.isDrawer = false,
  });

  final Function(int) onMenuItemClick;
  final int selectedIndex;
  final bool isDrawer;

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  // Track which groups are expanded. Key = group name.
  final Map<String, bool> _expanded = {};

  // Returns the group name that contains the given index, if any.
  String? _groupForIndex(int index) {
    for (final group in _menuGroups) {
      for (final item in group.items) {
        if (item.index == index) return group.title;
      }
    }
    return null;
  }

  @override
  void didUpdateWidget(SideMenu old) {
    super.didUpdateWidget(old);
    // Auto-expand the group that contains the newly selected item.
    final group = _groupForIndex(widget.selectedIndex);
    if (group != null && _expanded[group] != true) {
      setState(() => _expanded[group] = true);
    }
  }

  @override
  void initState() {
    super.initState();
    // Expand the group containing the initial selected item.
    final group = _groupForIndex(widget.selectedIndex);
    if (group != null) _expanded[group] = true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isDrawer ? null : 250,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          right: BorderSide(color: AppTheme.borderLight, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: defaultPadding * 2,
              horizontal: defaultPadding,
            ),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                bottom: BorderSide(color: AppTheme.divider, width: 1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    "assets/icons/wd_logo.png",
                    width: 140,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Walldot Builders',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Menu Groups
          Expanded(
            child: Consumer<PermissionProvider>(
              builder: (context, permissions, child) {
                return Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    children: _buildGroupedMenu(context, permissions),
                  ),
                );
              },
            ),
          ),

          // User Profile Footer
          Consumer<PortalAuthProvider>(
            builder: (context, auth, child) {
              final user = auth.currentUser;
              if (user == null) return const SizedBox();

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding / 2,
                  vertical: defaultPadding,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onMenuItemClick(15),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                AppTheme.primaryBlue.withOpacity(0.1),
                            child: Text(
                              (user.firstName.isNotEmpty == true)
                                  ? user.firstName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user.firstName} ${user.lastName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.deepSlate,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.role,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await auth.logout(context);
                            },
                            icon: const Icon(Icons.logout_rounded),
                            color: Colors.red[300],
                            tooltip: 'Logout',
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedMenu(
      BuildContext context, PermissionProvider permissions) {
    final widgets = <Widget>[];

    for (final group in _menuGroups) {
      // Filter items to those the user can see.
      final visibleItems = group.items
          .where((item) => item.isVisible(permissions))
          .toList();

      if (visibleItems.isEmpty) continue;

      final isExpanded = _expanded[group.title] ?? false;

      widgets.add(_MenuGroup(
        title: group.title,
        icon: group.icon,
        isExpanded: isExpanded,
        onToggle: () =>
            setState(() => _expanded[group.title] = !isExpanded),
        children: visibleItems
            .map((item) => _buildMenuItemForGroup(context, item))
            .toList(),
      ));
    }

    return widgets;
  }

  Widget _buildMenuItemForGroup(BuildContext context, _MenuItem item) {
    final isSelected = widget.selectedIndex == item.index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.coralRed : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () {
          widget.onMenuItemClick(item.index);
          if (widget.isDrawer) {
            Navigator.of(context).pop();
          }
        },
        horizontalTitleGap: 0.0,
        selected: isSelected,
        selectedTileColor: Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: item.svgSrc != null
            ? SvgPicture.asset(
                item.svgSrc!,
                colorFilter: ColorFilter.mode(
                  isSelected ? Colors.white : Colors.grey[600]!,
                  BlendMode.srcIn,
                ),
                height: 16,
              )
            : Icon(
                item.icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 18,
              ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── Group header widget ───────────────────────────────────────────────────────

class _MenuGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _MenuGroup({
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
            child: Row(
              children: [
                Icon(icon, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...children,
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── Data model for menu items ─────────────────────────────────────────────────

class _MenuItem {
  final String title;
  final String? svgSrc;
  final IconData? icon;
  final int index;
  final bool Function(PermissionProvider) isVisible;

  const _MenuItem({
    required this.title,
    this.svgSrc,
    this.icon,
    required this.index,
    this.isVisible = _alwaysVisible,
  });

  static bool _alwaysVisible(PermissionProvider _) => true;
}

class _MenuGroupData {
  final String title;
  final IconData icon;
  final List<_MenuItem> items;

  const _MenuGroupData({
    required this.title,
    required this.icon,
    required this.items,
  });
}

// ─── Menu structure ────────────────────────────────────────────────────────────

final List<_MenuGroupData> _menuGroups = [
  _MenuGroupData(
    title: 'CRM',
    icon: Icons.people_outline,
    items: [
      _MenuItem(
        title: 'Dashboard',
        svgSrc: 'assets/icons/menu_dashboard.svg',
        index: 0,
        isVisible: (p) => p.canViewDashboard,
      ),
      _MenuItem(
        title: 'Leads',
        svgSrc: 'assets/icons/menu_leads.svg',
        index: 1,
        isVisible: (p) => p.canViewLeads,
      ),
      _MenuItem(
        title: 'Customers',
        svgSrc: 'assets/icons/menu_profile.svg',
        index: 2,
        isVisible: (p) => p.canViewCustomers,
      ),
      const _MenuItem(
        title: 'Follow-ups',
        svgSrc: 'assets/icons/menu_task.svg',
        index: 7,
      ),
      const _MenuItem(
        title: 'Communication',
        svgSrc: 'assets/icons/menu_doc.svg',
        index: 11,
      ),
    ],
  ),
  _MenuGroupData(
    title: 'Projects',
    icon: Icons.construction_outlined,
    items: [
      _MenuItem(
        title: 'Projects',
        svgSrc: 'assets/icons/menu_task.svg',
        index: 3,
        isVisible: (p) => p.canViewProjects,
      ),
      _MenuItem(
        title: 'Tasks',
        svgSrc: 'assets/icons/menu_task.svg',
        index: 9,
        isVisible: (p) => p.canViewTasks,
      ),
      const _MenuItem(
        title: 'Site Visits',
        svgSrc: 'assets/icons/menu_task.svg',
        index: 8,
      ),
      _MenuItem(
        title: 'Documents',
        svgSrc: 'assets/icons/menu_doc.svg',
        index: 12,
        isVisible: (p) => p.canView('DOCUMENT'),
      ),
      _MenuItem(
        title: 'Reports',
        svgSrc: 'assets/icons/menu_setting.svg',
        index: 14,
        isVisible: (p) => p.canViewReports,
      ),
      const _MenuItem(
        title: 'Team Members',
        svgSrc: 'assets/icons/menu_profile.svg',
        index: 10,
      ),
    ],
  ),
  const _MenuGroupData(
    title: 'Finance',
    icon: Icons.account_balance_wallet_outlined,
    items: [
      _MenuItem(
        title: 'Payments',
        svgSrc: 'assets/icons/menu_task.svg',
        index: 13,
      ),
      _MenuItem(
        title: 'Challans',
        svgSrc: 'assets/icons/menu_doc.svg',
        index: 16,
      ),
      _MenuItem(
        title: 'Procurement',
        svgSrc: 'assets/icons/menu_task.svg',
        index: 17,
      ),
      _MenuItem(
        title: 'Finance',
        svgSrc: 'assets/icons/menu_tran.svg',
        index: 20,
      ),
    ],
  ),
  const _MenuGroupData(
    title: 'Operations',
    icon: Icons.settings_outlined,
    items: [
      _MenuItem(
        title: 'Labour',
        svgSrc: 'assets/icons/menu_profile.svg',
        index: 18,
      ),
      _MenuItem(
        title: 'Inventory',
        svgSrc: 'assets/icons/menu_store.svg',
        index: 19,
      ),
      _MenuItem(
        title: 'Contracts',
        svgSrc: 'assets/icons/menu_doc.svg',
        index: 6,
      ),
      _MenuItem(
        title: 'Quotations',
        svgSrc: 'assets/icons/menu_task.svg',
        index: 5,
      ),
    ],
  ),
  _MenuGroupData(
    title: 'Admin',
    icon: Icons.admin_panel_settings_outlined,
    items: [
      _MenuItem(
        title: 'Portal Users',
        svgSrc: 'assets/icons/menu_profile.svg',
        index: 4,
        isVisible: (p) => p.canViewPortalUsers,
      ),
      _MenuItem(
        title: 'Partnerships',
        svgSrc: 'assets/icons/menu_profile.svg',
        index: 21,
        isVisible: (p) => p.canViewPortalUsers,
      ),
      const _MenuItem(
        title: 'Support',
        icon: Icons.support_agent,
        index: 23,
      ),
      _MenuItem(
        title: 'Access Control',
        icon: Icons.shield_outlined,
        index: 22,
        isVisible: (p) => p.canEditPortalUser,
      ),
      _MenuItem(
        title: 'DPC Templates',
        icon: Icons.layers_outlined,
        index: 24,
        isVisible: (p) => p.canManageDpcTemplates,
      ),
      _MenuItem(
        title: 'DPC Customizations',
        icon: Icons.tune,
        index: 26,
        isVisible: (p) => p.canManageDpcCustomizationCatalog,
      ),
      _MenuItem(
        title: 'Estimation Settings',
        icon: Icons.tune,
        index: 27,
        isVisible: (p) => p.canManageEstimationSettings,
      ),
      const _MenuItem(
        title: 'Profile',
        svgSrc: 'assets/icons/menu_profile.svg',
        index: 15,
      ),
    ],
  ),
];
