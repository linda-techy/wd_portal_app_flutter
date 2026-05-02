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
import 'package:admin/features/projects/presentation/screens/projects_list_screen.dart';
import 'package:admin/screens/portal_users/portal_users_screen.dart';
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
import 'package:admin/screens/support/support_tickets_screen.dart';
import 'package:admin/screens/support/support_ticket_detail_screen.dart';
import 'package:admin/screens/auth/forgot_password_screen.dart';
import 'package:admin/screens/auth/reset_password_screen.dart';
import 'package:admin/features/dpc/presentation/screens/dpc_builder_screen.dart';
import 'package:admin/features/dpc/presentation/screens/dpc_revisions_screen.dart';
import 'package:admin/features/dpc/presentation/screens/dpc_templates_admin_screen.dart';
import 'package:admin/features/dpc/presentation/screens/dpc_template_edit_screen.dart';
import 'package:admin/features/leads/presentation/screens/lead_quotation_detail_screen.dart';
import 'package:admin/features/quotation_catalog/presentation/screens/quotation_catalog_admin_screen.dart';
import 'package:admin/features/dpc_customization_catalog/presentation/screens/dpc_customization_catalog_admin_screen.dart';
import 'package:admin/features/estimation_settings/presentation/screens/estimation_settings_hub_screen.dart';
import 'package:admin/features/estimation_settings/presentation/screens/packages_list_screen.dart';
import 'package:admin/features/estimation_settings/presentation/screens/rate_card_screen.dart';
import 'package:admin/features/estimation_settings/presentation/screens/market_index_screen.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// ── Route path → menu index mapping ─────────────────────────────────────────
const Map<String, int> kPathToMenuIndex = {
  '/':             0,
  '/leads':        1,
  '/customers':    2,
  '/projects':     3,
  '/users':        4,
  '/quotations':   5,
  '/contracts':    6,
  '/follow-ups':   7,
  '/site-visits':  8,
  '/tasks':        9,
  '/team':         10,
  '/communication':11,
  '/documents':    12,
  '/payments':     13,
  '/reports':      14,
  '/profile':      15,
  '/challans':     16,
  '/procurement':  17,
  '/labour':       18,
  '/inventory':    19,
  '/finance':      20,
  '/partnerships': 21,
  '/acl':          22,
  '/support':      23,
  '/dpc/templates':24,
  '/quotation-catalog':25,
  '/dpc-customization-catalog':26,
  '/settings/estimation':     27,
  '/settings/estimation/packages': 28,
  '/settings/estimation/rate-card': 29,
  '/settings/estimation/market-index': 30,
};

/// Map a menu index (from [MenuAppController]) to its route path.
const List<String> kIndexToPath = [
  '/', '/leads', '/customers', '/projects', '/users',
  '/quotations', '/contracts', '/follow-ups', '/site-visits',
  '/tasks', '/team', '/communication', '/documents', '/payments',
  '/reports', '/profile', '/challans', '/procurement', '/labour',
  '/inventory', '/finance', '/partnerships', '/acl', '/support',
  '/dpc/templates',
  '/quotation-catalog',
  '/dpc-customization-catalog',
  '/settings/estimation',
  '/settings/estimation/packages',
  '/settings/estimation/rate-card',
  '/settings/estimation/market-index',
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
        if (onLogin || onForgotPassword || onResetPassword) return null;
        return '/login';
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
          GoRoute(path: '/projects',     builder: (_, __) => const ProjectsListScreen()),
          GoRoute(path: '/users',        builder: (_, __) => const PortalUsersScreen()),
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
          GoRoute(path: '/support',      builder: (_, __) => const SupportTicketsScreen()),
          GoRoute(
            path: '/support/:ticketId',
            builder: (_, state) {
              final ticketId = int.tryParse(state.pathParameters['ticketId'] ?? '') ?? 0;
              return SupportTicketDetailScreen(ticketId: ticketId);
            },
          ),

          // DPC (Detailed Project Costing)
          GoRoute(
            path: '/dpc/builder/:projectId',
            builder: (_, state) {
              final projectId =
                  int.tryParse(state.pathParameters['projectId'] ?? '') ?? 0;
              return DpcBuilderScreen(projectId: projectId);
            },
          ),
          GoRoute(
            path: '/dpc/revisions/:projectId',
            builder: (_, state) {
              final projectId =
                  int.tryParse(state.pathParameters['projectId'] ?? '') ?? 0;
              return DpcRevisionsScreen(projectId: projectId);
            },
          ),
          GoRoute(
            path: '/dpc/templates',
            builder: (_, __) => const DpcTemplatesAdminScreen(),
          ),
          GoRoute(
            path: '/dpc/templates/:id',
            builder: (_, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return DpcTemplateEditScreen(templateId: id);
            },
          ),

          // Quotation detail (deep-linkable per-row route)
          GoRoute(
            path: '/quotations/:id',
            builder: (_, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return LeadQuotationDetailScreen(quotationId: id);
            },
          ),

          // Quotation Item Catalog (admin)
          GoRoute(
            path: '/quotation-catalog',
            builder: (_, __) => const QuotationCatalogAdminScreen(),
          ),

          // DPC Customization Catalog (admin)
          GoRoute(
            path: '/dpc-customization-catalog',
            builder: (_, __) => const DpcCustomizationCatalogAdminScreen(),
          ),

          // Estimation Settings
          GoRoute(
            path: '/settings/estimation',
            builder: (_, __) => const EstimationSettingsHubScreen(),
          ),
          GoRoute(
            path: '/settings/estimation/packages',
            builder: (_, __) => const PackagesListScreen(),
          ),
          GoRoute(
            path: '/settings/estimation/rate-card',
            builder: (_, __) => const RateCardScreen(),
          ),
          GoRoute(
            path: '/settings/estimation/market-index',
            builder: (_, __) => const MarketIndexScreen(),
          ),
        ],
      ),
    ],
  );
}
