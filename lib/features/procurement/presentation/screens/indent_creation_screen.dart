import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../utils/error_handler.dart';
import '../../data/models/material_indent.dart';
import '../../data/services/material_indent_service.dart';

class IndentCreationScreen extends StatefulWidget {
  final int projectId;

  const IndentCreationScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  _IndentCreationScreenState createState() => _IndentCreationScreenState();
}

class _IndentCreationScreenState extends State<IndentCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = MaterialIndentService();
  bool _isLoading = false;

  // Indent Details
  final _requiredDateController = TextEditingController();
  final _notesController = TextEditingController();
  String _priority = 'MEDIUM';
  DateTime? _selectedRequiredDate;

  // Items List
  List<MaterialIndentItem> _items = [];
  
  // Item Form Controllers
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _itemDescriptionController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedRequiredDate = picked;
        _requiredDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _addItem() {
    if (_itemNameController.text.isEmpty || _quantityController.text.isEmpty || _unitController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill item details')));
      return;
    }

    setState(() {
      _items.add(MaterialIndentItem(
        itemName: _itemNameController.text,
        quantityRequested: double.parse(_quantityController.text),
        unit: _unitController.text,
        description: _itemDescriptionController.text,
      ));
      
      // Clear Input
      _itemNameController.clear();
      _quantityController.clear();
      _unitController.clear();
      _itemDescriptionController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submitIndent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one item')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final indent = MaterialIndent(
        projectId: widget.projectId,
        requestDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        requiredDate: _requiredDateController.text,
        priority: _priority,
        notes: _notesController.text,
        items: _items,
      );

      await _service.createIndent(widget.projectId, indent);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indent Created Successfully')));
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) ErrorHandler.handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Material Indent')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header Details ---
                    const Text('Indent Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
                    TextFormField(
                      controller: _requiredDateController,
                      decoration: const InputDecoration(labelText: 'Required Date', suffixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) => setState(() => _priority = v!),
                    ),
                    const SizedBox(height: 10),
                    
                    CustomTextField(
                      controller: _notesController,
                      label: 'Notes / Justification',
                      maxLines: 2,
                    ),

                    const Divider(height: 30),

                    // --- Items Section ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.add_circle), onPressed: _showAddItemDialog),
                      ],
                    ),
                    
                    if (_items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: Text('No items added. Click + to add.')),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            child: ListTile(
                              title: Text(item.itemName),
                              subtitle: Text('${item.quantityRequested} ${item.unit}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeItem(index),
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitIndent,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                        child: const Text('SUBMIT INDENT'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Material'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(controller: _itemNameController, label: 'Item Name'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: CustomTextField(controller: _quantityController, label: 'Quantity', keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: CustomTextField(controller: _unitController, label: 'Unit (e.g. Kg)')),
                ],
              ),
              const SizedBox(height: 10),
              CustomTextField(controller: _itemDescriptionController, label: 'Description/Specs'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _addItem();
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
