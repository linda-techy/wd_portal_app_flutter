class PaginationParams {
  final int page;
  final int limit;
  final String? search;
  final String? status;
  final String? source;
  final String? priority;
  final String? customerType;
  final String? projectType;
  final String? assignedTeam;
  final String? state;
  final String? district;
  final double? minBudget;
  final double? maxBudget;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? sortBy;
  final String? sortOrder; // 'asc' or 'desc'

  const PaginationParams({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
    this.source,
    this.priority,
    this.customerType,
    this.projectType,
    this.assignedTeam,
    this.state,
    this.district,
    this.minBudget,
    this.maxBudget,
    this.startDate,
    this.endDate,
    this.sortBy = 'created_at',
    this.sortOrder = 'desc',
  });

  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status;
    }
    if (source != null) {
      params['source'] = source;
    }
    if (priority != null && priority!.isNotEmpty) {
      params['priority'] = priority;
    }
    if (customerType != null && customerType!.isNotEmpty) {
      params['customerType'] = customerType;
    }
    if (projectType != null && projectType!.isNotEmpty) {
      params['projectType'] = projectType;
    }
    if (assignedTeam != null && assignedTeam!.isNotEmpty) {
      params['assignedTeam'] = assignedTeam;
    }
    if (state != null && state!.isNotEmpty) {
      params['state'] = state;
    }
    if (district != null && district!.isNotEmpty) {
      params['district'] = district;
    }
    if (minBudget != null) {
      params['minBudget'] = minBudget;
    }
    if (maxBudget != null) {
      params['maxBudget'] = maxBudget;
    }
    if (startDate != null) {
      params['startDate'] = startDate!.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      params['endDate'] = endDate!.toIso8601String().split('T')[0];
    }

    return params;
  }

  PaginationParams copyWith({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? source,
    String? priority,
    String? customerType,
    String? projectType,
    String? assignedTeam,
    String? state,
    String? district,
    double? minBudget,
    double? maxBudget,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? sortOrder,
  }) {
    return PaginationParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      status: status ?? this.status,
      source: source ?? this.source,
      priority: priority ?? this.priority,
      customerType: customerType ?? this.customerType,
      projectType: projectType ?? this.projectType,
      assignedTeam: assignedTeam ?? this.assignedTeam,
      state: state ?? this.state,
      district: district ?? this.district,
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
