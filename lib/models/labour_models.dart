class Labour {
  final int? id;
  final String name;
  final String phone;
  final String tradeType;
  final String? idProofType;
  final String? idProofNumber;
  final double dailyWage;
  final String? emergencyContact;
  final bool active;

  Labour({
    this.id,
    required this.name,
    required this.phone,
    required this.tradeType,
    this.idProofType,
    this.idProofNumber,
    required this.dailyWage,
    this.emergencyContact,
    this.active = true,
  });

  factory Labour.fromJson(Map<String, dynamic> json) {
    return Labour(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      tradeType: json['tradeType'],
      idProofType: json['idProofType'],
      idProofNumber: json['idProofNumber'],
      dailyWage: (json['dailyWage'] as num).toDouble(),
      emergencyContact: json['emergencyContact'],
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'tradeType': tradeType,
      'idProofType': idProofType,
      'idProofNumber': idProofNumber,
      'dailyWage': dailyWage,
      'emergencyContact': emergencyContact,
      'active': active,
    };
  }
}

class LabourAttendance {
  final int? id;
  final int projectId;
  final int labourId;
  final String? labourName;
  final String attendanceDate; // ISO Date
  final String status; // PRESENT, ABSENT, HALF_DAY
  final double? hoursWorked;

  LabourAttendance({
    this.id,
    required this.projectId,
    required this.labourId,
    this.labourName,
    required this.attendanceDate,
    required this.status,
    this.hoursWorked,
  });

  factory LabourAttendance.fromJson(Map<String, dynamic> json) {
    return LabourAttendance(
      id: json['id'],
      projectId: json['projectId'],
      labourId: json['labourId'],
      labourName: json['labourName'],
      attendanceDate: json['attendanceDate'],
      status: json['status'],
      hoursWorked: json['hoursWorked']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'projectId': projectId,
      'labourId': labourId,
      'attendanceDate': attendanceDate,
      'status': status,
      if (hoursWorked != null) 'hoursWorked': hoursWorked,
    };
  }
}

class MeasurementBook {
  final int? id;
  final int projectId;
  final int? labourId;
  final int? boqItemId;
  final String description;
  final String measurementDate;
  final double length;
  final double breadth;
  final double depth;
  final double quantity;
  final String unit;
  final double rate;
  final double totalAmount;

  MeasurementBook({
    this.id,
    required this.projectId,
    this.labourId,
    this.boqItemId,
    required this.description,
    required this.measurementDate,
    required this.length,
    required this.breadth,
    required this.depth,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.totalAmount,
  });

  factory MeasurementBook.fromJson(Map<String, dynamic> json) {
    return MeasurementBook(
      id: json['id'],
      projectId: json['projectId'],
      labourId: json['labourId'],
      boqItemId: json['boqItemId'],
      description: json['description'],
      measurementDate: json['measurementDate'],
      length: (json['length'] as num).toDouble(),
      breadth: (json['breadth'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
      rate: (json['rate'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'projectId': projectId,
      if (labourId != null) 'labourId': labourId,
      if (boqItemId != null) 'boqItemId': boqItemId,
      'description': description,
      'measurementDate': measurementDate,
      'length': length,
      'breadth': breadth,
      'depth': depth,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'totalAmount': totalAmount,
    };
  }
}
