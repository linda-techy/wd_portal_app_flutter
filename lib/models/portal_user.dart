class PortalUser {
  final int? id;
  final String email;
  final bool enabled;
  final String firstName;
  final String lastName;
  final String? password; // Only for create/update, not returned from API
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? roleId;

  // Contact + role details — the API accepts these on both create and update,
  // but the portal admin forms previously didn't expose them, so admins could
  // not set phone / WhatsApp / designation / department from the UI.
  final String? phone;
  final String? whatsapp;
  final String? designation;
  final String? department;

  PortalUser({
    this.id,
    required this.email,
    this.enabled = true,
    required this.firstName,
    required this.lastName,
    this.password,
    this.createdAt,
    this.updatedAt,
    this.roleId,
    this.phone,
    this.whatsapp,
    this.designation,
    this.department,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory PortalUser.fromJson(Map<String, dynamic> json) {
    return PortalUser(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      email: json['email'] ?? '',
      enabled: json['enabled'] ?? true,
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])
              : null,
      roleId: json['role_id'] is int
          ? json['role_id']
          : json['roleId'] is int
              ? json['roleId']
              : int.tryParse(json['role_id']?.toString() ??
                  json['roleId']?.toString() ??
                  ''),
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      designation: json['designation'],
      department: json['department'],
    );
  }

  Map<String, dynamic> _baseJson() {
    return {
      'email': email,
      'enabled': enabled,
      'first_name': firstName,
      'last_name': lastName,
      if (password != null && password!.isNotEmpty) 'password': password,
      if (roleId != null) 'role_id': roleId,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (whatsapp != null && whatsapp!.isNotEmpty) 'whatsapp': whatsapp,
      if (designation != null && designation!.isNotEmpty) 'designation': designation,
      if (department != null && department!.isNotEmpty) 'department': department,
    };
  }

  Map<String, dynamic> toJson() => _baseJson();

  Map<String, dynamic> toCreateJson() => _baseJson();

  Map<String, dynamic> toUpdateJson() {
    final m = _baseJson();
    if (roleId != null) {
      m['role_id'] = roleId is int ? roleId : int.tryParse(roleId.toString());
    }
    return m;
  }

  PortalUser copyWith({
    int? id,
    String? email,
    bool? enabled,
    String? firstName,
    String? lastName,
    String? password,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? roleId,
    String? phone,
    String? whatsapp,
    String? designation,
    String? department,
  }) {
    return PortalUser(
      id: id ?? this.id,
      email: email ?? this.email,
      enabled: enabled ?? this.enabled,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roleId: roleId ?? this.roleId,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      designation: designation ?? this.designation,
      department: department ?? this.department,
    );
  }
}
