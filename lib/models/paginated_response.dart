class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      data: ((json['data'] ?? json['content']) as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      currentPage: json['currentPage'] ?? (json['number'] != null ? json['number'] + 1 : 1),
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? json['totalElements'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? json['size'] ?? 10,
      hasNextPage: json['hasNextPage'] ?? (json['last'] != null ? !json['last'] : false),
      hasPreviousPage: json['hasPreviousPage'] ?? (json['first'] != null ? !json['first'] : false),
    );
  }
}
