import 'package:flutter/material.dart';
import 'package:admin/features/lead_estimation/data/models/lead_estimation.dart' show EstimationPricingMode;
import 'package:admin/features/lead_estimation/presentation/screens/lead_estimation_wizard_screen.dart';

/// Step 2 — Floor dimensions, semi-covered area, open-terrace area.
///
/// Mutates [draft] in place; calls [onChanged] after every change so the
/// parent Stepper rebuilds.
class WizardStep2Dimensions extends StatelessWidget {
  final WizardDraft draft;
  final VoidCallback onChanged;

  const WizardStep2Dimensions({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  String? _validatePositive(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Must be a number';
    if (n <= 0) return 'Must be > 0';
    return null;
  }

  String? _validateNonNegative(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Must be a number';
    if (n < 0) return 'Must be >= 0';
    return null;
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }

  void _addFloor() {
    draft.floors.add(WizardFloorInput()..name = 'Floor ${draft.floors.length + 1}');
    onChanged();
  }

  void _removeFloor(int i) {
    if (draft.floors.length <= 1) return;
    draft.floors.removeAt(i);
    onChanged();
  }

  Widget _buildBudgetary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Estimated buildable area',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'At lead stage, exact per-floor dimensions usually aren\u2019t known. '
          'Enter a rough total buildable area; the estimate will be a \u00b110% range '
          'around (area \u00d7 base rate).',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: (draft.estimatedAreaSqft ?? 0) > 0
              ? draft.estimatedAreaSqft!.toString()
              : '',
          decoration: const InputDecoration(
            labelText: 'Estimated buildable area (sqft) *',
            border: OutlineInputBorder(),
            hintText: 'e.g. 2000',
          ),
          keyboardType: TextInputType.number,
          validator: _validatePositive,
          onChanged: (v) {
            draft.estimatedAreaSqft = double.tryParse(v.trim());
            onChanged();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (draft.pricingMode == EstimationPricingMode.BUDGETARY) {
      return _buildBudgetary(context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Floors',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (int i = 0; i < draft.floors.length; i++) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: draft.floors[i].name,
                          decoration:
                              const InputDecoration(labelText: 'Floor name *'),
                          validator: _validateName,
                          onChanged: (v) {
                            draft.floors[i].name = v;
                            onChanged();
                          },
                        ),
                      ),
                      if (draft.floors.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remove floor',
                          onPressed: () => _removeFloor(i),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: draft.floors[i].length > 0
                              ? draft.floors[i].length.toString()
                              : '',
                          decoration:
                              const InputDecoration(labelText: 'Length (ft) *'),
                          keyboardType: TextInputType.number,
                          validator: _validatePositive,
                          onChanged: (v) {
                            draft.floors[i].length =
                                double.tryParse(v.trim()) ?? 0;
                            onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: draft.floors[i].width > 0
                              ? draft.floors[i].width.toString()
                              : '',
                          decoration:
                              const InputDecoration(labelText: 'Width (ft) *'),
                          keyboardType: TextInputType.number,
                          validator: _validatePositive,
                          onChanged: (v) {
                            draft.floors[i].width =
                                double.tryParse(v.trim()) ?? 0;
                            onChanged();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add another floor'),
            onPressed: _addFloor,
          ),
        ),
        const SizedBox(height: 16),
        const Text('Other areas',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: draft.semiCoveredArea > 0
              ? draft.semiCoveredArea.toString()
              : '0',
          decoration:
              const InputDecoration(labelText: 'Semi-covered area (sqft)'),
          keyboardType: TextInputType.number,
          validator: _validateNonNegative,
          onChanged: (v) {
            draft.semiCoveredArea = double.tryParse(v.trim()) ?? 0;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: draft.openTerraceArea > 0
              ? draft.openTerraceArea.toString()
              : '0',
          decoration:
              const InputDecoration(labelText: 'Open terrace area (sqft)'),
          keyboardType: TextInputType.number,
          validator: _validateNonNegative,
          onChanged: (v) {
            draft.openTerraceArea = double.tryParse(v.trim()) ?? 0;
            onChanged();
          },
        ),
      ],
    );
  }
}
