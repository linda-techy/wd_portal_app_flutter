import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/leads/data/models/lead_interaction.dart';
import 'package:admin/features/leads/presentation/providers/lead_interaction_provider.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';

class LeadInteractionsScreen extends StatelessWidget {
  const LeadInteractionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LeadInteractionProvider()..fetch(),
      child: Consumer<LeadInteractionProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Lead Interactions'),
              actions: [
                Consumer<PermissionProvider>(
                  builder: (context, permissionProvider, _) {
                    if (permissionProvider.hasPermission('lead:edit')) {
                      return IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _navigateToCreate(context),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                _buildSearchAndFilters(context, provider),
                Expanded(child: _buildInteractionList(context, provider)),
                if (provider.totalPages > 1)
                  _buildPagination(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(
      BuildContext context, LeadInteractionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          SearchBarWidget(
            onSearch: (query) => provider.search(query),
            hintText: 'Search lead interactions...',
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
      BuildContext context, LeadInteractionProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          context,
          label: 'All Types',
          isSelected: provider.filters['interactionType'] == null,
          onTap: () => provider.clearFilters(),
        ),
        _buildFilterChip(
          context,
          label: 'Call',
          isSelected: provider.filters['interactionType'] == 'CALL',
          onTap: () => provider.updateFilter('interactionType', 'CALL'),
        ),
        _buildFilterChip(
          context,
          label: 'Email',
          isSelected: provider.filters['interactionType'] == 'EMAIL',
          onTap: () => provider.updateFilter('interactionType', 'EMAIL'),
        ),
        _buildFilterChip(
          context,
          label: 'Meeting',
          isSelected: provider.filters['interactionType'] == 'MEETING',
          onTap: () => provider.updateFilter('interactionType', 'MEETING'),
        ),
        _buildFilterChip(
          context,
          label: 'Site Visit',
          isSelected: provider.filters['interactionType'] == 'SITE_VISIT',
          onTap: () => provider.updateFilter('interactionType', 'SITE_VISIT'),
        ),
        const SizedBox(width: 16),
        _buildFilterChip(
          context,
          label: 'Follow-up Required',
          isSelected: provider.filters['followUpRequired'] == true,
          onTap: () => provider.updateFilter('followUpRequired', true),
          color: AppTheme.statusWarning,
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: color?.withOpacity(0.1),
      selectedColor: color ?? Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (color ?? Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildInteractionList(
      BuildContext context, LeadInteractionProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${provider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No lead interactions found', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetch(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.items.length,
        itemBuilder: (context, index) {
          final interaction = provider.items[index];
          return _buildInteractionCard(context, interaction);
        },
      ),
    );
  }

  Widget _buildInteractionCard(
      BuildContext context, LeadInteraction interaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, interaction),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getInteractionIcon(interaction.interactionType),
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          interaction.interactionType ?? 'Interaction',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (interaction.nextActionDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.statusWarning,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'FOLLOW-UP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (interaction.notes != null &&
                  interaction.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  interaction.notes!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.calendar_today,
                    label: _formatDate(interaction.interactionDate),
                  ),
                  if (interaction.outcome != null)
                    _buildInfoChip(
                      icon: Icons.check_circle,
                      label: interaction.outcome!,
                      color: _getOutcomeColor(interaction.outcome!),
                    ),
                  if (interaction.nextActionDate != null)
                    _buildInfoChip(
                      icon: Icons.event_available,
                      label:
                          'Next: ${_formatDate(interaction.nextActionDate!)}',
                      color: AppTheme.statusWarning,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getInteractionIcon(String? type) {
    switch (type?.toUpperCase()) {
      case 'CALL':
        return Icons.phone;
      case 'EMAIL':
        return Icons.email;
      case 'MEETING':
        return Icons.people;
      case 'SITE_VISIT':
        return Icons.location_on;
      default:
        return Icons.chat_bubble;
    }
  }

  Color _getOutcomeColor(String outcome) {
    switch (outcome.toUpperCase()) {
      case 'POSITIVE':
      case 'INTERESTED':
        return AppTheme.statusSuccess;
      case 'NEUTRAL':
        return AppTheme.statusWarning;
      case 'NEGATIVE':
      case 'NOT_INTERESTED':
        return AppTheme.statusError;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color ?? Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(
      BuildContext context, LeadInteractionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${provider.currentPage + 1} of ${provider.totalPages}',
            style: const TextStyle(fontSize: 14),
          ),
          Row(
            children: [
              IconButton(
                onPressed: provider.currentPage > 0
                    ? () => provider.goToPage(provider.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: provider.currentPage < provider.totalPages - 1
                    ? () => provider.goToPage(provider.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToDetail(BuildContext context, LeadInteraction interaction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for interaction ${interaction.id}')),
    );
  }

  void _navigateToCreate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create interaction - to be implemented')),
    );
  }
}

