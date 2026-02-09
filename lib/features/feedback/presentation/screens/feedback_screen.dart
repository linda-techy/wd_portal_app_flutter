import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/services/feedback_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/portal_auth_provider.dart';

class FeedbackScreen extends StatefulWidget {
  final int projectId;

  const FeedbackScreen({super.key, required this.projectId});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  final FeedbackService _service = FeedbackService();
  late TabController _tabController;
  List<FeedbackForm> _forms = [];
  List<FeedbackResponse> _responses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _verifyAuthAndLoadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider =
        Provider.of<PortalAuthProvider>(context, listen: false);
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
      final results = await Future.wait([
        _service.getProjectForms(widget.projectId),
        _service.getProjectResponses(widget.projectId),
      ]);
      if (mounted) {
        setState(() {
          _forms = results[0] as List<FeedbackForm>;
          _responses = results[1] as List<FeedbackResponse>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to load feedback data');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Forms (${_forms.length})'),
            Tab(text: 'Responses (${_responses.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateFormDialog,
        backgroundColor: AppTheme.deepSlate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFormsTab(),
                _buildResponsesTab(),
              ],
            ),
    );
  }

  Widget _buildFormsTab() {
    if (_forms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feedback_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No feedback forms yet',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 4),
            Text('Tap + to create a feedback form',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _forms.length,
        itemBuilder: (context, index) => _buildFormCard(_forms[index]),
      ),
    );
  }

  Widget _buildFormCard(FeedbackForm form) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFormDetail(form),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      form.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: form.isActive
                          ? AppTheme.successGreen.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      form.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: form.isActive ? AppTheme.successGreen : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              if (form.description != null && form.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  form.description!,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (form.responseCount != null) ...[
                    Icon(Icons.people_outline, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('${form.responseCount} responses',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    const SizedBox(width: 16),
                  ],
                  if (form.createdAt != null) ...[
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(dateFormat.format(form.createdAt!),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                  const Spacer(),
                  if (form.createdByName != null)
                    Text('by ${form.createdByName}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsesTab() {
    if (_responses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No responses yet',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _responses.length,
        itemBuilder: (context, index) =>
            _buildResponseCard(_responses[index]),
      ),
    );
  }

  Widget _buildResponseCard(FeedbackResponse response) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.deepSlate.withOpacity(0.1),
                  child: Text(
                    (response.customerName ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepSlate,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(response.customerName ?? 'Anonymous',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      if (response.formTitle != null)
                        Text('Re: ${response.formTitle}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                if (response.submittedAt != null)
                  Text(
                    dateFormat.format(response.submittedAt!),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textTertiary),
                  ),
              ],
            ),
            if (response.responseData != null &&
                response.responseData!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  response.responseData!,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFormDetail(FeedbackForm form) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(form.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (form.description != null) ...[
              const SizedBox(height: 8),
              Text(form.description!,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip(Icons.people, '${form.responseCount ?? 0} responses'),
                const SizedBox(width: 12),
                _buildStatChip(
                  form.isActive ? Icons.check_circle : Icons.cancel,
                  form.isActive ? 'Active' : 'Inactive',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditFormDialog(form);
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _toggleFormActive(form);
                    },
                    icon: Icon(
                      form.isActive ? Icons.pause : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(form.isActive ? 'Deactivate' : 'Activate'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDeleteForm(form);
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Future<void> _showCreateFormDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Feedback Form'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.deepSlate),
            child:
                const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      if (titleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title is required')),
        );
        return;
      }
      try {
        await _service.createForm(
          projectId: widget.projectId,
          title: titleController.text,
          description:
              descController.text.isNotEmpty ? descController.text : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Feedback form created'),
                backgroundColor: AppTheme.successGreen),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to create form');
        }
      }
    }
  }

  Future<void> _showEditFormDialog(FeedbackForm form) async {
    final titleController = TextEditingController(text: form.title);
    final descController =
        TextEditingController(text: form.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Feedback Form'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.deepSlate),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await _service.updateForm(
          form.id,
          title: titleController.text,
          description: descController.text.isNotEmpty
              ? descController.text
              : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Feedback form updated'),
                backgroundColor: AppTheme.successGreen),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to update form');
        }
      }
    }
  }

  Future<void> _toggleFormActive(FeedbackForm form) async {
    try {
      await _service.updateForm(form.id, isActive: !form.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                form.isActive ? 'Form deactivated' : 'Form activated'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to update form');
      }
    }
  }

  Future<void> _confirmDeleteForm(FeedbackForm form) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Feedback Form'),
        content: Text(
            'Are you sure you want to delete "${form.title}"? This will also remove all responses.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _service.deleteForm(form.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Feedback form deleted'),
                backgroundColor: AppTheme.successGreen),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to delete form');
        }
      }
    }
  }
}
