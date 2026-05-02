import 'package:flutter/material.dart';
import 'package:admin/features/lead_estimation/data/models/estimation_options.dart';
import 'package:admin/features/lead_estimation/presentation/screens/lead_estimation_wizard_screen.dart';
import 'package:admin/features/lead_estimation/providers/estimation_options_provider.dart';

/// Step 3 — Customisations.
///
/// Renders a [RadioListTile] group per customisation category returned by
/// [EstimationOptionsProvider]. Selecting an option updates
/// [WizardDraft.customisations] (replaces any existing entry for the same
/// category, keeping exactly one selection per category).
///
/// Shows a loading spinner while the provider is fetching, an error message
/// with a retry button if the fetch failed, and the previous "coming soon"
/// placeholder when the catalog is empty.
class WizardStep3Customisations extends StatelessWidget {
  final WizardDraft draft;
  final VoidCallback onChanged;
  final EstimationOptionsProvider optionsProvider;

  const WizardStep3Customisations({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.optionsProvider,
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String? _selectedOptionFor(String categoryId) {
    for (final entry in draft.customisations) {
      if (entry['categoryId'] == categoryId) return entry['optionId'];
    }
    return null;
  }

  void _selectOption(String categoryId, String optionId) {
    draft.customisations.removeWhere((e) => e['categoryId'] == categoryId);
    draft.customisations.add({'categoryId': categoryId, 'optionId': optionId});
    onChanged();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (optionsProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (optionsProvider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              optionsProvider.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => optionsProvider.loadForPackage(draft.packageId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final categories =
        optionsProvider.options?.customisationCategories ?? <CustomisationCategoryRef>[];

    // Empty / coming-soon state
    if (categories.isEmpty) {
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
              'catalog is populated. For now, leave empty and continue.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Catalog loaded — render categories + radio groups
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categories.map((category) {
          return _CategorySection(
            category: category,
            selectedOptionId: _selectedOptionFor(category.id),
            onSelect: (optionId) => _selectOption(category.id, optionId),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widget
// ---------------------------------------------------------------------------

class _CategorySection extends StatelessWidget {
  final CustomisationCategoryRef category;
  final String? selectedOptionId;
  final ValueChanged<String> onSelect;

  const _CategorySection({
    required this.category,
    required this.selectedOptionId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              category.name,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ...category.options.map((option) {
            return RadioListTile<String>(
              dense: true,
              value: option.id,
              groupValue: selectedOptionId,
              title: Text(option.name),
              subtitle: Text('₹${option.rate.toStringAsFixed(2)}'),
              onChanged: (value) {
                if (value != null) onSelect(value);
              },
            );
          }),
        ],
      ),
    );
  }
}
