class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  PaginatedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
