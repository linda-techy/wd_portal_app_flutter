import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/theme/app_theme.dart';

/// Displays the three VO payment tranches (advance / progress / completion)
/// in a card with status indicators.
///
/// [advancePct], [progressPct], [completionPct] are percentages (e.g. 20.0).
/// [advanceAmount], etc. are monetary values.
/// [advanceStatus], etc. are COPaymentStatus strings: PENDING · INVOICED · PAID.
class PaymentBreakdownCard extends StatelessWidget {
  final double advancePct;
  final double progressPct;
  final double completionPct;
  final double advanceAmount;
  final double progressAmount;
  final double completionAmount;
  final String advanceStatus;
  final String progressStatus;
  final String completionStatus;

  const PaymentBreakdownCard({
    super.key,
    required this.advancePct,
    required this.progressPct,
    required this.completionPct,
    required this.advanceAmount,
    required this.progressAmount,
    required this.completionAmount,
    required this.advanceStatus,
    required this.progressStatus,
    required this.completionStatus,
  });

  static final _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static const _statusColors = <String, Color>{
    'PENDING':  Colors.grey,
    'INVOICED': Colors.orange,
    'PAID':     Colors.green,
  };

  Color _statusColor(String status) =>
      _statusColors[status] ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Schedule',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.deepSlate,
              ),
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                    child: _tranche('Advance',
                        advancePct, advanceAmount, advanceStatus)),
                const SizedBox(width: 8),
                Expanded(
                    child: _tranche('Progress',
                        progressPct, progressAmount, progressStatus)),
                const SizedBox(width: 8),
                Expanded(
                    child: _tranche('Completion',
                        completionPct, completionAmount, completionStatus)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tranche(
      String label, double pct, double amount, String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text('${pct.toStringAsFixed(0)}%',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.deepSlate)),
          Text(_currency.format(amount),
              style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status,
                style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
