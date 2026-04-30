import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:admin/models/customer_project.dart';
import 'package:admin/services/customer_project_service.dart';
import 'package:admin/services/location_service.dart';
import 'package:admin/utils/error_handler.dart';

/// Site GPS card on the project detail screen (V82).
///
/// States:
///   * Not yet captured → "Capture site GPS" button (visible to anyone
///     with PROJECT_EDIT — the controller enforces auth).
///   * Locked (gpsLockedAt set) → coordinates displayed with a lock badge
///     and the locker's user id; an "Override (Admin)" button appears
///     only when [canOverride] is true (caller passes admin role check).
///
/// Calls back to [onUpdated] with the fresh project so the parent screen
/// can re-render without a full reload.
class ProjectGpsCard extends StatefulWidget {
  final int projectId;
  final bool canOverride;

  const ProjectGpsCard({
    super.key,
    required this.projectId,
    required this.canOverride,
  });

  @override
  State<ProjectGpsCard> createState() => _ProjectGpsCardState();
}

class _ProjectGpsCardState extends State<ProjectGpsCard> {
  final _service = CustomerProjectService();
  bool _busy = false;
  bool _loading = true;
  CustomerProject? _project;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _service.getProjectById(widget.projectId);
      if (mounted) setState(() { _project = p; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _captureAndSave() async {
    setState(() => _busy = true);
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos.latitude == 0.0 && pos.longitude == 0.0) {
        throw LocationException(
            'GPS not yet ready. Please wait a moment and try again.');
      }
      final updated = await _service.lockProjectGps(
          widget.projectId, pos.latitude, pos.longitude);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Site GPS saved and locked.')),
      );
      setState(() => _project = updated);
    } on LocationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmOverride() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Override site GPS?'),
        content: const Text(
            'This will replace the locked coordinates with your current GPS. '
            'Site-visit check-ins are validated against this location, so '
            'change it only if the original capture was wrong.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Override'),
          ),
        ],
      ),
    );
    if (ok == true) await _captureAndSave();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final p = _project;
    if (p == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Failed to load project — try again.'),
        ),
      );
    }
    final locked = p.isGpsLocked;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(locked ? Icons.lock_outlined : Icons.gps_off,
                    color: locked ? Colors.green : Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Site GPS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                if (locked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('LOCKED',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (locked) ...[
              SelectableText(
                '${p.latitude!.toStringAsFixed(6)}, ${p.longitude!.toStringAsFixed(6)}',
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Locked ${p.gpsLockedAt != null ? DateFormat('dd MMM yyyy, HH:mm').format(p.gpsLockedAt!) : ""}'
                '${p.gpsLockedByUserId != null ? " · by user #${p.gpsLockedByUserId}" : ""}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                'Site-visit check-ins must be within 2 km of this location.',
                style: TextStyle(
                    color: Colors.grey.shade700, fontSize: 12),
              ),
              if (widget.canOverride) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _confirmOverride,
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: Text(_busy
                      ? 'Capturing…'
                      : 'Override (Admin)'),
                ),
              ],
            ] else ...[
              const Text(
                'Site GPS has not been captured yet. Site-visit check-ins '
                'cannot be validated against a location until this is set. '
                'Stand at the project site and tap below.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _captureAndSave,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.my_location),
                label: Text(_busy ? 'Capturing…' : 'Capture site GPS'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
