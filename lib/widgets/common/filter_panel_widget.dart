import 'package:flutter/material.dart';

/// Reusable filter panel widget
/// Used across all modules for consistent filter UX
class FilterPanelWidget extends StatelessWidget {
  final Map<String, dynamic> filters;
  final Function(Map<String, dynamic>) onApply;
  final Function() onClear;
  final List<FilterField> fields;
  final bool isLoading;

  const FilterPanelWidget({
    super.key,
    required this.filters,
    required this.onApply,
    required this.onClear,
    required this.fields,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: isLoading ? null : onClear,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Filter fields
            ...fields.map((field) => _buildFilterField(context, field)),

            const SizedBox(height: 16),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => onApply(filters),
                icon: const Icon(Icons.filter_list),
                label: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterField(BuildContext context, FilterField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: field.build(context),
    );
  }
}

/// Abstract class for filter fields
abstract class FilterField {
  final String key;
  final String label;

  const FilterField({
    required this.key,
    required this.label,
  });

  Widget build(BuildContext context);
}

/// Dropdown filter field
class DropdownFilterField extends FilterField {
  final List<DropdownItem> items;
  final dynamic value;
  final Function(dynamic) onChanged;
  final String? hint;

  const DropdownFilterField({
    required super.key,
    required super.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField(
          value: value,
          decoration: InputDecoration(
            hintText: hint ?? 'Select $label',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(hint ?? 'All')),
            ...items.map((item) => DropdownMenuItem(
                  value: item.value,
                  child: Text(item.label),
                )),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Date range filter field
class DateRangeFilterField extends FilterField {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onChanged;

  const DateRangeFilterField({
    required super.key,
    required super.label,
    required this.startDate,
    required this.endDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                context,
                'From',
                startDate,
                (date) => onChanged(date, endDate),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateField(
                context,
                'To',
                endDate,
                (date) => onChanged(startDate, date),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? value,
    Function(DateTime?) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        child: Text(
          value != null
              ? '${value.day}/${value.month}/${value.year}'
              : 'Select date',
        ),
      ),
    );
  }
}

/// Text input filter field
class TextInputFilterField extends FilterField {
  final String? value;
  final Function(String) onChanged;
  final String? hint;

  const TextInputFilterField({
    required super.key,
    required super.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value),
          decoration: InputDecoration(
            hintText: hint ?? 'Enter $label',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Number range filter field
class NumberRangeFilterField extends FilterField {
  final num? min;
  final num? max;
  final Function(num?, num?) onChanged;
  final String? minHint;
  final String? maxHint;

  const NumberRangeFilterField({
    required super.key,
    required super.label,
    required this.min,
    required this.max,
    required this.onChanged,
    this.minHint,
    this.maxHint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(
                  text: min?.toString() ?? '',
                ),
                decoration: InputDecoration(
                  hintText: minHint ?? 'Min',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final numValue = num.tryParse(value);
                  onChanged(numValue, max);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: TextEditingController(
                  text: max?.toString() ?? '',
                ),
                decoration: InputDecoration(
                  hintText: maxHint ?? 'Max',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final numValue = num.tryParse(value);
                  onChanged(min, numValue);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Helper class for dropdown items
class DropdownItem {
  final dynamic value;
  final String label;

  const DropdownItem({
    required this.value,
    required this.label,
  });
}
