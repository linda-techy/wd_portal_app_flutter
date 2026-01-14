import 'package:flutter/material.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:admin/providers/common_data_provider.dart';

class ProjectFiltersWidget extends StatefulWidget {
  final String? selectedPhase;
  final String? selectedType;
  final Function(String?) onPhaseChanged;
  final Function(String?) onTypeChanged;
  final VoidCallback onClear;

  const ProjectFiltersWidget({
    super.key,
    this.selectedPhase,
    this.selectedType,
    required this.onPhaseChanged,
    required this.onTypeChanged,
    required this.onClear,
  });

  @override
  State<ProjectFiltersWidget> createState() => _ProjectFiltersWidgetState();
}

class _ProjectFiltersWidgetState extends State<ProjectFiltersWidget> {
  @override
  void initState() {
    super.initState();
    // Load filter data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final commonDataProvider = context.read<CommonDataProvider>();
      commonDataProvider.fetchProjectPhases();
      commonDataProvider.fetchProjectTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (widget.selectedPhase != null || widget.selectedType != null)
                TextButton.icon(
                  onPressed: widget.onClear,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.statusError,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),
          
          // Phase Filter
          Consumer<CommonDataProvider>(
            builder: (context, provider, child) {
              if (provider.isPhasesLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return DropdownButtonFormField<String>(
                value: widget.selectedPhase,
                decoration: const InputDecoration(
                  labelText: 'Project Phase',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Phases'),
                  ),
                  ...provider.projectPhases.map((phase) {
                    return DropdownMenuItem<String>(
                      value: phase.value,
                      child: Text(phase.displayName),
                    );
                  }),
                ],
                onChanged: widget.onPhaseChanged,
              );
            },
          ),
          
          const SizedBox(height: AppTheme.spacingMD),
          
          // Type Filter
          Consumer<CommonDataProvider>(
            builder: (context, provider, child) {
              if (provider.isProjectTypesLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return DropdownButtonFormField<String>(
                value: widget.selectedType,
                decoration: const InputDecoration(
                  labelText: 'Project Type',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Types'),
                  ),
                  ...provider.projectTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }),
                ],
                onChanged: widget.onTypeChanged,
              );
            },
          ),
        ],
      ),
    );
  }
}

