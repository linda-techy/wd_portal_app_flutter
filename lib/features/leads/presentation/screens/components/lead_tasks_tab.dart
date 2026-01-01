import 'package:admin/constants.dart';
import '../../../../../../models/task.dart'; // Wait, let's use absolute package import to be safe
// import 'package:admin/models/task.dart';
import 'package:admin/screens/tasks/tasks_screen.dart'; // Reuse logic if possible, or build custom list
// Actually, re-using TasksScreen might be heavy if it assumes full screen. 
// I'll create a simple list view fetching tasks by lead.

class LeadTasksTab extends StatefulWidget {
  final String leadId;
  const LeadTasksTab({Key? key, required this.leadId}) : super(key: key);

  @override
  _LeadTasksTabState createState() => _LeadTasksTabState();
}

class _LeadTasksTabState extends State<LeadTasksTab> {
  // Placeholder for tasks list
  bool _isLoading = true;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    // TODO: Implement Service Call: taskService.getTasksByLead(widget.leadId)
    // For now, simulate delay
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _tasks = []; // Empty for now
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tasks", style: Theme.of(context).textTheme.titleLarge),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Open Add Task Modal
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Add Task Implemented Next")));
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("New Task"),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    )
                  ],
                ),
              ),
              Expanded(
                child: _tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text("No tasks found for this lead",
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return ListTile(
                            title: Text(task.title),
                            subtitle: Text(task.status),
                            trailing: const Icon(Icons.chevron_right),
                          );
                        },
                      ),
              ),
            ],
          );
  }
}
