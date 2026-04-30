import 'package:admin/features/leads/data/models/quotation_assumption.dart';
import 'package:admin/features/leads/data/models/quotation_exclusion.dart';
import 'package:admin/features/leads/data/models/quotation_inclusion.dart';
import 'package:admin/features/leads/data/models/quotation_payment_milestone.dart';

class LeadQuotation {
  final int? id;
  final int leadId;

  /// Customer name resolved server-side (transient field on the entity,
  /// batch-loaded after the page query). Lets list cards show
  /// "Mr. Joseph" instead of leaking "Lead ID: 47". Nullable when the
  /// underlying lead is missing (orphaned quotation) or for endpoints
  /// that don't populate it.
  final String? leadName;
  final String? quotationNumber;
  final int version;
  final String title;
  final String? description;
  final double? totalAmount;
  final double? taxAmount;

  /// Tax rate as a percentage (e.g. 18.0 = 18% GST). When non-null the
  /// backend auto-computes [taxAmount] as `(subtotal − discount) × rate / 100`
  /// — the canonical Indian-GST tax base. When null, [taxAmount] is treated
  /// as a manual override and used as-is. New quotations default to 18.0.
  final double? taxRatePercent;
  final double? discountAmount;
  final double? finalAmount;

  /// Pricing mode — drives both the Flutter form layout and the customer
  /// PDF shape:
  ///   * `LINE_ITEM` — legacy: items have qty + unit price, subtotal sums.
  ///   * `SQFT_RATE` — Walldot's actual customer doc: subtotal is computed
  ///     server-side as `lead.projectSqftArea × ratePerSqft`. Items are
  ///     scope specs (description + notes) without prices.
  ///
  /// New customer-facing quotations should be created with `SQFT_RATE`;
  /// existing rows were backfilled to `LINE_ITEM` in V75.
  final String pricingMode;

  /// Per-sqft headline rate for `SQFT_RATE` mode. Null otherwise.
  final double? ratePerSqft;
  final int validityDays;

  // ── V76 redesign fields ────────────────────────────────────────────────

  /// Sales-stage discriminator: BUDGETARY (lead enquiry, no totals),
  /// DETAILED (post-site-visit estimate), or CONTRACT_BOQ (signed
  /// contract). Defaults to DETAILED on legacy rows.
  final String quotationType;

  /// Predecessor in the BUDGETARY → DETAILED → CONTRACT_BOQ chain.
  final int? parentQuotationId;

  /// Finish tier — ECONOMY / STANDARD / PREMIUM. Null for legacy rows.
  final String? tier;

  /// Lower / upper bound of the per-sqft rate range — used by BUDGETARY
  /// and DETAILED PDFs to render "₹1,950–2,150/sqft" instead of a single
  /// number. Both null for CONTRACT_BOQ.
  final double? ratePerSqftMin;
  final double? ratePerSqftMax;

  /// Lower / upper bound of estimated built-up area (sqft) for DETAILED.
  final double? estimatedAreaMin;
  final double? estimatedAreaMax;

  /// Estimated construction duration in months, as a range.
  final int? durationMonthsMin;
  final int? durationMonthsMax;

  /// Absolute expiry date — replaces validityDays as the source of truth.
  /// "Pricing locked till 04 May 2026" reads better than "30 days from when?"
  final DateTime? validUntil;

  /// When false, the rendered PDF must suppress every grand-total figure.
  /// New BUDGETARY rows default to false.
  final bool showGrandTotal;

  /// Random UUID for the customer-facing tracked link
  /// (`/public/quotations/{token}`). Null until "Send" is clicked.
  final String? publicViewToken;

  /// V76 sub-resources — populated by GET /leads/quotations/{id}.
  final List<QuotationInclusion> inclusions;
  final List<QuotationExclusion> exclusions;
  final List<QuotationAssumption> assumptions;
  final List<QuotationPaymentMilestone> paymentMilestones;

