import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/portal_auth_provider.dart';
import '../providers/permission_provider.dart';
import '../theme/app_theme.dart';
import '../screens/documents/document_management_screen.dart';

class PortalRoleBasedNavigation extends StatelessWidget {
  const PortalRoleBasedNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PortalAuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return Column(
          children: [
            // User Info Section - Walldot Branded
            if (user != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                margin: const EdgeInsets.all(AppTheme.spacingSM),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.deepSlate, AppTheme.deepSlateDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  boxShadow: AppTheme.shadowSM,
                ),
                child: Column(
                  children: [
                    // Logo or Avatar
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.coralRed,
                      child: Text(
                        user.firstName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textInverse,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textInverse.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    // Role Badge
                    Consumer<PermissionProvider>(
                      builder: (context, permProvider, _) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.coralRed,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        ),
                        child: Text(
                          permProvider.roleDisplayName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.borderLight, height: 1),
            ],

            // Navigation Menu Items
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacingSM),
                children: [
                  // Dashboard - Available to all authenticated users
                  if (authProvider.hasPermission('DASHBOARD_VIEW'))
                    _buildMenuItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      onTap: () {
                        // Navigate to dashboard
                      },
                    ),

                  // Reports - Available to Admin and Sales
                  if (authProvider
                      .hasAnyPermission(['REPORT_VIEW', 'REPORT_EXPORT']))
                    _buildMenuItem(
                      icon: Icons.assessment,
                      title: 'Reports',
                      onTap: () {
                        // Navigate to reports
                      },
                    ),

                  // Projects - Available to Admin and Employee
                  if (authProvider
                      .hasAnyPermission(['PROJECT_VIEW', 'PROJECT_CREATE']))
                    _buildMenuItem(
                      icon: Icons.construction,
                      title: 'Projects',
                      onTap: () {
                        // Navigate to projects
                      },
                    ),

                  // Clients - Available to Admin, Employee, and Sales
                  if (authProvider
                      .hasAnyPermission(['CUSTOMER_VIEW', 'CUSTOMER_CREATE']))
                    _buildMenuItem(
                      icon: Icons.people,
                      title: 'Clients',
                      onTap: () {
                        // Navigate to clients
                      },
                    ),

                  // Leads - Available to Admin and Sales
                  if (authProvider
                      .hasAnyPermission(['LEAD_VIEW', 'LEAD_CREATE']))
                    _buildMenuItem(
                      icon: Icons.person_add,
                      title: 'Leads',
                      onTap: () {
                        // Navigate to leads
                      },
                    ),

                  // Users - Available only to Admin
                  if (authProvider.hasPermission('PORTAL_USER_VIEW'))
                    _buildMenuItem(
                      icon: Icons.manage_accounts,
                      title: 'Users',
                      onTap: () {
                        // Navigate to users management
                      },
                    ),

                  // Documents - Available to all authenticated users
                  // if (authProvider.hasPermission('VIEW_DOCUMENTS'))
                  _buildMenuItem(
                    icon: Icons.folder,
                    title: 'Documents',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DocumentManagementScreen(),
                        ),
                      );
                    },
                  ),

                  // Invoices - Available to Admin and Sales
                  if (authProvider
                      .hasAnyPermission(['FINANCE_VIEW', 'FINANCE_CREATE']))
                    _buildMenuItem(
                      icon: Icons.receipt,
                      title: 'Invoices',
                      onTap: () {
                        // Navigate to invoices
                      },
                    ),

                  // Contracts - Available to Admin and Sales
                  if (authProvider
                      .hasAnyPermission(['DOCUMENT_VIEW', 'DOCUMENT_CREATE']))
                    _buildMenuItem(
                      icon: Icons.description,
                      title: 'Contracts',
                      onTap: () {
                        // Navigate to contracts
                      },
                    ),

                  // Communication - Available to all authenticated users
                  if (authProvider.hasPermission('QUERY_VIEW'))
                    _buildMenuItem(
                      icon: Icons.message,
                      title: 'Communication',
                      onTap: () {
                        // Navigate to communication
                      },
                    ),

                  // Follow-ups - Available to Admin and Sales
                  if (authProvider.hasAnyPermission(
                      ['LEAD_VIEW', 'LEAD_CREATE']))
                    _buildMenuItem(
                      icon: Icons.schedule,
                      title: 'Follow-ups',
                      onTap: () {
                        // Navigate to follow-ups
                      },
                    ),

                  // Site Visits - Available to Admin and Employee
                  if (authProvider.hasAnyPermission(
                      ['SITE_REPORT_VIEW', 'SITE_REPORT_CREATE']))
                    _buildMenuItem(
                      icon: Icons.location_on,
                      title: 'Site Visits',
                      onTap: () {
                        // Navigate to site visits
                      },
                    ),

                  // Tasks - Available to Admin and Employee
                  if (authProvider
                      .hasAnyPermission(['TASK_VIEW', 'TASK_CREATE']))
                    _buildMenuItem(
                      icon: Icons.task,
                      title: 'Tasks',
                      onTap: () {
                        // Navigate to tasks
                      },
                    ),

                  // Team Members - Available to Admin
                  if (authProvider.hasPermission('PORTAL_USER_VIEW'))
                    _buildMenuItem(
                      icon: Icons.group,
                      title: 'Team Members',
                      onTap: () {
                        // Navigate to team members
                      },
                    ),

                  // Quotations - Available to Admin and Sales
                  if (authProvider.hasAnyPermission(
                      ['BOQ_VIEW', 'BOQ_CREATE']))
                    _buildMenuItem(
                      icon: Icons.format_quote,
                      title: 'Quotations',
                      onTap: () {
                        // Navigate to quotations
                      },
                    ),
                ],
              ),
            ),

            // Logout Button - Walldot Styled
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authProvider.logout(context);
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.coralRed, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      hoverColor: AppTheme.coralRed.withOpacity(0.08),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingXS,
      ),
    );
  }
}
