class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.count,
    required this.results,
  });

  final int count;
  final List<T> results;
}


