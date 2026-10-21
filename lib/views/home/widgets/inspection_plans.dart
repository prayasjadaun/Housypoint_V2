import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../controllers/home_controller.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/pdi/pdi_models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/skeleton_box.dart';
import '../../inspection/widgets/inspection_steps.dart';
import 'promo_banners.dart';

String _rupees(int v) => '₹${Formatters.grouped(v)}';

/// Inspection banner with a ticket-style pricing strip joined underneath.
/// Tapping a plan opens the comparison sheet; [onBook] gets the chosen plan
/// id (null = no preference).
class InspectionPlansBanner extends StatelessWidget {
  const InspectionPlansBanner({super.key, required this.onBook});

  final ValueChanged<int?> onBook;

  @override
  Widget build(BuildContext context) {
    final plans = context.select<HomeController, List<PdiPlan>?>(
      (h) => h.inspectionPlans,
    );
    // Failed or empty → plain banner, no strip.
    final showStrip = plans == null || plans.isNotEmpty;

    return Column(
      children: [
        InspectionBanner(onTap: () => onBook(null), attached: showStrip),
        if (showStrip)
          _PlansStrip(
            plans: plans,
            onTapPlan: (p) => _openSheet(context, plans!, p),
          ),
      ],
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    List<PdiPlan> plans,
    PdiPlan initial,
  ) async {
    AppHaptics.tap();
    final picked = await showModalBottomSheet<PdiPlan>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlansSheet(plans: plans, initial: initial),
    );
    if (picked != null) onBook(picked.id);
  }
}

// ── Strip ───────────────────────────────────────────────────

class _PlansStrip extends StatelessWidget {
  const _PlansStrip({required this.plans, required this.onTapPlan});

  /// Null while loading.
  final List<PdiPlan>? plans;
  final ValueChanged<PdiPlan> onTapPlan;

  static const double _notch = 16;
  static const _corner = Radius.circular(AppRadius.xl + 4);

  @override
  Widget build(BuildContext context) {
    final plans = this.plans;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(bottom: _corner),
            boxShadow: [
              BoxShadow(
                color: Color(0x0F0B3B20),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Iconsax.receipt_2_copy, size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'INSPECTION PLANS',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  if (plans != null && plans.isNotEmpty)
                    GestureDetector(
                      onTap: () => onTapPlan(_defaultPlan(plans)),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Text(
                            'Compare',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(Iconsax.arrow_right_3_copy, size: 13, color: AppColors.primary),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (plans == null)
                const Row(
                  children: [
                    Expanded(child: SkeletonBox(width: double.infinity, height: 92, radius: AppRadius.lg)),
                    SizedBox(width: 10),
                    Expanded(child: SkeletonBox(width: double.infinity, height: 92, radius: AppRadius.lg)),
                  ],
                )
              else if (plans.length <= 3)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < plans.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: _PlanTile(plan: plans[i], onTap: () => onTapPlan(plans[i])),
                        ),
                      ],
                    ],
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < plans.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          SizedBox(
                            width: 132,
                            child: _PlanTile(plan: plans[i], onTap: () => onTapPlan(plans[i])),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                'Tap a plan to see everything it covers · + 18% GST',
                style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        // Ticket punch-holes where the strip meets the banner.
        for (final left in [true, false])
          Positioned(
            top: -_notch / 2,
            left: left ? -_notch / 2 : null,
            right: left ? null : -_notch / 2,
            child: Container(
              width: _notch,
              height: _notch,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
            ),
          ),
        // Perforation along the tear line.
        Positioned(
          top: 0,
          left: _notch,
          right: _notch,
          child: LayoutBuilder(
            builder: (_, constraints) {
              final count = (constraints.maxWidth / 9).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < count; i++)
                    Container(
                      width: 4,
                      height: 1.5,
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

PdiPlan _defaultPlan(List<PdiPlan> plans) =>
    plans.firstWhere((p) => p.isPopular, orElse: () => plans.first);

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.onTap});

  final PdiPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final popular = plan.isPopular;
    final radius = BorderRadius.circular(AppRadius.lg);

    return Material(
      color: popular ? AppColors.primarySoft : AppColors.surfaceMuted,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: popular ? AppColors.primary : AppColors.border,
              width: popular ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (popular)
                    const Icon(Iconsax.crown_1, size: 15, color: AppColors.goldDark),
                ],
              ),
              if (popular)
                Text(
                  'Most popular',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10.5,
                    color: AppColors.goldDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const Spacer(),
              const SizedBox(height: 8),
              if (plan.oldPrice > plan.price)
                Text(
                  _rupees(plan.oldPrice),
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _rupees(plan.price),
                  style: AppTextStyles.title.copyWith(
                    fontSize: 20,
                    color: popular ? AppColors.primaryDark : AppColors.textPrimary,
                  ),
                ),
              ),
              if (plan.savings > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Save ${_rupees(plan.savings)}',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Comparison sheet ────────────────────────────────────────

/// All plans with their features; pops with the plan to book.
class _PlansSheet extends StatefulWidget {
  const _PlansSheet({required this.plans, required this.initial});

  final List<PdiPlan> plans;
  final PdiPlan initial;

  @override
  State<_PlansSheet> createState() => _PlansSheetState();
}

class _PlansSheetState extends State<_PlansSheet> {
  late PdiPlan _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                children: [
                  Text('Choose your inspection plan', style: AppTextStyles.heading.copyWith(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    'Every plan includes a detailed digital report.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final p in widget.plans)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: PlanCard(
                        plan: p,
                        selected: p.id == _selected.id,
                        onTap: () {
                          AppHaptics.selection();
                          setState(() => _selected = p);
                        },
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, bottom + 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _rupees(_selected.total),
                        style: AppTextStyles.title.copyWith(color: AppColors.primaryDark),
                      ),
                      Text('incl. GST', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Book ${_selected.title}',
                      icon: Iconsax.arrow_right_3_copy,
                      onPressed: () => Navigator.pop(context, _selected),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
