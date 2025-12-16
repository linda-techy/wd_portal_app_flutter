import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/theme/app_theme.dart';

class SideMenu extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: isDrawer ? null : 250,
      decoration: BoxDecoration(
        color: secondaryColor,
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header - Cleaner, more professional look
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: defaultPadding * 2,
              horizontal: defaultPadding,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    "assets/icons/wd_logo.png",
                    width: 140, // Slightly larger for better visibility
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
                  child: Text(
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
          // Menu Items - DYNAMIC BASED ON PERMISSIONS
          Expanded(
            child: Consumer<PermissionProvider>(
              builder: (context, permissions, child) {
                return ListView(
                  children: _buildDynamicMenuItems(context, permissions),
                );
              },
            ),
          ),
          // User Profile Section (Desktop Footer Replacement)
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
                    onTap: () => onMenuItemClick(17), // Navigate to Profile (Index 17)
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                            child: Text(
                              (user.firstName?.isNotEmpty == true) 
                                  ? user.firstName![0].toUpperCase() 
                                  : 'U',
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // User Info
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
                                  user.role ?? 'User',
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
                          // Logout Action
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

  /// Build dynamic menu items based on permissions
  /// CRITICAL: Menu is ONLY visible if user has VIEW permission
  List<Widget> _buildDynamicMenuItems(
      BuildContext context, PermissionProvider permissions) {
    List<Widget> menuItems = [];

    // DASHBOARD - Always visible (or check DASHBOARD_VIEW)
    if (permissions.canViewDashboard) {
      menuItems.add(_buildMenuItem(
        context,
        title: dashboardModule,
        svgSrc: "assets/icons/menu_dashboard.svg",
        index: 0,
      ));
    }

    // LEADS - Only if can view leads
    if (permissions.canViewLeads) {
      menuItems.add(_buildMenuItem(
        context,
        title: leadsModule,
        svgSrc: "assets/icons/menu_leads.svg",
        index: 1,
      ));
    }

    // CUSTOMERS - Only if can view customers
    if (permissions.canViewCustomers) {
      menuItems.add(_buildMenuItem(
        context,
        title: customersModule,
        svgSrc: "assets/icons/menu_profile.svg",
        index: 2,
      ));
    }

    // CUSTOMER PROJECTS - Only if can view projects
    if (permissions.canViewProjects) {
      menuItems.add(_buildMenuItem(
        context,
        title: customerProjectsModule,
        svgSrc: "assets/icons/menu_task.svg",
        index: 3,
      ));
    }

    // TASKS - Only if can view tasks
    if (permissions.canViewTasks) {
      menuItems.add(_buildMenuItem(
        context,
        title: "Tasks",
        svgSrc: "assets/icons/menu_task.svg",
        index: 11, // Tasks index in MainScreen
      ));
    }

    // PORTAL USERS - Only if can view portal users
    if (permissions.canViewPortalUsers) {
      menuItems.add(_buildMenuItem(
        context,
        title: portalUsersModule,
        svgSrc: "assets/icons/menu_profile.svg",
        index: 4,
      ));
    }

    // DOCUMENTS - Check for document view permission
    if (permissions.canView('DOCUMENT')) {
      menuItems.add(_buildMenuItem(
        context,
        title: "Documents",
        svgSrc: "assets/icons/menu_doc.svg",
        index: 14, // Matches MainScreen index
      ));
    }

    // REPORTS - Only if can view reports
    if (permissions.canViewReports) {
      menuItems.add(_buildMenuItem(
        context,
        title: reportsModule,
        svgSrc: "assets/icons/menu_setting.svg",
        index: 13,
      ));
    }

    return menuItems;
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required String svgSrc,
    required int index,
  }) {
    final isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.coralRed : Colors.transparent,
        borderRadius:BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () {
          onMenuItemClick(index);
          if (isDrawer) {
            Navigator.of(context).pop(); // Close drawer on mobile
          }
        },
        horizontalTitleGap: 0.0,
        selected: isSelected,
        selectedTileColor: Colors.transparent,
        leading: SvgPicture.asset(
          svgSrc,
          colorFilter: ColorFilter.mode(
            isSelected ? Colors.white : Colors.grey[600]!,
            BlendMode.srcIn,
          ),
          height: 16,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
