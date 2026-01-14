class PaginatedResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final bool isFirst;
  final bool isLast;
  final bool hasNext;
  final bool hasPrevious;

  PaginatedResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.isFirst,
    required this.isLast,
    required this.hasNext,
    required this.hasPrevious,
  });

  // Compatibility getters for existing code
  List<T> get data => content;
  int get totalItems => totalElements;
  int get itemsPerPage => pageSize;
  bool get hasNextPage => hasNext;
  bool get hasPreviousPage => hasPrevious;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final contentList = json['content'] as List<dynamic>? ?? [];

    return PaginatedResponse(
      content: contentList
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] ?? json['total_elements'] ?? 0,
      totalPages: json['totalPages'] ?? json['total_pages'] ?? 0,
      currentPage: json['number'] ?? json['current_page'] ?? 0,
      pageSize: json['size'] ?? json['page_size'] ?? 20,
      isFirst: json['first'] ?? json['is_first'] ?? true,
      isLast: json['last'] ?? json['is_last'] ?? false,
      hasNext: !(json['last'] ?? json['is_last'] ?? false),
      hasPrevious: !(json['first'] ?? json['is_first'] ?? true),
    );
  }

  factory PaginatedResponse.empty() {
    return PaginatedResponse(
      content: [],
      totalElements: 0,
      totalPages: 0,
      currentPage: 0,
      pageSize: 20,
      isFirst: true,
      isLast: true,
      hasNext: false,
      hasPrevious: false,
    );
  }
}