  final String status;
  final DateTime? sentAt;
  final DateTime? viewedAt;
  final DateTime? respondedAt;
  final int? createdById;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final List<LeadQuotationItem> items;

  LeadQuotation({
    this.id,
    required this.leadId,
    this.leadName,
    this.quotationNumber,
    this.version = 1,
    required this.title,
    this.description,
    this.totalAmount,
    this.taxAmount,
    this.taxRatePercent,
    this.discountAmount,
    this.finalAmount,
    this.validityDays = 30,
    this.status = 'DRAFT',
    this.pricingMode = 'LINE_ITEM',
    this.ratePerSqft,
    this.sentAt,
    this.viewedAt,
    this.respondedAt,
    this.createdById,
    this.createdAt,
    this.updatedAt,
    this.notes,
    this.items = const [],
    // V76 redesign defaults — DETAILED keeps legacy semantics; new
    // BUDGETARY rows must override quotationType + showGrandTotal=false.
    this.quotationType = 'DETAILED',
    this.parentQuotationId,
    this.tier,
    this.ratePerSqftMin,
    this.ratePerSqftMax,
    this.estimatedAreaMin,
    this.estimatedAreaMax,
    this.durationMonthsMin,
    this.durationMonthsMax,
    this.validUntil,
    this.showGrandTotal = true,
    this.publicViewToken,
    this.inclusions = const [],
    this.exclusions = const [],
    this.assumptions = const [],
    this.paymentMilestones = const [],
  });

