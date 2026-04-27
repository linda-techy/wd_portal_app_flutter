import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:admin/constants.dart';
import 'package:admin/features/dpc_customization_catalog/data/models/dpc_customization_catalog_item.dart';
import 'package:admin/features/dpc_customization_catalog/data/services/dpc_customization_catalog_service.dart';
import 'package:admin/utils/error_handler.dart';

/// Modal dialog used by the DPC builder to add customization lines sourced
/// from the master catalog.
///
/// Persisting mode only — POSTs to
/// `/api/dpc-documents/{dpcDocumentId}/customizations/from-catalog` and
/// invokes [onAdded] with the raw line-item map the backend returned. The
/// caller is then expected to refresh the DPC document.
class DpcCustomizationCatalogPickerDialog extends StatefulWidget {
  /// DPC document to append the customization line to.
  final int dpcDocumentId;

  /// Invoked after a successful add with the new line map
  /// (`{id, displayOrder, title, description, amount, source, ...}`).
  final void Function(Map<String, dynamic> newLine)? onAdded;

  const DpcCustomizationCatalogPickerDialog({
    super.key,
    required this.dpcDocumentId,
    this.onAdded,
  });

  @override
  State<DpcCustomizationCatalogPickerDialog> createState() =>
      _DpcCustomizationCatalogPickerDialogState();
}

class _DpcCustomizationCatalogPickerDialogState
    extends State<DpcCustomizationCatalogPickerDialog> {
  final DpcCustomizationCatalogService _service =
      DpcCustomizationCatalogService();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _search = '';
  String? _category;

  List<DpcCustomizationCatalogItem> _items = [];
  bool _loading = true;
  String? _error;

  // Track which row is currently expanded — only one at a time keeps the
  // dialog compact and predictable.
  int? _expandedId;
  // Per-row override controllers — built lazily when a row expands.
  final Map<int, TextEditingController> _amountCtrls = {};
  // Track per-row "adding" state for the spinner on the Add button.
  final Set<int> _addingIds = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.search(
        search: _search.isEmpty ? null : _search,
        category: _category,
        isActive: true,
        page: 0,
        size: 50,
        sortBy: 'timesUsed',
        sortDirection: 'desc',
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorHandler.getErrorMessage(e);
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _search = v.trim();
      });
      _load();
    });
  }

  /// Categories derived from the currently loaded result set.
  List<String> get _categories {
    final set = <String>{};
    for (final it in _items) {
      if (it.category != null && it.category!.isNotEmpty) {
        set.add(it.category!);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> _addItem(DpcCustomizationCatalogItem it) async {
    final amtStr = _amountCtrls[it.id]?.text.trim() ?? '';
    final parsed = amtStr.isEmpty ? null : double.tryParse(amtStr);
    // Only send an override when it differs from the catalog default —
    // keeps the audit trail clean (a "real" override is logged) and lets
    // the backend stamp the row with its catalog-default amount otherwise.
    final amountOverride =
        (parsed != null && parsed != it.defaultAmount) ? parsed : null;

    setState(() => _addingIds.add(it.id));
    try {
      final newLine = await _service.addCustomizationFromCatalog(
        dpcDocumentId: widget.dpcDocumentId,
        catalogItemId: it.id,
        amountOverride: amountOverride,
      );
      if (!mounted) return;
      widget.onAdded?.call(newLine);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
        setState(() => _addingIds.remove(it.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 720,
        height: 640,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                children: [
                  const Icon(Icons.tune,
                      color: primaryColor, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Add Customization from Catalog',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by code, name, description...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            // Category chips
            if (_categories.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  children: [
                    _categoryChip(null, 'All'),
                    const SizedBox(width: 6),
                    ..._categories.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _categoryChip(c, c),
                        )),
                  ],
                ),
              ),
            const Divider(height: 1),
            // Body — list of items
            Expanded(child: _buildBody()),
            const Divider(height: 1),
            // Footer — helper text
            const Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.help_outline,
                      size: 16, color: textSecondary),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tip: tap a row to expand and override the default '
                      'amount before adding.',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String? value, String label) {
    final selected = _category == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _category = value);
        _load();
      },
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36, color: errorColor),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('No catalog items match your search.',
            style: TextStyle(color: textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (ctx, i) => _itemCard(_items[i]),
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemCount: _items.length,
    );
  }

  Widget _itemCard(DpcCustomizationCatalogItem it) {
    final expanded = _expandedId == it.id;
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: expanded ? primaryColor : containerBorder,
          width: expanded ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedId = null;
                } else {
                  _expandedId = it.id;
                  _amountCtrls.putIfAbsent(
                    it.id,
                    () => TextEditingController(
                        text: it.defaultAmount.toStringAsFixed(0)),
                  );
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Code chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: boxInfo,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: boxBorderInfo),
                    ),
                    child: Text(
                      it.code,
                      style: const TextStyle(
                        fontSize: 11,
                        color: infoColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                        if (it.category != null && it.category!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: boxGray,
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: containerBorder),
                              ),
                              child: Text(it.category!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: textSecondary)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Times-used badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: it.timesUsed > 0 ? boxSuccess : boxGray,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: it.timesUsed > 0
                            ? boxBorderSuccess
                            : containerBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.show_chart,
                            size: 12,
                            color: it.timesUsed > 0
                                ? successColor
                                : textSecondary),
                        const SizedBox(width: 3),
                        Text('${it.timesUsed}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: it.timesUsed > 0
                                  ? successColor
                                  : textSecondary,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _currency.format(it.defaultAmount) +
                        (it.unit != null && it.unit!.isNotEmpty
                            ? ' / ${it.unit}'
                            : ''),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more,
                      color: textMuted),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (it.description != null && it.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        it.description!,
                        style: const TextStyle(
                            fontSize: 12.5, color: textSecondary),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountCtrls[it.id],
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Amount (override)',
                            prefixText: '\u20B9 ',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: _addingIds.contains(it.id)
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.add, size: 16),
                        label: Text(_addingIds.contains(it.id)
                            ? 'Adding...'
                            : 'Add to DPC'),
                        onPressed: _addingIds.contains(it.id)
                            ? null
                            : () => _addItem(it),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
