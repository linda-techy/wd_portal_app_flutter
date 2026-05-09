// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_db.dart';

// ignore_for_file: type=lint
class $OutboxEntriesTable extends OutboxEntries
    with TableInfo<$OutboxEntriesTable, OutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _clientUuidMeta =
      const VerificationMeta('clientUuid');
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
      'client_uuid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _mutationTypeMeta =
      const VerificationMeta('mutationType');
  @override
  late final GeneratedColumn<String> mutationType = GeneratedColumn<String>(
      'mutation_type', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 32),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
      'task_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _photoFilePathMeta =
      const VerificationMeta('photoFilePath');
  @override
  late final GeneratedColumn<String> photoFilePath = GeneratedColumn<String>(
      'photo_file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _gpsAccuracyMetersMeta =
      const VerificationMeta('gpsAccuracyMeters');
  @override
  late final GeneratedColumn<double> gpsAccuracyMeters =
      GeneratedColumn<double>('gps_accuracy_meters', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _capturedAtMeta =
      const VerificationMeta('capturedAt');
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
      'captured_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextRetryAtMeta =
      const VerificationMeta('nextRetryAt');
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
      'next_retry_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastErrorMessageMeta =
      const VerificationMeta('lastErrorMessage');
  @override
  late final GeneratedColumn<String> lastErrorMessage = GeneratedColumn<String>(
      'last_error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastErrorStatusMeta =
      const VerificationMeta('lastErrorStatus');
  @override
  late final GeneratedColumn<int> lastErrorStatus = GeneratedColumn<int>(
      'last_error_status', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        clientUuid,
        mutationType,
        projectId,
        taskId,
        payloadJson,
        photoFilePath,
        latitude,
        longitude,
        gpsAccuracyMeters,
        capturedAt,
        state,
        attempts,
        nextRetryAt,
        lastErrorMessage,
        lastErrorStatus,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_entries';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_uuid')) {
      context.handle(
          _clientUuidMeta,
          clientUuid.isAcceptableOrUnknown(
              data['client_uuid']!, _clientUuidMeta));
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('mutation_type')) {
      context.handle(
          _mutationTypeMeta,
          mutationType.isAcceptableOrUnknown(
              data['mutation_type']!, _mutationTypeMeta));
    } else if (isInserting) {
      context.missing(_mutationTypeMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta,
          taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('photo_file_path')) {
      context.handle(
          _photoFilePathMeta,
          photoFilePath.isAcceptableOrUnknown(
              data['photo_file_path']!, _photoFilePathMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    if (data.containsKey('gps_accuracy_meters')) {
      context.handle(
          _gpsAccuracyMetersMeta,
          gpsAccuracyMeters.isAcceptableOrUnknown(
              data['gps_accuracy_meters']!, _gpsAccuracyMetersMeta));
    }
    if (data.containsKey('captured_at')) {
      context.handle(
          _capturedAtMeta,
          capturedAt.isAcceptableOrUnknown(
              data['captured_at']!, _capturedAtMeta));
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
          _nextRetryAtMeta,
          nextRetryAt.isAcceptableOrUnknown(
              data['next_retry_at']!, _nextRetryAtMeta));
    }
    if (data.containsKey('last_error_message')) {
      context.handle(
          _lastErrorMessageMeta,
          lastErrorMessage.isAcceptableOrUnknown(
              data['last_error_message']!, _lastErrorMessageMeta));
    }
    if (data.containsKey('last_error_status')) {
      context.handle(
          _lastErrorStatusMeta,
          lastErrorStatus.isAcceptableOrUnknown(
              data['last_error_status']!, _lastErrorStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      clientUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_uuid'])!,
      mutationType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mutation_type'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id']),
      taskId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}task_id']),
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      photoFilePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_file_path']),
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude']),
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude']),
      gpsAccuracyMeters: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}gps_accuracy_meters']),
      capturedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}captured_at']),
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      nextRetryAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_retry_at']),
      lastErrorMessage: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_error_message']),
      lastErrorStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_error_status']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $OutboxEntriesTable createAlias(String alias) {
    return $OutboxEntriesTable(attachedDatabase, alias);
  }
}

class OutboxEntry extends DataClass implements Insertable<OutboxEntry> {
  final int id;
  final String clientUuid;
  final String mutationType;
  final int? projectId;
  final int? taskId;
  final String payloadJson;
  final String? photoFilePath;
  final double? latitude;
  final double? longitude;
  final double? gpsAccuracyMeters;
  final DateTime? capturedAt;
  final String state;
  final int attempts;
  final DateTime? nextRetryAt;
  final String? lastErrorMessage;
  final int? lastErrorStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const OutboxEntry(
      {required this.id,
      required this.clientUuid,
      required this.mutationType,
      this.projectId,
      this.taskId,
      required this.payloadJson,
      this.photoFilePath,
      this.latitude,
      this.longitude,
      this.gpsAccuracyMeters,
      this.capturedAt,
      required this.state,
      required this.attempts,
      this.nextRetryAt,
      this.lastErrorMessage,
      this.lastErrorStatus,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_uuid'] = Variable<String>(clientUuid);
    map['mutation_type'] = Variable<String>(mutationType);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<int>(projectId);
    }
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<int>(taskId);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || photoFilePath != null) {
      map['photo_file_path'] = Variable<String>(photoFilePath);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || gpsAccuracyMeters != null) {
      map['gps_accuracy_meters'] = Variable<double>(gpsAccuracyMeters);
    }
    if (!nullToAbsent || capturedAt != null) {
      map['captured_at'] = Variable<DateTime>(capturedAt);
    }
    map['state'] = Variable<String>(state);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    if (!nullToAbsent || lastErrorMessage != null) {
      map['last_error_message'] = Variable<String>(lastErrorMessage);
    }
    if (!nullToAbsent || lastErrorStatus != null) {
      map['last_error_status'] = Variable<int>(lastErrorStatus);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntriesCompanion(
      id: Value(id),
      clientUuid: Value(clientUuid),
      mutationType: Value(mutationType),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      taskId:
          taskId == null && nullToAbsent ? const Value.absent() : Value(taskId),
      payloadJson: Value(payloadJson),
      photoFilePath: photoFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoFilePath),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      gpsAccuracyMeters: gpsAccuracyMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsAccuracyMeters),
      capturedAt: capturedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(capturedAt),
      state: Value(state),
      attempts: Value(attempts),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      lastErrorMessage: lastErrorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorMessage),
      lastErrorStatus: lastErrorStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OutboxEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntry(
      id: serializer.fromJson<int>(json['id']),
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      mutationType: serializer.fromJson<String>(json['mutationType']),
      projectId: serializer.fromJson<int?>(json['projectId']),
      taskId: serializer.fromJson<int?>(json['taskId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      photoFilePath: serializer.fromJson<String?>(json['photoFilePath']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      gpsAccuracyMeters:
          serializer.fromJson<double?>(json['gpsAccuracyMeters']),
      capturedAt: serializer.fromJson<DateTime?>(json['capturedAt']),
      state: serializer.fromJson<String>(json['state']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      lastErrorMessage: serializer.fromJson<String?>(json['lastErrorMessage']),
      lastErrorStatus: serializer.fromJson<int?>(json['lastErrorStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientUuid': serializer.toJson<String>(clientUuid),
      'mutationType': serializer.toJson<String>(mutationType),
      'projectId': serializer.toJson<int?>(projectId),
      'taskId': serializer.toJson<int?>(taskId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'photoFilePath': serializer.toJson<String?>(photoFilePath),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'gpsAccuracyMeters': serializer.toJson<double?>(gpsAccuracyMeters),
      'capturedAt': serializer.toJson<DateTime?>(capturedAt),
      'state': serializer.toJson<String>(state),
      'attempts': serializer.toJson<int>(attempts),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'lastErrorMessage': serializer.toJson<String?>(lastErrorMessage),
      'lastErrorStatus': serializer.toJson<int?>(lastErrorStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OutboxEntry copyWith(
          {int? id,
          String? clientUuid,
          String? mutationType,
          Value<int?> projectId = const Value.absent(),
          Value<int?> taskId = const Value.absent(),
          String? payloadJson,
          Value<String?> photoFilePath = const Value.absent(),
          Value<double?> latitude = const Value.absent(),
          Value<double?> longitude = const Value.absent(),
          Value<double?> gpsAccuracyMeters = const Value.absent(),
          Value<DateTime?> capturedAt = const Value.absent(),
          String? state,
          int? attempts,
          Value<DateTime?> nextRetryAt = const Value.absent(),
          Value<String?> lastErrorMessage = const Value.absent(),
          Value<int?> lastErrorStatus = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      OutboxEntry(
        id: id ?? this.id,
        clientUuid: clientUuid ?? this.clientUuid,
        mutationType: mutationType ?? this.mutationType,
        projectId: projectId.present ? projectId.value : this.projectId,
        taskId: taskId.present ? taskId.value : this.taskId,
        payloadJson: payloadJson ?? this.payloadJson,
        photoFilePath:
            photoFilePath.present ? photoFilePath.value : this.photoFilePath,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
        gpsAccuracyMeters: gpsAccuracyMeters.present
            ? gpsAccuracyMeters.value
            : this.gpsAccuracyMeters,
        capturedAt: capturedAt.present ? capturedAt.value : this.capturedAt,
        state: state ?? this.state,
        attempts: attempts ?? this.attempts,
        nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
        lastErrorMessage: lastErrorMessage.present
            ? lastErrorMessage.value
            : this.lastErrorMessage,
        lastErrorStatus: lastErrorStatus.present
            ? lastErrorStatus.value
            : this.lastErrorStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  OutboxEntry copyWithCompanion(OutboxEntriesCompanion data) {
    return OutboxEntry(
      id: data.id.present ? data.id.value : this.id,
      clientUuid:
          data.clientUuid.present ? data.clientUuid.value : this.clientUuid,
      mutationType: data.mutationType.present
          ? data.mutationType.value
          : this.mutationType,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      photoFilePath: data.photoFilePath.present
          ? data.photoFilePath.value
          : this.photoFilePath,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      gpsAccuracyMeters: data.gpsAccuracyMeters.present
          ? data.gpsAccuracyMeters.value
          : this.gpsAccuracyMeters,
      capturedAt:
          data.capturedAt.present ? data.capturedAt.value : this.capturedAt,
      state: data.state.present ? data.state.value : this.state,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextRetryAt:
          data.nextRetryAt.present ? data.nextRetryAt.value : this.nextRetryAt,
      lastErrorMessage: data.lastErrorMessage.present
          ? data.lastErrorMessage.value
          : this.lastErrorMessage,
      lastErrorStatus: data.lastErrorStatus.present
          ? data.lastErrorStatus.value
          : this.lastErrorStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntry(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('mutationType: $mutationType, ')
          ..write('projectId: $projectId, ')
          ..write('taskId: $taskId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('photoFilePath: $photoFilePath, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('gpsAccuracyMeters: $gpsAccuracyMeters, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('lastErrorStatus: $lastErrorStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      clientUuid,
      mutationType,
      projectId,
      taskId,
      payloadJson,
      photoFilePath,
      latitude,
      longitude,
      gpsAccuracyMeters,
      capturedAt,
      state,
      attempts,
      nextRetryAt,
      lastErrorMessage,
      lastErrorStatus,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntry &&
          other.id == this.id &&
          other.clientUuid == this.clientUuid &&
          other.mutationType == this.mutationType &&
          other.projectId == this.projectId &&
          other.taskId == this.taskId &&
          other.payloadJson == this.payloadJson &&
          other.photoFilePath == this.photoFilePath &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.gpsAccuracyMeters == this.gpsAccuracyMeters &&
          other.capturedAt == this.capturedAt &&
          other.state == this.state &&
          other.attempts == this.attempts &&
          other.nextRetryAt == this.nextRetryAt &&
          other.lastErrorMessage == this.lastErrorMessage &&
          other.lastErrorStatus == this.lastErrorStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OutboxEntriesCompanion extends UpdateCompanion<OutboxEntry> {
  final Value<int> id;
  final Value<String> clientUuid;
  final Value<String> mutationType;
  final Value<int?> projectId;
  final Value<int?> taskId;
  final Value<String> payloadJson;
  final Value<String?> photoFilePath;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<double?> gpsAccuracyMeters;
  final Value<DateTime?> capturedAt;
  final Value<String> state;
  final Value<int> attempts;
  final Value<DateTime?> nextRetryAt;
  final Value<String?> lastErrorMessage;
  final Value<int?> lastErrorStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const OutboxEntriesCompanion({
    this.id = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.mutationType = const Value.absent(),
    this.projectId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.photoFilePath = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.gpsAccuracyMeters = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.lastErrorStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  OutboxEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String clientUuid,
    required String mutationType,
    this.projectId = const Value.absent(),
    this.taskId = const Value.absent(),
    required String payloadJson,
    this.photoFilePath = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.gpsAccuracyMeters = const Value.absent(),
    this.capturedAt = const Value.absent(),
    required String state,
    this.attempts = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.lastErrorStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : clientUuid = Value(clientUuid),
        mutationType = Value(mutationType),
        payloadJson = Value(payloadJson),
        state = Value(state);
  static Insertable<OutboxEntry> custom({
    Expression<int>? id,
    Expression<String>? clientUuid,
    Expression<String>? mutationType,
    Expression<int>? projectId,
    Expression<int>? taskId,
    Expression<String>? payloadJson,
    Expression<String>? photoFilePath,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? gpsAccuracyMeters,
    Expression<DateTime>? capturedAt,
    Expression<String>? state,
    Expression<int>? attempts,
    Expression<DateTime>? nextRetryAt,
    Expression<String>? lastErrorMessage,
    Expression<int>? lastErrorStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (mutationType != null) 'mutation_type': mutationType,
      if (projectId != null) 'project_id': projectId,
      if (taskId != null) 'task_id': taskId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (photoFilePath != null) 'photo_file_path': photoFilePath,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (gpsAccuracyMeters != null) 'gps_accuracy_meters': gpsAccuracyMeters,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (state != null) 'state': state,
      if (attempts != null) 'attempts': attempts,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (lastErrorMessage != null) 'last_error_message': lastErrorMessage,
      if (lastErrorStatus != null) 'last_error_status': lastErrorStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  OutboxEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? clientUuid,
      Value<String>? mutationType,
      Value<int?>? projectId,
      Value<int?>? taskId,
      Value<String>? payloadJson,
      Value<String?>? photoFilePath,
      Value<double?>? latitude,
      Value<double?>? longitude,
      Value<double?>? gpsAccuracyMeters,
      Value<DateTime?>? capturedAt,
      Value<String>? state,
      Value<int>? attempts,
      Value<DateTime?>? nextRetryAt,
      Value<String?>? lastErrorMessage,
      Value<int?>? lastErrorStatus,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return OutboxEntriesCompanion(
      id: id ?? this.id,
      clientUuid: clientUuid ?? this.clientUuid,
      mutationType: mutationType ?? this.mutationType,
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      payloadJson: payloadJson ?? this.payloadJson,
      photoFilePath: photoFilePath ?? this.photoFilePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsAccuracyMeters: gpsAccuracyMeters ?? this.gpsAccuracyMeters,
      capturedAt: capturedAt ?? this.capturedAt,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      lastErrorStatus: lastErrorStatus ?? this.lastErrorStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (mutationType.present) {
      map['mutation_type'] = Variable<String>(mutationType.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (photoFilePath.present) {
      map['photo_file_path'] = Variable<String>(photoFilePath.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (gpsAccuracyMeters.present) {
      map['gps_accuracy_meters'] = Variable<double>(gpsAccuracyMeters.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (lastErrorMessage.present) {
      map['last_error_message'] = Variable<String>(lastErrorMessage.value);
    }
    if (lastErrorStatus.present) {
      map['last_error_status'] = Variable<int>(lastErrorStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntriesCompanion(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('mutationType: $mutationType, ')
          ..write('projectId: $projectId, ')
          ..write('taskId: $taskId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('photoFilePath: $photoFilePath, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('gpsAccuracyMeters: $gpsAccuracyMeters, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('lastErrorStatus: $lastErrorStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$OutboxDb extends GeneratedDatabase {
  _$OutboxDb(QueryExecutor e) : super(e);
  $OutboxDbManager get managers => $OutboxDbManager(this);
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [outboxEntries];
}

typedef $$OutboxEntriesTableCreateCompanionBuilder = OutboxEntriesCompanion
    Function({
  Value<int> id,
  required String clientUuid,
  required String mutationType,
  Value<int?> projectId,
  Value<int?> taskId,
  required String payloadJson,
  Value<String?> photoFilePath,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<double?> gpsAccuracyMeters,
  Value<DateTime?> capturedAt,
  required String state,
  Value<int> attempts,
  Value<DateTime?> nextRetryAt,
  Value<String?> lastErrorMessage,
  Value<int?> lastErrorStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$OutboxEntriesTableUpdateCompanionBuilder = OutboxEntriesCompanion
    Function({
  Value<int> id,
  Value<String> clientUuid,
  Value<String> mutationType,
  Value<int?> projectId,
  Value<int?> taskId,
  Value<String> payloadJson,
  Value<String?> photoFilePath,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<double?> gpsAccuracyMeters,
  Value<DateTime?> capturedAt,
  Value<String> state,
  Value<int> attempts,
  Value<DateTime?> nextRetryAt,
  Value<String?> lastErrorMessage,
  Value<int?> lastErrorStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$OutboxEntriesTableFilterComposer
    extends Composer<_$OutboxDb, $OutboxEntriesTable> {
  $$OutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mutationType => $composableBuilder(
      column: $table.mutationType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taskId => $composableBuilder(
      column: $table.taskId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoFilePath => $composableBuilder(
      column: $table.photoFilePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get gpsAccuracyMeters => $composableBuilder(
      column: $table.gpsAccuracyMeters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastErrorMessage => $composableBuilder(
      column: $table.lastErrorMessage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastErrorStatus => $composableBuilder(
      column: $table.lastErrorStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$OutboxEntriesTableOrderingComposer
    extends Composer<_$OutboxDb, $OutboxEntriesTable> {
  $$OutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mutationType => $composableBuilder(
      column: $table.mutationType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taskId => $composableBuilder(
      column: $table.taskId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoFilePath => $composableBuilder(
      column: $table.photoFilePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get gpsAccuracyMeters => $composableBuilder(
      column: $table.gpsAccuracyMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastErrorMessage => $composableBuilder(
      column: $table.lastErrorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastErrorStatus => $composableBuilder(
      column: $table.lastErrorStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$OutboxEntriesTableAnnotationComposer
    extends Composer<_$OutboxDb, $OutboxEntriesTable> {
  $$OutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => column);

  GeneratedColumn<String> get mutationType => $composableBuilder(
      column: $table.mutationType, builder: (column) => column);

  GeneratedColumn<int> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<int> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get photoFilePath => $composableBuilder(
      column: $table.photoFilePath, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get gpsAccuracyMeters => $composableBuilder(
      column: $table.gpsAccuracyMeters, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => column);

  GeneratedColumn<String> get lastErrorMessage => $composableBuilder(
      column: $table.lastErrorMessage, builder: (column) => column);

  GeneratedColumn<int> get lastErrorStatus => $composableBuilder(
      column: $table.lastErrorStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OutboxEntriesTableTableManager extends RootTableManager<
    _$OutboxDb,
    $OutboxEntriesTable,
    OutboxEntry,
    $$OutboxEntriesTableFilterComposer,
    $$OutboxEntriesTableOrderingComposer,
    $$OutboxEntriesTableAnnotationComposer,
    $$OutboxEntriesTableCreateCompanionBuilder,
    $$OutboxEntriesTableUpdateCompanionBuilder,
    (OutboxEntry, BaseReferences<_$OutboxDb, $OutboxEntriesTable, OutboxEntry>),
    OutboxEntry,
    PrefetchHooks Function()> {
  $$OutboxEntriesTableTableManager(_$OutboxDb db, $OutboxEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> clientUuid = const Value.absent(),
            Value<String> mutationType = const Value.absent(),
            Value<int?> projectId = const Value.absent(),
            Value<int?> taskId = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<String?> photoFilePath = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<double?> gpsAccuracyMeters = const Value.absent(),
            Value<DateTime?> capturedAt = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<DateTime?> nextRetryAt = const Value.absent(),
            Value<String?> lastErrorMessage = const Value.absent(),
            Value<int?> lastErrorStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              OutboxEntriesCompanion(
            id: id,
            clientUuid: clientUuid,
            mutationType: mutationType,
            projectId: projectId,
            taskId: taskId,
            payloadJson: payloadJson,
            photoFilePath: photoFilePath,
            latitude: latitude,
            longitude: longitude,
            gpsAccuracyMeters: gpsAccuracyMeters,
            capturedAt: capturedAt,
            state: state,
            attempts: attempts,
            nextRetryAt: nextRetryAt,
            lastErrorMessage: lastErrorMessage,
            lastErrorStatus: lastErrorStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String clientUuid,
            required String mutationType,
            Value<int?> projectId = const Value.absent(),
            Value<int?> taskId = const Value.absent(),
            required String payloadJson,
            Value<String?> photoFilePath = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<double?> gpsAccuracyMeters = const Value.absent(),
            Value<DateTime?> capturedAt = const Value.absent(),
            required String state,
            Value<int> attempts = const Value.absent(),
            Value<DateTime?> nextRetryAt = const Value.absent(),
            Value<String?> lastErrorMessage = const Value.absent(),
            Value<int?> lastErrorStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              OutboxEntriesCompanion.insert(
            id: id,
            clientUuid: clientUuid,
            mutationType: mutationType,
            projectId: projectId,
            taskId: taskId,
            payloadJson: payloadJson,
            photoFilePath: photoFilePath,
            latitude: latitude,
            longitude: longitude,
            gpsAccuracyMeters: gpsAccuracyMeters,
            capturedAt: capturedAt,
            state: state,
            attempts: attempts,
            nextRetryAt: nextRetryAt,
            lastErrorMessage: lastErrorMessage,
            lastErrorStatus: lastErrorStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OutboxEntriesTableProcessedTableManager = ProcessedTableManager<
    _$OutboxDb,
    $OutboxEntriesTable,
    OutboxEntry,
    $$OutboxEntriesTableFilterComposer,
    $$OutboxEntriesTableOrderingComposer,
    $$OutboxEntriesTableAnnotationComposer,
    $$OutboxEntriesTableCreateCompanionBuilder,
    $$OutboxEntriesTableUpdateCompanionBuilder,
    (OutboxEntry, BaseReferences<_$OutboxDb, $OutboxEntriesTable, OutboxEntry>),
    OutboxEntry,
    PrefetchHooks Function()>;

class $OutboxDbManager {
  final _$OutboxDb _db;
  $OutboxDbManager(this._db);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
}
