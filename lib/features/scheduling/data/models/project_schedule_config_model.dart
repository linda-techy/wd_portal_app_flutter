import 'package:flutter/foundation.dart';

/// Mirrors the `project_schedule_config` row.
///
/// Monsoon window stored as MMDD smallint server-side; we use `(month, day)`
/// pairs in Dart to keep the form ergonomic.
@immutable
class ProjectScheduleConfig {
  final int projectId;
  final bool sundayWorking;
  final int monsoonStartMonth; // 1-12
  final int monsoonStartDay; // 1-31
  final int monsoonEndMonth;
  final int monsoonEndDay;
  final String? districtCode;

  const ProjectScheduleConfig({
    required this.projectId,
    required this.sundayWorking,
    required this.monsoonStartMonth,
    required this.monsoonStartDay,
    required this.monsoonEndMonth,
    required this.monsoonEndDay,
    this.districtCode,
  });

  factory ProjectScheduleConfig.fromJson(Map<String, dynamic> j) {
    final start = (j['monsoonStartMonthDay'] as num).toInt();
    final end = (j['monsoonEndMonthDay'] as num).toInt();
    return ProjectScheduleConfig(
      projectId: (j['projectId'] as num).toInt(),
      sundayWorking: j['sundayWorking'] as bool? ?? false,
      monsoonStartMonth: start ~/ 100,
      monsoonStartDay: start % 100,
      monsoonEndMonth: end ~/ 100,
      monsoonEndDay: end % 100,
      districtCode: j['districtCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'sundayWorking': sundayWorking,
        'monsoonStartMonthDay': monsoonStartMonth * 100 + monsoonStartDay,
        'monsoonEndMonthDay': monsoonEndMonth * 100 + monsoonEndDay,
        if (districtCode != null) 'districtCode': districtCode,
      };

  ProjectScheduleConfig copyWith({
    bool? sundayWorking,
    int? monsoonStartMonth,
    int? monsoonStartDay,
    int? monsoonEndMonth,
    int? monsoonEndDay,
    String? districtCode,
    bool clearDistrictCode = false,
  }) =>
      ProjectScheduleConfig(
        projectId: projectId,
        sundayWorking: sundayWorking ?? this.sundayWorking,
        monsoonStartMonth: monsoonStartMonth ?? this.monsoonStartMonth,
        monsoonStartDay: monsoonStartDay ?? this.monsoonStartDay,
        monsoonEndMonth: monsoonEndMonth ?? this.monsoonEndMonth,
        monsoonEndDay: monsoonEndDay ?? this.monsoonEndDay,
        districtCode:
            clearDistrictCode ? null : (districtCode ?? this.districtCode),
      );
}

enum HolidayOverrideAction {
  exclude,
  add;

  String toApi() => this == HolidayOverrideAction.exclude ? 'EXCLUDE' : 'ADD';
  static HolidayOverrideAction fromApi(String s) =>
      s == 'EXCLUDE' ? HolidayOverrideAction.exclude : HolidayOverrideAction.add;
  String get label => this == HolidayOverrideAction.exclude
      ? 'Work this day (exclude holiday)'
      : 'Add project-only holiday';
}

@immutable
class ProjectHolidayOverride {
  final int? id;
  final int projectId;
  final int holidayId;
  final HolidayOverrideAction action;

  const ProjectHolidayOverride({
    this.id,
    required this.projectId,
    required this.holidayId,
    required this.action,
  });

  factory ProjectHolidayOverride.fromJson(Map<String, dynamic> j) =>
      ProjectHolidayOverride(
        id: j['id'] as int?,
        projectId: (j['projectId'] as num).toInt(),
        holidayId: (j['holidayId'] as num).toInt(),
        action: HolidayOverrideAction.fromApi(j['action'] as String),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'projectId': projectId,
        'holidayId': holidayId,
        'action': action.toApi(),
      };
}
