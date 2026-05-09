/// Wire values mirror the `mutation_type` column stored in `outbox_entries`
/// and the dispatch switch in [SyncService].
enum OutboxMutationType {
  taskMarkComplete,
  siteReportCreate,
  delayLogCreate;

  String toWire() {
    switch (this) {
      case OutboxMutationType.taskMarkComplete:
        return 'TASK_MARK_COMPLETE';
      case OutboxMutationType.siteReportCreate:
        return 'SITE_REPORT_CREATE';
      case OutboxMutationType.delayLogCreate:
        return 'DELAY_LOG_CREATE';
    }
  }

  static OutboxMutationType fromWire(String wire) {
    switch (wire) {
      case 'TASK_MARK_COMPLETE':
        return OutboxMutationType.taskMarkComplete;
      case 'SITE_REPORT_CREATE':
        return OutboxMutationType.siteReportCreate;
      case 'DELAY_LOG_CREATE':
        return OutboxMutationType.delayLogCreate;
      default:
        throw ArgumentError('Unknown OutboxMutationType wire value: $wire');
    }
  }
}
