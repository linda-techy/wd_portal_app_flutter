import 'package:flutter/foundation.dart';

/// Permission Provider for Role-Based Access Control (RBAC)
/// 
/// This provider manages user permissions and provides helper methods
/// to check if a user has specific permissions.
/// 
/// Key Features:
/// - Stores user permissions from login response
/// - Provides permission checking methods
/// - Handles ADMIN role bypass (ADMIN sees everything)
/// - Module-level permission helpers (VIEW, CREATE, EDIT, DELETE)
class PermissionProvider with ChangeNotifier {
  List<String> _permissions = [];
  bool _isAdmin = false;
  String _roleCode = '';

  // Getters
  List<String> get permissions => List.unmodifiable(_permissions);
  bool get isAdmin => _isAdmin;
  String get roleCode => _roleCode;

  /// Set permissions from login response
  void setPermissions(List<String> permissions, String roleCode) {
    final normalizedRoleCode = roleCode;
    final normalizedPermissions = List<String>.from(permissions);
    final nextIsAdmin = normalizedRoleCode.toUpperCase() == 'ADMIN' ||
        normalizedRoleCode.toUpperCase() == 'ROLE_ADMIN';

    final hasRoleChanged = _roleCode != normalizedRoleCode;
    final hasAdminChanged = _isAdmin != nextIsAdmin;
    final hasPermissionsChanged =
        _permissions.length != normalizedPermissions.length ||
            !_permissions.every(normalizedPermissions.contains);

    if (!hasRoleChanged && !hasAdminChanged && !hasPermissionsChanged) {
      return;
    }

    _permissions = normalizedPermissions;
    _roleCode = normalizedRoleCode;
    _isAdmin = nextIsAdmin;
    notifyListeners();
  }

  /// Clear permissions (on logout)
  void clearPermissions() {
    if (_permissions.isEmpty && !_isAdmin && _roleCode.isEmpty) {
      return;
    }
    _permissions = [];
    _isAdmin = false;
    _roleCode = '';
    notifyListeners();
  }

  /// Check if user has a specific permission
  /// ADMIN always returns true
  bool hasPermission(String permission) {
    if (_isAdmin) return true;
    return _permissions.contains(permission);
  }

  /// Check if user has ANY of the specified permissions
  /// ADMIN always returns true
  bool hasAnyPermission(List<String> permissionList) {
    if (_isAdmin) return true;
    return permissionList.any((permission) => _permissions.contains(permission));
  }

  /// Check if user has ALL of the specified permissions
  /// ADMIN always returns true
  bool hasAllPermissions(List<String> permissionList) {
    if (_isAdmin) return true;
    return permissionList.every((permission) => _permissions.contains(permission));
  }

  /// Check if user can VIEW a module
  /// Module menu should be visible only if this returns true
  bool canView(String module) {
    return hasPermission('${module.toUpperCase()}_VIEW');
  }

  /// Check if user can CREATE in a module
  bool canCreate(String module) {
    return hasPermission('${module.toUpperCase()}_CREATE');
  }

  /// Check if user can EDIT in a module
  bool canEdit(String module) {
    return hasPermission('${module.toUpperCase()}_EDIT');
  }

  /// Check if user can DELETE in a module
  bool canDelete(String module) {
    return hasPermission('${module.toUpperCase()}_DELETE');
  }

  /// Check if user can EXPORT from a module
  bool canExport(String module) {
    return hasPermission('${module.toUpperCase()}_EXPORT');
  }

  /// Get all permissions as a debug string
  String getPermissionsDebug() {
    if (_isAdmin) {
      return 'ADMIN (All Permissions)';
    }
    return _permissions.join(', ');
  }

  /// Module-specific permission checks with better naming
  
  // Dashboard permissions
  bool get canViewDashboard => canView('DASHBOARD');
  bool get canFilterDashboard => hasPermission('DASHBOARD_FILTER');
  bool get canExportDashboard => canExport('DASHBOARD');
  
