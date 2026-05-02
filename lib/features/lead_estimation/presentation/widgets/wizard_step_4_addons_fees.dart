import 'package:flutter/material.dart';
import 'package:admin/features/lead_estimation/data/models/estimation_options.dart';
import 'package:admin/features/lead_estimation/presentation/screens/lead_estimation_wizard_screen.dart';
import 'package:admin/features/lead_estimation/providers/estimation_options_provider.dart';

/// Step 4 — Add-ons, site fees, govt fees.
///
/// Renders three labeled sections (Add-ons / Site Fees / Govt Fees). Each item
/// is a [CheckboxListTile]; toggling it adds/removes the item ID from the
/// corresponding list in [WizardDraft].
///
/// Site fee cost display respects the [SiteFeeRef.mode] field:
///   - `LUMP` → "₹50,000.00"
///   - `PER_SQFT` → "₹50.00/sqft"
///
/// Shows the same loading / error / empty states as Step 3.
class WizardStep4AddOnsFees extends StatelessWidget {
  final WizardDraft draft;
  final VoidCallback onChanged;
  final EstimationOptionsProvider optionsProvider;

  const WizardStep4AddOnsFees({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.optionsProvider,
  });

  // ---------------------------------------------------------------------------
  // Toggle helpers
  // ---------------------------------------------------------------------------

  void _toggleAddon(String id) {
    if (draft.addOnIds.contains(id)) {
      draft.addOnIds.remove(id);
    } else {
      draft.addOnIds.add(id);
    }
    onChanged();
  }

  void _toggleSiteFee(String id) {
    if (draft.siteFeeIds.contains(id)) {
      draft.siteFeeIds.remove(id);
    } else {
      draft.siteFeeIds.add(id);
    }
    onChanged();
  }

  void _toggleGovtFee(String id) {
    if (draft.govtFeeIds.contains(id)) {
      draft.govtFeeIds.remove(id);
    } else {
      draft.govtFeeIds.add(id);
    }
    onChanged();
  }

  // ---------------------------------------------------------------------------
  // Cost label helpers
  // ---------------------------------------------------------------------------

  String _addonCostLabel(AddonRef addon) =>
      '₹${addon.lumpAmount.toStringAsFixed(2)}';

  String _siteFeeCostLabel(SiteFeeRef fee) {
    if (fee.mode == 'PER_SQFT') {
      final rate = fee.perSqftRate ?? 0.0;
      return '₹${rate.toStringAsFixed(2)}/sqft';
    }
    final amount = fee.lumpAmount ?? 0.0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _govtFeeCostLabel(GovtFeeRef fee) =>
      '₹${fee.lumpAmount.toStringAsFixed(2)}';

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

    final options = optionsProvider.options;
    final addons = options?.addons ?? <AddonRef>[];
    final siteFees = options?.siteFees ?? <SiteFeeRef>[];
    final govtFees = options?.govtFees ?? <GovtFeeRef>[];

    // Empty / coming-soon state
    if (addons.isEmpty && siteFees.isEmpty && govtFees.isEmpty) {
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
              'once the catalog is populated. Leave empty and continue.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Catalog loaded — render three sections
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (addons.isNotEmpty) ...[
            const _SectionHeader(label: 'Add-ons'),
            ...addons.map((addon) => CheckboxListTile(
                  dense: true,
                  value: draft.addOnIds.contains(addon.id),
                  title: Text(addon.name),
                  subtitle: Text(_addonCostLabel(addon)),
                  onChanged: (_) => _toggleAddon(addon.id),
                )),
            const SizedBox(height: 12),
          ],
          if (siteFees.isNotEmpty) ...[
            const _SectionHeader(label: 'Site Fees'),
            ...siteFees.map((fee) => CheckboxListTile(
                  dense: true,
                  value: draft.siteFeeIds.contains(fee.id),
                  title: Text(fee.name),
                  subtitle: Text(_siteFeeCostLabel(fee)),
                  onChanged: (_) => _toggleSiteFee(fee.id),
                )),
            const SizedBox(height: 12),
          ],
          if (govtFees.isNotEmpty) ...[
            const _SectionHeader(label: 'Govt Fees'),
            ...govtFees.map((fee) => CheckboxListTile(
                  dense: true,
                  value: draft.govtFeeIds.contains(fee.id),
                  title: Text(fee.name),
                  subtitle: Text(_govtFeeCostLabel(fee)),
                  onChanged: (_) => _toggleGovtFee(fee.id),
                )),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widget
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
