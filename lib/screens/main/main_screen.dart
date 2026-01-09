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
import 'package:admin/screens/payments/challan_management_screen.dart';
import 'package:admin/screens/reports/reports_screen.dart';
import 'package:admin/screens/tasks/task_list_screen.dart';
import 'package:admin/screens/profile/profile_screen.dart';
import 'package:admin/screens/procurement/procurement_dashboard_screen.dart';
import 'package:admin/screens/labour/labour_dashboard_screen.dart';
import 'package:admin/screens/inventory/inventory_dashboard_screen.dart';
import 'package:admin/screens/finance/finance_dashboard_screen.dart';
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
    const ChallanManagementScreen(), // Index 18 - Challans
    const ProcurementDashboardScreen(), // Index 19 - Procurement
    const LabourDashboardScreen(), // Index 20 - Labour
    const InventoryDashboardScreen(), // Index 21 - Inventory
    const FinanceDashboardScreen(), // Index 22 - Finance
  ];

  void _onMenuItemClick(int index) {
    context.read<MenuAppController>().setSelectedIndex(index);
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
      case 18:
        return 'Challans';
      case 19:
        return 'Procurement';
      case 20:
        return 'Labour Management';
      case 21:
        return 'Inventory Tracking';
      case 22:
        return 'Finance & Billing';
      default:
        return 'Tasks';
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuController = context.watch<MenuAppController>();
    final selectedIndex = menuController.selectedIndex;

    return Scaffold(
      key: menuController.scaffoldKey,
      appBar: Responsive.isDesktop(context)
          ? null
          : AppBar(
              title: Text(_getScreenTitle(selectedIndex)),
              backgroundColor: secondaryColor,
              foregroundColor: Colors.black87,
              automaticallyImplyLeading: false,

            ),
      drawer: Drawer(
        child: SideMenu(
          onMenuItemClick: _onMenuItemClick,
          selectedIndex: selectedIndex,
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
                      selectedIndex: selectedIndex,
                      isDrawer: false,
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width,
                      ),
                      child: _screens[selectedIndex],
                    ),
                  ),
                ],
               )
             : _screens[selectedIndex],
      ),
      bottomNavigationBar: ResponsiveUtils.isMobile(context) || ResponsiveUtils.isTablet(context)
          ? BottomNavigationBar(
              backgroundColor: Colors.white,
              selectedItemColor:AppTheme.primaryBlue,
              unselectedItemColor: AppTheme.textTertiary,
              currentIndex: selectedIndex == 3 ? 1 : selectedIndex == 17 ? 2 : 0,
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
