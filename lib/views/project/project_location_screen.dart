import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/launcher.dart';
import '../../models/project/project_model.dart';
import '../../repositories/project_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/glass_icon_button.dart';
import '../../widgets/common/section_header.dart';

/// Project location — a stylised neighbourhood map with the project pinned
/// at the centre and its nearby landmarks orbiting around it.
class ProjectLocationScreen extends StatefulWidget {
  const ProjectLocationScreen({super.key, required this.id, this.initial});

  final int id;

  /// The already-loaded project (passed as route `extra`); fetched if null.
  final ProjectDetail? initial;

  @override
  State<ProjectLocationScreen> createState() => _ProjectLocationScreenState();
}

class _ProjectLocationScreenState extends State<ProjectLocationScreen> {
  ProjectDetail? _project;
  String? _error;

  @override
  void initState() {
    super.initState();
    _project = widget.initial;
    if (_project == null) _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final project = await context.read<ProjectRepository>().getProject(
        widget.id,
      );
      if (mounted) setState(() => _project = project);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    if (project == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: _error == null
              ? const AppSpinner()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: AppTextStyles.body),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
        ),
      );
    }

    final places = _Place.sorted(project.landmarks);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(project: project),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  _AddressCard(project: project, places: places),
                  const SizedBox(height: AppSpacing.md),
                  _NeighbourhoodMap(project: project, places: places),
                  const SizedBox(height: AppSpacing.md),
                  _MapActions(project: project),
                  if (places.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(
                      title: 'All nearby places',
                      subtitle:
                          '${places.length} ${places.length == 1 ? 'place' : 'places'} · nearest first',
                    ),
                    const SizedBox(height: 12),
                    _PlacesList(project: project, places: places),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

enum _Category {
  transit('Transit', Iconsax.bus_copy, AppColors.accentBlue),
  airport('Airport', Iconsax.airplane_copy, AppColors.accentSky),
  health('Healthcare', Iconsax.hospital_copy, AppColors.accentRose),
  education('Education', Iconsax.teacher_copy, AppColors.accentAmber),
  shopping('Shopping', Iconsax.shop_copy, AppColors.accentViolet),
  leisure('Leisure', Iconsax.tree_copy, AppColors.accentEmerald),
  road('Connectivity', Iconsax.routing_copy, AppColors.accentIndigo),
  dining('Food & stay', Iconsax.coffee_copy, AppColors.goldDark),
  work('Business hub', Iconsax.building_4_copy, AppColors.primaryDark),
  other('Landmark', Iconsax.location_copy, AppColors.primary);

  const _Category(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static const _keywords = {
    airport: ['airport', 'aerocity'],
    transit: ['metro', 'station', 'railway', 'rail', 'bus stand', 'isbt'],
    health: ['hospital', 'clinic', 'medical', 'medicity', 'health'],
    education: ['school', 'college', 'university', 'institute', 'academy'],
    shopping: ['mall', 'market', 'plaza', 'shopping', 'bazaar', 'store'],
    leisure: ['park', 'garden', 'golf', 'club', 'lake', 'stadium', 'gym'],
    road: ['highway', 'expressway', 'road', 'nh-', 'nh ', 'flyover', 'toll'],
    dining: ['hotel', 'restaurant', 'cafe', 'resort'],
    work: ['cyber', 'tech', 'it ', 'office', 'sez', 'court', 'bank'],
  };

  static _Category of(String name) {
    final n = ' ${name.toLowerCase()} ';
    for (final MapEntry(:key, :value) in _keywords.entries) {
      if (value.any(n.contains)) return key;
    }
    return other;
  }
}

class _Place {
  _Place(this.landmark, this.km) : category = _Category.of(landmark.name);

  final Landmark landmark;

  /// Parsed distance (km, or minutes for travel-time values); null if the
  /// API string has no number in it.
  final double? km;
  final _Category category;

  String get name => landmark.name;
  String get distance => landmark.distance;

  static double? _parse(String raw) {
    final s = raw.toLowerCase();
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(s);
    if (match == null) return null;
    final value = double.parse(match.group(0)!);
    final metres =
        RegExp(r'\d\s*m\b').hasMatch(s) ||
        s.contains('mtr') ||
        s.contains('meter') ||
        s.contains('metre');
    return metres ? value / 1000 : value;
  }

  static List<_Place> sorted(List<Landmark> landmarks) {
    final places = [
      for (final l in landmarks)
        if (l.name.isNotEmpty) _Place(l, _parse(l.distance)),
    ];
    places.sort((a, b) => (a.km ?? double.maxFinite).compareTo(
      b.km ?? double.maxFinite,
    ));
    return places;
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.project});

  final ProjectDetail project;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          GlassIconButton(
            icon: CupertinoIcons.back,
            color: AppColors.textPrimary,
            background: AppColors.surface,
            onTap: () => context.pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location & neighbourhood', style: AppTextStyles.title),
                Text(
                  project.summary.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.project, required this.places});

  final ProjectDetail project;
  final List<_Place> places;

  @override
  Widget build(BuildContext context) {
    final p = project.summary;
    final address = [
      project.location,
      if (project.sector.isNotEmpty) 'Sector ${project.sector}',
      p.city,
    ].where((s) => s.isNotEmpty).join(', ');
    final nearest = places.isEmpty ? null : places.first;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Iconsax.location_copy,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project address',
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                    Text(
                      address.isEmpty ? p.name : address,
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (places.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Places nearby',
                      value: '${places.length}',
                    ),
                  ),
                  Container(width: 1, height: 28, color: AppColors.border),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _MiniStat(
                      label: 'Closest',
                      value: [
                        nearest!.name,
                        nearest.distance,
                      ].where((s) => s.isNotEmpty).join(' · '),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Orbit map
// ---------------------------------------------------------------------------

/// Unit directions of the orbit slots, in fill order: the four sides
/// first, then the corners.
const _slots = [
  Offset(0, -1),
  Offset(1, 0),
  Offset(0, 1),
  Offset(-1, 0),
  Offset(1, -1),
  Offset(-1, 1),
  Offset(-1, -1),
  Offset(1, 1),
];

class _NeighbourhoodMap extends StatefulWidget {
  const _NeighbourhoodMap({required this.project, required this.places});

  final ProjectDetail project;
  final List<_Place> places;

  @override
  State<_NeighbourhoodMap> createState() => _NeighbourhoodMapState();
}

class _NeighbourhoodMapState extends State<_NeighbourhoodMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  int? _selected;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orbit = widget.places.take(_slots.length).toList();
    final hidden = widget.places.length - orbit.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl + 4),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) =>
                _buildOrbit(constraints.maxWidth, orbit),
          ),
          const SizedBox(height: 10),
          _Legend(hidden: hidden),
        ],
      ),
    );
  }

  Widget _buildOrbit(double width, List<_Place> orbit) {
    final cardW = (width * 0.25).clamp(78.0, 96.0);
    const cardH = 92.0;
    const gap = 10.0;
    final discD = math.min(width - 2 * (cardW + gap), 220.0);
    final height = orbit.isEmpty ? discD + 40 : discD + 2 * (cardH + 18);
    final center = Offset(width / 2, height / 2);
    final r = discD / 2;

    // Card centres sit on the frame edges; landmark dots sit inside the disc
    // along the same bearing, further out the farther the place is.
    final maxKm = orbit.fold<double>(0, (m, p) => math.max(m, p.km ?? 0));
    final cards = <Offset>[];
    final dots = <Offset>[];
    for (var i = 0; i < orbit.length; i++) {
      final s = _slots[i];
      cards.add(
        center +
            Offset(
              s.dx * (width / 2 - cardW / 2 - 2),
              s.dy * (height / 2 - cardH / 2 - 2),
            ),
      );
      final km = orbit[i].km;
      final t = km == null || maxKm == 0 ? 0.6 : km / maxKm;
      final bearing = math.atan2(s.dy, s.dx);
      final dist = r * (0.34 + 0.52 * t);
      dots.add(
        center + Offset(math.cos(bearing) * dist, math.sin(bearing) * dist),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _OrbitRingsPainter(center: center, radius: r),
            ),
          ),
          Positioned(
            left: center.dx - r,
            top: center.dy - r,
            width: discD,
            height: discD,
            child: _MapDisc(seed: widget.project.summary.id),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ConnectorPainter(
                dots: dots,
                cards: cards,
                colors: [for (final p in orbit) p.category.color],
                selected: _selected,
              ),
            ),
          ),
          for (var i = 0; i < orbit.length; i++)
            Positioned(
              left: dots[i].dx - 9,
              top: dots[i].dy - 9,
              child: _MapDot(
                index: i + 1,
                color: orbit[i].category.color,
                selected: _selected == i,
              ),
            ),
          Positioned(
            left: center.dx - 40,
            top: center.dy - 40,
            width: 80,
            height: 80,
            child: _CenterPin(project: widget.project, pulse: _pulse),
          ),
          for (var i = 0; i < orbit.length; i++)
            Positioned(
              left: cards[i].dx - cardW / 2,
              top: cards[i].dy - cardH / 2,
              width: cardW,
              height: cardH,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 420 + i * 70),
                curve: Curves.easeOutBack,
                builder: (_, v, child) => Opacity(
                  opacity: v.clamp(0, 1),
                  child: Transform.scale(scale: 0.85 + 0.15 * v, child: child),
                ),
                child: _OrbitCard(
                  index: i + 1,
                  place: orbit[i],
                  selected: _selected == i,
                  onTap: () =>
                      setState(() => _selected = _selected == i ? null : i),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrbitRingsPainter extends CustomPainter {
  _OrbitRingsPainter({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    // Soft glow behind the disc.
    canvas.drawCircle(
      center,
      radius * 1.9,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primarySoft,
            AppColors.primarySoft.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.9)),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.primary.withValues(alpha: 0.14);
    for (final f in [1.22, 1.5]) {
      _dashedCircle(canvas, center, radius * f, ring, dash: 4, gap: 5);
    }
  }

  @override
  bool shouldRepaint(_OrbitRingsPainter old) =>
      old.center != center || old.radius != radius;
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({
    required this.dots,
    required this.cards,
    required this.colors,
    required this.selected,
  });

  final List<Offset> dots;
  final List<Offset> cards;
  final List<Color> colors;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < dots.length; i++) {
      final active = selected == i;
      final dim = selected != null && !active;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = active ? 2 : 1.2
        ..color = colors[i].withValues(
          alpha: active ? 0.9 : (dim ? 0.15 : 0.45),
        );
      if (active) {
        canvas.drawLine(dots[i], cards[i], paint);
      } else {
        _dashedLine(canvas, dots[i], cards[i], paint, dash: 4, gap: 4);
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.selected != selected || old.dots != dots || old.cards != cards;
}

void _dashedLine(
  Canvas canvas,
  Offset a,
  Offset b,
  Paint paint, {
  required double dash,
  required double gap,
}) {
  final total = (b - a).distance;
  if (total == 0) return;
  final dir = (b - a) / total;
  for (var d = 0.0; d < total; d += dash + gap) {
    canvas.drawLine(a + dir * d, a + dir * math.min(d + dash, total), paint);
  }
}

void _dashedCircle(
  Canvas canvas,
  Offset c,
  double r,
  Paint paint, {
  required double dash,
  required double gap,
}) {
  final step = (dash + gap) / r;
  final sweep = dash / r;
  for (var a = 0.0; a < math.pi * 2; a += step) {
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, sweep, false, paint);
  }
}

/// The circular "map": blocks, roads, a river and parks, generated from the
/// project id so each project gets its own (stable) street pattern.
class _MapDisc extends StatelessWidget {
  const _MapDisc({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(painter: _StreetMapPainter(seed)),
      ),
    );
  }
}

