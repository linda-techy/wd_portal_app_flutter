import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:admin/features/scheduling/data/models/wbs_template_model.dart';
import 'package:admin/features/scheduling/data/services/wbs_template_service.dart';

/// Result returned by [WbsTemplatePickerDialog] when the user confirms a
/// choice. `null` is returned when the user skips.
class WbsTemplatePickerResult {
  final int templateId;
  final int floorCount;

  const WbsTemplatePickerResult({
    required this.templateId,
    required this.floorCount,
  });
}

/// Maps a `CustomerProject.projectType` string (Flutter snake_case form like
/// `residential_construction`) to the [WbsProjectType] used by WBS templates.
///
/// Returns `null` when there's no sensible mapping (e.g. Vastu / Smart Home).
WbsProjectType? mapCustomerProjectTypeToWbs(String? projectType) {
  if (projectType == null || projectType.isEmpty) return null;
  switch (projectType.toLowerCase()) {
    case 'residential_construction':
    case 'residential':
      return WbsProjectType.residential;
    case 'commercial_construction':
    case 'commercial':
    case 'industrial_construction':
    case 'industrial':
      // Industrial maps to commercial — there's no industrial template type.
      return WbsProjectType.commercial;
    case 'interior_work':
    case 'interior_fitout':
    case 'interiors':
      return WbsProjectType.interiorFitout;
    case 'renovation_remodeling':
    case 'renovation':
      return WbsProjectType.renovation;
    default:
      return null;
  }
}

/// Modal dialog used by the project-creation flow (B9) to let the scheduler
/// choose a WBS template + floor count to materialize on the new project.
///
/// Returns a [WbsTemplatePickerResult] if the user clicks **Materialize**,
/// or `null` if they click **Skip**.
class WbsTemplatePickerDialog extends StatefulWidget {
  final WbsProjectType projectType;
  final int? defaultFloors;

  /// Optional injected service for tests.
  final WbsTemplateService? serviceOverride;

  const WbsTemplatePickerDialog({
    super.key,
    required this.projectType,
    this.defaultFloors,
    this.serviceOverride,
  });

  /// Show the dialog and await a [WbsTemplatePickerResult] (or `null` for skip).
  static Future<WbsTemplatePickerResult?> show(
    BuildContext context, {
    required WbsProjectType projectType,
    int? defaultFloors,
    WbsTemplateService? serviceOverride,
  }) {
    return showDialog<WbsTemplatePickerResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WbsTemplatePickerDialog(
        projectType: projectType,
        defaultFloors: defaultFloors,
        serviceOverride: serviceOverride,
      ),
    );
  }

  @override
  State<WbsTemplatePickerDialog> createState() =>
      _WbsTemplatePickerDialogState();
}

class _WbsTemplatePickerDialogState extends State<WbsTemplatePickerDialog> {
  late final WbsTemplateService _service;
  late final TextEditingController _floorsController;
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  String? _error;
  List<WbsTemplate> _templates = const [];
  int? _selectedTemplateId;

  static const int _minFloors = 1;
  static const int _maxFloors = 20;

  @override
  void initState() {
    super.initState();
    _service = widget.serviceOverride ?? WbsTemplateService();
    final initial = (widget.defaultFloors ?? 1).clamp(_minFloors, _maxFloors);
    _floorsController = TextEditingController(text: '$initial');
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _floorsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await _service.list(includeInactive: false);
      final filtered = all
          .where((t) => t.projectType == widget.projectType && t.isActive)
          .toList();
      if (!mounted) return;
      setState(() {
        _templates = filtered;
        _selectedTemplateId =
            filtered.length == 1 ? filtered.first.id : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load templates: $e';
        _loading = false;
      });
    }
  }

  void _onSkip() => Navigator.of(context).pop();

  void _onMaterialize() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTemplateId == null) return;
    final floors = int.parse(_floorsController.text.trim());
    Navigator.of(context).pop(
      WbsTemplatePickerResult(
        templateId: _selectedTemplateId!,
        floorCount: floors,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Materialize WBS from template'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Optionally pick a ${widget.projectType.label} template to '
                'create the initial WBS for this project. You can skip this '
                'and add one later.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _ErrorRow(message: _error!, onRetry: _load)
              else if (_templates.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No active ${widget.projectType.label} templates found. '
                    'Skip and have an admin create one first.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _templates.length,
                    itemBuilder: (_, i) {
                      final t = _templates[i];
                      return RadioListTile<int>(
                        value: t.id!,
                        groupValue: _selectedTemplateId,
                        onChanged: (v) =>
                            setState(() => _selectedTemplateId = v),
                        title: Text(t.name),
                        subtitle: Text('v${t.version}'),
                        dense: true,
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _floorsController,
                decoration: const InputDecoration(
                  labelText: 'Floors *',
                  border: OutlineInputBorder(),
                  helperText: 'Number of floors to materialize (1–20).',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Required';
                  final n = int.tryParse(s);
                  if (n == null) return 'Must be a whole number';
                  if (n < _minFloors || n > _maxFloors) {
                    return 'Must be between $_minFloors and $_maxFloors';
                  }
                  return null;
                },
              ),
            ],
          ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _onSkip, child: const Text('Skip')),
        FilledButton(
          onPressed: (_loading ||
                  _templates.isEmpty ||
                  _selectedTemplateId == null)
              ? null
              : _onMaterialize,
          child: const Text('Materialize'),
        ),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRow({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
