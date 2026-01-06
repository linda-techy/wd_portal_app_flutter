class SiteVisit {
  final int id;
  final int projectId;
  final String projectName;
  final int? visitedById;
  final String? visitedByName;
  final DateTime? visitDate;
  final String? notes;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? visitType;
  final String? visitStatus;
  final int? durationMinutes;
  final String? formattedDuration;
  final String? checkOutNotes;
  final DateTime? createdAt;

  SiteVisit({
    required this.id,
    required this.projectId,
    required this.projectName,
    this.visitedById,
    this.visitedByName,
    this.visitDate,
    this.notes,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.visitType,
    this.visitStatus,
    this.durationMinutes,
    this.formattedDuration,
    this.checkOutNotes,
    this.createdAt,
  });

  factory SiteVisit.fromJson(Map<String, dynamic> json) {
    return SiteVisit(
      id: json['id'] as int,
      projectId: json['projectId'] as int,
      projectName: json['projectName'] ?? 'Unknown Project',
      visitedById: json['visitedById'] as int?,
      visitedByName: json['visitedByName'] as String?,
      visitDate: json['visitDate'] != null ? DateTime.tryParse(json['visitDate'].toString()) : null,
      notes: json['notes'] as String?,
      checkInTime: json['checkInTime'] != null ? DateTime.tryParse(json['checkInTime'].toString()) : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.tryParse(json['checkOutTime'].toString()) : null,
      checkInLatitude: (json['checkInLatitude'] as num?)?.toDouble(),
      checkInLongitude: (json['checkInLongitude'] as num?)?.toDouble(),
      checkOutLatitude: (json['checkOutLatitude'] as num?)?.toDouble(),
      checkOutLongitude: (json['checkOutLongitude'] as num?)?.toDouble(),
      visitType: json['visitType'] as String?,
      visitStatus: json['visitStatus'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      formattedDuration: json['formattedDuration'] as String?,
      checkOutNotes: json['checkOutNotes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'projectName': projectName,
      'visitedById': visitedById,
      'visitedByName': visitedByName,
      'visitDate': visitDate?.toIso8601String(),
      'notes': notes,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'visitType': visitType,
      'visitStatus': visitStatus,
      'durationMinutes': durationMinutes,
      'formattedDuration': formattedDuration,
      'checkOutNotes': checkOutNotes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  bool get isActive => visitStatus == 'CHECKED_IN';
  bool get isCompleted => visitStatus == 'CHECKED_OUT';
}

class CheckInRequest {
  final int projectId;
  final double latitude;
  final double longitude;
  final String visitType;
  final String? notes;

  CheckInRequest({
    required this.projectId,
    required this.latitude,
    required this.longitude,
    required this.visitType,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'latitude': latitude,
      'longitude': longitude,
      'visitType': visitType,
      'notes': notes,
    };
  }
}

class CheckOutRequest {
  final double latitude;
  final double longitude;
  final String? notes;

  CheckOutRequest({
    required this.latitude,
    required this.longitude,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
    };
  }
}

class VisitTypeOption {
  final String value;
  final String label;

  VisitTypeOption({required this.value, required this.label});

  factory VisitTypeOption.fromJson(Map<String, dynamic> json) {
    return VisitTypeOption(
      value: json['value'] as String,
      label: json['label'] as String,
    );
  }
}