class _StreetMapPainter extends CustomPainter {
  _StreetMapPainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.primarySoft,
    );

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate((rnd.nextDouble() - 0.5) * 0.7);
    canvas.translate(-c.dx, -c.dy);

    // Parks.
    final park = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.22);
    for (var i = 0; i < 3; i++) {
      final w = r * (0.35 + rnd.nextDouble() * 0.3);
      final h = r * (0.25 + rnd.nextDouble() * 0.25);
      final o = Offset(
        rnd.nextDouble() * size.width - w / 2,
        rnd.nextDouble() * size.height - h / 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(o & Size(w, h), const Radius.circular(10)),
        park,
      );
    }

    // River.
    final flip = rnd.nextBool();
    final river = Path()
      ..moveTo(-10, size.height * (flip ? 0.2 : 0.75))
      ..cubicTo(
        size.width * 0.3,
        size.height * (flip ? 0.05 : 0.95),
        size.width * 0.6,
        size.height * (flip ? 0.45 : 0.6),
        size.width + 10,
        size.height * (flip ? 0.15 : 0.85),
      );
    canvas.drawPath(
      river,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.16
        ..strokeCap = StrokeCap.round
        ..color = AppColors.accentSky.withValues(alpha: 0.28),
    );

    // Street grid.
    final street = Paint()
      ..color = AppColors.surface
      ..strokeCap = StrokeCap.round;
    for (var x = -r; x < size.width + r; x += r * (0.28 + rnd.nextDouble() * 0.2)) {
      street.strokeWidth = 2 + rnd.nextDouble() * 2.5;
      canvas.drawLine(Offset(x, -r), Offset(x, size.height + r), street);
    }
    for (var y = -r; y < size.height + r; y += r * (0.28 + rnd.nextDouble() * 0.2)) {
      street.strokeWidth = 2 + rnd.nextDouble() * 2.5;
      canvas.drawLine(Offset(-r, y), Offset(size.width + r, y), street);
    }

    // Arterial roads through the centre.
    final arterial = Paint()
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = AppColors.surface;
    final median = Paint()
      ..strokeWidth = 1.6
      ..color = AppColors.gold.withValues(alpha: 0.9);
    final diag = Offset(r * 1.6, r * (0.6 + rnd.nextDouble() * 0.6));
    for (final (a, b) in [
      (Offset(c.dx, -r), Offset(c.dx + r * 0.15, size.height + r)),
      (c - diag, c + diag),
    ]) {
      canvas.drawLine(a, b, arterial);
      canvas.drawLine(a, b, median);
    }
    canvas.restore();

    // Distance rings.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.primary.withValues(alpha: 0.28);
    for (final f in [0.45, 0.78]) {
      _dashedCircle(canvas, c, r * f, ring, dash: 3, gap: 4);
    }

    // Edge vignette so the disc reads as a lens onto the city.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          stops: const [0.7, 1],
          colors: [
            AppColors.surface.withValues(alpha: 0),
            AppColors.surface.withValues(alpha: 0.55),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_StreetMapPainter old) => old.seed != seed;
}

