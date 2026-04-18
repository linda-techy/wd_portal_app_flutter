import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/features/projects/data/models/project_model.dart';
import 'package:admin/theme/app_theme.dart';
import 'gantt_screen.dart';

class ProjectDetailScreen extends StatelessWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(project.code ?? project.name),
        actions: [
          if (project.id != null)
            IconButton(
              icon: const Icon(Icons.view_timeline_outlined),
              tooltip: 'Gantt Timeline',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GanttScreen(
                    projectId: project.id!,
                    projectName: project.name,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            if (project.overallProgress != null) ...[
              _buildProgressCard(context),
              const SizedBox(height: 16),
            ],
            _buildDetailsCard(context),
            if (project.budget != null || project.sqfeet != null) ...[
              const SizedBox(height: 16),
              _buildFinancialsCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (project.code != null) ...[
              const SizedBox(height: 4),
              Text(
                project.code!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (project.projectPhase != null)
                  _buildChip(
                    label: project.projectPhase!,
                    backgroundColor: AppTheme.deepSlate,
                    textColor: Colors.white,
                  ),
                if (project.projectStatus != null)
                  _buildChip(
                    label: project.projectStatus!,
                    backgroundColor: _statusColor(project.projectStatus!).withOpacity(0.15),
                    textColor: _statusColor(project.projectStatus!),
                    borderColor: _statusColor(project.projectStatus!),
                  ),
                if (project.projectType != null)
                  _buildChip(
                    label: project.projectType!,
                    backgroundColor: Colors.grey[200]!,
                    textColor: Colors.grey[800]!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    final progress = project.overallProgress!;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Overall Progress',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${progress.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _progressColor(progress),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (progress / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_progressColor(progress)),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const Divider(height: 20),
            _buildDetailRow(
              icon: Icons.location_on,
              label: 'Location',
              value: project.location,
            ),
            if (project.customerName != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.person,
                label: 'Customer',
                value: project.customerName!,
              ),
            ],
            if (project.startDate != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.calendar_today,
                label: 'Start Date',
                value: dateFormat.format(project.startDate!),
              ),
            ],
            if (project.endDate != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.event,
                label: 'End Date',
                value: dateFormat.format(project.endDate!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialsCard(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financials & Specs',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const Divider(height: 20),
            if (project.budget != null)
              _buildDetailRow(
                icon: Icons.currency_rupee,
                label: 'Budget',
                value: currencyFormat.format(project.budget!),
              ),
            if (project.sqfeet != null) ...[
              if (project.budget != null) const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.square_foot,
                label: 'Area',
                value: '${project.sqfeet!.toStringAsFixed(0)} sq.ft',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'ongoing':
      case 'in_progress':
        return Colors.green;
      case 'completed':
      case 'handover':
        return Colors.blue;
      case 'on_hold':
      case 'paused':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _progressColor(double progress) {
    if (progress >= 75) return Colors.green;
    if (progress >= 40) return AppTheme.constructionOrange;
    return AppTheme.coralRed;
  }
}
