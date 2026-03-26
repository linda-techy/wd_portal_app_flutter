import 'package:admin/models/acl_models.dart';
import 'package:admin/services/api_service.dart';

/// Service for ACL (Access Control) API calls.
/// Wraps the portal-api /acl/* endpoints.
class AclService {
  static final AclService _instance = AclService._internal();
  factory AclService() => _instance;
  AclService._internal();

  final ApiService _apiService = ApiService();

  // ── Roles ──────────────────────────────────────────────────────────────────

  /// Fetch all portal roles with permission count.
  Future<List<AclRole>> getRoles() async {
    final response = await _apiService.get('/acl/roles');
    return _apiService.unwrapList<AclRole>(
        response, (json) => AclRole.fromJson(json));
  }

  /// Fetch a single role with its full permission name list.
  Future<AclRoleDetail> getRoleDetail(int id) async {
    final response = await _apiService.get('/acl/roles/$id');
    return _apiService.unwrap<AclRoleDetail>(
        response, (json) => AclRoleDetail.fromJson(json as Map<String, dynamic>));
  }

  /// Bulk-replace permissions for a role.
  /// Returns the updated role detail.
  Future<AclRoleDetail> updateRolePermissions(
      int roleId, List<int> permissionIds) async {
    final response = await _apiService.put(
      '/acl/roles/$roleId/permissions',
      data: {'permissionIds': permissionIds},
    );
    return _apiService.unwrap<AclRoleDetail>(
        response, (json) => AclRoleDetail.fromJson(json as Map<String, dynamic>));
  }

  // ── Permissions ────────────────────────────────────────────────────────────

  /// Fetch all permissions grouped by module.
  Future<List<AclModuleGroup>> getPermissionsGrouped() async {
    final response = await _apiService.get('/acl/permissions');
    return _apiService.unwrapList<AclModuleGroup>(
        response, (json) => AclModuleGroup.fromJson(json));
  }

  // ── Templates ─────────────────────────────────────────────────────────────

  /// Fetch predefined role permission templates.
  Future<List<AclRoleTemplate>> getRoleTemplates() async {
    final response = await _apiService.get('/acl/role-templates');
    return _apiService.unwrapList<AclRoleTemplate>(
        response, (json) => AclRoleTemplate.fromJson(json));
  }
}
