import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
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
  }

  double get _currentTotal {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
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

            // Footer (Total)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: const Border(top: BorderSide(color: Colors.blue)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount:', style: TextStyle(fontSize: 18)),
                  Text(
                    '₹$_currentTotal',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
