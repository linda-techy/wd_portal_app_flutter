import 'package:flutter/foundation.dart';

/// Represents the four template `code` values aligned with `CustomerProject.projectType`.
enum WbsProjectType {
  residential,
  commercial,
  interiorFitout,
  renovation;

  String toApi() {
    switch (this) {
      case WbsProjectType.residential:
        return 'RESIDENTIAL';
      case WbsProjectType.commercial:
        return 'COMMERCIAL';
      case WbsProjectType.interiorFitout:
        return 'INTERIOR_FITOUT';
      case WbsProjectType.renovation:
        return 'RENOVATION';
    }
  }

  static WbsProjectType fromApi(String s) {
    switch (s) {
      case 'RESIDENTIAL':
        return WbsProjectType.residential;
      case 'COMMERCIAL':
        return WbsProjectType.commercial;
      case 'INTERIOR_FITOUT':
        return WbsProjectType.interiorFitout;
      case 'RENOVATION':
        return WbsProjectType.renovation;
      default:
        throw ArgumentError('Unknown projectType: $s');
    }
  }

  String get label {
    switch (this) {
      case WbsProjectType.residential:
        return 'Residential';
      case WbsProjectType.commercial:
        return 'Commercial';
      case WbsProjectType.interiorFitout:
        return 'Interior Fit-out';
      case WbsProjectType.renovation:
        return 'Renovation';
    }
  }
}

enum FloorLoop {
  none,
  perFloor;

  String toApi() => this == FloorLoop.none ? 'NONE' : 'PER_FLOOR';
  static FloorLoop fromApi(String s) =>
      s == 'PER_FLOOR' ? FloorLoop.perFloor : FloorLoop.none;
  String get label => this == FloorLoop.none ? 'Once' : 'Per floor';
}

@immutable
class WbsTemplateTaskPredecessorRef {
  final int predecessorTemplateTaskId;
  final int lagDays;

  const WbsTemplateTaskPredecessorRef({
    required this.predecessorTemplateTaskId,
    required this.lagDays,
  });

