class TeamMember {
  final String? id;
  final String? employeeId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? designation;
  final String? department;
  final DateTime? joiningDate;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TeamMember({
    this.id,
    this.employeeId,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.whatsapp,
    this.designation,
    this.department,
    this.joiningDate,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'],
      employeeId: json['employeeId'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      designation: json['designation'],
      department: json['department'],
      joiningDate: json['joiningDate'] != null
          ? DateTime.parse(json['joiningDate'])
          : null,
      isActive: json['isActive'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'designation': designation,
      'department': department,
      'joiningDate': joiningDate?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  TeamMember copyWith({
    String? id,
    String? employeeId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? whatsapp,
    String? designation,
    String? department,
    DateTime? joiningDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamMember(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      joiningDate: joiningDate ?? this.joiningDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
