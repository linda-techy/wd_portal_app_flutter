import 'package:flutter/material.dart';
import 'package:admin/services/boq_payment_service.dart';
import 'package:admin/services/customer_project_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';

/// Default 8 payment stages seeded from the DPC default plan. Percentages are
/// shown to the user as integers (e.g. 10) and converted to fractions on
/// submit (0.10).
const List<Map<String, dynamic>> _defaultStages = [
  {'name': 'Booking & design freeze', 'percent': 10.0},
  {'name': 'Foundation completion', 'percent': 15.0},
  {'name': 'Ground floor slab', 'percent': 15.0},
  {'name': 'First floor slab + masonry', 'percent': 15.0},
  {'name': 'Plastering & waterproofing', 'percent': 12.0},
  {'name': 'Flooring & joinery', 'percent': 12.0},
  {'name': 'MEP fitouts & painting', 'percent': 13.0},
  {'name': 'Final handover', 'percent': 8.0},
];

class CustomerApproveBoqDialog extends StatefulWidget {
  final int boqDocumentId;
  final int projectId;
  final VoidCallback onApproved;

  const CustomerApproveBoqDialog({
    super.key,
    required this.boqDocumentId,
    required this.projectId,
    required this.onApproved,
  });

  @override
  State<CustomerApproveBoqDialog> createState() =>
      _CustomerApproveBoqDialogState();
}

class _StageRow {
  final TextEditingController nameCtrl;
  final TextEditingController percentCtrl;

  _StageRow(String name, double percent)
      : nameCtrl = TextEditingController(text: name),
        percentCtrl = TextEditingController(
            text: percent == percent.roundToDouble()
                ? percent.toStringAsFixed(0)
                : percent.toString());

  void dispose() {
    nameCtrl.dispose();
    percentCtrl.dispose();
  }
}

class _CustomerApproveBoqDialogState extends State<CustomerApproveBoqDialog> {
  final _boqService = BoqPaymentService();
  final _projectService = CustomerProjectService();

  bool _loadingMembers = true;
  String? _membersError;
  List<Map<String, dynamic>> _members = [];
  int? _selectedMemberId;

