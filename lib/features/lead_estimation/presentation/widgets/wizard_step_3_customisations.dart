import 'package:flutter/material.dart';
import 'package:admin/features/lead_estimation/presentation/screens/lead_estimation_wizard_screen.dart';

/// Step 3 — Customisations.
///
/// MVP placeholder. The customisation-category endpoint is not yet exposed
/// publicly (`GET /api/estimation/customisation-categories?packageId=X` is a
/// future sub-project). For now this step is a skip-able placeholder that
/// passes `customisations: []` to the backend, which is a valid no-op.
class WizardStep3Customisations extends StatelessWidget {
  // ignore: unused_element_parameter — draft kept for symmetry with other steps;
  // future revisions will mutate `draft.customisations` once the endpoint exists
  final WizardDraft draft;
  // ignore: unused_element_parameter
  final VoidCallback onChanged;

  const WizardStep3Customisations({
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
                  'Customisations — coming soon',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Per-package customisation categories (kitchen finish, bathroom '
            'fittings, flooring, etc.) will be selectable here once the '
            'public endpoint is shipped. For now, leave empty and continue.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
