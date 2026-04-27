import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:admin/constants.dart';
import 'package:admin/features/quotation_catalog/data/models/quotation_catalog_item.dart';
import 'package:admin/features/quotation_catalog/data/services/quotation_catalog_service.dart';
import 'package:admin/utils/error_handler.dart';

/// Modal dialog used by the lead-quotation builder to add line items sourced
/// from the master catalog.
///
/// Two operating modes:
///
/// 1. **Persisting mode** (default) — when [quotationId] is non-null, the
///    "Add" button POSTs to `/leads/quotations/{id}/items/from-catalog`
///    immediately and invokes [onItemAdded] with the raw line-item map the
///    backend returned.
/// 2. **Preview mode** — when [quotationId] is null, the dialog does NOT
///    hit the network. Instead it invokes [onPreviewItemAdded] with the
///    picked catalog row and the user's qty / unit-price overrides, letting
///    the caller append the row to a still-being-edited form (e.g. the
///    create-quotation screen, where no quotationId exists yet).
///
/// Tapping "Add custom item" closes the dialog after invoking
/// [onAddCustomRequested], letting the parent open its existing ad-hoc form.
class QuotationCatalogPickerDialog extends StatefulWidget {
  /// Quotation to append to. When non-null the picker persists the line
  /// directly via the backend. When null, see [onPreviewItemAdded].
  final int? quotationId;
  final void Function(Map<String, dynamic> newItem)? onItemAdded;

  /// Invoked instead of [onItemAdded] when the dialog is in preview mode
  /// (i.e. [quotationId] is null). Receives the chosen catalog row plus the
  /// user's optional qty / unit-price overrides — the caller is responsible
  /// for building the in-memory line-item row.
  final void Function(
    QuotationCatalogItem item, {
    double? quantity,
    double? unitPriceOverride,
  })? onPreviewItemAdded;

  final VoidCallback? onAddCustomRequested;

  const QuotationCatalogPickerDialog({
    super.key,
    this.quotationId,
    this.onItemAdded,
    this.onPreviewItemAdded,
    this.onAddCustomRequested,
  }) : assert(
          quotationId != null || onPreviewItemAdded != null,
          'Either quotationId (persisting mode) or onPreviewItemAdded '
          '(preview mode) must be supplied.',
        );

  @override
  State<QuotationCatalogPickerDialog> createState() =>
      _QuotationCatalogPickerDialogState();
}

class _QuotationCatalogPickerDialogState
    extends State<QuotationCatalogPickerDialog> {
  final QuotationCatalogService _service = QuotationCatalogService();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _search = '';
  String? _category;

  List<QuotationCatalogItem> _items = [];
  bool _loading = true;
  String? _error;

  // Track which row is currently expanded — only one at a time keeps the
  // dialog compact and predictable.
  int? _expandedId;
  // Per-row override controllers — built lazily when a row expands.
  final Map<int, TextEditingController> _qtyCtrls = {};
  final Map<int, TextEditingController> _priceCtrls = {};
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
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    for (final c in _priceCtrls.values) {
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

  Future<void> _addItem(QuotationCatalogItem it) async {
    final qty = double.tryParse(_qtyCtrls[it.id]?.text.trim() ?? '');
    final priceStr = _priceCtrls[it.id]?.text.trim() ?? '';
    final priceOverride = priceStr.isEmpty ? null : double.tryParse(priceStr);

    // Preview mode — no network hit, just hand the picked row back to the
    // caller so they can splice it into their in-memory form.
    if (widget.quotationId == null) {
      widget.onPreviewItemAdded?.call(
        it,
        quantity: qty,
        unitPriceOverride: priceOverride,
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() => _addingIds.add(it.id));
    try {
      final newItem = await _service.addItemFromCatalog(
        quotationId: widget.quotationId!,
        catalogItemId: it.id,
        quantity: qty,
        unitPriceOverride: priceOverride,
      );
      if (!mounted) return;
      widget.onItemAdded?.call(newItem);
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
                  const Icon(Icons.inventory_2_outlined,
                      color: primaryColor, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Add from Catalog',
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
                  hintText: 'Search items by code, name, description...',
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
            // Footer — custom-item escape hatch
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.help_outline,
                      size: 16, color: textSecondary),
                  const SizedBox(width: 6),
                  const Text(
                    "Can't find what you need?",
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add custom item'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onAddCustomRequested?.call();
                    },
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

  Widget _itemCard(QuotationCatalogItem it) {
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
                  _qtyCtrls.putIfAbsent(it.id,
                      () => TextEditingController(text: '1'));
                  _priceCtrls.putIfAbsent(
                    it.id,
                    () => TextEditingController(
                        text: it.defaultUnitPrice.toStringAsFixed(0)),
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
                    _currency.format(it.defaultUnitPrice) +
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
                      SizedBox(
                        width: 130,
                        child: TextField(
                          controller: _qtyCtrls[it.id],
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            suffixText: it.unit,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _priceCtrls[it.id],
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Unit price (override)',
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
                            : 'Add to quotation'),
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
