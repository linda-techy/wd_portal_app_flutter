class Project {
  final String? id;
  final String? projectCode;
  final String? projectName;
  final String? clientId;
  final String? projectType;
  final String? constructionType;
  final double? totalArea;
  final String? unitOfArea;
  final String? location;
  final String? city;
  final String? state;
  final double? estimatedBudgetMin;
  final double? estimatedBudgetMax;
  final double? actualBudget;
  final DateTime? startDate;
  final DateTime? expectedCompletionDate;
  final DateTime? actualCompletionDate;
  final String? status;
  final double? progressPercentage;
  final String? assignedTo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Project({
    this.id,
    this.projectCode,
    this.projectName,
    this.clientId,
    this.projectType,
    this.constructionType,
    this.totalArea,
    this.unitOfArea,
    this.location,
    this.city,
    this.state,
    this.estimatedBudgetMin,
    this.estimatedBudgetMax,
    this.actualBudget,
    this.startDate,
    this.expectedCompletionDate,
    this.actualCompletionDate,
    this.status,
    this.progressPercentage,
    this.assignedTo,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      projectCode: json['projectCode'],
      projectName: json['projectName'],
      clientId: json['clientId'],
      projectType: json['projectType'],
      constructionType: json['constructionType'],
      totalArea: json['totalArea']?.toDouble(),
      unitOfArea: json['unitOfArea'],
      location: json['location'],
      city: json['city'],
      state: json['state'],
      estimatedBudgetMin: json['estimatedBudgetMin']?.toDouble(),
      estimatedBudgetMax: json['estimatedBudgetMax']?.toDouble(),
      actualBudget: json['actualBudget']?.toDouble(),
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      expectedCompletionDate: json['expectedCompletionDate'] != null
          ? DateTime.parse(json['expectedCompletionDate'])
          : null,
      actualCompletionDate: json['actualCompletionDate'] != null
          ? DateTime.parse(json['actualCompletionDate'])
          : null,
      status: json['status'],
      progressPercentage: json['progressPercentage']?.toDouble(),
      assignedTo: json['assignedTo'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectCode': projectCode,
      'projectName': projectName,
      'clientId': clientId,
      'projectType': projectType,
      'constructionType': constructionType,
      'totalArea': totalArea,
      'unitOfArea': unitOfArea,
      'location': location,
      'city': city,
      'state': state,
      'estimatedBudgetMin': estimatedBudgetMin,
      'estimatedBudgetMax': estimatedBudgetMax,
      'actualBudget': actualBudget,
      'startDate': startDate?.toIso8601String(),
      'expectedCompletionDate': expectedCompletionDate?.toIso8601String(),
      'actualCompletionDate': actualCompletionDate?.toIso8601String(),
      'status': status,
      'progressPercentage': progressPercentage,
      'assignedTo': assignedTo,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Project copyWith({
    String? id,
    String? projectCode,
    String? projectName,
    String? clientId,
    String? projectType,
    String? constructionType,
    double? totalArea,
    String? unitOfArea,
    String? location,
    String? city,
    String? state,
    double? estimatedBudgetMin,
    double? estimatedBudgetMax,
    double? actualBudget,
    DateTime? startDate,
    DateTime? expectedCompletionDate,
    DateTime? actualCompletionDate,
    String? status,
    double? progressPercentage,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      projectCode: projectCode ?? this.projectCode,
      projectName: projectName ?? this.projectName,
      clientId: clientId ?? this.clientId,
      projectType: projectType ?? this.projectType,
      constructionType: constructionType ?? this.constructionType,
      totalArea: totalArea ?? this.totalArea,
      unitOfArea: unitOfArea ?? this.unitOfArea,
      location: location ?? this.location,
      city: city ?? this.city,
      state: state ?? this.state,
      estimatedBudgetMin: estimatedBudgetMin ?? this.estimatedBudgetMin,
      estimatedBudgetMax: estimatedBudgetMax ?? this.estimatedBudgetMax,
      actualBudget: actualBudget ?? this.actualBudget,
      startDate: startDate ?? this.startDate,
      expectedCompletionDate:
          expectedCompletionDate ?? this.expectedCompletionDate,
      actualCompletionDate: actualCompletionDate ?? this.actualCompletionDate,
      status: status ?? this.status,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
