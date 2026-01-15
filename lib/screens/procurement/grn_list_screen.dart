import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/models/procurement_models.dart';
import 'package:admin/services/procurement_service.dart';
import 'package:intl/intl.dart';

class GRNListScreen extends StatefulWidget {
  const GRNListScreen({super.key});

  @override
  State<GRNListScreen> createState() => _GRNListScreenState();
}

class _GRNListScreenState extends State<GRNListScreen> {
  final ProcurementService _service = ProcurementService();
  final TextEditingController _searchController = TextEditingController();
  
  List<GoodsReceivedNote> _grns = [];
  List<GoodsReceivedNote> _filteredGrns = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGRNs();
  }

  Future<void> _loadGRNs() async {
    setState(() => _isLoading = true);
    try {
      _grns = await _service.fetchAllGRNs();
      _filteredGrns = _grns;
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterGRNs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGrns = _grns;
      } else {
        final q = query.toLowerCase();
        _filteredGrns = _grns.where((grn) =>
          (grn.grnNumber?.toLowerCase().contains(q) ?? false) ||
          (grn.vendorName?.toLowerCase().contains(q) ?? false) ||
          (grn.projectName?.toLowerCase().contains(q) ?? false) ||
          (grn.poNumber?.toLowerCase().contains(q) ?? false)
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Goods Received Notes", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadGRNs,
                  tooltip: "Refresh",
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search
            TextField(
              controller: _searchController,
              onChanged: _filterGRNs,
              decoration: InputDecoration(
                hintText: "Search by GRN#, Vendor, Project, or PO#...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // GRN List
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                  ? Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.red)))
                  : _filteredGrns.isEmpty
                    ? const Center(child: Text("No Goods Received Notes found."))
                    : ListView.builder(
                        itemCount: _filteredGrns.length,
                        itemBuilder: (context, index) {
                          final grn = _filteredGrns[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.coralRed,
                                child: const Icon(Icons.receipt_long, color: Colors.white),
                              ),
                              title: Text(grn.grnNumber ?? "GRN", 
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Vendor: ${grn.vendorName ?? 'N/A'}"),
                                  Text("Project: ${grn.projectName ?? 'N/A'}"),
                                  Text("PO: ${grn.poNumber ?? 'N/A'}"),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(DateFormat('dd MMM yyyy').format(grn.receivedDate),
                                    style: const TextStyle(fontWeight: FontWeight.w500)),
                                  if (grn.invoiceNumber != null && grn.invoiceNumber!.isNotEmpty)
                                    Text("Inv: ${grn.invoiceNumber}", 
                                      style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

