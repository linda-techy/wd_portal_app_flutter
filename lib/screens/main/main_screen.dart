import 'package:admin/controllers/menu_app_controller.dart';
import 'package:admin/widgets/offline_banner.dart';
import 'package:admin/responsive.dart';
import 'package:admin/constants.dart';
import 'package:admin/screens/dashboard/dashboard_screen.dart';
import 'package:admin/features/leads/presentation/screens/leads_screen.dart';
import 'package:admin/features/customers/presentation/screens/customers_screen.dart';
import 'package:admin/features/projects/presentation/screens/projects_list_screen.dart';
import 'package:admin/screens/portal_users/portal_users_screen.dart';
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
import 'package:admin/features/partnerships/presentation/screens/partnerships_admin_screen.dart';
import 'package:admin/screens/notifications/portal_notification_screen.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/services/portal_notification_service.dart';
import 'package:admin/config/router.dart' show indexToPath;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:admin/theme/responsive_utils.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:badges/badges.dart' as badges;

import 'components/side_menu.dart';

class MainScreen extends StatefulWidget {
  /// When provided by GoRouter's ShellRoute, this widget replaces the
  /// legacy index-based screen lookup. Falls back to [_screens[selectedIndex]]
  /// when null (non-GoRouter usage).
  final Widget? child;

  const MainScreen({super.key, this.child});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _unreadNotificationCount = 0;
  late final PortalNotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = PortalNotificationService(
      Provider.of<ApiService>(context, listen: false),
    );
    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) setState(() => _unreadNotificationCount = count);
    } catch (_) {}
  }

  void _openNotifications(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PortalNotificationScreen(),
      ),
    );
    // Refresh count after returning from notification screen
    await _refreshUnreadCount();
  }

  final List<Widget> _screens = [
    const DashboardScreen(),        // 0
    const LeadsScreen(),            // 1
    const CustomersScreen(),        // 2
    const ProjectsListScreen(),     // 3
    const PortalUsersScreen(),      // 4
    const QuotationsScreen(),       // 5
    const ContractsScreen(),        // 6
    const FollowUpsScreen(),        // 7
    const SiteVisitsScreen(),       // 8
    const TaskListScreen(),         // 9
    const TeamMembersScreen(),      // 10
    const CommunicationScreen(),    // 11
    const DocumentManagementScreen(), // 12
    const PaymentsDashboardScreen(), // 13
    const ReportsScreen(),          // 14
    const ProfileScreen(),          // 15
    const ChallanManagementScreen(), // 16
    const ProcurementDashboardScreen(), // 17
    const LabourDashboardScreen(),  // 18
    const InventoryDashboardScreen(), // 19
    const FinanceDashboardScreen(), // 20
    const PartnershipsAdminScreen(), // 21
  ];

  void _onMenuItemClick(int index) {
    context.read<MenuAppController>().setSelectedIndex(index);
    context.go(indexToPath(index));
  }

  String _getScreenTitle(int index) {
    switch (index) {
      case 0:  return 'Dashboard';
      case 1:  return 'Leads';
      case 2:  return 'Customers';
      case 3:  return 'Customer Projects';
      case 4:  return 'Portal Users';
      case 5:  return 'Quotations';
      case 6:  return 'Contracts';
      case 7:  return 'Follow Ups';
      case 8:  return 'Site Visits';
      case 9:  return 'Tasks';
      case 10: return 'Team Members';
      case 11: return 'Communication';
      case 12: return 'Documents';
      case 13: return 'Payments';
      case 14: return 'Reports';
      case 15: return 'Profile';
      case 16: return 'Challans';
      case 17: return 'Procurement';
      case 18: return 'Labour Management';
      case 19: return 'Inventory Tracking';
      case 20: return 'Finance & Billing';
      case 21: return 'Partnerships & Referrals';
      case 32: return 'Approval Inbox';
      case 33: return 'Pending Sync';
      case 34: return 'My Tasks';
      default: return 'Dashboard';
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
              actions: [
                IconButton(
                  icon: _unreadNotificationCount > 0
                      ? badges.Badge(
                          badgeContent: Text(
                            _unreadNotificationCount > 99
                                ? '99+'
                                : '$_unreadNotificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          badgeStyle: const badges.BadgeStyle(
                            badgeColor: AppTheme.coralRed,
                          ),
                          child: const Icon(Icons.notifications_outlined),
                        )
                      : const Icon(Icons.notifications_outlined),
                  onPressed: () => _openNotifications(context),
                ),
              ],
            ),
      drawer: Drawer(
        child: SideMenu(
          onMenuItemClick: _onMenuItemClick,
          selectedIndex: selectedIndex,
          isDrawer: true,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
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
                            child: widget.child ?? _screens[selectedIndex],
                          ),
                        ),
                      ],
                    )
                  : (widget.child ?? _screens[selectedIndex]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ResponsiveUtils.isMobile(context) || ResponsiveUtils.isTablet(context)
          ? BottomNavigationBar(
              backgroundColor: Colors.white,
              selectedItemColor:AppTheme.primaryBlue,
              unselectedItemColor: AppTheme.textTertiary,
              currentIndex: selectedIndex == 3 ? 1 : selectedIndex == 15 ? 2 : 0,
              onTap: (index) {
                // Map bottom nav indices
                // 0 -> Open Menu, 1 -> Projects (3), 2 -> Profile (15)
                if (index == 0) {
                  // Open drawer/menu
                  context.read<MenuAppController>().controlMenu();
                } else {
                  final screenIndex = index == 1 ? 3 : 15;
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

