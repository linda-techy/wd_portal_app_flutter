/// Lifecycle state for an outbox row. Wire values are stored in the `state`
/// column.
enum OutboxState {
  pending,
  inFlight,
  permanentFailure,
  done;

  String toWire() {
    switch (this) {
      case OutboxState.pending:
        return 'PENDING';
      case OutboxState.inFlight:
        return 'IN_FLIGHT';
      case OutboxState.permanentFailure:
        return 'PERMANENT_FAILURE';
      case OutboxState.done:
        return 'DONE';
    }
  }

  static OutboxState fromWire(String wire) {
    switch (wire) {
      case 'PENDING':
        return OutboxState.pending;
      case 'IN_FLIGHT':
        return OutboxState.inFlight;
      case 'PERMANENT_FAILURE':
        return OutboxState.permanentFailure;
      case 'DONE':
        return OutboxState.done;
      default:
        throw ArgumentError('Unknown OutboxState wire value: $wire');
    }
  }
}
