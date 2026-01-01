import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/labour_provider.dart';
import 'package:admin/models/labour_models.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/services/crm_service.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final CRMService _crmService = CRMService();
  List<CustomerProject> _projects = [];
  CustomerProject? _selectedProject;
  DateTime _attendanceDate = DateTime.now();
  Map<int, String> _attendanceMap = {}; // labourId -> status

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final projectsResponse = await _crmService.getCustomerProjectsPaginated(page: 0, size: 100);
      setState(() {
        _projects = projectsResponse.data;
      });
      await context.read<LabourProvider>().fetchLabour();
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final labourList = context.watch<LabourProvider>().labourList;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                  DropdownButtonFormField<CustomerProject>(
                    value: _selectedProject,
                    decoration: const InputDecoration(labelText: "Project", prefixIcon: Icon(Icons.folder)),
                    items: _projects.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    onChanged: (val) => setState(() => _selectedProject = val),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text("Attendance Date"),
                    subtitle: Text(DateFormat('dd-MM-yyyy').format(_attendanceDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _attendanceDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _attendanceDate = picked);
                    },
                  ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: labourList.isEmpty
                  ? const Center(child: Text("No workers registered."))
                  : ListView.builder(
                      itemCount: labourList.length,
                      itemBuilder: (context, index) {
                        final l = labourList[index];
                        final status = _attendanceMap[l.id] ?? 'ABSENT';
                        return Card(
                          child: ListTile(
                            title: Text(l.name),
                            subtitle: Text(l.tradeType),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                _statusChip(l.id!, 'PRESENT', Colors.green, status == 'PRESENT'),
                                _statusChip(l.id!, 'HALF_DAY', Colors.orange, status == 'HALF_DAY'),
                                _statusChip(l.id!, 'ABSENT', Colors.red, status == 'ABSENT'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedProject == null ? null : _saveAttendance,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                child: const Text("Record Bulk Attendance", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(int labourId, String status, Color color, bool isSelected) {
    return ChoiceChip(
      label: Text(status == 'HALF_DAY' ? '1/2' : status[0]),
      selected: isSelected,
      selectedColor: color.withOpacity(0.5),
      onSelected: (val) {
        if (val) setState(() => _attendanceMap[labourId] = status);
      },
    );
  }

  void _saveAttendance() async {
    final labourList = context.read<LabourProvider>().labourList;
    List<LabourAttendance> attendanceList = [];

    for (var l in labourList) {
      attendanceList.add(LabourAttendance(
        projectId: _selectedProject!.id!,
        labourId: l.id!,
        attendanceDate: _attendanceDate.toIso8601String(),
        status: _attendanceMap[l.id] ?? 'ABSENT',
      ));
    }

    final success = await context.read<LabourProvider>().recordAttendance(attendanceList);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Attendance recorded successfully!")));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${context.read<LabourProvider>().error}")));
      }
    }
  }
}
