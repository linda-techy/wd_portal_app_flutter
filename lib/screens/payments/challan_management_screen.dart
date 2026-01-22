import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/models/payment_models.dart';
import 'package:admin/services/challan_service.dart';
import 'package:admin/utils/motion_toast.dart';
import 'package:admin/utils/file_download_helper.dart';

class ChallanManagementScreen extends StatefulWidget {
  const ChallanManagementScreen({super.key});

  @override
  State<ChallanManagementScreen> createState() => _ChallanManagementScreenState();
}

class _ChallanManagementScreenState extends State<ChallanManagementScreen> {
  final ChallanService _challanService = ChallanService();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  
  List<ChallanItem> _challans = [];
  bool _isLoading = false;
  String? _selectedFy;
  DateTimeRange? _dateRange;
  final Set<int> _selectedIds = {};

  final List<String> _fyOptions = ['2023-24', '2024-25', '2025-26'];

  @override
  void initState() {
    super.initState();
    _loadChallans();
  }

  Future<void> _loadChallans() async {
    setState(() => _isLoading = true);
    try {
      final results = await _challanService.searchChallans(
        fy: _selectedFy,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
      );
      setState(() {
        _challans = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      MotionToast.show(context, message: 'Failed to load challans', isError: true);
    }
  }

  Future<void> _downloadChallan(ChallanItem challan) async {
    try {
      final bytes = await _challanService.downloadChallan(challan.id);
      final filename = 'Walldot_Challan_${challan.challanNumber.replaceAll("/", "_")}.pdf';
      
      await FileDownloadHelper.downloadAndShareFile(
        bytes: bytes,
        fileName: filename,
        mimeType: 'application/pdf',
        shareText: 'Payment Challan - ${challan.challanNumber}',
      );
    } catch (e) {
      MotionToast.show(context, message: e.toString(), isError: true);
    }
  }

  Future<void> _downloadBulk() async {
    if (_selectedIds.isEmpty) return;
    
    try {
      MotionToast.show(context, message: 'Generating ZIP archive...');
      final bytes = await _challanService.downloadBulk(_selectedIds.toList());
      
      await FileDownloadHelper.downloadAndShareFile(
        bytes: bytes,
        fileName: 'Walldot_Challans_Bulk.zip',
        mimeType: 'application/zip',
        shareText: 'Walldot Challans - Bulk Download',
      );
    } catch (e) {
      MotionToast.show(context, message: e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Receipt Management'),
        actions: [
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: _downloadBulk,
                icon: const Icon(Icons.archive),
                label: Text('Download (${_selectedIds.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _challans.isEmpty 
                ? _buildEmptyState()
                : _buildChallanTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFy,
              decoration: const InputDecoration(
                labelText: 'Financial Year',
                border: OutlineInputBorder(),
              ),
              items: _fyOptions.map((fy) => DropdownMenuItem(value: fy, child: Text(fy))).toList()
                ..insert(0, const DropdownMenuItem(value: null, child: Text('All Years'))),
              onChanged: (val) {
                setState(() => _selectedFy = val);
                _loadChallans();
              },
            ),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: InkWell(
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: _dateRange,
                );
                if (range != null) {
                  setState(() => _dateRange = range);
                  _loadChallans();
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date Range',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.date_range),
                ),
                child: Text(
                  _dateRange == null 
                    ? 'Select Dates' 
                    : '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}',
                  style: AppTheme.bodyMedium,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedFy = null;
                _dateRange = null;
                _selectedIds.clear();
              });
              _loadChallans();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear Filters',
          ),
        ],
      ),
    );
  }

  Widget _buildChallanTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
        child: DataTable(
          headingTextStyle: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text('Receipt No.')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Client/Project')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _challans.map((challan) {
            final isSelected = _selectedIds.contains(challan.id);
            return DataRow(
              selected: isSelected,
              onSelectChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedIds.add(challan.id);
                  } else {
                    _selectedIds.remove(challan.id);
                  }
                });
              },
              cells: [
                DataCell(Text(challan.challanNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(DateFormat('dd MMM yyyy').format(challan.transactionDate))),
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(challan.clientName, style: AppTheme.bodyMedium),
                    Text(challan.projectName, style: AppTheme.bodySmall.copyWith(color: Colors.grey)),
                  ],
                )),
                DataCell(Text(_currencyFormat.format(challan.amount))),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download, color: AppTheme.primaryBlue),
                      onPressed: () => _downloadChallan(challan),
                      tooltip: 'Download PDF',
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.document_scanner_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: AppTheme.spacingMD),
          Text('No challans found for selection', style: AppTheme.bodyLarge),
          const SizedBox(height: AppTheme.spacingSM),
          Text('Try adjusting your filters', style: AppTheme.bodyMedium.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

