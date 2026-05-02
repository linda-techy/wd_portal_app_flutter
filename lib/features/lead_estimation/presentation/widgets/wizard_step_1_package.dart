import 'package:flutter/material.dart';
import 'package:admin/features/estimation_settings/data/models/package_rate_version.dart';
import 'package:admin/features/estimation_settings/providers/estimation_packages_provider.dart';
import 'package:admin/features/lead_estimation/presentation/screens/lead_estimation_wizard_screen.dart';

/// Step 1 — Package + Project Type selection.
///
/// Mutates [draft] in-place; calls [onChanged] after every change so the
/// parent Stepper rebuilds.
class WizardStep1Package extends StatelessWidget {
  final WizardDraft draft;
  final EstimationPackagesProvider packagesProvider;
  final VoidCallback onChanged;

  const WizardStep1Package({
    super.key,
    required this.draft,
    required this.packagesProvider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final packages = packagesProvider.packages;
    final isLoading = packagesProvider.isLoading;
    final error = packagesProvider.errorMessage;

    if (isLoading && packages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null && packages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Failed to load packages: $error',
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: packagesProvider.load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: draft.packageId,
          decoration: const InputDecoration(
            labelText: 'Estimation Package *',
            border: OutlineInputBorder(),
          ),
          items: packages
              .map((p) => DropdownMenuItem<String>(
                    value: p.id,
                    child: Text('${p.internalName} — ${p.marketingName}'),
                  ))
              .toList(),
          onChanged: (v) {
            draft.packageId = v;
            onChanged();
          },
          validator: (v) => v == null ? 'Please select a package' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ProjectType>(
          value: draft.projectType,
          decoration: const InputDecoration(
            labelText: 'Project Type *',
            border: OutlineInputBorder(),
          ),
          items: ProjectType.values
              .map((pt) => DropdownMenuItem<ProjectType>(
                    value: pt,
                    child: Text(pt.name),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              draft.projectType = v;
              onChanged();
            }
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Note: Only NEW_BUILD and COMMERCIAL are fully supported today.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
