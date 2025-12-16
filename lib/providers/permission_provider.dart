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
    _permissions = permissions;
    _roleCode = roleCode;
    _isAdmin = roleCode.toUpperCase() == 'ADMIN' || roleCode.toUpperCase() == 'ROLE_ADMIN';
    notifyListeners();
  }

  /// Clear permissions (on logout)
  void clearPermissions() {
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
}
