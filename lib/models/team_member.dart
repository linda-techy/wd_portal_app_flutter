import 'package:flutter/foundation.dart';

@immutable
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
  final String? type; // "PORTAL" or "CUSTOMER"
  final int? roleId;
  final String? roleName;

  const TeamMember({
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
    this.type,
    this.roleId,
    this.roleName,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id']?.toString(),
      employeeId: json['employeeId']?.toString(),
      firstName: json['first_name'] ?? json['firstName'],
      lastName: json['last_name'] ?? json['lastName'],
      email: json['email'],
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      designation: json['designation'],
      department: json['department'],
      joiningDate: json['joiningDate'] != null
          ? DateTime.tryParse(json['joiningDate'])
          : null,
      // Accept both JSON shapes: is_active (current Portal API) and isActive
      // (older / legacy). Fall back to enabled for PortalUser-shaped rows.
      isActive: json['is_active'] ?? json['isActive'] ?? json['enabled'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      type: json['type'],
      roleId: json['role_id'] != null 
          ? (json['role_id'] is int ? json['role_id'] : int.tryParse(json['role_id'].toString()))
          : null,
      roleName: json['role_name'],
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
      'type': type,
      if (roleId != null) 'role_id': roleId,
      if (roleName != null) 'role_name': roleName,
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
    String? type,
    int? roleId,
    String? roleName,
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
      type: type ?? this.type,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamMember && other.id == id && other.type == type;
  }

  @override
  int get hashCode => Object.hash(id, type);
}
