/// Lead Estimation Wizard — 5-step Material Stepper.
///
/// Steps:
///   1. Package + Project Type selection
///   2. Floor dimensions (length × width per floor, semi-covered + open-terrace areas)
///   3. Customisations  — real selectors from EstimationOptionsProvider
///   4. Add-ons & Fees  — real selectors from EstimationOptionsProvider
///   5. Review + live preview → Save
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/estimation_settings/data/models/package_rate_version.dart';
import 'package:admin/features/estimation_settings/providers/estimation_packages_provider.dart';
import 'package:admin/features/lead_estimation/data/models/lead_estimation.dart' show EstimationPricingMode, LeadEstimationDetail;
import 'package:admin/features/lead_estimation/providers/estimation_options_provider.dart';
import 'package:admin/features/lead_estimation/providers/lead_estimations_provider.dart';
import 'package:admin/features/lead_estimation/presentation/widgets/wizard_step_1_package.dart';
import 'package:admin/features/lead_estimation/presentation/widgets/wizard_step_2_dimensions.dart';
import 'package:admin/features/lead_estimation/presentation/widgets/wizard_step_3_customisations.dart';
import 'package:admin/features/lead_estimation/presentation/widgets/wizard_step_4_addons_fees.dart';
import 'package:admin/features/lead_estimation/presentation/widgets/wizard_step_5_review.dart';

// ---------------------------------------------------------------------------
// Wizard draft model — public so step widgets can reference the types
// ---------------------------------------------------------------------------

class WizardFloorInput {
  String name = '';
  double length = 0;
  double width = 0;
}

class WizardDraft {
  // K — pricing mode (drives whether subsequent steps gather floors+catalog or just an area).
  EstimationPricingMode pricingMode = EstimationPricingMode.LINE_ITEM;

  // Step 1
  String? packageId;
  ProjectType projectType = ProjectType.NEW_BUILD;

  // Step 2 — line-item path
  List<WizardFloorInput> floors = [WizardFloorInput()];
  double semiCoveredArea = 0;
  double openTerraceArea = 0;

  // Step 2 — budgetary path
  double? estimatedAreaSqft;

  // Step 3 — empty until future endpoint is available
  List<Map<String, String>> customisations = [];

  // Step 4 — empty until future endpoint is available
  List<String> siteFeeIds = [];
  List<String> addOnIds = [];
  List<String> govtFeeIds = [];

  // Step 5 — all optional (backend supplies defaults)
  double? discountPercent;
  double? gstRate;
  DateTime? validUntil;

  Map<String, dynamic> toPreviewPayload() {
    if (pricingMode == EstimationPricingMode.BUDGETARY) {
      return {
        'projectType': projectType.name,
        'packageId': packageId,
        'pricingMode': 'BUDGETARY',
        'estimatedAreaSqft': estimatedAreaSqft,
        if (gstRate != null) 'gstRate': gstRate,
      };
    }
    return {
      'projectType': projectType.name,
      'packageId': packageId,
      'pricingMode': 'LINE_ITEM',
      'dimensions': {
        'floors': floors
            .map((f) => {
                  'floorName': f.name,
                  'length': f.length,
                  'width': f.width,
                })
            .toList(),
        'semiCoveredArea': semiCoveredArea,
        'openTerraceArea': openTerraceArea,
      },
      'customisations': customisations,
      'siteFees': siteFeeIds.map((id) => {'id': id}).toList(),
      'addOns': addOnIds.map((id) => {'id': id}).toList(),
      'govtFees': govtFeeIds.map((id) => {'id': id}).toList(),
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (gstRate != null) 'gstRate': gstRate,
    };
  }
}

// ---------------------------------------------------------------------------
// Screen widget
// ---------------------------------------------------------------------------

class LeadEstimationWizardScreen extends StatefulWidget {
  final int leadId;

  /// When set, the wizard calls `reviseEstimation` instead of `create` on save.
  final String? reviseFromEstimationId;

  /// When set, pre-populates the draft with package + projectType from this detail.
  /// MVP limitation: dimensions are not pre-filled (detail response omits raw
  /// input dimensions); user re-enters them manually.
  final LeadEstimationDetail? prefillFrom;

  const LeadEstimationWizardScreen({
    super.key,
    required this.leadId,
    this.reviseFromEstimationId,
    this.prefillFrom,
  });

  @override
  State<LeadEstimationWizardScreen> createState() =>
      _LeadEstimationWizardScreenState();
}

