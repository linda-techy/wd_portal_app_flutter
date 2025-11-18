import 'package:admin/controllers/menu_app_controller.dart';
import 'package:admin/responsive.dart';
import 'package:admin/constants.dart';
import 'package:admin/screens/dashboard/dashboard_screen.dart';
import 'package:admin/screens/leads/leads_screen.dart';
import 'package:admin/screens/customers/customers_screen.dart';
import 'package:admin/screens/clients/clients_screen.dart';
import 'package:admin/screens/projects/projects_screen.dart';
import 'package:admin/screens/quotations/quotations_screen.dart';
import 'package:admin/screens/contracts/contracts_screen.dart';
import 'package:admin/screens/follow_ups/follow_ups_screen.dart';
import 'package:admin/screens/site_visits/site_visits_screen.dart';
import 'package:admin/screens/tasks/tasks_screen.dart';
import 'package:admin/screens/team_members/team_members_screen.dart';
import 'package:admin/screens/communication/communication_screen.dart';
import 'package:admin/screens/documents/documents_screen.dart';
import 'package:admin/screens/invoices/invoices_screen.dart';
import 'package:admin/screens/reports/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/providers/portal_auth_provider.dart';

import 'components/side_menu.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Start with Dashboard

  final List<Widget> _screens = [
    const DashboardScreen(),
    const LeadsScreen(),
    const CustomersScreen(),
    const ClientsScreen(),
    const ProjectsScreen(),
    const QuotationsScreen(),
    const ContractsScreen(),
    const FollowUpsScreen(),
    const SiteVisitsScreen(),
    const TasksScreen(),
    const TeamMembersScreen(),
    const CommunicationScreen(),
    const DocumentsScreen(),
    const InvoicesScreen(),
    const ReportsScreen(),
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
        return 'Clients';
      case 4:
        return 'Projects';
      case 5:
        return 'Quotations';
      case 6:
        return 'Contracts';
      case 7:
        return 'Follow Ups';
      case 8:
        return 'Site Visits';
      case 9:
        return 'Tasks';
      case 10:
        return 'Team Members';
      case 11:
        return 'Communication';
      case 12:
        return 'Documents';
      case 13:
        return 'Invoices';
      case 14:
        return 'Reports';
      default:
        return 'Dashboard';
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
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  context.read<MenuAppController>().controlMenu();
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    final authProvider =
                        Provider.of<PortalAuthProvider>(context, listen: false);
                    await authProvider.logout();
                  },
                  tooltip: 'Logout',
                ),
              ],
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
    );
  }
}
