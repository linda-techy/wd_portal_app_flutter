import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/features/labour/data/models/labour_models.dart';
import 'package:admin/features/labour/data/services/labour_service.dart';
import 'package:admin/services/crm_service.dart';
import 'package:admin/models/customer_project.dart';

class WageSheetScreen extends StatefulWidget {
  final int? projectId;

  const WageSheetScreen({super.key, this.projectId});

  @override
  _WageSheetScreenState createState() => _WageSheetScreenState();
}

class _WageSheetScreenState extends State<WageSheetScreen> {
  final LabourService _labourService = LabourService();
  final CRMService _crmService = CRMService();
  
  WageSheet? _currentSheet;
  bool _isLoading = false;
  bool _isPageLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  
  List<CustomerProject> _projects = [];
  int? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.projectId;
    if (_selectedProjectId == null || _selectedProjectId == 0) {
      _loadProjects();
    } else {
      _isPageLoading = false;
    }
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _crmService.getAllCustomerProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
          _isPageLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading projects: $e')));
         setState(() => _isPageLoading = false);
      }
    }
  }

  Future<void> _generateSheet() async {
    if (_selectedProjectId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final sheet = await _labourService.generateWageSheet(_selectedProjectId!, _startDate, _endDate);
      setState(() {
        _currentSheet = sheet;
        _isLoading = false;
      });
    } catch (e) {
      // Show more descriptive error
      print('Wage sheet error: $e'); // For debugging
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wage Sheet Generation'),
      ),
      body: _isPageLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.projectId == null || widget.projectId == 0) ...[
              DropdownButtonFormField<int>(
                value: _selectedProjectId,
                decoration: const InputDecoration(
                  labelText: 'Select Project',
                  border: OutlineInputBorder(),
                ),
                items: _projects.map((project) {
                  return DropdownMenuItem<int>(
                    value: project.id,
                    child: Text(project.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProjectId = value;
                    _currentSheet = null; // Reset sheet when project changes
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            
            if (_selectedProjectId != null) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(context, true),
                      child: Text('Start: ${DateFormat('yyyy-MM-dd').format(_startDate)}'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(context, false),
                      child: Text('End: ${DateFormat('yyyy-MM-dd').format(_endDate)}'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _generateSheet,
                    child: _isLoading ? const CircularProgressIndicator() : const Text('Generate'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_currentSheet != null) ...[
                Text('Sheet Number: ${_currentSheet!.sheetNumber}', style: Theme.of(context).textTheme.titleLarge),
                Text('Total Amount: ₹${_currentSheet!.totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _currentSheet!.entries.length,
                    itemBuilder: (context, index) {
                      final entry = _currentSheet!.entries[index];
                      return Card(
                        child: ListTile(
                          title: Text(entry.labourName),
                          subtitle: Text('Days: ${entry.daysWorked} | Rate: ₹${entry.dailyWage}'),
                          trailing: Text('Net: ₹${entry.netPayable.toStringAsFixed(2)}'),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (!_isLoading) ...[
                 const Expanded(child: Center(child: Text('Select dates and click Generate to view Wage Sheet'))),
              ],
            ] else ...[
               const Expanded(child: Center(child: Text('Please select a project to proceed'))),
            ],
          ],
        ),
      ),
    );
  }
}