class _CenterPin extends StatelessWidget {
  const _CenterPin({required this.project, required this.pulse});

  final ProjectDetail project;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final p = project.summary;
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: pulse,
          builder: (_, _) {
            final v = Curves.easeOut.transform(pulse.value);
            return Container(
              width: 40 + 40 * v,
              height: 40 + 40 * v,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.28 * (1 - v)),
              ),
            );
          },
        ),
        Container(
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.primary, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: AppNetworkImage(
              url: p.logo.isNotEmpty ? p.logo : p.builderLogo,
              fit: BoxFit.contain,
              fallbackIcon: Iconsax.buildings_2_copy,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapDot extends StatelessWidget {
  const _MapDot({
    required this.index,
    required this.color,
    required this.selected,
  });

  final int index;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.3 : 1,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '$index',
          style: AppTextStyles.caption.copyWith(
            fontSize: 8.5,
            height: 1,
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _OrbitCard extends StatelessWidget {
  const _OrbitCard({
    required this.index,
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final _Place place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = place.category.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (selected ? color : AppColors.textPrimary).withValues(
                alpha: selected ? 0.22 : 0.06,
              ),
              blurRadius: selected ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm + 1),
                  ),
                  child: Icon(place.category.icon, size: 15, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  place.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10.5,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (place.distance.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    place.distance,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
            Positioned(
              top: -4,
              left: -2,
              child: Text(
                '$index',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.hidden});

  final int hidden;

  @override
  Widget build(BuildContext context) {
    Widget item(Widget mark, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 5),
        Text(text, style: AppTextStyles.caption.copyWith(fontSize: 10.5)),
      ],
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 4,
      children: [
        item(
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
          ),
          'Project',
        ),
        item(
          const Icon(Icons.circle, size: 9, color: AppColors.accentBlue),
          'Nearby place',
        ),
        item(
          const Icon(
            Iconsax.radar_copy,
            size: 11,
            color: AppColors.textTertiary,
          ),
          'Rings show relative distance',
        ),
        if (hidden > 0)
          Text(
            '+$hidden more below',
            style: AppTextStyles.caption.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Actions & list
// ---------------------------------------------------------------------------

class _MapActions extends StatelessWidget {
  const _MapActions({required this.project});

  final ProjectDetail project;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => Launcher.url(project.directionsUrl),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              textStyle: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Iconsax.routing_2_copy, size: 18),
            label: const Text('Get directions'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Launcher.url(project.mapsSearchUrl),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              backgroundColor: AppColors.surface,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              textStyle: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Iconsax.map_copy, size: 18),
            label: const Text('Open in Maps'),
          ),
        ),
      ],
    );
  }
}

class _PlacesList extends StatelessWidget {
  const _PlacesList({required this.project, required this.places});

  final ProjectDetail project;
  final List<_Place> places;

  @override
  Widget build(BuildContext context) {
    final maxKm = places.fold<double>(0, (m, p) => math.max(m, p.km ?? 0));
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < places.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 62,
                color: AppColors.border,
              ),
            _PlaceRow(
              place: places[i],
              proximity: places[i].km == null || maxKm == 0
                  ? null
                  : 1 - places[i].km! / maxKm * 0.85,
              onTap: () => Launcher.url(
                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${places[i].name} ${project.summary.city}')}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.place,
    required this.proximity,
    required this.onTap,
  });

  final _Place place;

  /// 0–1, higher = closer; drives the small proximity bar.
  final double? proximity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = place.category.color;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(place.category.icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        place.category.label,
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                      if (proximity != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppRadius.pill,
                            ),
                            child: LinearProgressIndicator(
                              value: proximity,
                              minHeight: 3,
                              color: color,
                              backgroundColor: AppColors.surfaceMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (place.distance.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  place.distance,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
