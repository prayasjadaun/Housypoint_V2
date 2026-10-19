/// A page of a DRF-paginated list: `{count, next, previous, results}`.
class Paged<T> {
  const Paged({required this.items, required this.count, this.next});

  final List<T> items;
  final int count;

  /// Full URL of the next page; null on the last page.
  final String? next;

  bool get hasMore => next != null;

  factory Paged.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final results = json['results'] as List? ?? const [];
    return Paged(
      items: results.map((e) => fromItem(e as Map<String, dynamic>)).toList(),
      count: json['count'] as int? ?? results.length,
      next: json['next'] as String?,
    );
  }
}
