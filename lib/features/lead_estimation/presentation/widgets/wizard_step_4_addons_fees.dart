import 'package:flutter/material.dart';
import 'package:admin/features/lead_estimation/presentation/screens/lead_estimation_wizard_screen.dart';

/// Step 4 — Add-ons, site fees, govt fees.
///
/// MVP placeholder. The catalog endpoints for these (per-package add-ons,
/// city-specific site fees, govt fees) are not yet exposed publicly. For now
/// this step is a skip-able placeholder that passes empty arrays to the
/// backend, which is a valid no-op.
class WizardStep4AddOnsFees extends StatelessWidget {
  // ignore: unused_element_parameter — kept for symmetry with other steps
  final WizardDraft draft;
  // ignore: unused_element_parameter
  final VoidCallback onChanged;

  const WizardStep4AddOnsFees({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blueGrey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add-ons & fees — coming soon',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Optional add-ons (modular kitchen, smart-home, false ceiling, '
            'designer lighting), site fees (sloped lot, hard-rock excavation), '
            'and government fees (permits, deposits) will be selectable here '
            'once public endpoints are shipped. Leave empty and continue.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
