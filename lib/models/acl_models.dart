// Data models for the ACL (Access Control) feature.
// Maps to AclController DTOs:
//   GET /acl/roles          → List<AclRole>
//   GET /acl/roles/{id}     → AclRoleDetail
//   GET /acl/permissions    → List<AclModuleGroup>
//   GET /acl/role-templates → List<AclRoleTemplate>

// ─────────────────────────────────────────────────────────────────────────────
// Role list item
// ─────────────────────────────────────────────────────────────────────────────

class AclRole {
  final int id;
  final String name;
  final String code;
  final String? description;
  final int permissionCount;

  const AclRole({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.permissionCount,
  });

  factory AclRole.fromJson(Map<String, dynamic> json) => AclRole(
        id: json['id'] is int
            ? json['id'] as int
            : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        name: json['name'] as String? ?? '',
        code: json['code'] as String? ?? '',
        description: json['description'] as String?,
        permissionCount: json['permissionCount'] as int? ?? 0,
      );

  bool get isAdmin => code.toUpperCase() == 'ADMIN';
}

// ─────────────────────────────────────────────────────────────────────────────
// Role detail with permission names
// ─────────────────────────────────────────────────────────────────────────────

class AclRoleDetail {
  final int id;
  final String name;
  final String code;
  final String? description;
  final List<String> permissionNames;

  const AclRoleDetail({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.permissionNames,
  });

  factory AclRoleDetail.fromJson(Map<String, dynamic> json) => AclRoleDetail(
        id: json['id'] is int
            ? json['id'] as int
            : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        name: json['name'] as String? ?? '',
        code: json['code'] as String? ?? '',
        description: json['description'] as String?,
        permissionNames: (json['permissionNames'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );

  bool get isAdmin => code.toUpperCase() == 'ADMIN';
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual permission
// ─────────────────────────────────────────────────────────────────────────────

class AclPermission {
  final int id;
  final String name;
  final String? description;

  const AclPermission({
    required this.id,
    required this.name,
    this.description,
  });

  factory AclPermission.fromJson(Map<String, dynamic> json) => AclPermission(
        id: json['id'] is int
            ? json['id'] as int
            : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
      );

  /// Returns the action label (VIEW, CREATE, EDIT, DELETE, APPROVE, EXPORT, FILTER)
  String get actionLabel {
    const actions = ['APPROVE', 'EXPORT', 'FILTER', 'DELETE', 'CREATE', 'EDIT', 'VIEW'];
    for (final action in actions) {
      if (name.endsWith('_$action')) return action;
    }
    return name;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Permission module group
// ─────────────────────────────────────────────────────────────────────────────

class AclModuleGroup {
  final String module;
  final String displayName;
  final List<AclPermission> permissions;

  const AclModuleGroup({
    required this.module,
    required this.displayName,
    required this.permissions,
  });

  factory AclModuleGroup.fromJson(Map<String, dynamic> json) => AclModuleGroup(
        module: json['module'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        permissions: (json['permissions'] as List?)
                ?.map((p) =>
                    AclPermission.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Role template (predefined permission set)
// ─────────────────────────────────────────────────────────────────────────────

class AclRoleTemplate {
  final String roleCode;
  final String displayName;
  final String description;
  final List<String> permissionNames;

  const AclRoleTemplate({
    required this.roleCode,
    required this.displayName,
    required this.description,
    required this.permissionNames,
  });

  factory AclRoleTemplate.fromJson(Map<String, dynamic> json) =>
      AclRoleTemplate(
        roleCode: json['roleCode'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        description: json['description'] as String? ?? '',
        permissionNames: (json['permissionNames'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}
