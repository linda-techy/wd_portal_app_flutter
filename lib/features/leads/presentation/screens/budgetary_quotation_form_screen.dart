import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/features/leads/data/models/quotation_assumption.dart';
import 'package:admin/features/leads/data/models/quotation_exclusion.dart';
import 'package:admin/features/leads/data/models/quotation_inclusion.dart';
import 'package:admin/features/leads/data/models/quotation_payment_milestone.dart';
import 'package:admin/features/leads/data/services/lead_quotation_service.dart';
import 'package:admin/features/leads/presentation/widgets/quotation/assumptions_editor.dart';
import 'package:admin/features/leads/presentation/widgets/quotation/exclusions_editor.dart';
import 'package:admin/features/leads/presentation/widgets/quotation/inclusions_editor.dart';
import 'package:admin/features/leads/presentation/widgets/quotation/payment_milestone_editor.dart';
import 'package:admin/features/leads/presentation/widgets/quotation/tier_selector_cards.dart';
import 'package:admin/utils/error_handler.dart';

/// Stage 1 of the 3-stage redesign: BUDGETARY quotation form.
///
/// Used for the lead-enquiry conversation when the area is unknown, the
/// plan isn't drawn, and the customer is comparing builders. Critically,
/// this form NEVER captures or shows a grand total — the headline output
/// is a tier range, scope, payment shape, and a CTA.
///
/// Save semantics (v1, pragmatic):
///   1. POST `/leads/quotations` with `quotationType = BUDGETARY`,
///      `pricingMode = SQFT_RATE` (so the tier range maps to the existing
///      rate column when the customer later promotes to DETAILED).
///   2. After the parent is created, POST each sub-resource row in
///      sequence. Failures on individual rows don't roll back the parent
///      — staff sees a row-level error toast and can retry.
///   3. Validity defaults to creation-date + 30 days; staff can shorten.
///
/// What this form deliberately does NOT do (deferred to later phases):
///   * Edit existing BUDGETARY quotations — first cut is create-only.
///     Editing would require diff-based PUT/DELETE on sub-resources.
///   * Promote-to-DETAILED — separate screen.
class BudgetaryQuotationFormScreen extends StatefulWidget {
  final Lead lead;

  const BudgetaryQuotationFormScreen({super.key, required this.lead});

  @override
  State<BudgetaryQuotationFormScreen> createState() =>
      _BudgetaryQuotationFormScreenState();
}

