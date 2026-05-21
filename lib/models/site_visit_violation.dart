class SiteVisitViolation {
  final int id;
  final int? projectId;
  final String? projectName;
  final int? userId;
  final String? userName;
  final String? userEmail;
  final String attemptType; // CHECK_IN | CHECK_OUT
  final DateTime attemptedAt;
  final double attemptedLatitude;
  final double attemptedLongitude;
  final double? projectLatitude;
  final double? projectLongitude;
  final double distanceKm;
  final double allowedRadiusKm;
  final int? visitId;
  final String? errorMessage;

  SiteVisitViolation({
    required this.id,
    this.projectId,
    this.projectName,
    this.userId,
    this.userName,
    this.userEmail,
    required this.attemptType,
    required this.attemptedAt,
    required this.attemptedLatitude,
    required this.attemptedLongitude,
    this.projectLatitude,
    this.projectLongitude,
    required this.distanceKm,
    required this.allowedRadiusKm,
    this.visitId,
    this.errorMessage,
  });

  factory SiteVisitViolation.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) => v == null ? 0.0 : (v as num).toDouble();
    double? toNullableDouble(dynamic v) =>
        v == null ? null : (v as num).toDouble();
    return SiteVisitViolation(
      id: json['id'] as int,
      projectId: json['projectId'] as int?,
      projectName: json['projectName'] as String?,
      userId: json['userId'] as int?,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      attemptType: json['attemptType'] as String? ?? 'CHECK_IN',
      attemptedAt: DateTime.parse(json['attemptedAt'] as String),
      attemptedLatitude: toDouble(json['attemptedLatitude']),
      attemptedLongitude: toDouble(json['attemptedLongitude']),
      projectLatitude: toNullableDouble(json['projectLatitude']),
      projectLongitude: toNullableDouble(json['projectLongitude']),
      distanceKm: toDouble(json['distanceKm']),
      allowedRadiusKm: toDouble(json['allowedRadiusKm']),
      visitId: json['visitId'] as int?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Human-readable distance: "350 m" or "1.2 km".
  String get formattedDistance => distanceKm < 1.0
      ? '${(distanceKm * 1000).round()} m'
      : '${distanceKm.toStringAsFixed(2)} km';

  String get formattedAllowedRadius => allowedRadiusKm < 1.0
      ? '${(allowedRadiusKm * 1000).round()} m'
      : '${allowedRadiusKm.toStringAsFixed(2)} km';
}
