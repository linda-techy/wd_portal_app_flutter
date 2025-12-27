import 'package:admin/controllers/menu_app_controller.dart';
import 'package:admin/responsive.dart';
import 'package:admin/constants.dart';
import 'package:admin/screens/dashboard/dashboard_screen.dart';
import 'package:admin/features/leads/presentation/screens/leads_screen.dart';
import 'package:admin/features/customers/presentation/screens/customers_screen.dart';
import 'package:admin/screens/customer_projects/customer_projects_screen.dart';
import 'package:admin/screens/portal_users/portal_users_screen.dart';
import 'package:admin/screens/clients/clients_screen.dart';
import 'package:admin/screens/projects/projects_screen.dart';
import 'package:admin/screens/quotations/quotations_screen.dart';
import 'package:admin/screens/contracts/contracts_screen.dart';
import 'package:admin/screens/follow_ups/follow_ups_screen.dart';
import 'package:admin/screens/site_visits/site_visits_screen.dart';
import 'package:admin/screens/tasks/tasks_screen.dart';
import 'package:admin/screens/team_members/team_members_screen.dart';
import 'package:admin/screens/communication/communication_screen.dart';
import 'package:admin/screens/documents/document_management_screen.dart';
import 'package:admin/screens/payments/payments_dashboard_screen.dart';
import 'package:admin/screens/reports/reports_screen.dart';
import 'package:admin/screens/tasks/task_list_screen.dart';
import 'package:admin/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/theme/responsive_utils.dart';
import 'package:admin/theme/app_theme.dart';

import 'components/side_menu.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 11; // Start with Tasks

  final List<Widget> _screens = [
    const DashboardScreen(),
    const LeadsScreen(),
    const CustomersScreen(),
    const CustomerProjectsScreen(),
    const PortalUsersScreen(),
    const ClientsScreen(),
    const ProjectsScreen(),
    const QuotationsScreen(),
    const ContractsScreen(),
    const FollowUpsScreen(),
    const SiteVisitsScreen(),
    const TaskListScreen(), // Index 11 - Tasks (Entry Screen)
    const TeamMembersScreen(),
    const CommunicationScreen(),
    const DocumentManagementScreen(),
    const PaymentsDashboardScreen(), // Index 15 - Payments Dashboard
    const ReportsScreen(),
    const ProfileScreen(), // Index 17 - Profile
  ];

  void _onMenuItemClick(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getScreenTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Leads';
      case 2:
        return 'Customers';
      case 3:
        return 'Customer Projects';
      case 4:
        return 'Portal Users';
      case 5:
        return 'Clients';
      case 6:
        return 'Projects';
      case 7:
        return 'Quotations';
      case 8:
        return 'Contracts';
      case 9:
        return 'Follow Ups';
      case 10:
        return 'Site Visits';
      case 11:
        return 'Tasks';
      case 12:
        return 'Team Members';
      case 13:
        return 'Communication';
      case 14:
        return 'Documents';
      case 15:
        return 'Payments';
      case 16:
        return 'Reports';
      case 17:
        return 'Profile';
      default:
        return 'Tasks';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: context.read<MenuAppController>().scaffoldKey,
      appBar: Responsive.isDesktop(context)
          ? null
          : AppBar(
              title: Text(_getScreenTitle(_selectedIndex)),
              backgroundColor: secondaryColor,
              foregroundColor: Colors.black87,
              automaticallyImplyLeading: false,

            ),
      drawer: Drawer(
        child: SideMenu(
          onMenuItemClick: _onMenuItemClick,
          selectedIndex: _selectedIndex,
          isDrawer: true,
        ),
      ),
      body: SafeArea(
        child: Responsive.isDesktop(context)
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: SideMenu(
                      onMenuItemClick: _onMenuItemClick,
                      selectedIndex: _selectedIndex,
                      isDrawer: false,
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width,
                      ),
                      child: _screens[_selectedIndex],
                    ),
                  ),
                ],
               )
             : _screens[_selectedIndex],
      ),
      bottomNavigationBar: ResponsiveUtils.isMobile(context) || ResponsiveUtils.isTablet(context)
          ? BottomNavigationBar(
              backgroundColor: Colors.white,
              selectedItemColor:AppTheme.primaryBlue,
              unselectedItemColor: AppTheme.textTertiary,
              currentIndex: _selectedIndex == 3 ? 1 : _selectedIndex == 17 ? 2 : 0,
              onTap: (index) {
                // Map bottom nav indices
                // 0 -> Open Menu, 1 -> Projects (3), 2 -> Profile (17)
                if (index == 0) {
                  // Open drawer/menu
                  context.read<MenuAppController>().controlMenu();
                } else {
                  final screenIndex = index == 1 ? 3 : 17;
                  _onMenuItemClick(screenIndex);
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu),
                  label: 'Menu',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder),
                  label: 'Projects',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            )
          : null,
    );
  }
}
