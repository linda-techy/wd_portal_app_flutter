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
  final int projectCount;

  // Business Fields
  final String? phone;
  final String? whatsappNumber;
  final String? address;
  final String? companyName;
  final String? gstNumber;
  final String? leadSource;
  final String? notes;

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
    this.projectCount = 0,
    this.phone,
    this.whatsappNumber,
    this.address,
    this.companyName,
    this.gstNumber,
    this.leadSource,
    this.notes,
  });

  String get fullName => '$firstName $lastName'.trim();

  /// Whether the customer account is active (alias for enabled).
  bool get isActive => enabled;

  /// Primary contact phone (phone preferred, fallback to whatsapp).
  String? get primaryPhone => phone ?? whatsappNumber;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
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
              : int.tryParse(
                  json['role_id']?.toString() ??
                      json['roleId']?.toString() ??
                      ''),
      projectCount: json['project_count'] is int
          ? json['project_count']
          : int.tryParse(json['project_count']?.toString() ?? '0') ?? 0,
      phone: json['phone'],
      whatsappNumber: json['whatsapp_number'] ?? json['whatsappNumber'],
      address: json['address'],
      companyName: json['company_name'] ?? json['companyName'],
      gstNumber: json['gst_number'] ?? json['gstNumber'],
      leadSource: json['lead_source'] ?? json['leadSource'],
      notes: json['notes'],
    );
  }

  /// Serialise for both create and update — password omitted when null/empty.
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'enabled': enabled,
      'first_name': firstName,
      'last_name': lastName,
      if (password != null && password!.isNotEmpty) 'password': password,
      if (roleId != null) 'role_id': roleId,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (whatsappNumber != null && whatsappNumber!.isNotEmpty)
        'whatsapp_number': whatsappNumber,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (companyName != null && companyName!.isNotEmpty)
        'company_name': companyName,
      if (gstNumber != null && gstNumber!.isNotEmpty) 'gst_number': gstNumber,
      if (leadSource != null && leadSource!.isNotEmpty)
        'lead_source': leadSource,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  /// Alias kept for call-site compatibility.
  Map<String, dynamic> toCreateJson() => toJson();

  /// Alias kept for call-site compatibility.
  Map<String, dynamic> toUpdateJson() => toJson();

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
    int? projectCount,
    String? phone,
    String? whatsappNumber,
    String? address,
    String? companyName,
    String? gstNumber,
    String? leadSource,
    String? notes,
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
      projectCount: projectCount ?? this.projectCount,
      phone: phone ?? this.phone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      address: address ?? this.address,
      companyName: companyName ?? this.companyName,
      gstNumber: gstNumber ?? this.gstNumber,
      leadSource: leadSource ?? this.leadSource,
      notes: notes ?? this.notes,
    );
  }
}