  late List<_StageRow> _stages;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _stages = _defaultStages
        .map((m) => _StageRow(m['name'] as String, m['percent'] as double))
        .toList();
    for (final s in _stages) {
      s.nameCtrl.addListener(_onChanged);
      s.percentCtrl.addListener(_onChanged);
    }
    _loadMembers();
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    for (final s in _stages) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _projectService.getProjectMembers(widget.projectId);
      // Prefer OWNER, fall back to all members.
      final owners = members
          .where((m) =>
              (m['roleInProject']?.toString().toUpperCase() ?? '') == 'OWNER')
          .toList();
      final filtered = owners.isNotEmpty ? owners : members;
      if (!mounted) return;
      setState(() {
        _members = filtered;
        _loadingMembers = false;
        if (_members.length == 1) {
          _selectedMemberId = _toIntOrNull(_members.first['customerUserId']);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMembers = false;
        _membersError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  static int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  double get _totalPercent {
    double total = 0;
    for (final s in _stages) {
      total += double.tryParse(s.percentCtrl.text.trim()) ?? 0;
    }
    return total;
  }

  bool get _isSumValid {
    // Allow tiny float drift (sum equals 100 within 0.01%).
    return (_totalPercent - 100).abs() < 0.01;
  }

  bool get _allStagesValid {
    for (final s in _stages) {
      if (s.nameCtrl.text.trim().isEmpty) return false;
      final pct = double.tryParse(s.percentCtrl.text.trim());
      if (pct == null || pct <= 0) return false;
    }
    return _stages.isNotEmpty;
  }

  void _addStage() {
    setState(() {
      final row = _StageRow('', 0.0);
      row.nameCtrl.addListener(_onChanged);
      row.percentCtrl.addListener(_onChanged);
      _stages.add(row);
    });
  }

  void _deleteStage(int index) {
    setState(() {
      _stages.removeAt(index).dispose();
    });
  }

  void _moveStage(int index, int delta) {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _stages.length) return;
    setState(() {
      final s = _stages.removeAt(index);
      _stages.insert(newIndex, s);
    });
  }

  Future<void> _submit() async {
    if (_selectedMemberId == null || !_allStagesValid || !_isSumValid) return;
    setState(() => _submitting = true);
    try {
      final stages = _stages
          .map((s) => (
                name: s.nameCtrl.text.trim(),
                percentage:
                    (double.tryParse(s.percentCtrl.text.trim()) ?? 0) / 100.0,
              ))
          .toList();
      await _boqService.customerApproveDocument(
        widget.boqDocumentId,
        _selectedMemberId!,
        stages,
      );
      widget.onApproved();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final msg = e.toString();
      if (msg.contains('403') ||
          msg.toLowerCase().contains('not.*member') ||
          msg.toLowerCase().contains('do not have permission')) {
        await ErrorHandler.handleApiError(
          context,
          'Customer is not a member of this project — add them as project member first.',
          defaultMessage: 'Customer-approve failed',
        );
      } else {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Customer-approve failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final width = media.width > 720 ? 700.0 : media.width * 0.95;
    final maxHeight = media.height * 0.85;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSignerSection(),
                    const SizedBox(height: 20),
                    _buildStagesSection(),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppTheme.coralRed),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Record Customer Approval',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed:
                    _submitting ? null : () => Navigator.of(context).pop(false),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 34, right: 12),
            child: Text(
              'Use this after the customer confirms approval offline '
              '(call, meeting, WhatsApp). You sign off on their behalf — '
              'pick which customer signatory confirmed and enter the agreed '
              'payment stages.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer signatory (who confirmed approval)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (_loadingMembers)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text('Loading project members…'),
              ],
            ),
          )
        else if (_membersError != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _membersError!,
              style: const TextStyle(color: AppTheme.errorRed),
            ),
          )
        else if (_members.isEmpty)
          const Text(
            'No project members found. Add a customer as a project member first.',
            style: TextStyle(color: AppTheme.errorRed),
          )
        else
          DropdownButtonFormField<int>(
            value: _selectedMemberId,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            hint: const Text('Select customer signer'),
            items: _members.map((m) {
              final id = _toIntOrNull(m['customerUserId']) ?? 0;
              final name = (m['fullName'] ?? '').toString();
              final email = (m['email'] ?? '').toString();
              final role = (m['roleInProject'] ?? '').toString();
              return DropdownMenuItem<int>(
                value: id,
                child: Text(
                  '$name${email.isNotEmpty ? ' ($email)' : ''}'
                  '${role.isNotEmpty ? ' — $role' : ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _submitting
                ? null
                : (v) => setState(() => _selectedMemberId = v),
          ),
      ],
    );
  }

  Widget _buildStagesSection() {
    final total = _totalPercent;
    final isValid = _isSumValid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Payment Stages',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _submitting ? null : _addStage,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add stage'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Each stage represents a payment milestone. Percentages must sum to 100%.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < _stages.length; i++) _buildStageRow(i),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: (isValid ? AppTheme.successGreen : AppTheme.errorRed)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.error_outline,
                color: isValid ? AppTheme.successGreen : AppTheme.errorRed,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isValid
                    ? 'Total: 100%'
                    : 'Total: ${total.toStringAsFixed(2)}% (must equal 100%)',
                style: TextStyle(
                  color: isValid ? AppTheme.successGreen : AppTheme.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStageRow(int index) {
    final s = _stages[index];
    final isFirst = index == 0;
    final isLast = index == _stages.length - 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag-handle-styled index
          SizedBox(
            width: 24,
            child: Text(
              '${index + 1}.',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
          // Name field
          Expanded(
            flex: 5,
            child: TextField(
              controller: s.nameCtrl,
              enabled: !_submitting,
              decoration: const InputDecoration(
                hintText: 'Stage name',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Percent field
          SizedBox(
            width: 90,
            child: TextField(
              controller: s.percentCtrl,
              enabled: !_submitting,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'e.g. 10',
                suffixText: '%',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
          // Reorder + delete
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 18),
            tooltip: 'Move up',
            onPressed:
                isFirst || _submitting ? null : () => _moveStage(index, -1),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 18),
            tooltip: 'Move down',
            onPressed:
                isLast || _submitting ? null : () => _moveStage(index, 1),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppTheme.errorRed),
            tooltip: 'Delete',
            onPressed: _submitting || _stages.length == 1
                ? null
                : () => _deleteStage(index),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final canSubmit =
        !_submitting && _selectedMemberId != null && _allStagesValid && _isSumValid;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed:
                _submitting ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: canSubmit ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.coralRed,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            label: Text(_submitting ? 'Recording…' : 'Record Approval'),
          ),
        ],
      ),
    );
  }
}
