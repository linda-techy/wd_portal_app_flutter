class Client {
  final String? id;
  final String? clientCode;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? source;
  final String? assignedTo;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Client({
    this.id,
    this.clientCode,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.whatsapp,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.source,
    this.assignedTo,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      clientCode: json['clientCode'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      source: json['source'],
      assignedTo: json['assignedTo'],
      status: json['status'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientCode': clientCode,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'source': source,
      'assignedTo': assignedTo,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Client copyWith({
    String? id,
    String? clientCode,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? whatsapp,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? source,
    String? assignedTo,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      clientCode: clientCode ?? this.clientCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      source: source ?? this.source,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
