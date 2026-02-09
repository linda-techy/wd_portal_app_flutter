import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../theme/app_theme.dart';

class CreateDocumentScreen extends StatefulWidget {
  final String documentType;

  const CreateDocumentScreen({
    super.key,
    required this.documentType,
  });

  @override
  State<CreateDocumentScreen> createState() => _CreateDocumentScreenState();
}

class _CreateDocumentScreenState extends State<CreateDocumentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Common fields
  late final TextEditingController _titleController;
  late final TextEditingController _dateController;
  late final TextEditingController _notesController;

  DateTime? _documentDate;

  // Construction Agreement fields
  late final TextEditingController _clientNameController;
  late final TextEditingController _projectValueController;
  late final TextEditingController _contractTermsController;
  late final TextEditingController _paymentTermsController;
  late final TextEditingController _caStartDateController;
  late final TextEditingController _caCompletionDateController;

  DateTime? _caStartDate;
  DateTime? _caCompletionDate;

  // Site Handover fields
  late final TextEditingController _handoverDateController;
  late final TextEditingController _siteConditionController;
  late final TextEditingController _inspectionNotesController;
  late final TextEditingController _pendingItemsController;
  late final TextEditingController _handoverToController;

  DateTime? _handoverDate;

  // Completion Certificate fields
  late final TextEditingController _completionDateController;
  late final TextEditingController _certifyingAuthorityController;
  late final TextEditingController _finalInspectionNotesController;
  late final TextEditingController _deficiencyListController;
  late final TextEditingController _warrantyPeriodController;

  DateTime? _completionDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.documentType);
    _dateController = TextEditingController();
    _notesController = TextEditingController();

    _clientNameController = TextEditingController();
    _projectValueController = TextEditingController();
    _contractTermsController = TextEditingController();
    _paymentTermsController = TextEditingController();
    _caStartDateController = TextEditingController();
    _caCompletionDateController = TextEditingController();

    _handoverDateController = TextEditingController();
    _siteConditionController = TextEditingController();
    _inspectionNotesController = TextEditingController();
    _pendingItemsController = TextEditingController();
    _handoverToController = TextEditingController();

    _completionDateController = TextEditingController();
    _certifyingAuthorityController = TextEditingController();
    _finalInspectionNotesController = TextEditingController();
    _deficiencyListController = TextEditingController();
    _warrantyPeriodController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _notesController.dispose();

    _clientNameController.dispose();
    _projectValueController.dispose();
    _contractTermsController.dispose();
    _paymentTermsController.dispose();
    _caStartDateController.dispose();
    _caCompletionDateController.dispose();

    _handoverDateController.dispose();
    _siteConditionController.dispose();
    _inspectionNotesController.dispose();
    _pendingItemsController.dispose();
    _handoverToController.dispose();

    _completionDateController.dispose();
    _certifyingAuthorityController.dispose();
    _finalInspectionNotesController.dispose();
    _deficiencyListController.dispose();
    _warrantyPeriodController.dispose();

    super.dispose();
  }

  bool get _isConstructionAgreement =>
      widget.documentType.toLowerCase() == 'construction agreement';

  bool get _isSiteHandover =>
      widget.documentType.toLowerCase() == 'site handover';

  bool get _isCompletionCertificate =>
      widget.documentType.toLowerCase() == 'completion certificate';

  Future<void> _pickDate({
    required BuildContext context,
    required TextEditingController controller,
    required ValueChanged<DateTime?> onDateSelected,
    DateTime? initialDate,
  }) async {
    final now = DateTime.now();
    final firstDate = AppConfig.datePickerFirstDate;
    final lastDate = DateTime(now.year + 10, 12, 31);

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selected != null) {
      onDateSelected(selected);
      controller.text = _formatDate(selected);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.documentType} generated successfully.',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textInverse),
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).maybePop();
  }

  InputDecoration _buildInputDecoration(String label, {String? hint, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Create ${widget.documentType}',
          style: AppTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingLG),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(
                    color: AppTheme.borderLight,
                    width: 1,
                  ),
                  boxShadow: AppTheme.shadowSM,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.documentType,
                        style: AppTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingSM),
                      Text(
                        'Fill in the details below to generate the document.',
                        style: AppTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingLG),
                      _buildCommonFieldsSection(),
                      if (_isConstructionAgreement) ...[
                        const SizedBox(height: AppTheme.spacingLG),
                        _buildSectionHeader('Construction Agreement Details'),
                        const SizedBox(height: AppTheme.spacingMD),
                        _buildConstructionAgreementFields(),
                      ],
                      if (_isSiteHandover) ...[
                        const SizedBox(height: AppTheme.spacingLG),
                        _buildSectionHeader('Site Handover Details'),
                        const SizedBox(height: AppTheme.spacingMD),
                        _buildSiteHandoverFields(),
                      ],
                      if (_isCompletionCertificate) ...[
                        const SizedBox(height: AppTheme.spacingLG),
                        _buildSectionHeader('Completion Certificate Details'),
                        const SizedBox(height: AppTheme.spacingMD),
                        _buildCompletionCertificateFields(),
                      ],
                      const SizedBox(height: AppTheme.spacingLG),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 220,
                          child: ElevatedButton.icon(
                            onPressed: _onSave,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Save & Generate'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSM),
        Text(
          title,
          style: AppTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildCommonFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Document Details'),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _titleController,
          decoration: _buildInputDecoration('Document title'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a document title';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacingMD),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _pickDate(
              context: context,
              controller: _dateController,
              onDateSelected: (date) => _documentDate = date,
              initialDate: _documentDate,
            );
          },
          child: AbsorbPointer(
            child: TextFormField(
              controller: _dateController,
              decoration: _buildInputDecoration(
                'Document date',
                hint: 'Select date',
              ).copyWith(
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              validator: (value) {
                if (_documentDate == null) {
                  return 'Please select a document date';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _notesController,
          decoration: _buildInputDecoration('Notes', hint: 'Additional notes'),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildConstructionAgreementFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _clientNameController,
          decoration: _buildInputDecoration('Client name'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the client name';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _projectValueController,
          keyboardType: TextInputType.number,
          decoration: _buildInputDecoration(
            'Project value',
            hint: 'Enter amount',
          ).copyWith(
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMD,
                vertical: AppTheme.spacingSM,
              ),
              child: Text(
                '₹',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the project value';
            }
            final cleaned = value.replaceAll(',', '').trim();
            final amount = num.tryParse(cleaned);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _contractTermsController,
          decoration: _buildInputDecoration('Contract terms'),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please specify the contract terms';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _paymentTermsController,
          decoration: _buildInputDecoration('Payment terms'),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please specify the payment terms';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacingMD),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _pickDate(
                    context: context,
                    controller: _caStartDateController,
                    onDateSelected: (date) => _caStartDate = date,
                    initialDate: _caStartDate ?? _documentDate,
                  );
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _caStartDateController,
                    decoration: _buildInputDecoration(
                      'Start date',
                      hint: 'Select date',
                    ).copyWith(
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (value) {
                      if (_caStartDate == null) {
                        return 'Select start date';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _pickDate(
                    context: context,
                    controller: _caCompletionDateController,
                    onDateSelected: (date) => _caCompletionDate = date,
                    initialDate: _caCompletionDate ?? _caStartDate,
                  );
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _caCompletionDateController,
                    decoration: _buildInputDecoration(
                      'Completion date',
                      hint: 'Select date',
                    ).copyWith(
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (value) {
                      if (_caCompletionDate == null) {
                        return 'Select completion date';
                      }
                      if (_caStartDate != null &&
                          _caCompletionDate!.isBefore(_caStartDate!)) {
                        return 'Completion cannot be before start';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSiteHandoverFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _pickDate(
              context: context,
              controller: _handoverDateController,
              onDateSelected: (date) => _handoverDate = date,
              initialDate: _handoverDate ?? _documentDate,
            );
          },
          child: AbsorbPointer(
            child: TextFormField(
              controller: _handoverDateController,
              decoration: _buildInputDecoration(
                'Handover date',
                hint: 'Select date',
              ).copyWith(
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              validator: (value) {
                if (_handoverDate == null) {
                  return 'Please select the handover date';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _siteConditionController,
          decoration: _buildInputDecoration('Site condition'),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please describe the site condition';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _inspectionNotesController,
          decoration: _buildInputDecoration('Inspection notes'),
          maxLines: 3,
        ),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _pendingItemsController,
          decoration: _buildInputDecoration('Pending items'),
          maxLines: 3,
        ),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _handoverToController,
          decoration: _buildInputDecoration('Handover to (name)'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the name of the person receiving handover';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCompletionCertificateFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _pickDate(
              context: context,
              controller: _completionDateController,
              onDateSelected: (date) => _completionDate = date,
              initialDate: _completionDate ?? _documentDate,
            );
          },
          child: AbsorbPointer(
            child: TextFormField(
              controller: _completionDateController,
              decoration: _buildInputDecoration(
                'Completion date',
                hint: 'Select date',
              ).copyWith(
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              validator: (value) {
                if (_completionDate == null) {
                  return 'Please select the completion date';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _certifyingAuthorityController,
          decoration: _buildInputDecoration('Certifying authority'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please specify the certifying authority';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _finalInspectionNotesController,
          decoration: _buildInputDecoration('Final inspection notes'),
          maxLines: 3,
        ),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _deficiencyListController,
          decoration: _buildInputDecoration('Deficiency list'),
          maxLines: 3,
        ),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _warrantyPeriodController,
          decoration: _buildInputDecoration('Warranty period'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please specify the warranty period';
            }
            return null;
          },
        ),
      ],
    );
  }
}

