class Customer {
  final int? id;
  final String email;
  final bool enabled;
  final String firstName;
  final String lastName;
  final String? password; // Only for create/update, not returned from API
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? roleId;

  Customer({
    this.id,
    required this.email,
    this.enabled = true,
    required this.firstName,
    required this.lastName,
    this.password,
    this.createdAt,
    this.updatedAt,
    this.roleId,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
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
              : int.tryParse(json['role_id']?.toString() ?? json['roleId']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'enabled': enabled,
      'first_name': firstName,
      'last_name': lastName,
      if (password != null && password!.isNotEmpty) 'password': password,
      if (roleId != null) 'role_id': roleId,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'email': email,
      'enabled': enabled,
      'first_name': firstName,
      'last_name': lastName,
      if (password != null && password!.isNotEmpty) 'password': password,
      if (roleId != null) 'role_id': roleId,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'email': email,
      'enabled': enabled,
      'first_name': firstName,
      'last_name': lastName,
      if (password != null && password!.isNotEmpty) 'password': password,
      if (roleId != null) 'role_id': roleId is int ? roleId : int.tryParse(roleId.toString()),
    };
  }

  Customer copyWith({
    int? id,
    String? email,
    bool? enabled,
    String? firstName,
    String? lastName,
    String? password,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? roleId,
  }) {
    return Customer(
      id: id ?? this.id,
      email: email ?? this.email,
      enabled: enabled ?? this.enabled,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roleId: roleId ?? this.roleId,
    );
  }
}

