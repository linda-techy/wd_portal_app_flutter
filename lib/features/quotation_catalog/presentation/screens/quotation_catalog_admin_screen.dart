import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:admin/constants.dart';
import 'package:admin/features/quotation_catalog/data/models/quotation_catalog_item.dart';
import 'package:admin/features/quotation_catalog/data/services/quotation_catalog_service.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/utils/error_handler.dart';

/// Admin CRUD screen for the master Quotation Item Catalog.
///
/// Backed by `GET/POST/PATCH/DELETE /api/quotation-catalog` — listing,
/// creation, edit (via dialog), soft-delete, and quick toggle of `isActive`.
class QuotationCatalogAdminScreen extends StatefulWidget {
  const QuotationCatalogAdminScreen({super.key});

  @override
  State<QuotationCatalogAdminScreen> createState() =>
      _QuotationCatalogAdminScreenState();
}

class _QuotationCatalogAdminScreenState
    extends State<QuotationCatalogAdminScreen> {
  final QuotationCatalogService _service = QuotationCatalogService();

  // Indian-locale rupee formatter (no decimals — large catalog prices read
  // cleaner without paise; matches the rest of the portal).
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  // ---- Filters / paging state ----
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  String _search = '';
  String? _categoryFilter; // null = all
  // 3-state Active filter: null = All, true = Active only, false = Inactive only
  bool? _activeFilter;
  String _sortBy = 'timesUsed';
  String _sortDirection = 'desc';
  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  static const int _pageSize = 50;

  // ---- Data ----
  List<QuotationCatalogItem> _items = [];
  // Categories collected across all paged pulls — keeps the dropdown stable
  // even after filters narrow the visible result set.
  final Set<String> _knownCategories = <String>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
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
        category: _categoryFilter,
        isActive: _activeFilter,
        page: _page,
        size: _pageSize,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _totalElements = result.totalElements;
        _totalPages = result.totalPages;
        for (final it in result.items) {
          if (it.category != null && it.category!.isNotEmpty) {
            _knownCategories.add(it.category!);
          }
        }
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
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _search = v.trim();
        _page = 0;
      });
      _load();
    });
  }

  void _toggleSort(String column) {
    setState(() {
      if (_sortBy == column) {
        _sortDirection = _sortDirection == 'asc' ? 'desc' : 'asc';
      } else {
        _sortBy = column;
        _sortDirection = column == 'timesUsed' ? 'desc' : 'asc';
      }
      _page = 0;
    });
    _load();
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<QuotationCatalogItem>(
      context: context,
      builder: (_) => _CatalogItemEditDialog(
        service: _service,
        existingCategories: _knownCategories.toList()..sort(),
      ),
    );
    if (created != null) {
      ErrorHandler.showSuccessSnackBar(
        // ignore: use_build_context_synchronously
        context,
        'Catalog item created (${created.code})',
      );
      _load();
    }
  }

  Future<void> _openEditDialog(QuotationCatalogItem item) async {
    final saved = await showDialog<QuotationCatalogItem>(
      context: context,
      builder: (_) => _CatalogItemEditDialog(
        service: _service,
        existing: item,
        existingCategories: _knownCategories.toList()..sort(),
      ),
    );
    if (saved != null) {
      ErrorHandler.showSuccessSnackBar(
        // ignore: use_build_context_synchronously
        context,
        'Catalog item updated',
      );
      _load();
    }
  }

  Future<void> _toggleActive(QuotationCatalogItem item) async {
    try {
      await _service.update(item.id, isActive: !item.isActive);
      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(
        context,
        item.isActive ? 'Item disabled' : 'Item enabled',
      );
      _load();
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _confirmDelete(QuotationCatalogItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete catalog item?'),
        content: Text(
          'Soft-delete "${item.name}" (${item.code})? '
          'It will be hidden from the picker but historical line items '
          'remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteCatalogItem(item.id);
      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(context, 'Catalog item deleted');
      _load();
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permProvider = context.watch<PermissionProvider>();
    final canManage = permProvider.hasPermission('QUOTATION_CATALOG_MANAGE');

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Quotation Item Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(right: defaultPadding),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Item'),
                onPressed: _openCreateDialog,
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFiltersRow(),
            const SizedBox(height: 8),
            Text(
              '$_totalElements item${_totalElements == 1 ? '' : 's'}',
              style: const TextStyle(color: textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(canManage)),
            if (!_loading && _totalPages > 1) _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    final categories = _knownCategories.toList()..sort();
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: containerBorder),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
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
          const SizedBox(width: 12),
          // Category dropdown
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String?>(
              value: _categoryFilter,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All categories'),
                ),
                ...categories.map((c) =>
                    DropdownMenuItem<String?>(value: c, child: Text(c))),
              ],
              onChanged: (v) {
                setState(() {
                  _categoryFilter = v;
                  _page = 0;
                });
                _load();
              },
            ),
          ),
          const SizedBox(width: 12),
          // Active 3-state filter
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              value: _activeFilter == null ? 0 : (_activeFilter! ? 1 : 2),
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('All')),
                DropdownMenuItem(value: 1, child: Text('Active only')),
                DropdownMenuItem(value: 2, child: Text('Inactive only')),
              ],
              onChanged: (v) {
                setState(() {
                  _activeFilter =
                      v == 0 ? null : (v == 1 ? true : false);
                  _page = 0;
                });
                _load();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool canManage) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: errorColor),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            const Text('No catalog items found',
                style: TextStyle(color: textSecondary)),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: containerBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(boxSecondary),
              columnSpacing: 16,
              horizontalMargin: 16,
              sortColumnIndex: _sortColumnIndex(),
              sortAscending: _sortDirection == 'asc',
              columns: [
                DataColumn(
                  label: const Text('Code',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (_, __) => _toggleSort('code'),
                ),
                DataColumn(
                  label: const Text('Name',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (_, __) => _toggleSort('name'),
                ),
                DataColumn(
                  label: const Text('Category',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (_, __) => _toggleSort('category'),
                ),
                const DataColumn(
                    label: Text('Unit',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                  label: const Text('Default Price',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  numeric: true,
                  onSort: (_, __) => _toggleSort('defaultUnitPrice'),
                ),
                DataColumn(
                  label: const Text('Times Used',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  numeric: true,
                  onSort: (_, __) => _toggleSort('timesUsed'),
                ),
                const DataColumn(
                    label: Text('Active',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(
                    label: Text('Actions',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _items.map((it) => _buildRow(it, canManage)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  int? _sortColumnIndex() {
    switch (_sortBy) {
      case 'code':
        return 0;
      case 'name':
        return 1;
      case 'category':
        return 2;
      case 'defaultUnitPrice':
        return 4;
      case 'timesUsed':
        return 5;
      default:
        return null;
    }
  }

  DataRow _buildRow(QuotationCatalogItem it, bool canManage) {
    return DataRow(
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  it.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (it.description != null && it.description!.isNotEmpty)
                  Text(
                    it.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 11, color: textSecondary),
                  ),
              ],
            ),
          ),
        ),
        DataCell(Text(it.category ?? '-')),
        DataCell(Text(it.unit ?? '-')),
        DataCell(Text(_currency.format(it.defaultUnitPrice))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: it.timesUsed > 0 ? boxSuccess : boxGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: it.timesUsed > 0 ? boxBorderSuccess : containerBorder,
              ),
            ),
            child: Text(
              '${it.timesUsed}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: it.timesUsed > 0 ? successColor : textSecondary,
              ),
            ),
          ),
        ),
        DataCell(
          Icon(
            it.isActive ? Icons.check_circle : Icons.cancel_outlined,
            color: it.isActive ? successColor : textMuted,
            size: 18,
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit',
                onPressed: canManage ? () => _openEditDialog(it) : null,
                splashRadius: 18,
              ),
              IconButton(
                icon: Icon(
                  it.isActive
                      ? Icons.toggle_on
                      : Icons.toggle_off_outlined,
                  size: 22,
                ),
                tooltip: it.isActive ? 'Disable' : 'Enable',
                color: it.isActive ? successColor : textMuted,
                onPressed: canManage ? () => _toggleActive(it) : null,
                splashRadius: 18,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: 'Delete',
                color: errorColor,
                onPressed: canManage ? () => _confirmDelete(it) : null,
                splashRadius: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.only(top: defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 0
                ? () {
                    setState(() => _page--);
                    _load();
                  }
                : null,
          ),
          Text('Page ${_page + 1} of $_totalPages',
              style: const TextStyle(fontSize: 13)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < _totalPages - 1
                ? () {
                    setState(() => _page++);
                    _load();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create / Edit dialog
// ─────────────────────────────────────────────────────────────────────────────

class _CatalogItemEditDialog extends StatefulWidget {
  final QuotationCatalogService service;
  final QuotationCatalogItem? existing;
  final List<String> existingCategories;

  const _CatalogItemEditDialog({
    required this.service,
    this.existing,
    this.existingCategories = const [],
  });

  @override
  State<_CatalogItemEditDialog> createState() => _CatalogItemEditDialogState();
}

class _CatalogItemEditDialogState extends State<_CatalogItemEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _priceCtrl;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _categoryCtrl = TextEditingController(text: e?.category ?? '');
    _unitCtrl = TextEditingController(text: e?.unit ?? '');
    _priceCtrl = TextEditingController(
      text: e != null ? e.defaultUnitPrice.toString() : '',
    );
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final code = _codeCtrl.text.trim().toUpperCase();
      final name = _nameCtrl.text.trim();
      final description =
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
      final category =
          _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim();
      final unit = _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim();
      final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;

      final QuotationCatalogItem result;
      if (_isEdit) {
        result = await widget.service.update(
          widget.existing!.id,
          code: code,
          name: name,
          description: description ?? '',
          category: category ?? '',
          unit: unit ?? '',
          defaultUnitPrice: price,
          isActive: _isActive,
        );
      } else {
        result = await widget.service.create(
          code: code,
          name: name,
          description: description,
          category: category,
          unit: unit,
          defaultUnitPrice: price,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Catalog Item' : 'New Catalog Item'),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Code (auto-uppercase, alphanumeric+dash)
                TextFormField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9\-]')),
                    LengthLimitingTextInputFormatter(80),
                    _UpperCaseTextFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Code *',
                    hintText: 'e.g. PNT-INT-WHT',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Code is required';
                    if (s.length > 80) return 'Max 80 characters';
                    if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(s)) {
                      return 'Only A-Z, 0-9 and - allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(255),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Name is required';
                    if (s.length > 255) return 'Max 255 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  minLines: 2,
                  maxLines: 4,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(1000),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Category (Autocomplete from known categories)
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _categoryCtrl.text),
                  optionsBuilder: (TextEditingValue value) {
                    if (value.text.isEmpty) return widget.existingCategories;
                    return widget.existingCategories.where((c) =>
                        c.toLowerCase().contains(value.text.toLowerCase()));
                  },
                  fieldViewBuilder:
                      (ctx, controller, focusNode, onFieldSubmitted) {
                    // Keep our controller in sync.
                    controller.addListener(() {
                      _categoryCtrl.text = controller.text;
                    });
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(80),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        hintText: 'e.g. Painting, Plumbing',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    );
                  },
                  onSelected: (s) => _categoryCtrl.text = s,
                ),
                const SizedBox(height: 12),

                // Unit + Price row
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: TextFormField(
                        controller: _unitCtrl,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(40),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          hintText: 'sqft / lot / hr',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Default unit price *',
                          prefixText: '\u20B9 ',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return 'Price required';
                          final n = double.tryParse(s);
                          if (n == null) return 'Enter a number';
                          if (n < 0) return 'Must be ≥ 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                if (_isEdit) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    subtitle: Text(
                      _isActive
                          ? 'Visible in the catalog picker'
                          : 'Hidden from the catalog picker',
                      style: const TextStyle(
                          fontSize: 12, color: textSecondary),
                    ),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving
              ? 'Saving...'
              : (_isEdit ? 'Save changes' : 'Create item')),
        ),
      ],
    );
  }
}

/// Forces TextField input to upper-case while preserving caret position.
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