class _LeadEstimationWizardScreenState
    extends State<LeadEstimationWizardScreen> {
  late final EstimationPackagesProvider _packagesProvider;
  late final LeadEstimationsProvider _estimationsProvider;
  late final EstimationOptionsProvider _optionsProvider;

  final _draft = WizardDraft();
  int _currentStep = 0;

  // Per-step form keys for validation
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _packagesProvider = EstimationPackagesProvider();
    _estimationsProvider = LeadEstimationsProvider();
    _optionsProvider = EstimationOptionsProvider();

    // Pre-fill draft when revising an existing estimation.
    final prefill = widget.prefillFrom;
    if (prefill != null) {
      _draft.packageId = prefill.packageId;
      _draft.projectType = prefill.projectType;
      _draft.pricingMode = prefill.pricingMode;
      // N — hydrate budgetary area or line-item dimensions from the parent.
      if (prefill.pricingMode == EstimationPricingMode.BUDGETARY) {
        _draft.estimatedAreaSqft = prefill.estimatedAreaSqft;
      } else {
        _hydrateDimensionsFromJson(prefill.dimensionsJson);
      }
      // Trigger catalog load for the pre-filled package.
      if (prefill.packageId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _optionsProvider.loadForPackage(prefill.packageId);
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        _packagesProvider.load(),
        _estimationsProvider.loadForLead(widget.leadId),
      ]);
    });
  }

  @override
  void dispose() {
    _packagesProvider.dispose();
    _estimationsProvider.dispose();
    _optionsProvider.dispose();
    super.dispose();
  }

  /// N — populates draft floor list + semi/terrace areas from a parent estimation's
  /// dimensions_json blob. Tolerant of missing/empty fields (the wizard handles
  /// `floors = []` by leaving the seeded blank floor in place).
  void _hydrateDimensionsFromJson(Map<String, dynamic>? dim) {
    if (dim == null || dim.isEmpty) return;
    final floors = dim['floors'];
    if (floors is List && floors.isNotEmpty) {
      _draft.floors = floors.map((f) {
        final m = f as Map<String, dynamic>;
        return WizardFloorInput()
          ..name = (m['floorName'] as String?) ?? ''
          ..length = (m['length'] as num?)?.toDouble() ?? 0
          ..width = (m['width'] as num?)?.toDouble() ?? 0;
      }).toList();
    }
    _draft.semiCoveredArea = (dim['semiCoveredArea'] as num?)?.toDouble() ?? 0;
    _draft.openTerraceArea = (dim['openTerraceArea'] as num?)?.toDouble() ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _goNext() {
    if (_currentStep == 0) {
      if (!(_step1Key.currentState?.validate() ?? false)) return;
      if (_draft.packageId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a package.')),
        );
        return;
      }
      // Trigger catalog load only for line-item mode (budgetary skips catalog).
      if (_draft.pricingMode == EstimationPricingMode.LINE_ITEM) {
        _optionsProvider.loadForPackage(_draft.packageId);
      }
    } else if (_currentStep == 1) {
      if (!(_step2Key.currentState?.validate() ?? false)) return;
    }
    if (_currentStep < 4) {
      // Budgetary mode skips Steps 3 (customisations) + 4 (addons/fees) entirely:
      // jump directly from Step 2 (area) to Step 5 (review).
      if (_draft.pricingMode == EstimationPricingMode.BUDGETARY &&
          _currentStep == 1) {
        setState(() => _currentStep = 4);
      } else {
        setState(() => _currentStep++);
      }
    }
  }

  void _goBack() {
    if (_currentStep == 0) return;
    // Mirror the forward jump on the way back.
    if (_draft.pricingMode == EstimationPricingMode.BUDGETARY &&
        _currentStep == 4) {
      setState(() => _currentStep = 1);
    } else {
      setState(() => _currentStep--);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<EstimationPackagesProvider>.value(
            value: _packagesProvider),
        ChangeNotifierProvider<LeadEstimationsProvider>.value(
            value: _estimationsProvider),
        ChangeNotifierProvider<EstimationOptionsProvider>.value(
            value: _optionsProvider),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.reviseFromEstimationId != null
              ? 'Revise Estimation — Lead #${widget.leadId}'
              : 'New Estimation — Lead #${widget.leadId}'),
        ),
        body: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepTapped: (i) {
            // Allow tapping back to already-visited steps; block forward jumps
            if (i < _currentStep) setState(() => _currentStep = i);
          },
          controlsBuilder: _buildControls,
          steps: [
            Step(
              title: const Text('Package'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Form(
                key: _step1Key,
                child: WizardStep1Package(
                  draft: _draft,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
            Step(
              title: const Text('Dimensions'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Form(
                key: _step2Key,
                child: WizardStep2Dimensions(
                  draft: _draft,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
            Step(
              title: const Text('Customisations'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: WizardStep3Customisations(
                draft: _draft,
                onChanged: () => setState(() {}),
              ),
            ),
            Step(
              title: const Text('Add-ons & Fees'),
              isActive: _currentStep >= 3,
              state: _currentStep > 3 ? StepState.complete : StepState.indexed,
              content: WizardStep4AddOnsFees(
                draft: _draft,
                onChanged: () => setState(() {}),
              ),
            ),
            Step(
              title: const Text('Review & Save'),
              isActive: _currentStep >= 4,
              state: StepState.indexed,
              content: WizardStep5Review(
                draft: _draft,
                estimationsProvider: _estimationsProvider,
                onChanged: () => setState(() {}),
                onSaved: (created) => Navigator.of(context).pop(created),
                reviseFromEstimationId: widget.reviseFromEstimationId,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, ControlsDetails details) {
    // Step 5 manages its own Save button; the stepper controls are hidden there.
    if (_currentStep == 4) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          FilledButton(
            onPressed: _goNext,
            child: Text(_currentStep == 3 ? 'Continue to Review' : 'Next'),
          ),
          const SizedBox(width: 12),
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: _goBack,
              child: const Text('Back'),
            ),
          // Steps 3 + 4 show a Skip shortcut for clarity
          if (_currentStep == 2 || _currentStep == 3) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: _goNext,
              child: const Text('Skip'),
            ),
          ],
        ],
      ),
    );
  }
}
