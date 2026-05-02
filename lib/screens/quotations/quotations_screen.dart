import 'package:flutter/material.dart';
import 'package:admin/constants.dart';

/// Legacy quotation list screen — removed as part of C.PR-4 cutover.
///
/// The quotation workflow is now handled entirely through the Estimations tab
/// on each lead's detail screen (LeadQuotationsScreen → _LeadEstimationsSection).
/// This stub keeps the `/quotations` shell-route alive so the router
/// and side-menu entry compile without changes.
class QuotationsScreen extends StatelessWidget {
  const QuotationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calculate_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Estimations are now managed per lead',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Open a lead and go to the Quotations tab to view\nor generate estimations.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
