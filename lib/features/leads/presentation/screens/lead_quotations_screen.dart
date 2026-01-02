import 'package:flutter/material.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/features/leads/data/services/lead_quotation_service.dart';
import 'package:admin/features/leads/presentation/screens/add_quotation_screen.dart';
import 'package:intl/intl.dart';

class LeadQuotationsScreen extends StatefulWidget {
  final Lead lead;

  const LeadQuotationsScreen({Key? key, required this.lead}) : super(key: key);

  @override
  _LeadQuotationsScreenState createState() => _LeadQuotationsScreenState();
}

class _LeadQuotationsScreenState extends State<LeadQuotationsScreen> {
  final LeadQuotationService _service = LeadQuotationService();
  List<LeadQuotation> _quotations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchQuotations();
  }

  Future<void> _fetchQuotations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final leadIdInt = int.parse(widget.lead.leadId);
      final quotations = await _service.getQuotationsByLead(leadIdInt);
      setState(() {
        _quotations = quotations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteQuotation(LeadQuotation quotation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: Text('Are you sure you want to delete "${quotation.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && quotation.id != null) {
      try {
        await _service.deleteQuotation(quotation.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation deleted')),
        );
        _fetchQuotations();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendQuotation(LeadQuotation quotation) async {
    // Only draft quotations can be sent generally, but check status
    if (quotation.status != 'DRAFT') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only Draft quotations can be sent.')),
      );
      return;
    }

    try {
      if (quotation.id != null) {
        await _service.sendQuotation(quotation.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation marked as SENT')),
        );
        _fetchQuotations();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quotations for ${widget.lead.name}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddQuotationScreen(lead: widget.lead),
            ),
          );
          if (result == true) {
            _fetchQuotations();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Quotation',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : _quotations.isEmpty
                  ? const Center(child: Text('No quotations found.'))
                  : ListView.builder(
                      itemCount: _quotations.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final quotation = _quotations[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    quotation.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                _buildStatusChip(quotation.status),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(quotation.description ?? 'No description'),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Amount: ${NumberFormat.currency(symbol: '₹').format(quotation.finalAmount ?? 0)}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                                    ),
                                    Text(
                                      'Date: ${quotation.createdAt != null ? DateFormat('MMM dd, yyyy').format(quotation.createdAt!) : '-'}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddQuotationScreen(
                                        lead: widget.lead,
                                        quotationToEdit: quotation,
                                      ),
                                    ),
                                  ).then((v) {
                                    if (v == true) _fetchQuotations();
                                  });
                                } else if (value == 'send') {
                                  _sendQuotation(quotation);
                                } else if (value == 'delete') {
                                  _deleteQuotation(quotation);
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                if (quotation.status == 'DRAFT')
                                  const PopupMenuItem<String>(
                                    value: 'send',
                                    child: Text('Mark as Sent'),
                                  ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'DRAFT':
        color = Colors.grey;
        break;
      case 'SENT':
        color = Colors.blue;
        break;
      case 'ACCEPTED':
        color = Colors.green;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      default:
        color = Colors.black;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