  factory WbsTemplateTaskPredecessorRef.fromJson(Map<String, dynamic> j) =>
      WbsTemplateTaskPredecessorRef(
        predecessorTemplateTaskId: j['predecessorTemplateTaskId'] as int,
        lagDays: (j['lagDays'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'predecessorTemplateTaskId': predecessorTemplateTaskId,
        'lagDays': lagDays,
      };
}

@immutable
class WbsTemplateTask {
  final int? id;
  final int sequence;
  final String name;
  final String? roleHint;
  final int durationDays;
  final int? weightFactor;
  final bool monsoonSensitive;
  final bool isPaymentMilestone;
  final FloorLoop floorLoop;
  final double? optionalCost;
  final List<WbsTemplateTaskPredecessorRef> predecessors;

  const WbsTemplateTask({
    this.id,
    required this.sequence,
    required this.name,
    this.roleHint,
    required this.durationDays,
    this.weightFactor,
    required this.monsoonSensitive,
    required this.isPaymentMilestone,
    required this.floorLoop,
    this.optionalCost,
    required this.predecessors,
  });

  factory WbsTemplateTask.fromJson(Map<String, dynamic> j) => WbsTemplateTask(
        id: j['id'] as int?,
        sequence: j['sequence'] as int,
        name: j['name'] as String,
        roleHint: j['roleHint'] as String?,
        durationDays: (j['durationDays'] as num).toInt(),
        weightFactor: (j['weightFactor'] as num?)?.toInt(),
        monsoonSensitive: j['monsoonSensitive'] as bool? ?? false,
        isPaymentMilestone: j['isPaymentMilestone'] as bool? ?? false,
        floorLoop: FloorLoop.fromApi(j['floorLoop'] as String? ?? 'NONE'),
        optionalCost: (j['optionalCost'] as num?)?.toDouble(),
        predecessors: ((j['predecessors'] as List?) ?? const [])
            .map((e) =>
                WbsTemplateTaskPredecessorRef.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'sequence': sequence,
        'name': name,
        if (roleHint != null) 'roleHint': roleHint,
        'durationDays': durationDays,
        if (weightFactor != null) 'weightFactor': weightFactor,
        'monsoonSensitive': monsoonSensitive,
        'isPaymentMilestone': isPaymentMilestone,
        'floorLoop': floorLoop.toApi(),
        if (optionalCost != null) 'optionalCost': optionalCost,
        'predecessors': predecessors.map((p) => p.toJson()).toList(),
      };

  WbsTemplateTask copyWith({
    int? sequence,
    String? name,
    String? roleHint,
    int? durationDays,
    int? weightFactor,
    bool clearWeightFactor = false,
    bool? monsoonSensitive,
    bool? isPaymentMilestone,
    FloorLoop? floorLoop,
    double? optionalCost,
    List<WbsTemplateTaskPredecessorRef>? predecessors,
  }) =>
      WbsTemplateTask(
        id: id,
        sequence: sequence ?? this.sequence,
        name: name ?? this.name,
        roleHint: roleHint ?? this.roleHint,
        durationDays: durationDays ?? this.durationDays,
        weightFactor:
            clearWeightFactor ? null : (weightFactor ?? this.weightFactor),
        monsoonSensitive: monsoonSensitive ?? this.monsoonSensitive,
        isPaymentMilestone: isPaymentMilestone ?? this.isPaymentMilestone,
        floorLoop: floorLoop ?? this.floorLoop,
        optionalCost: optionalCost ?? this.optionalCost,
        predecessors: predecessors ?? this.predecessors,
      );
}

@immutable
class WbsTemplatePhase {
  final int? id;
  final int sequence;
  final String name;
  final String? roleHint;
  final bool monsoonSensitive;
  final List<WbsTemplateTask> tasks;

  const WbsTemplatePhase({
    this.id,
    required this.sequence,
    required this.name,
    this.roleHint,
    required this.monsoonSensitive,
    required this.tasks,
  });

  factory WbsTemplatePhase.fromJson(Map<String, dynamic> j) => WbsTemplatePhase(
        id: j['id'] as int?,
        sequence: j['sequence'] as int,
        name: j['name'] as String,
        roleHint: j['roleHint'] as String?,
        monsoonSensitive: j['monsoonSensitive'] as bool? ?? false,
        tasks: ((j['tasks'] as List?) ?? const [])
            .map((e) => WbsTemplateTask.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'sequence': sequence,
        'name': name,
        if (roleHint != null) 'roleHint': roleHint,
        'monsoonSensitive': monsoonSensitive,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  WbsTemplatePhase copyWith({
    int? sequence,
    String? name,
    String? roleHint,
    bool? monsoonSensitive,
    List<WbsTemplateTask>? tasks,
  }) =>
      WbsTemplatePhase(
        id: id,
        sequence: sequence ?? this.sequence,
        name: name ?? this.name,
        roleHint: roleHint ?? this.roleHint,
        monsoonSensitive: monsoonSensitive ?? this.monsoonSensitive,
        tasks: tasks ?? this.tasks,
      );
}

@immutable
class WbsTemplate {
  final int? id;
  final String code;
  final WbsProjectType projectType;
  final String name;
  final int version;
  final bool isActive;
  final DateTime? updatedAt;
  final List<WbsTemplatePhase> phases;

  const WbsTemplate({
    this.id,
    required this.code,
    required this.projectType,
    required this.name,
    required this.version,
    required this.isActive,
    this.updatedAt,
    required this.phases,
  });

  factory WbsTemplate.fromJson(Map<String, dynamic> j) => WbsTemplate(
        id: j['id'] as int?,
        code: j['code'] as String,
        projectType: WbsProjectType.fromApi(j['projectType'] as String),
        name: j['name'] as String,
        version: (j['version'] as num).toInt(),
        isActive: j['isActive'] as bool? ?? false,
        updatedAt: j['updatedAt'] == null
            ? null
            : DateTime.parse(j['updatedAt'] as String),
        phases: ((j['phases'] as List?) ?? const [])
            .map((e) => WbsTemplatePhase.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'code': code,
        'projectType': projectType.toApi(),
        'name': name,
        'version': version,
        'isActive': isActive,
        'phases': phases.map((p) => p.toJson()).toList(),
      };

  WbsTemplate copyWith({
    String? name,
    bool? isActive,
    List<WbsTemplatePhase>? phases,
  }) =>
      WbsTemplate(
        id: id,
        code: code,
        projectType: projectType,
        name: name ?? this.name,
        version: version,
        isActive: isActive ?? this.isActive,
        updatedAt: updatedAt,
        phases: phases ?? this.phases,
      );
}
