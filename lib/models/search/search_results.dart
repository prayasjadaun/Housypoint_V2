String _str(Object? v) {
  final s = v?.toString().trim() ?? '';
  return s == 'null' ? '' : s;
}

/// One hit of `GET /api/search/` (API ref M7).
class SearchHit {
  const SearchHit({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.image,
    this.projectId,
    this.builderId,
    this.isRental = false,
  });

  /// property / project / builder
  final String kind;
  final String title;
  final String subtitle;
  final String image;
  final int? projectId;
  final int? builderId;
  final bool isRental;
}

class SearchResults {
  const SearchResults({required this.properties, required this.projects, required this.builders});

  final List<SearchHit> properties;
  final List<SearchHit> projects;
  final List<SearchHit> builders;

  bool get isEmpty => properties.isEmpty && projects.isEmpty && builders.isEmpty;

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(String key) => [
      for (final item in (json[key] ?? json[key.toLowerCase()]) as List? ?? const [])
        if (item is Map) Map<String, dynamic>.from(item),
    ];

    return SearchResults(
      // "Resale Properties in X" groups; the url carries the project id.
      properties: [
        for (final p in list('Properties'))
          () {
            final uri = Uri.tryParse(_str(p['url']));
            final count = int.tryParse(_str(p['count'])) ?? 0;
            return SearchHit(
              kind: 'property',
              title: _str(p['name']),
              subtitle: [
                if (_str(p['builder_name']).isNotEmpty) _str(p['builder_name']),
                '$count ${count == 1 ? 'listing' : 'listings'}',
              ].join(' · '),
              image: _str(p['project_image']),
              projectId: int.tryParse(uri?.queryParameters['project'] ?? ''),
              isRental: uri?.queryParameters['type'] == 'rental',
            );
          }(),
      ],
      projects: [
        for (final p in list('Projects'))
          SearchHit(
            kind: 'project',
            title: _str(p['name']),
            subtitle: _str(p['location']),
            image: _str(p['project_logo_image']),
            projectId: int.tryParse(_str(p['id'])),
          ),
      ],
      builders: [
        for (final b in list('Builders'))
          SearchHit(
            kind: 'builder',
            title: _str(b['name']),
            subtitle: '${_str(b['projects_count'])} projects',
            image: _str(b['builder_logo']),
            builderId: int.tryParse(_str(b['id'])),
          ),
      ],
    );
  }
}
