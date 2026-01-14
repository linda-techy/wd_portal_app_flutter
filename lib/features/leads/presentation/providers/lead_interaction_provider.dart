import 'package:admin/features/leads/data/models/lead_interaction.dart';
import 'package:admin/features/leads/data/services/lead_service.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';

class LeadInteractionProvider extends BasePaginatedProvider<LeadInteraction> {
  final LeadService _service = LeadService();

  @override
  Future<PaginatedResponse<LeadInteraction>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchLeadInteractions(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // LeadInteraction-specific convenience methods

  void filterByLeadId(int? leadId) {
    updateFilter('leadId', leadId);
  }

  void filterByInteractionType(String? interactionType) {
    updateFilter('interactionType', interactionType);
  }

  void filterByUserId(int? userId) {
    updateFilter('userId', userId);
  }

  void filterByOutcome(String? outcome) {
    updateFilter('outcome', outcome);
  }

  void filterByFollowUpRequired(bool? followUpRequired) {
    updateFilter('followUpRequired', followUpRequired);
  }

  void applyAllFilters({
    int? leadId,
    String? interactionType,
    int? userId,
    String? outcome,
    bool? followUpRequired,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filters = <String, dynamic>{};
    
    if (leadId != null) filters['leadId'] = leadId;
    if (interactionType != null) filters['interactionType'] = interactionType;
    if (userId != null) filters['userId'] = userId;
    if (outcome != null) filters['outcome'] = outcome;
    if (followUpRequired != null) filters['followUpRequired'] = followUpRequired;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    
    applyFilters(filters);
  }
}

