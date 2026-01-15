import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/labour_provider.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/services/crm_service.dart';
import 'mb_entry_screen.dart';

class MBListScreen extends StatefulWidget {
  const MBListScreen({super.key});

  @override
  State<MBListScreen> createState() => _MBListScreenState();
}

class _MBListScreenState extends State<MBListScreen> {
  final CRMService _crmService = CRMService();
  List<CustomerProject> _projects = [];
  CustomerProject? _selectedProject;

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
    } catch (e) {
      debugPrint("Error loading projects: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<CustomerProject>(
                  value: _selectedProject,
                  decoration: const InputDecoration(labelText: "Filter by Project", prefixIcon: Icon(Icons.folder)),
                  items: _projects.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedProject = val);
                    if (val != null) context.read<LabourProvider>().fetchMBEntries(val.id!);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Measurement Records", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _selectedProject == null ? null : () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MBEntryScreen(project: _selectedProject!)));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("New MB Entry"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed, foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<LabourProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                  if (_selectedProject == null) return const Center(child: Text("Select a project to view MB entries."));
                  if (provider.mbEntries.isEmpty) return const Center(child: Text("No records for this project."));

                  return ListView.builder(
                    itemCount: provider.mbEntries.length,
                    itemBuilder: (context, index) {
                      final m = provider.mbEntries[index];
                      return Card(
                        child: ListTile(
                          title: Text(m.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Qty: ${m.quantity} ${m.unit} | ₹${m.rate}/${m.unit}"),
                          trailing: Text("₹${m.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepSlate)),
                        ),
                      );
                    },
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