  // Lead permissions
  bool get canViewLeads => canView('LEAD');
  bool get canCreateLead => canCreate('LEAD');
  bool get canEditLead => canEdit('LEAD');
  bool get canDeleteLead => canDelete('LEAD');
  bool get canExportLeads => canExport('LEAD');
  
  // Project permissions
  bool get canViewProjects => canView('PROJECT');
  bool get canCreateProject => canCreate('PROJECT');
  bool get canEditProject => canEdit('PROJECT');
  bool get canDeleteProject => canDelete('PROJECT');
  
  // Task permissions
  bool get canViewTasks => canView('TASK');
  bool get canCreateTask => canCreate('TASK');
  bool get canEditTask => canEdit('TASK');
  bool get canDeleteTask => canDelete('TASK');
  
  // Customer permissions
  bool get canViewCustomers => canView('CUSTOMER');
  bool get canCreateCustomer => canCreate('CUSTOMER');
  bool get canEditCustomer => canEdit('CUSTOMER');
  bool get canDeleteCustomer => canDelete('CUSTOMER');
  
  // Portal User permissions
  bool get canViewPortalUsers => canView('PORTAL_USER');
  bool get canCreatePortalUser => canCreate('PORTAL_USER');
  bool get canEditPortalUser => canEdit('PORTAL_USER');
  bool get canDeletePortalUser => canDelete('PORTAL_USER');

  // Reports permissions
  bool get canViewReports => canView('REPORT');
  bool get canExportReports => canExport('REPORT');

  // Finance permissions
  bool get canViewFinance => canView('FINANCE');
  bool get canCreateFinance => canCreate('FINANCE');
  bool get canEditFinance => canEdit('FINANCE');

  // Payment permissions
  bool get canViewPayments => canView('PAYMENT');
  bool get canCreatePayment => canCreate('PAYMENT');
  bool get canEditPayment => canEdit('PAYMENT');
  bool get canApprovePayment => hasPermission('PAYMENT_APPROVE');

  // BOQ permissions
  bool get canViewBoq => canView('BOQ');
  bool get canCreateBoq => canCreate('BOQ');
  bool get canEditBoq => canEdit('BOQ');
  bool get canDeleteBoq => canDelete('BOQ');
  bool get canApproveBoq => hasPermission('BOQ_APPROVE');
  bool get canSubmitBoqDoc => hasPermission('BOQ_APPROVE');
  bool get canCustomerApproveBoq => hasPermission('BOQ_APPROVE');
  bool get canCorrectBoq => hasPermission('BOQ_CORRECT');

  // Estimation Settings permissions
  bool get canManageEstimationSettings => hasPermission('ESTIMATION_SETTINGS_MANAGE');
  bool get canPublishMarketIndex => hasPermission('ESTIMATION_MARKET_INDEX_PUBLISH');

  // DPC (Detailed Project Costing) permissions
  bool get canViewDpc => hasPermission('DPC_VIEW');
  bool get canCreateDpc => hasPermission('DPC_CREATE');
  bool get canEditDpc => hasPermission('DPC_EDIT');
  bool get canIssueDpc => hasPermission('DPC_ISSUE');
  bool get canManageDpcTemplates => hasPermission('DPC_TEMPLATE_MANAGE');
  bool get canViewDpcCustomizationCatalog =>
      hasPermission('DPC_CUSTOMIZATION_CATALOG_VIEW');
  bool get canManageDpcCustomizationCatalog =>
      hasPermission('DPC_CUSTOMIZATION_CATALOG_MANAGE');

  // Site Report permissions
  bool get canViewSiteReports => canView('SITE_REPORT');
  bool get canCreateSiteReport => canCreate('SITE_REPORT');
  bool get canEditSiteReport => canEdit('SITE_REPORT');

  // Gallery permissions
  bool get canViewGallery => canView('GALLERY');
  bool get canCreateGallery => canCreate('GALLERY');
  bool get canDeleteGallery => canDelete('GALLERY');

