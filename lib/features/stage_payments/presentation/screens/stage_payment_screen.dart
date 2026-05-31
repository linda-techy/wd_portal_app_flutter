import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/models/stage_payment_models.dart';
import 'package:admin/services/stage_payment_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/services/reports/payment_report.dart';

class StagePaymentScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const StagePaymentScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<StagePaymentScreen> createState() => _StagePaymentScreenState();
}

class _StagePaymentScreenState extends State<StagePaymentScreen> {
  final StagePaymentService _service = StagePaymentService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  List<StageTimelineSummary> _stages = [];
  bool _isLoading = true;
  int? _expandedStageId;

  static const _statusColors = {
    'UPCOMING': Colors.grey,
    'DUE':      Colors.orange,
    'INVOICED': Colors.blue,
    'PAID':     Colors.green,
    'OVERDUE':  Colors.red,
    'ON_HOLD':  Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stages = await _service.getProjectStages(widget.projectId);
      if (!mounted) return;
      setState(() {
        _stages = stages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _certifyStage(StageTimelineSummary stage) async {
    final certCtrl = TextEditingController();
    final retCtrl = TextEditingController(text: '5');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Certify Stage ${stage.stageNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: certCtrl,
              decoration: const InputDecoration(
                  labelText: 'Certified By *',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: retCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Retention %',
                  border: OutlineInputBorder(),
                  suffixText: '%'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Certify',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (certCtrl.text.trim().isEmpty) {
      ErrorHandler.showErrorSnackBar(context, 'Certified By is required');
      return;
    }
    try {
      final retPct = (double.tryParse(retCtrl.text) ?? 5.0) / 100.0;
      await _service.certify(
        widget.projectId,
        stage.id,
        CertifyStageRequest(
            certifiedBy: certCtrl.text.trim(),
            retentionPct: retPct),
      );
      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(
          context, 'Stage ${stage.stageNumber} certified');
      await _load();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _exportPdf() async {
    try {
      await PaymentReport.generate(
          projectName: widget.projectName, stages: _stages);
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.deepSlate,
        foregroundColor: Colors.white,
        title: Text('Stages — ${widget.projectName}',
            style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export PDF',
              onPressed: _exportPdf),
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTimeline(),
    );
  }

  Widget _buildTimeline() {
    if (_stages.isEmpty) {
      return const Center(
          child: Text('No payment stages found.',
              style: TextStyle(color: Colors.grey)));
    }

    // Summary row
    final totalHeld = _stages.fold<double>(
        0, (s, st) => s + (st.retentionHeld ?? 0));
    final totalPaid = _stages
        .where((s) => s.status == 'PAID')
        .fold<double>(0, (s, st) => s + st.netPayableAmount);

    return Column(
      children: [
        _summaryBar(totalPaid, totalHeld),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _stages.length,
              itemBuilder: (_, i) => _buildStageCard(_stages[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryBar(double totalPaid, double totalHeld) => Container(
        color: AppTheme.deepSlate,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _summaryItem('Paid', _currency.format(totalPaid), Colors.green),
            const SizedBox(width: 24),
            _summaryItem(
                'Retention Held', _currency.format(totalHeld), Colors.orange),
            const Spacer(),
            Text('${_stages.length} stages',
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      );

  Widget _summaryItem(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      );

  Widget _buildStageCard(StageTimelineSummary stage) {
    final statusColor = _statusColors[stage.status] ?? Colors.grey;
    final isExpanded = _expandedStageId == stage.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.15),
              child: Text('${stage.stageNumber}',
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.bold)),
            ),
            title: Text(stage.stageName,
                style: const TextStyle(fontWeight: FontWeight.w600,
                    fontSize: 14)),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(stage.status,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                if (stage.certified)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.verified_outlined,
                        size: 14, color: Colors.green[700]),
                  ),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_currency.format(stage.netPayableAmount),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.deepSlate)),
                if (stage.retentionHeld != null &&
                    stage.retentionHeld! > 0)
                  Text(
                      'Ret: ${_currency.format(stage.retentionHeld!)}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.orange)),
              ],
            ),
            onTap: () => setState(() =>
                _expandedStageId = isExpanded ? null : stage.id),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  if (stage.dueDate != null)
                    Text('Due: ${stage.dueDate}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  if (stage.certifiedAt != null)
                    Text(
                        'Certified: ${stage.certifiedAt!.substring(0, 10)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  if (!stage.certified &&
                      (stage.status == 'UPCOMING' ||
                          stage.status == 'DUE'))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.coralRed),
                        icon: const Icon(Icons.verified_outlined,
                            size: 16, color: Colors.white),
                        label: const Text('Certify Stage',
                            style: TextStyle(color: Colors.white)),
                        onPressed: () => _certifyStage(stage),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
