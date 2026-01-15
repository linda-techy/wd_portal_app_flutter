import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/services/boq_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/portal_auth_provider.dart';

class BoqScreen extends StatefulWidget {
  final int projectId;

  const BoqScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  _BoqScreenState createState() => _BoqScreenState();
}

class _BoqScreenState extends State<BoqScreen> {
  final BoqService _service = BoqService();
  List<BoqItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verifyAuthAndLoadData();
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider = Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
         await ErrorHandler.handleAuthError(context);
         Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await _service.getProjectBoq(widget.projectId);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to load BoQ');
      }
    }
  }

  double get _totalProjectCost {
    return _items.fold(0.0, (sum, item) => sum + (item.totalAmount ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill of Quantities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Project Value:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currencyFormat.format(_totalProjectCost),
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? const Center(child: Text('No BoQ items found.'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Description')),
                                DataColumn(label: Text('Unit')),
                                DataColumn(label: Text('Qty'), numeric: true),
                                DataColumn(label: Text('Rate'), numeric: true),
                                DataColumn(label: Text('Amount'), numeric: true),
                              ],
                              rows: _items.map((item) {
                                return DataRow(cells: [
                                  DataCell(Container(
                                    width: 200,
                                    child: Text(item.description, overflow: TextOverflow.ellipsis),
                                  )),
                                  DataCell(Text(item.unit)),
                                  DataCell(Text(item.quantity.toString())),
                                  DataCell(Text(currencyFormat.format(item.unitRate))),
                                  DataCell(Text(
                                    currencyFormat.format(item.totalAmount ?? 0),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

