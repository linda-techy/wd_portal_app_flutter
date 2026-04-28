import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/features/leads/data/services/lead_quotation_service.dart';
import 'package:admin/features/quotation_catalog/data/models/quotation_catalog_item.dart';
import 'package:admin/features/quotation_catalog/data/services/quotation_catalog_service.dart';
import 'package:admin/features/quotation_catalog/presentation/screens/quotation_catalog_picker_dialog.dart';

class AddQuotationScreen extends StatefulWidget {
  final Lead lead;
  final LeadQuotation? quotationToEdit;

  const AddQuotationScreen(
      {super.key, required this.lead, this.quotationToEdit});

  @override
  State<AddQuotationScreen> createState() => _AddQuotationScreenState();
}

class _AddQuotationScreenState extends State<AddQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final LeadQuotationService _service = LeadQuotationService();
  final QuotationCatalogService _catalogService = QuotationCatalogService();
  bool _isSaving = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _validityController =
      TextEditingController(text: '30');

  /// Tax rate as % (e.g. 18.00 for 18% GST). Empty string means
  /// "use the backend default" — currently 18%. Setting to 0 means "no tax".
  /// The backend computes taxAmount = (subtotal − discount) × rate / 100.
  final TextEditingController _taxRateController =
      TextEditingController(text: '18.00');

  /// Optional fixed-rupee discount applied to the subtotal before GST.
  /// Backend rejects values exceeding the subtotal.
  final TextEditingController _discountController = TextEditingController();

  List<LeadQuotationItem> _items = [];

  // ── Autosave state ────────────────────────────────────────────────────
  // Timer fires every 30s while the screen is open; the next tick saves
  // a DRAFT silently if the form is non-trivial (title set, ≥1 item).
  // First successful save flips the screen from create-mode to edit-mode
  // by stamping `_autoCreatedId`, so subsequent ticks PUT instead of POST.
  Timer? _autosaveTimer;
  int? _autoCreatedId;
  DateTime? _lastAutosaveAt;
  bool _autosaveInFlight = false;
  bool _formDirty = false;

  // Controllers for the item being added
  final TextEditingController _itemDescController = TextEditingController();
  final TextEditingController _itemQtyController =
      TextEditingController(text: '1');
  final TextEditingController _itemPriceController =
      TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    if (widget.quotationToEdit != null) {
      _titleController.text = widget.quotationToEdit!.title;
      _descriptionController.text = widget.quotationToEdit!.description ?? '';
      _validityController.text =
          widget.quotationToEdit!.validityDays.toString();
      // Tax-rate field: blank entry keeps backend default. Show the existing
      // rate (if any) so staff can see what's set; an existing null on the
      // server means legacy "manual mode" which we surface as blank.
      final existingRate = widget.quotationToEdit!.taxRatePercent;
      _taxRateController.text = existingRate != null
          ? existingRate.toStringAsFixed(2)
          : '';
      final existingDiscount = widget.quotationToEdit!.discountAmount;
      _discountController.text = existingDiscount != null && existingDiscount > 0
          ? existingDiscount.toStringAsFixed(2)
          : '';
      // clone items
      _items = List.from(widget.quotationToEdit!.items);
    }
    // 30-second autosave heartbeat. Each tick checks `_formDirty` and saves
    // silently when the form is non-trivial. Marking dirty happens via
    // `_markDirty()` from text-field onChanged + add/remove-item actions.
    _autosaveTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _autosaveIfNeeded());
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _validityController.dispose();
    _taxRateController.dispose();
    _discountController.dispose();
    _itemDescController.dispose();
    _itemQtyController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  /// Mark the form dirty so the next autosave tick fires. Called from text
  /// field onChanged handlers and item add/remove actions.
  void _markDirty() {
    if (!_formDirty) setState(() => _formDirty = true);
  }

  /// One autosave attempt. Skips when:
  ///   - a manual save is already in progress (`_isSaving`),
  ///   - an autosave is in flight (`_autosaveInFlight`),
  ///   - the form hasn't changed since the last save (`_formDirty == false`),
  ///   - the form isn't substantive yet (title empty or no items).
  /// First successful tick stamps `_autoCreatedId` so subsequent ticks PUT
  /// instead of POST — same flow the manual Save button uses.
  Future<void> _autosaveIfNeeded() async {
    if (!mounted || _isSaving || _autosaveInFlight) return;
    if (!_formDirty) return;
    final title = _titleController.text.trim();
    if (title.isEmpty || _items.isEmpty) return;

    setState(() => _autosaveInFlight = true);
    try {
      final leadIdInt = int.parse(widget.lead.leadId);
      final taxRateText = _taxRateController.text.trim();
      final taxRate = taxRateText.isEmpty ? null : double.tryParse(taxRateText);
      final discountText = _discountController.text.trim();
      final discount =
          discountText.isEmpty ? null : double.tryParse(discountText);

      // Pre-existing edit target wins; otherwise we attach to the screen's
      // own auto-created draft so we keep updating the same row.
      final targetId = widget.quotationToEdit?.id ?? _autoCreatedId;
      final draft = LeadQuotation(
        id: targetId,
        leadId: leadIdInt,
        title: title,
        description: _descriptionController.text,
        validityDays: int.tryParse(_validityController.text) ?? 30,
        totalAmount: _subtotal,
        taxRatePercent: taxRate,
        discountAmount: discount,
        finalAmount: _liveFinal,
        items: _items.where((it) => it.catalogItemId == null).toList(),
        status: 'DRAFT',
      );

      if (targetId == null) {
        final created = await _service.createQuotation(draft);
        if (!mounted) return;
        setState(() {
          _autoCreatedId = created.id;
          _lastAutosaveAt = DateTime.now();
          _formDirty = false;
        });
      } else {
        await _service.updateQuotation(targetId, draft);
        if (!mounted) return;
        setState(() {
          _lastAutosaveAt = DateTime.now();
          _formDirty = false;
        });
      }
    } catch (_) {
      // Autosave failures are silent — the user gets to retry on the next
      // tick or via manual Save. Don't bother them with a snackbar.
    } finally {
      if (mounted) setState(() => _autosaveInFlight = false);
    }
  }

  void _addItem() {
    final desc = _itemDescController.text;
    final qty = double.tryParse(_itemQtyController.text) ?? 1;
    final price = double.tryParse(_itemPriceController.text) ?? 0;

    if (desc.isEmpty) return;

    setState(() {
      _items.add(LeadQuotationItem(
        itemNumber: _items.length + 1,
        description: desc,
        quantity: qty,
        unitPrice: price,
        totalPrice: qty * price,
      ));

      // Clear inputs
      _itemDescController.clear();
      _itemQtyController.text = '1';
      _itemPriceController.text = '0';
    });
    _markDirty();
  }

  /// Build the row description for a catalog-sourced line, mirroring the
  /// backend's `LeadQuotationService#addItemFromCatalog` formatting so what
  /// the user sees in the form matches what the server would produce.
  String _buildCatalogDescription(QuotationCatalogItem cat) {
    final desc = cat.description;
    if (desc == null || desc.trim().isEmpty) return cat.name;
    final truncated = desc.length > 500 ? desc.substring(0, 500) : desc;
    return '${cat.name} - $truncated';
  }

  /// Open the catalog picker in preview mode — the picked row is appended
  /// locally; persistence to the server happens at form-save via a second
  /// `addItemFromCatalog` call (the inline `createQuotation` body does NOT
  /// persist `catalog_item_id` for nested items).
  Future<void> _openCatalogPicker() async {
    await showDialog<void>(
      context: context,
      builder: (_) => QuotationCatalogPickerDialog(
        // quotationId omitted — preview mode.
        onPreviewItemAdded: (cat, {quantity, unitPriceOverride}) {
          final qty = quantity ?? 1.0;
          final price = unitPriceOverride ?? cat.defaultUnitPrice;
          setState(() {
            _items.add(LeadQuotationItem(
              itemNumber: _items.length + 1,
              description: _buildCatalogDescription(cat),
              quantity: qty,
              unitPrice: price,
              totalPrice: qty * price,
              catalogItemId: cat.id,
            ));
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      // Re-number ? Optional
    });
    _markDirty();
  }

  /// Inline edit dialog for an existing line item. Three fields,
  /// total recomputed on save. Catalog-link is preserved across edits
  /// (the catalogItemId rides with the row so the backend's catalog
  /// promotion / FK semantics keep working).
  Future<void> _editItem(int index) async {
    final original = _items[index];
    final descCtrl = TextEditingController(text: original.description);
    final qtyCtrl = TextEditingController(
        text: original.quantity.toString());
    final priceCtrl = TextEditingController(
        text: original.unitPrice.toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Unit Price (₹)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save')),
        ],
      ),
    );

    descCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();

    if (saved != true || !mounted) return;
    final newDesc = descCtrl.text.trim().isEmpty
        ? original.description
        : descCtrl.text.trim();
    final newQty = double.tryParse(qtyCtrl.text.trim()) ?? original.quantity;
    final newPrice =
        double.tryParse(priceCtrl.text.trim()) ?? original.unitPrice;

    setState(() {
      _items[index] = LeadQuotationItem(
        id: original.id,
        quotationId: original.quotationId,
        itemNumber: original.itemNumber,
        description: newDesc,
        quantity: newQty,
        unitPrice: newPrice,
        totalPrice: newQty * newPrice,
        notes: original.notes,
        catalogItemId: original.catalogItemId,
      );
    });
    _markDirty();
  }

  /// Subtotal = sum of line-item totals. The "₹X" before tax/discount.
  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Discount value as the user has it typed right now (0 if blank/invalid).
  double get _liveDiscount {
    final t = _discountController.text.trim();
    if (t.isEmpty) return 0.0;
    return double.tryParse(t) ?? 0.0;
  }

  /// Tax rate as the user has it typed (null = "leave blank, backend default").
  double? get _liveTaxRate {
    final t = _taxRateController.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  /// Mirrors LeadQuotationService.calculateTotals — discounted base after
  /// clamping discount to subtotal so a typo can't produce a negative.
  double get _liveDiscountedBase {
    final base = _subtotal - _liveDiscount;
    return base < 0 ? 0.0 : base;
  }

  /// Live tax projection. Uses the entered rate; when blank, falls back to
  /// 18% so staff see the most likely customer-facing figure during entry.
  double get _liveTax {
    final rate = _liveTaxRate ?? 18.0;
    return _liveDiscountedBase * rate / 100.0;
  }

  /// What the customer will see as Final Amount on the PDF.
  double get _liveFinal => _liveDiscountedBase + _liveTax;

  /// Backwards-compatibility alias kept until the rest of the file is fully
  /// migrated; reads as "this screen's primary number" for legacy callers.
  double get _currentTotal => _subtotal;

  /// Indian-grouping rupee formatter (e.g. 4728200 → "₹47,28,200").
  static final NumberFormat _inr = NumberFormat.currency(
      locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  /// Live total footer — mirrors LeadQuotationService.calculateTotals so
  /// what staff sees here is what the customer sees on the PDF.
  Widget _buildLiveTotalFooter(BuildContext context) {
    final hasDiscount = _liveDiscount > 0;
    final hasTax = _liveTaxRate != 0; // null treated as default 18%
    final showBreakdown = hasDiscount || hasTax;
    final rateLabel = _liveTaxRate != null
        ? 'GST (${_formatRate(_liveTaxRate!)}%)'
        : 'GST (18% default)';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: const Border(top: BorderSide(color: Colors.blue)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBreakdown) ...[
            _footerRow('Subtotal', _inr.format(_subtotal)),
            if (hasDiscount)
              _footerRow('Discount', '− ${_inr.format(_liveDiscount)}'),
            _footerRow(rateLabel, '+ ${_inr.format(_liveTax)}'),
            const Divider(height: 14),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Final Amount',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              Text(
                _inr.format(_liveFinal),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tiny AppBar badge that surfaces autosave state without ever stealing
  /// focus. Shows a 14px spinner while a save is in flight, then collapses
  /// to "Saved · HH:mm" once the last save succeeded. Stays empty when no
  /// save has happened yet so we don't lie about persistence state.
  Widget _buildAutosaveBadge() {
    if (_autosaveInFlight) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 6),
            Text('Saving…',
                style: TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      );
    }
    if (_lastAutosaveAt == null) return const SizedBox.shrink();
    final hh = _lastAutosaveAt!.hour.toString().padLeft(2, '0');
    final mm = _lastAutosaveAt!.minute.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_done_outlined, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text('Saved · $hh:$mm',
              style: const TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _footerRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// 18.00 → "18", 12.50 → "12.5". Avoids stray trailing zeros in the chip.
  String _formatRate(double rate) {
    if (rate == rate.roundToDouble()) return rate.toStringAsFixed(0);
    return rate
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  Future<void> _saveQuotation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final leadIdInt = int.parse(widget.lead.leadId);

      // Resolve the optional financial knobs once for both create and edit.
      // Empty string means "let the backend keep its default" (currently 18%
      // for new entities). A typed `0` means "0% tax / no discount" — those
      // are valid and explicitly different from "default".
      final taxRateText = _taxRateController.text.trim();
      final taxRate = taxRateText.isEmpty ? null : double.tryParse(taxRateText);
      final discountText = _discountController.text.trim();
      final discount =
          discountText.isEmpty ? null : double.tryParse(discountText);

      // Split items: catalog-sourced rows must be persisted via
      // `addItemFromCatalog` so the FK link is recorded — the inline
      // create body ignores `catalogItemId`.
      final adHocItems =
          _items.where((it) => it.catalogItemId == null).toList();
      final catalogItems =
          _items.where((it) => it.catalogItemId != null).toList();

      if (widget.quotationToEdit != null) {
        // Edit path — preserve existing behaviour (single update call).
        // Catalog-link preservation on edit is out-of-scope for this slice;
        // existing rows that already have catalogItemId remain linked
        // because the backend uses the request's items list verbatim, but
        // newly-added catalog rows during edit will lose the link. The
        // primary "Add from catalog" UX is on create, where it fully works.
        final quotation = LeadQuotation(
          id: widget.quotationToEdit!.id,
          leadId: leadIdInt,
          title: _titleController.text,
          description: _descriptionController.text,
          validityDays: int.tryParse(_validityController.text) ?? 30,
          totalAmount: _currentTotal,
          taxRatePercent: taxRate,
          discountAmount: discount,
          finalAmount: _currentTotal,
          items: _items,
          status: widget.quotationToEdit!.status,
        );
        await _service.updateQuotation(quotation.id!, quotation);
      } else {
        // Create path — two-phase when catalog rows are present.
        // Re-number ad-hoc items 1..N before sending.
        final renumberedAdHoc = <LeadQuotationItem>[];
        for (var i = 0; i < adHocItems.length; i++) {
          final r = adHocItems[i];
          renumberedAdHoc.add(LeadQuotationItem(
            itemNumber: i + 1,
            description: r.description,
            quantity: r.quantity,
            unitPrice: r.unitPrice,
            totalPrice: r.totalPrice,
            notes: r.notes,
          ));
        }

        // If there are no ad-hoc items at all but only catalog rows, we
        // still need a quotation skeleton — backend allows empty items
        // on create (calculateTotals only runs when items present).
        final initial = LeadQuotation(
          leadId: leadIdInt,
          title: _titleController.text,
          description: _descriptionController.text,
          validityDays: int.tryParse(_validityController.text) ?? 30,
          totalAmount: 0,
          taxRatePercent: taxRate,
          discountAmount: discount,
          finalAmount: 0,
          items: renumberedAdHoc,
          status: 'DRAFT',
        );
        final created = await _service.createQuotation(initial);

        // Phase 2 — append catalog-linked items via the dedicated endpoint.
        if (catalogItems.isNotEmpty && created.id != null) {
          for (final c in catalogItems) {
            await _catalogService.addItemFromCatalog(
              quotationId: created.id!,
              catalogItemId: c.catalogItemId!,
              quantity: c.quantity,
              unitPriceOverride: c.unitPrice,
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation saved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quotationToEdit != null
            ? 'Edit Quotation'
            : 'New Quotation'),
        actions: [
          // Autosave indicator — quietly tells the user their work is safe
          // without ever interrupting them. Three states: in-flight (small
          // spinner), saved (clock icon + HH:mm), or absent (no save yet).
          _buildAutosaveBadge(),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveQuotation,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    TextFormField(
                      controller: _titleController,
                      onChanged: (_) => _markDirty(),
                      decoration: const InputDecoration(
                        labelText: 'Quotation Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      onChanged: (_) => _markDirty(),
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _validityController,
                            onChanged: (_) => _markDirty(),
                            decoration: const InputDecoration(
                              labelText: 'Validity (Days)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _taxRateController,
                            // Trigger a rebuild so the live footer math reflects
                            // the typed rate as the user types; mark dirty so
                            // autosave picks the change up at the next tick.
                            onChanged: (_) {
                              setState(() {});
                              _markDirty();
                            },
                            decoration: const InputDecoration(
                              labelText: 'GST Rate (%)',
                              helperText: 'Default 18%. Leave blank for none.',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final parsed = double.tryParse(v.trim());
                              if (parsed == null) return 'Must be a number';
                              if (parsed < 0 || parsed > 100) {
                                return 'Must be 0–100';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _discountController,
                            onChanged: (_) {
                              setState(() {});
                              _markDirty();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Discount (₹)',
                              helperText: 'Optional fixed amount.',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final parsed = double.tryParse(v.trim());
                              if (parsed == null) return 'Must be a number';
                              if (parsed < 0) return 'Must be ≥ 0';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Items Section header — title on the left, catalog
                    // shortcut on the right so the user can pick from
                    // catalog without first saving the quotation.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Line Items',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.inventory_2_outlined,
                              size: 18),
                          label: const Text('Add from catalog'),
                          onPressed: _isSaving ? null : _openCatalogPicker,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Add Item Form (ad-hoc / custom items)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _itemDescController,
                                  decoration: const InputDecoration(
                                      labelText: 'Item Description',
                                      isDense: true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: _itemQtyController,
                                  decoration: const InputDecoration(
                                      labelText: 'Qty', isDense: true),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _itemPriceController,
                                  decoration: const InputDecoration(
                                      labelText: 'Unit Price', isDense: true),
                                  keyboardType: TextInputType.number,
                                  // Enter on the last field of the line-add
                                  // form commits the item — keyboards stay
                                  // up so the next item is one tap away.
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _addItem(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addItem,
                                child: const Text('Add Item'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Items List
                    if (_items.isEmpty)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No items added',
                            style: TextStyle(color: Colors.grey)),
                      ))
                    else
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              // Tap the row to edit qty / price / description
                              // inline. Was: delete-and-re-add, ~8 taps per
                              // typo. Now: 3 taps to fix a misplaced decimal.
                              onTap: () => _editItem(index),
                              title: Text(item.description),
                              subtitle:
                                  Text('${item.quantity} x ₹${item.unitPrice}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${item.totalPrice}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 20),
                                    tooltip: 'Edit',
                                    onPressed: () => _editItem(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _removeItem(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Sticky footer — mirrors the customer-facing PDF math live so
            // staff can see what the customer will actually see *before*
            // hitting Send. Previously this only summed line items, which
            // led to "wait, why is the customer's total different?"
            // moments after sending.
            _buildLiveTotalFooter(context),
          ],
        ),
      ),
    );
  }
}
