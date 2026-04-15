import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/models/final_account_models.dart';
import 'package:admin/services/final_account_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';

class FinalAccountScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const FinalAccountScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<FinalAccountScreen> createState() => _FinalAccountScreenState();
}

class _FinalAccountScreenState extends State<FinalAccountScreen> {
  final FinalAccountService _service = FinalAccountService();
  final _currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  FinalAccountData? _fa;
  bool _isLoading = true;
  bool _isActing = false;

  static const _statusColors = {
    'DRAFT':      Colors.grey,
    'SUBMITTED':  Colors.orange,
    'DISPUTED':   Colors.red,
    'AGREED':     Colors.green,
    'CLOSED':     Colors.black54,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final fa = await _service.getByProject(widget.projectId);
      if (!mounted) return;
      setState(() {
        _fa = fa;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // 404 means no final account yet — that's OK
    }
  }

  Future<void> _createFinalAccount() async {
    final baseCtrl = TextEditingController();
    final addCtrl = TextEditingController(text: '0');
    final dedCtrl = TextEditingController(text: '0');
    final recCtrl = TextEditingController(text: '0');
    final retCtrl = TextEditingController(text: '0');
    final prepCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Final Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(baseCtrl, 'Base Contract Value *'),
              const SizedBox(height: 10),
              _dialogField(addCtrl, 'Total Additions'),
              const SizedBox(height: 10),
              _dialogField(dedCtrl, 'Total Accepted Deductions'),
              const SizedBox(height: 10),
              _dialogField(recCtrl, 'Total Received to Date'),
              const SizedBox(height: 10),
              _dialogField(retCtrl, 'Total Retention Held'),
              const SizedBox(height: 10),
              TextField(
                controller: prepCtrl,
                decoration: const InputDecoration(
                    labelText: 'Prepared By *',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isActing = true);
    try {
      final fa = await _service.create(
        widget.projectId,
        CreateFinalAccountRequest(
          baseContractValue: double.parse(baseCtrl.text),
          totalAdditions: double.tryParse(addCtrl.text),
          totalAcceptedDeductions: double.tryParse(dedCtrl.text),
          totalReceivedToDate: double.tryParse(recCtrl.text),
          totalRetentionHeld: double.tryParse(retCtrl.text),
          preparedBy: prepCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() => _fa = fa);
      ErrorHandler.showSuccessSnackBar(context, 'Final account created');
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _transitionStatus(String targetStatus, {String? agreedBy}) async {
    String? by = agreedBy;
    if (targetStatus == 'AGREED') {
      final ctrl = TextEditingController();
      by = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Mark as Agreed'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
                labelText: 'Agreed By *',
                border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green),
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Confirm',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (by == null || by.isEmpty || !mounted) return;
    }
    setState(() => _isActing = true);
    try {
      final fa = await _service.updateStatus(
        widget.projectId,
        FinalAccountStatusRequest(
            targetStatus: targetStatus, agreedBy: by),
      );
      if (!mounted) return;
      setState(() => _fa = fa);
      ErrorHandler.showSuccessSnackBar(
          context, 'Status updated to $targetStatus');
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _recompute() async {
    setState(() => _isActing = true);
    try {
      final fa = await _service.recompute(widget.projectId);
      if (!mounted) return;
      setState(() => _fa = fa);
      ErrorHandler.showSuccessSnackBar(context, 'Totals recomputed');
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.deepSlate,
        foregroundColor: Colors.white,
        title: Text('Final Account — ${widget.projectName}',
            style: const TextStyle(fontSize: 16)),
        actions: [
          if (_fa != null && _fa!.isDraft)
            IconButton(
              icon: const Icon(Icons.calculate_outlined),
              tooltip: 'Recompute Totals',
              onPressed: _recompute,
            ),
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _fa == null ? _buildEmpty() : _buildContent(),
                if (_isActing)
                  const ColoredBox(
                    color: Colors.black26,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No final account prepared yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.coralRed),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Final Account',
                  style: TextStyle(color: Colors.white)),
              onPressed: _createFinalAccount,
            ),
          ],
        ),
      );

  Widget _buildContent() {
    final fa = _fa!;
    final statusColor = _statusColors[fa.status] ?? Colors.grey;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status + action row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Text(fa.status,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            const Spacer(),
            ..._buildActionButtons(fa),
          ],
        ),
        const SizedBox(height: 16),

        // Financial summary
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Financial Summary',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.deepSlate)),
                const Divider(height: 16),
                _finRow('Base Contract Value',
                    _currency.format(fa.baseContractValue)),
                _finRow('+ Total Additions',
                    _currency.format(fa.totalAdditions),
                    valueColor: Colors.green),
                _finRow('− Accepted Deductions',
                    _currency.format(fa.totalAcceptedDeductions),
                    valueColor: Colors.red),
                const Divider(height: 12),
                _finRow('Net Revised Contract Value',
                    _currency.format(fa.netRevisedContractValue),
                    bold: true),
                _finRow('Total Received to Date',
                    _currency.format(fa.totalReceivedToDate)),
                _finRow('Total Retention Held',
                    _currency.format(fa.totalRetentionHeld),
                    valueColor: Colors.orange),
                const Divider(height: 12),
                _finRow('Balance Payable',
                    _currency.format(fa.balancePayable),
                    bold: true,
                    valueColor: fa.balancePayable > 0
                        ? Colors.red
                        : Colors.green),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // DLP & Retention
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DLP & Retention',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.deepSlate)),
                const Divider(height: 16),
                _finRow('DLP Start', fa.dlpStartDate ?? '—'),
                _finRow('DLP End', fa.dlpEndDate ?? '—'),
                _finRow('Retention Released',
                    fa.retentionReleased ? 'Yes' : 'No',
                    valueColor: fa.retentionReleased
                        ? Colors.green
                        : Colors.orange),
                if (fa.retentionReleaseDate != null)
                  _finRow('Released On', fa.retentionReleaseDate!),
              ],
            ),
          ),
        ),
        if (fa.preparedBy != null || fa.agreedBy != null) ...[
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (fa.preparedBy != null)
                    _finRow('Prepared By', fa.preparedBy!),
                  if (fa.agreedBy != null)
                    _finRow('Agreed By', fa.agreedBy!),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActionButtons(FinalAccountData fa) {
    if (fa.isDraft) {
      return [
        _actionBtn('Submit', Colors.orange,
            () => _transitionStatus('SUBMITTED')),
      ];
    }
    if (fa.isSubmitted) {
      return [
        _actionBtn('Mark Agreed', Colors.green,
            () => _transitionStatus('AGREED')),
        const SizedBox(width: 8),
        _actionBtn('Disputed', Colors.red,
            () => _transitionStatus('DISPUTED')),
      ];
    }
    if (fa.isDisputed) {
      return [
        _actionBtn('Re-submit', Colors.orange,
            () => _transitionStatus('SUBMITTED')),
      ];
    }
    if (fa.isAgreed && !fa.retentionReleased) {
      return [
        _actionBtn('Release Retention', Colors.teal, _releaseRetention),
      ];
    }
    return [];
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) =>
      ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6)),
        onPressed: onTap,
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      );

  Future<void> _releaseRetention() async {
    final releasedByCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Release Retention'),
        content: TextField(
          controller: releasedByCtrl,
          decoration: const InputDecoration(
              labelText: 'Released By *',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Release',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isActing = true);
    try {
      final now = DateTime.now().toIso8601String().substring(0, 10);
      final fa = await _service.releaseRetention(
        widget.projectId,
        ReleaseRetentionRequest(
            releaseDate: now,
            releasedBy: releasedByCtrl.text.trim()),
      );
      if (!mounted) return;
      setState(() => _fa = fa);
      ErrorHandler.showSuccessSnackBar(context, 'Retention released');
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Widget _finRow(String label, String value,
      {bool bold = false, Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 13)),
            ),
            Expanded(
              flex: 4,
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      fontWeight:
                          bold ? FontWeight.bold : FontWeight.normal,
                      color: valueColor ?? AppTheme.deepSlate,
                      fontSize: 13)),
            ),
          ],
        ),
      );

  TextField _dialogField(TextEditingController ctrl, String label) =>
      TextField(
        controller: ctrl,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
      );
}
