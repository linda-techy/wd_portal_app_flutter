import 'package:flutter/material.dart';

/// Three-card tier picker (Economy / Standard / Premium) for the BUDGETARY
/// stage. The same shape Walldot's customer sees on the PDF — so staff
/// pick what the customer will see.
///
/// Selection is stored as a string ('ECONOMY' | 'STANDARD' | 'PREMIUM') to
/// match the backend `tier` column. Default Walldot ranges are hard-wired
/// here; once the rate_card admin UI lands they should be fed in via
/// [tierRanges] instead.
class TierSelectorCards extends StatelessWidget {
  final String? selectedTier;
  final ValueChanged<String> onChanged;
  final Map<String, ({double min, double max})> tierRanges;

  const TierSelectorCards({
    super.key,
    required this.selectedTier,
    required this.onChanged,
    this.tierRanges = const {
      'ECONOMY': (min: 1750, max: 1950),
      'STANDARD': (min: 1950, max: 2150),
      'PREMIUM': (min: 2150, max: 2500),
    },
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tier in const ['ECONOMY', 'STANDARD', 'PREMIUM'])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _TierCard(
                tier: tier,
                range: tierRanges[tier]!,
                selected: selectedTier == tier,
                isMostPicked: tier == 'STANDARD' && selectedTier == null,
                onTap: () => onChanged(tier),
              ),
            ),
          ),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  final String tier;
  final ({double min, double max}) range;
  final bool selected;
  final bool isMostPicked;
  final VoidCallback onTap;

  const _TierCard({
    required this.tier,
    required this.range,
    required this.selected,
    required this.isMostPicked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.06)
              : null,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(tier,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text('₹${range.min.toStringAsFixed(0)} – ${range.max.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('per sq.ft.', style: TextStyle(fontSize: 11)),
            if (selected)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text('YOUR TIER',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: 0.5)),
              )
            else if (isMostPicked)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text('★ MOST PICKED',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: 0.5)),
              ),
          ],
        ),
      ),
    );
  }
}
