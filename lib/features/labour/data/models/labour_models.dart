class Labour {
  final int id;
  final String name;
  final String phone;
  final String tradeType;
  final double dailyWage;
  final bool active;

  Labour({
    required this.id,
    required this.name,
    required this.phone,
    required this.tradeType,
    required this.dailyWage,
    required this.active,
  });

  factory Labour.fromJson(Map<String, dynamic> json) {
    return Labour(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      tradeType: json['tradeType'] ?? 'HELPER',
      dailyWage: (json['dailyWage'] as num).toDouble(),
      active: json['active'] ?? true,
    );
  }
}

class WageSheet {
  final int id;
  final String sheetNumber;
  final int projectId;
  final String periodStart;
  final String periodEnd;
  final double totalAmount;
  final String status;
  final List<WageSheetEntry> entries;

  WageSheet({
    required this.id,
    required this.sheetNumber,
    required this.projectId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalAmount,
    required this.status,
    required this.entries,
  });

  factory WageSheet.fromJson(Map<String, dynamic> json) {
    var list = json['entries'] as List? ?? [];
    List<WageSheetEntry> entriesList = list.map((i) => WageSheetEntry.fromJson(i)).toList();

    return WageSheet(
      id: json['id'],
      sheetNumber: json['sheetNumber'],
      projectId: json['project'] != null ? json['project']['id'] : 0, // Simplified mapping
      periodStart: json['periodStart'],
      periodEnd: json['periodEnd'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'],
      entries: entriesList,
    );
  }
}

class WageSheetEntry {
  final int id;
  final int labourId;
  final String labourName;
  final double daysWorked;
  final double dailyWage;
  final double totalWage;
  final double advancesDeducted;
  final double netPayable;

  WageSheetEntry({
    required this.id,
    required this.labourId,
    required this.labourName,
    required this.daysWorked,
    required this.dailyWage,
    required this.totalWage,
    required this.advancesDeducted,
    required this.netPayable,
  });

  factory WageSheetEntry.fromJson(Map<String, dynamic> json) {
    return WageSheetEntry(
      id: json['id'],
      labourId: json['labour'] != null ? json['labour']['id'] : 0,
      labourName: json['labour'] != null ? json['labour']['name'] : 'Unknown',
      daysWorked: (json['daysWorked'] as num).toDouble(),
      dailyWage: (json['dailyWage'] as num).toDouble(),
      totalWage: (json['totalWage'] as num).toDouble(),
      advancesDeducted: (json['advancesDeducted'] as num).toDouble(),
      netPayable: (json['netPayable'] as num).toDouble(),
    );
  }
}

class LabourAdvance {
  final int id;
  final int labourId;
  final String advanceDate;
  final double amount;
  final double recoveredAmount;
  final String? notes;

  LabourAdvance({
    required this.id,
    required this.labourId,
    required this.advanceDate,
    required this.amount,
    required this.recoveredAmount,
    this.notes,
  });

  factory LabourAdvance.fromJson(Map<String, dynamic> json) {
    return LabourAdvance(
      id: json['id'],
      labourId: json['labour'] != null ? json['labour']['id'] : 0,
      advanceDate: json['advanceDate'],
      amount: (json['amount'] as num).toDouble(),
      recoveredAmount: (json['recoveredAmount'] as num).toDouble(),
      notes: json['notes'],
    );
  }
}
