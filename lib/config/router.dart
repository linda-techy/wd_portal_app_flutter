import 'package:admin/controllers/menu_app_controller.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/screens/auth/portal_login_screen.dart';
import 'package:admin/screens/main/main_screen.dart';
import 'package:admin/utils/navigation_service.dart';
import 'package:admin/widgets/splash_screen.dart';

// ── Module screens ───────────────────────────────────────────────────────────
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
import 'package:admin/screens/tasks/task_list_screen.dart';
import 'package:admin/screens/team_members/team_members_screen.dart';
import 'package:admin/screens/communication/communication_screen.dart';
import 'package:admin/screens/documents/document_management_screen.dart';
import 'package:admin/screens/payments/payments_dashboard_screen.dart';
import 'package:admin/screens/reports/reports_screen.dart';
import 'package:admin/screens/profile/profile_screen.dart';
import 'package:admin/screens/payments/challan_management_screen.dart';
import 'package:admin/screens/procurement/procurement_dashboard_screen.dart';
import 'package:admin/screens/labour/labour_dashboard_screen.dart';
import 'package:admin/screens/inventory/inventory_dashboard_screen.dart';
import 'package:admin/screens/finance/finance_dashboard_screen.dart';
import 'package:admin/features/partnerships/presentation/screens/partnerships_admin_screen.dart';
import 'package:admin/screens/acl/acl_screen.dart';
import 'package:admin/screens/auth/forgot_password_screen.dart';
import 'package:admin/screens/auth/reset_password_screen.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// ── Route path → menu index mapping ─────────────────────────────────────────
const Map<String, int> kPathToMenuIndex = {
  '/':             0,
  '/leads':        1,
  '/customers':    2,
  '/cx-projects':  3,
  '/users':        4,
  '/clients':      5,
  '/projects':     6,
  '/quotations':   7,
  '/contracts':    8,
  '/follow-ups':   9,
  '/site-visits':  10,
  '/tasks':        11,
  '/team':         12,
  '/communication':13,
  '/documents':    14,
  '/payments':     15,
  '/reports':      16,
  '/profile':      17,
  '/challans':     18,
  '/procurement':  19,
  '/labour':       20,
  '/inventory':    21,
  '/finance':      22,
  '/partnerships': 23,
  '/acl':          24,
};

/// Map a menu index (from [MenuAppController]) to its route path.
const List<String> kIndexToPath = [
  '/', '/leads', '/customers', '/cx-projects', '/users', '/clients',
  '/projects', '/quotations', '/contracts', '/follow-ups', '/site-visits',
  '/tasks', '/team', '/communication', '/documents', '/payments',
  '/reports', '/profile', '/challans', '/procurement', '/labour',
  '/inventory', '/finance', '/partnerships', '/acl',
];

String indexToPath(int index) =>
    (index >= 0 && index < kIndexToPath.length) ? kIndexToPath[index] : '/';

// ── Router factory ───────────────────────────────────────────────────────────
/// Create the [GoRouter] for the app.
/// [authProvider] must be the same instance registered in [MultiProvider] so
/// [refreshListenable] triggers redirects on auth state changes.
GoRouter buildAppRouter(PortalAuthProvider authProvider) {
  return GoRouter(
    navigatorKey: NavigationService.navigatorKey,
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final auth = context.read<PortalAuthProvider>();
      if (auth.isLoading) return '/loading';

      final onLogin = state.matchedLocation == '/login';
      final onLoading = state.matchedLocation == '/loading';
      final onForgotPassword = state.matchedLocation == '/forgot-password';
      final onResetPassword = state.matchedLocation.startsWith('/reset-password');

      if (!auth.isAuthenticated) {
        return (onLogin || onLoading || onForgotPassword || onResetPassword)
            ? null
            : '/login';
      }
      // Authenticated
      if (onLogin || onLoading) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const PortalLoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),

      // ── Authenticated shell ─────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          // Sync MenuAppController with the active route so SideMenu
          // highlights the correct item when navigating via URL.
          final index = kPathToMenuIndex[state.matchedLocation] ?? 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.read<MenuAppController>().setSelectedIndex(index);
            }
          });
          return MainScreen(child: child);
        },
        routes: [
          GoRoute(path: '/',             builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/leads',        builder: (_, __) => const LeadsScreen()),
          GoRoute(path: '/customers',    builder: (_, __) => const CustomersScreen()),
          GoRoute(path: '/cx-projects',  builder: (_, __) => const CustomerProjectsScreen()),
          GoRoute(path: '/users',        builder: (_, __) => const PortalUsersScreen()),
          GoRoute(path: '/clients',      builder: (_, __) => const ClientsScreen()),
          GoRoute(path: '/projects',     builder: (_, __) => const ProjectsScreen()),
          GoRoute(path: '/quotations',   builder: (_, __) => const QuotationsScreen()),
          GoRoute(path: '/contracts',    builder: (_, __) => const ContractsScreen()),
          GoRoute(path: '/follow-ups',   builder: (_, __) => const FollowUpsScreen()),
          GoRoute(path: '/site-visits',  builder: (_, __) => const SiteVisitsScreen()),
          GoRoute(path: '/tasks',        builder: (_, __) => const TaskListScreen()),
          GoRoute(path: '/team',         builder: (_, __) => const TeamMembersScreen()),
          GoRoute(path: '/communication',builder: (_, __) => const CommunicationScreen()),
          GoRoute(path: '/documents',    builder: (_, __) => const DocumentManagementScreen()),
          GoRoute(path: '/payments',     builder: (_, __) => const PaymentsDashboardScreen()),
          GoRoute(path: '/reports',      builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/profile',      builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/challans',     builder: (_, __) => const ChallanManagementScreen()),
          GoRoute(path: '/procurement',  builder: (_, __) => const ProcurementDashboardScreen()),
          GoRoute(path: '/labour',       builder: (_, __) => const LabourDashboardScreen()),
          GoRoute(path: '/inventory',    builder: (_, __) => const InventoryDashboardScreen()),
          GoRoute(path: '/finance',      builder: (_, __) => const FinanceDashboardScreen()),
          GoRoute(path: '/partnerships', builder: (_, __) => const PartnershipsAdminScreen()),
          GoRoute(path: '/acl',          builder: (_, __) => const AclScreen()),
        ],
      ),
    ],
  );
}
