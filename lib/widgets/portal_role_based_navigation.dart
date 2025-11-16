import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/portal_auth_provider.dart';
import '../constants.dart';

class PortalRoleBasedNavigation extends StatelessWidget {
  const PortalRoleBasedNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PortalAuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return Column(
          children: [
            // User Info Section
            if (user != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: primaryColor,
                      child: Text(
                        user.firstName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
            ],

            // Navigation Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  // Dashboard - Available to all authenticated users
                  if (authProvider.hasPermission('VIEW_DASHBOARD'))
                    _buildMenuItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      onTap: () {
                        // Navigate to dashboard
                      },
                    ),

                  // Reports - Available to Admin and Sales
                  if (authProvider
                      .hasAnyPermission(['VIEW_REPORTS', 'MANAGE_REPORTS']))
                    _buildMenuItem(
                      icon: Icons.assessment,
                      title: 'Reports',
                      onTap: () {
                        // Navigate to reports
                      },
                    ),

                  // Projects - Available to Admin and Employee
                  if (authProvider
                      .hasAnyPermission(['VIEW_PROJECTS', 'MANAGE_PROJECTS']))
                    _buildMenuItem(
                      icon: Icons.construction,
                      title: 'Projects',
                      onTap: () {
                        // Navigate to projects
                      },
                    ),

                  // Clients - Available to Admin, Employee, and Sales
                  if (authProvider
                      .hasAnyPermission(['VIEW_CLIENTS', 'MANAGE_CLIENTS']))
                    _buildMenuItem(
                      icon: Icons.people,
                      title: 'Clients',
                      onTap: () {
                        // Navigate to clients
                      },
                    ),

                  // Leads - Available to Admin and Sales
                  if (authProvider
                      .hasAnyPermission(['VIEW_LEADS', 'MANAGE_LEADS']))
                    _buildMenuItem(
                      icon: Icons.person_add,
                      title: 'Leads',
                      onTap: () {
                        // Navigate to leads
                      },
                    ),

                  // Users - Available only to Admin
                  if (authProvider.hasPermission('MANAGE_USERS'))
                    _buildMenuItem(
                      icon: Icons.manage_accounts,
                      title: 'Users',
                      onTap: () {
                        // Navigate to users management
                      },
                    ),

                  // Documents - Available to all authenticated users
                  if (authProvider.hasPermission('VIEW_DOCUMENTS'))
                    _buildMenuItem(
                      icon: Icons.folder,
                      title: 'Documents',
                      onTap: () {
                        // Navigate to documents
                      },
                    ),

                  // Invoices - Available to Admin and Sales
                  if (authProvider
                      .hasAnyPermission(['VIEW_INVOICES', 'MANAGE_INVOICES']))
                    _buildMenuItem(
                      icon: Icons.receipt,
                      title: 'Invoices',
                      onTap: () {
                        // Navigate to invoices
                      },
                    ),

                  // Contracts - Available to Admin and Sales
                  if (authProvider
                      .hasAnyPermission(['VIEW_CONTRACTS', 'MANAGE_CONTRACTS']))
                    _buildMenuItem(
                      icon: Icons.description,
                      title: 'Contracts',
                      onTap: () {
                        // Navigate to contracts
                      },
                    ),

                  // Communication - Available to all authenticated users
                  if (authProvider.hasPermission('VIEW_COMMUNICATION'))
                    _buildMenuItem(
                      icon: Icons.message,
                      title: 'Communication',
                      onTap: () {
                        // Navigate to communication
                      },
                    ),

                  // Follow-ups - Available to Admin and Sales
                  if (authProvider.hasAnyPermission(
                      ['VIEW_FOLLOW_UPS', 'MANAGE_FOLLOW_UPS']))
                    _buildMenuItem(
                      icon: Icons.schedule,
                      title: 'Follow-ups',
                      onTap: () {
                        // Navigate to follow-ups
                      },
                    ),

                  // Site Visits - Available to Admin and Employee
                  if (authProvider.hasAnyPermission(
                      ['VIEW_SITE_VISITS', 'MANAGE_SITE_VISITS']))
                    _buildMenuItem(
                      icon: Icons.location_on,
                      title: 'Site Visits',
                      onTap: () {
                        // Navigate to site visits
                      },
                    ),

                  // Tasks - Available to Admin and Employee
                  if (authProvider
                      .hasAnyPermission(['VIEW_TASKS', 'MANAGE_TASKS']))
                    _buildMenuItem(
                      icon: Icons.task,
                      title: 'Tasks',
                      onTap: () {
                        // Navigate to tasks
                      },
                    ),

                  // Team Members - Available to Admin
                  if (authProvider.hasPermission('MANAGE_TEAM_MEMBERS'))
                    _buildMenuItem(
                      icon: Icons.group,
                      title: 'Team Members',
                      onTap: () {
                        // Navigate to team members
                      },
                    ),

                  // Quotations - Available to Admin and Sales
                  if (authProvider.hasAnyPermission(
                      ['VIEW_QUOTATIONS', 'MANAGE_QUOTATIONS']))
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

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authProvider.logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
      leading: Icon(icon, color: primaryColor),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      hoverColor: primaryColor.withOpacity(0.1),
    );
  }
}