  factory LeadQuotation.fromJson(Map<String, dynamic> json) {
    return LeadQuotation(
      id: json['id'],
      leadId: json['leadId'] ?? json['lead_id'],
      leadName: json['leadName'] ?? json['lead_name'],
      quotationNumber: json['quotationNumber'] ?? json['quotation_number'],
      version: json['version'] ?? 1,
      title: json['title'],
      description: json['description'],
      totalAmount:
          (json['totalAmount'] ?? json['total_amount'] as num?)?.toDouble(),
      taxAmount: (json['taxAmount'] ?? json['tax_amount'] as num?)?.toDouble(),
      taxRatePercent:
          (json['taxRatePercent'] ?? json['tax_rate_percent'] as num?)
              ?.toDouble(),
      discountAmount:
          (json['discountAmount'] ?? json['discount_amount'] as num?)
              ?.toDouble(),
      finalAmount:
          (json['finalAmount'] ?? json['final_amount'] as num?)?.toDouble(),
      validityDays: json['validityDays'] ?? json['validity_days'] ?? 30,
      status: json['status'] ?? 'DRAFT',
      pricingMode:
          json['pricingMode'] ?? json['pricing_mode'] ?? 'LINE_ITEM',
      ratePerSqft:
          (json['ratePerSqft'] ?? json['rate_per_sqft'] as num?)?.toDouble(),
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : (json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null),
      viewedAt: json['viewedAt'] != null
          ? DateTime.parse(json['viewedAt'])
          : (json['viewed_at'] != null
              ? DateTime.parse(json['viewed_at'])
              : null),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'])
          : (json['responded_at'] != null
              ? DateTime.parse(json['responded_at'])
              : null),
      createdById: json['createdById'] ?? json['created_by_id'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null),
      notes: json['notes'],
      items: json['items'] != null
          ? (json['items'] as List)
              .map((i) => LeadQuotationItem.fromJson(i))
              .toList()
          : [],
      // V76 fields. Server sends camelCase; legacy snake_case fallbacks
      // keep older snapshots / fixtures decoding cleanly.
      quotationType: (json['quotationType'] ?? json['quotation_type'])
              as String? ??
          'DETAILED',
      parentQuotationId:
          (json['parentQuotationId'] ?? json['parent_quotation_id']) as int?,
      tier: json['tier'] as String?,
      ratePerSqftMin: (json['ratePerSqftMin'] ?? json['rate_per_sqft_min']
              as num?)
          ?.toDouble(),
      ratePerSqftMax: (json['ratePerSqftMax'] ?? json['rate_per_sqft_max']
              as num?)
          ?.toDouble(),
      estimatedAreaMin: (json['estimatedAreaMin'] ?? json['estimated_area_min']
              as num?)
          ?.toDouble(),
      estimatedAreaMax: (json['estimatedAreaMax'] ?? json['estimated_area_max']
              as num?)
          ?.toDouble(),
      durationMonthsMin:
          (json['durationMonthsMin'] ?? json['duration_months_min']) as int?,
      durationMonthsMax:
          (json['durationMonthsMax'] ?? json['duration_months_max']) as int?,
      validUntil: _parseDate(json['validUntil'] ?? json['valid_until']),
      showGrandTotal:
          (json['showGrandTotal'] ?? json['show_grand_total']) as bool? ?? true,
      publicViewToken:
          (json['publicViewToken'] ?? json['public_view_token']) as String?,
      inclusions: (json['inclusions'] as List?)
              ?.map((i) =>
                  QuotationInclusion.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      exclusions: (json['exclusions'] as List?)
              ?.map((i) =>
                  QuotationExclusion.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      assumptions: (json['assumptions'] as List?)
              ?.map((i) =>
                  QuotationAssumption.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      paymentMilestones: (json['paymentMilestones'] as List?)
              ?.map((i) => QuotationPaymentMilestone.fromJson(
                  i as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Tolerant ISO-8601 / yyyy-MM-dd date parser. Accepts the bare LocalDate
  /// shape (`"2026-05-04"`) the backend serialises validUntil as, plus
  /// full timestamps for safety in case the column is migrated to
  /// TIMESTAMP WITH TIME ZONE later.
  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leadId': leadId,
      'quotationNumber': quotationNumber,
      'version': version,
      'title': title,
      'description': description,
      'totalAmount': totalAmount,
      'taxAmount': taxAmount,
      'taxRatePercent': taxRatePercent,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'validityDays': validityDays,
      'status': status,
      'pricingMode': pricingMode,
      'ratePerSqft': ratePerSqft,
      'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'leadId': leadId,
      'title': title,
      'description': description,
      'totalAmount': totalAmount,
      'taxAmount': taxAmount,
      'taxRatePercent': taxRatePercent,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'validityDays': validityDays,
      'pricingMode': pricingMode,
      'ratePerSqft': ratePerSqft,
      'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
      // V76 — only emit non-null fields so legacy DETAILED creates stay
      // backwards-compatible with older API snapshots.
      'quotationType': quotationType,
      if (parentQuotationId != null) 'parentQuotationId': parentQuotationId,
      if (tier != null) 'tier': tier,
      if (ratePerSqftMin != null) 'ratePerSqftMin': ratePerSqftMin,
      if (ratePerSqftMax != null) 'ratePerSqftMax': ratePerSqftMax,
      if (estimatedAreaMin != null) 'estimatedAreaMin': estimatedAreaMin,
      if (estimatedAreaMax != null) 'estimatedAreaMax': estimatedAreaMax,
      if (durationMonthsMin != null) 'durationMonthsMin': durationMonthsMin,
      if (durationMonthsMax != null) 'durationMonthsMax': durationMonthsMax,
      if (validUntil != null)
        'validUntil':
            '${validUntil!.year.toString().padLeft(4, '0')}-${validUntil!.month.toString().padLeft(2, '0')}-${validUntil!.day.toString().padLeft(2, '0')}',
      'showGrandTotal': showGrandTotal,
    };
  }

  LeadQuotation copyWith({
    int? id,
    int? leadId,
    String? quotationNumber,
    int? version,
    String? title,
    String? description,
    double? totalAmount,
    double? taxAmount,
    double? taxRatePercent,
    double? discountAmount,
    double? finalAmount,
    int? validityDays,
    String? status,
    String? pricingMode,
    double? ratePerSqft,
    List<LeadQuotationItem>? items,
    String? quotationType,
    int? parentQuotationId,
    String? tier,
    double? ratePerSqftMin,
    double? ratePerSqftMax,
    double? estimatedAreaMin,
    double? estimatedAreaMax,
    int? durationMonthsMin,
    int? durationMonthsMax,
    DateTime? validUntil,
    bool? showGrandTotal,
    String? publicViewToken,
    List<QuotationInclusion>? inclusions,
    List<QuotationExclusion>? exclusions,
    List<QuotationAssumption>? assumptions,
    List<QuotationPaymentMilestone>? paymentMilestones,
  }) {
    return LeadQuotation(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      leadName: leadName,
      quotationNumber: quotationNumber ?? this.quotationNumber,
      version: version ?? this.version,
      title: title ?? this.title,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      taxRatePercent: taxRatePercent ?? this.taxRatePercent,
      discountAmount: discountAmount ?? this.discountAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      validityDays: validityDays ?? this.validityDays,
      status: status ?? this.status,
      pricingMode: pricingMode ?? this.pricingMode,
      ratePerSqft: ratePerSqft ?? this.ratePerSqft,
      items: items ?? this.items,
      sentAt: sentAt,
      viewedAt: viewedAt,
      respondedAt: respondedAt,
      createdById: createdById,
      createdAt: createdAt,
      updatedAt: updatedAt,
      notes: notes,
      quotationType: quotationType ?? this.quotationType,
      parentQuotationId: parentQuotationId ?? this.parentQuotationId,
      tier: tier ?? this.tier,
      ratePerSqftMin: ratePerSqftMin ?? this.ratePerSqftMin,
      ratePerSqftMax: ratePerSqftMax ?? this.ratePerSqftMax,
      estimatedAreaMin: estimatedAreaMin ?? this.estimatedAreaMin,
      estimatedAreaMax: estimatedAreaMax ?? this.estimatedAreaMax,
      durationMonthsMin: durationMonthsMin ?? this.durationMonthsMin,
      durationMonthsMax: durationMonthsMax ?? this.durationMonthsMax,
      validUntil: validUntil ?? this.validUntil,
      showGrandTotal: showGrandTotal ?? this.showGrandTotal,
      publicViewToken: publicViewToken ?? this.publicViewToken,
      inclusions: inclusions ?? this.inclusions,
      exclusions: exclusions ?? this.exclusions,
      assumptions: assumptions ?? this.assumptions,
      paymentMilestones: paymentMilestones ?? this.paymentMilestones,
    );
  }
}

class LeadQuotationItem {
  final int? id;
  final int? quotationId; // Optional as it might be new
  final int itemNumber;
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;

  /// FK to the master quotation-catalog row this line was sourced from.
  /// `null` means the line was authored ad-hoc (custom) and is therefore a
  /// candidate for "Promote to catalog". The backend GET endpoint exposes
  /// this as `catalogItemId` (see LeadQuotationController#mapItem).
  final int? catalogItemId;

  LeadQuotationItem({
    this.id,
    this.quotationId,
    required this.itemNumber,
    required this.description,
    this.quantity = 1.0,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    this.catalogItemId,
  });

  factory LeadQuotationItem.fromJson(Map<String, dynamic> json) {
    return LeadQuotationItem(
      id: json['id'],
      quotationId: json['quotationId'] ?? json['quotation_id'],
      itemNumber: json['itemNumber'] ?? json['item_number'],
      description: json['description'],
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] ?? json['unit_price'] as num).toDouble(),
      totalPrice: (json['totalPrice'] ?? json['total_price'] as num).toDouble(),
      notes: json['notes'],
      catalogItemId: (json['catalogItemId'] ?? json['catalog_item_id']) as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemNumber': itemNumber,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'notes': notes,
      'catalogItemId': catalogItemId,
    };
  }
}