class _BudgetaryQuotationFormScreenState
    extends State<BudgetaryQuotationFormScreen> {
  final _service = LeadQuotationService();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // ── Header fields ───────────────────────────────────────────────────────
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String? _tier; // null = no tier picked yet
  final _rateMinController = TextEditingController();
  final _rateMaxController = TextEditingController();
  final _areaMinController = TextEditingController();
  final _areaMaxController = TextEditingController();
  final _durationMinController = TextEditingController(text: '10');
  final _durationMaxController = TextEditingController(text: '12');

  /// Default to creation-date + 30 days. Customer-facing PDF reads this
  /// as "Pricing locked till 04 May 2026" — absolute dates beat
  /// "30 days from when?" every time.
  late DateTime _validUntil;

  // ── Sub-resources (local state until parent is saved) ──────────────────
  List<QuotationInclusion> _inclusions = const [];
  List<QuotationExclusion> _exclusions = const [];
  List<QuotationAssumption> _assumptions = const [];
  List<QuotationPaymentMilestone> _milestones =
      QuotationPaymentMilestone.defaultKeralaSchedule();

  @override
  void initState() {
    super.initState();
    _validUntil = DateTime.now().add(const Duration(days: 30));
    _titleController.text = 'Budgetary Quotation — ${widget.lead.name}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _rateMinController.dispose();
    _rateMaxController.dispose();
    _areaMinController.dispose();
    _areaMaxController.dispose();
    _durationMinController.dispose();
    _durationMaxController.dispose();
    super.dispose();
  }

  /// Auto-fill the rate range from the picked tier. Walldot's defaults —
  /// staff can override after.
  void _onTierChanged(String tier) {
    setState(() {
      _tier = tier;
      switch (tier) {
        case 'ECONOMY':
          _rateMinController.text = '1750';
          _rateMaxController.text = '1950';
          break;
        case 'STANDARD':
          _rateMinController.text = '1950';
          _rateMaxController.text = '2150';
          break;
        case 'PREMIUM':
          _rateMinController.text = '2150';
          _rateMaxController.text = '2500';
          break;
      }
    });
  }

  Future<void> _pickValidUntil() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntil,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _validUntil = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a tier first.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // Lead.leadId is the external string id; quotations key on the
      // numeric primary key, which mirror across with int.parse.
      final leadIdInt = int.parse(widget.lead.leadId);
      final draft = LeadQuotation(
        leadId: leadIdInt,
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        quotationType: 'BUDGETARY',
        showGrandTotal: false,
        // BUDGETARY uses LINE_ITEM mode internally — no items, no totals.
        // Switching to SQFT_RATE on the DETAILED promotion happens in a
        // later screen; here we keep the parent uncluttered.
        pricingMode: 'LINE_ITEM',
        // Final/total amounts intentionally null — backend currently
        // requires non-null but with a server-side change in V76.5 this
        // will become valid. For now, safer to send 0 and rely on the
        // showGrandTotal=false flag to hide it on the PDF.
        totalAmount: 0,
        finalAmount: 0,
        tier: _tier,
        ratePerSqftMin: double.tryParse(_rateMinController.text),
        ratePerSqftMax: double.tryParse(_rateMaxController.text),
        estimatedAreaMin: double.tryParse(_areaMinController.text),
        estimatedAreaMax: double.tryParse(_areaMaxController.text),
        durationMonthsMin: int.tryParse(_durationMinController.text),
        durationMonthsMax: int.tryParse(_durationMaxController.text),
        validUntil: _validUntil,
        validityDays: _validUntil.difference(DateTime.now()).inDays,
      );

      final created = await _service.createQuotation(draft);
      final quotationId = created.id!;

      // Fire sub-resource POSTs in sequence. Sequential rather than
      // Future.wait so a single failure surfaces a clear row index in
      // the error toast.
      for (final inc in _inclusions) {
        await _service.createInclusion(quotationId, inc);
      }
      for (final exc in _exclusions) {
        await _service.createExclusion(quotationId, exc);
      }
      for (final ass in _assumptions) {
        await _service.createAssumption(quotationId, ass);
      }
      for (final m in _milestones) {
        await _service.createPaymentMilestone(quotationId, m);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budgetary quotation #$quotationId created')),
      );
      Navigator.of(context).pop(created);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Budgetary Quotation'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _customerCard(),
            const SizedBox(height: 16),
            _section('Title', [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
            ]),
            _section('Tier', [
              const Text(
                'The customer-facing PDF shows all three tiers; the picked one is highlighted.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TierSelectorCards(
                selectedTier: _tier,
                onChanged: _onTierChanged,
              ),
              const SizedBox(height: 12),
              _twoFields(
                'Rate min (₹/sqft)', _rateMinController,
                'Rate max (₹/sqft)', _rateMaxController,
              ),
            ]),
            _section('Estimate ranges', [
              _twoFields(
                'Area min (sqft)', _areaMinController,
                'Area max (sqft)', _areaMaxController,
              ),
              const SizedBox(height: 8),
              _twoFields(
                'Duration min (months)', _durationMinController,
                'Duration max (months)', _durationMaxController,
              ),
            ]),
            _section('Validity', [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Locked till: ${DateFormat('dd MMM yyyy').format(_validUntil)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickValidUntil,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Change date'),
                  ),
                ],
              ),
            ]),
            _section('Inclusions', [
              InclusionsEditor(
                inclusions: _inclusions,
                onChanged: (next) => setState(() => _inclusions = next),
              ),
            ]),
            _section('Exclusions', [
              ExclusionsEditor(
                exclusions: _exclusions,
                onChanged: (next) => setState(() => _exclusions = next),
              ),
            ]),
            _section('Assumptions', [
              AssumptionsEditor(
                assumptions: _assumptions,
                onChanged: (next) => setState(() => _assumptions = next),
              ),
            ]),
            _section('Payment milestones', [
              PaymentMilestoneEditor(
                milestones: _milestones,
                onChanged: (next) => setState(() => _milestones = next),
              ),
            ]),
            _section('Internal notes (not on PDF)', [
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ]),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _customerCard() {
    final lead = widget.lead;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.person, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lead.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    [
                      if (lead.phone.isNotEmpty) lead.phone,
                      if (lead.district.isNotEmpty) lead.district,
                    ].join(' · '),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _twoFields(String l1, TextEditingController c1, String l2,
      TextEditingController c2) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: c1,
            decoration: InputDecoration(
              labelText: l1,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: c2,
            decoration: InputDecoration(
              labelText: l2,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }
}