  // Labour permissions
  bool get canViewLabour => canView('LABOUR');
  bool get canCreateLabour => canCreate('LABOUR');
  bool get canEditLabour => canEdit('LABOUR');

  // Procurement permissions
  bool get canViewProcurement => canView('PROCUREMENT');
  bool get canCreateProcurement => canCreate('PROCUREMENT');
  bool get canEditProcurement => canEdit('PROCUREMENT');
  bool get canApproveProcurement => hasPermission('PROCUREMENT_APPROVE');

  // Inventory permissions
  bool get canViewInventory => canView('INVENTORY');
  bool get canCreateInventory => canCreate('INVENTORY');
  bool get canEditInventory => canEdit('INVENTORY');
  bool get canDeleteInventory => canDelete('INVENTORY');

  // QC permissions
  bool get canViewQc => canView('QC');
  bool get canCreateQc => canCreate('QC');
  bool get canEditQc => canEdit('QC');

  // Observation permissions
  bool get canViewObservations => canView('OBSERVATION');
  bool get canCreateObservation => canCreate('OBSERVATION');
  bool get canEditObservation => canEdit('OBSERVATION');

  // Snag permissions
  bool get canViewSnags => canView('SNAG');
  bool get canCreateSnag => canCreate('SNAG');
  bool get canEditSnag => canEdit('SNAG');

  // Query permissions
  bool get canViewQueries => canView('QUERY');
  bool get canCreateQuery => canCreate('QUERY');
  bool get canEditQuery => canEdit('QUERY');

  // Attendance permissions
  bool get canViewAttendance => canView('ATTENDANCE');
  bool get canCreateAttendance => canCreate('ATTENDANCE');
  bool get canEditAttendance => canEdit('ATTENDANCE');

  // Notification permissions
  bool get canViewNotifications => canView('NOTIFICATION');

  /// Human-readable display name for the current role
  String get roleDisplayName {
    const Map<String, String> roleNames = {
      'ADMIN': 'Administrator',
      'PROJECT_MANAGER': 'Project Manager',
      'SITE_ENGINEER': 'Site Engineer',
      'PROCUREMENT_OFFICER': 'Procurement Officer',
      'INVENTORY_MANAGER': 'Inventory Manager',
      'FINANCE_OFFICER': 'Finance Officer',
      'HR_MANAGER': 'HR Manager',
      'SALES': 'Sales Team Member',
      'QUALITY_SAFETY': 'Quality & Safety Officer',
      'EMPLOYEE': 'Employee',
      'SITE_SUPERVISOR': 'Site Supervisor',
      'ESTIMATOR': 'Estimator / Quantity Surveyor',
      'ARCHITECT_DESIGNER': 'Architect / Designer',
      'VISUALIZER': '3D Visualizer',
      'STRUCTURAL_ENGINEER': 'Structural Engineer',
      'INTERIOR_DESIGNER': 'Interior Designer',
      'PURCHASE_ASSISTANT': 'Purchase Assistant',
      'ACCOUNTS_ASSISTANT': 'Accounts Assistant',
      'ADMIN_EXECUTIVE': 'Admin Executive',
      'CLIENT_COORDINATOR': 'Client Coordinator',
      'MARKETING': 'Marketing Executive',
      'CRM': 'CRM Executive',
      'IT_ADMIN': 'IT / Systems Administrator',
      'DRAFTSMAN': 'Draftsman',
      'FOREMAN': 'Foreman',
      'MEP_SUPERVISOR': 'MEP Supervisor',
      'INTERN': 'Intern / Trainee',
      // Legacy codes
      'USER': 'User',
      'PM': 'Project Manager',
      'SALES_MANAGER': 'Sales Manager',
      'PROCUREMENT_MANAGER': 'Procurement Manager',
    };
    return roleNames[_roleCode.toUpperCase()] ?? _roleCode;
  }
}
