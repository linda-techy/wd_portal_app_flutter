import 'package:flutter/foundation.dart';

enum HolidayScope {
  national,
  state,
  district,
  project;

  String toApi() {
    switch (this) {
      case HolidayScope.national:
        return 'NATIONAL';
      case HolidayScope.state:
        return 'STATE';
      case HolidayScope.district:
        return 'DISTRICT';
      case HolidayScope.project:
        return 'PROJECT';
    }
  }

  static HolidayScope fromApi(String s) {
    switch (s) {
      case 'NATIONAL':
        return HolidayScope.national;
      case 'STATE':
        return HolidayScope.state;
      case 'DISTRICT':
        return HolidayScope.district;
      case 'PROJECT':
        return HolidayScope.project;
      default:
        throw ArgumentError('Unknown scope: $s');
    }
  }

  String get label {
    switch (this) {
      case HolidayScope.national:
        return 'National';
      case HolidayScope.state:
        return 'State';
      case HolidayScope.district:
        return 'District';
      case HolidayScope.project:
        return 'Project';
    }
  }
}

enum HolidayRecurrenceType {
  fixedDate,
  lunar,
  oneOff;

  String toApi() {
    switch (this) {
      case HolidayRecurrenceType.fixedDate:
        return 'FIXED_DATE';
      case HolidayRecurrenceType.lunar:
        return 'LUNAR';
      case HolidayRecurrenceType.oneOff:
        return 'ONE_OFF';
    }
  }

  static HolidayRecurrenceType fromApi(String s) {
    switch (s) {
      case 'FIXED_DATE':
        return HolidayRecurrenceType.fixedDate;
      case 'LUNAR':
        return HolidayRecurrenceType.lunar;
      case 'ONE_OFF':
        return HolidayRecurrenceType.oneOff;
      default:
        throw ArgumentError('Unknown recurrence: $s');
    }
  }

  String get label {
    switch (this) {
      case HolidayRecurrenceType.fixedDate:
        return 'Fixed date';
      case HolidayRecurrenceType.lunar:
        return 'Lunar';
      case HolidayRecurrenceType.oneOff:
        return 'One-off';
    }
  }
}

@immutable
class Holiday {
  final int? id;
  final String? code;
  final String name;
  final DateTime date;
  final HolidayScope scope;
  final String? scopeRef;
  final HolidayRecurrenceType recurrenceType;
  final String? source;
  final bool isActive;

  const Holiday({
    this.id,
    this.code,
    required this.name,
    required this.date,
    required this.scope,
    this.scopeRef,
    required this.recurrenceType,
    this.source,
    required this.isActive,
  });

  factory Holiday.fromJson(Map<String, dynamic> j) => Holiday(
        id: j['id'] as int?,
        code: j['code'] as String?,
        name: j['name'] as String,
        date: DateTime.parse(j['date'] as String),
        scope: HolidayScope.fromApi(j['scope'] as String),
        scopeRef: j['scopeRef'] as String?,
        recurrenceType:
            HolidayRecurrenceType.fromApi(j['recurrenceType'] as String),
        source: j['source'] as String?,
        isActive: j['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (code != null) 'code': code,
        'name': name,
        'date': '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}',
        'scope': scope.toApi(),
        if (scopeRef != null) 'scopeRef': scopeRef,
        'recurrenceType': recurrenceType.toApi(),
        if (source != null) 'source': source,
        'isActive': isActive,
      };
}
