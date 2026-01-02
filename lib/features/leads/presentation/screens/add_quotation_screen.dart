import 'package:flutter/material.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/features/leads/data/services/lead_quotation_service.dart';

class AddQuotationScreen extends StatefulWidget {
  final Lead lead;
  final LeadQuotation? quotationToEdit;

  const AddQuotationScreen({Key? key, required this.lead, this.quotationToEdit}) : super(key: key);

  @override
  _AddQuotationScreenState createState() => _AddQuotationScreenState();
}

class _AddQuotationScreenState extends State<AddQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final LeadQuotationService _service = LeadQuotationService();
  bool _isSaving = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _validityController = TextEditingController(text: '30');
  
  List<LeadQuotationItem> _items = [];

  // Controllers for the item being added
  final TextEditingController _itemDescController = TextEditingController();
  final TextEditingController _itemQtyController = TextEditingController(text: '1');
  final TextEditingController _itemPriceController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    if (widget.quotationToEdit != null) {
      _titleController.text = widget.quotationToEdit!.title;
      _descriptionController.text = widget.quotationToEdit!.description ?? '';
      _validityController.text = widget.quotationToEdit!.validityDays.toString();
      // clone items
      _items = List.from(widget.quotationToEdit!.items); 
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _validityController.dispose();
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
      
      final quotation = LeadQuotation(
        id: widget.quotationToEdit?.id,
        leadId: leadIdInt,
        title: _titleController.text,
        description: _descriptionController.text,
        validityDays: int.tryParse(_validityController.text) ?? 30,
        totalAmount: _currentTotal,
        finalAmount: _currentTotal, // Assuming no tax/discount logic yet for simplicity
        items: _items,
        status: widget.quotationToEdit?.status ?? 'DRAFT',
      );

      if (widget.quotationToEdit != null) {
        await _service.updateQuotation(quotation.id!, quotation);
      } else {
        await _service.createQuotation(quotation);
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
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
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
        title: Text(widget.quotationToEdit != null ? 'Edit Quotation' : 'New Quotation'),
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
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                    TextFormField(
                      controller: _validityController,
                      decoration: const InputDecoration(
                        labelText: 'Validity (Days)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    
                    // Items Section
                    const Text('Line Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    // Add Item Form
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
                                  decoration: const InputDecoration(labelText: 'Item Description', isDense: true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: _itemQtyController,
                                  decoration: const InputDecoration(labelText: 'Qty', isDense: true),
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
                                  decoration: const InputDecoration(labelText: 'Unit Price', isDense: true),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addItem,
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Items List
                    if (_items.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No items added', style: TextStyle(color: Colors.grey)),
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
                              subtitle: Text('${item.quantity} x ₹${item.unitPrice}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${item.totalPrice}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
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
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
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
