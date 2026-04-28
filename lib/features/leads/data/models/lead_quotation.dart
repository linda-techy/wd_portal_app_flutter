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
    );
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
  }) {
    return LeadQuotation(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
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
