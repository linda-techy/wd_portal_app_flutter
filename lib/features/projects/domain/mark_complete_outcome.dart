/// Result of the offline mark-complete wrapper. Returned to the bottom-sheet
/// `_MarkCompleteRow` so it can transition its state machine without knowing
/// the details of camera/GPS/outbox plumbing.
///
/// S5.1 — see docs/superpowers/specs/2026-05-10-s5-1-task-progress-offline-wiring-design.md
sealed class MarkCompleteOutcome {
  const MarkCompleteOutcome();

  factory MarkCompleteOutcome.queued(int reportEntryId, int markCompleteEntryId) =
      MarkCompleteQueued;
  factory MarkCompleteOutcome.failed(MarkCompleteError reason, [String? message]) =
      MarkCompleteFailed;
}

class MarkCompleteQueued extends MarkCompleteOutcome {
  const MarkCompleteQueued(this.reportEntryId, this.markCompleteEntryId);
  final int reportEntryId;
  final int markCompleteEntryId;
}

class MarkCompleteFailed extends MarkCompleteOutcome {
  const MarkCompleteFailed(this.reason, [this.message]);
  final MarkCompleteError reason;
  final String? message;
}

enum MarkCompleteError {
  /// `image_picker` returned null (cancelled by user OR permission denied).
  cameraDenied,

  /// `LocationService.getCurrentPosition` threw `LocationException` or
  /// any other error while resolving GPS.
  gpsUnavailable,

  /// One of the two `OutboxService.enqueue` calls (or the `int.tryParse` of
  /// the task id, or a missing project id) failed. Compensating rollback is
  /// best-effort.
  outboxFailure,
}
