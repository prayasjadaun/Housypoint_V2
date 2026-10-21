import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/share_helper.dart';
import '../../../models/referral/referral_models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Overview: tier + referral code, key numbers, share links, how it works.
class ReferralOverview extends StatelessWidget {
  const ReferralOverview({super.key, required this.stats, this.pdiStats});

  final ReferralStats stats;
  final PdiReferralStats? pdiStats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CodeCard(stats: stats),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.9,
          children: [
            _StatTile(icon: Iconsax.profile_2user_copy, label: 'Friends referred', value: '${stats.totalReferred}'),
            _StatTile(icon: Iconsax.user_tick_copy, label: 'Active', value: '${stats.activeReferred}'),
            _StatTile(icon: Iconsax.wallet_money_copy, label: 'Total earned', value: Formatters.price(stats.totalEarned).replaceAll('Price on request', '₹0')),
            _StatTile(icon: Iconsax.wallet_check_copy, label: 'Available', value: Formatters.price(stats.availableBalance).replaceAll('Price on request', '₹0')),
          ],
        ),
        if (pdiStats != null && pdiStats!.bookings > 0) ...[
          const SizedBox(height: 10),
          _PdiCard(stats: pdiStats!),
        ],
        if (stats.links.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Share your links', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text('Anyone who uses these links is tagged to you.', style: AppTextStyles.caption),
          const SizedBox(height: 12),
          for (final entry in stats.links.entries)
            _LinkTile(label: entry.key, url: entry.value),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('How it works', style: AppTextStyles.title),
        const SizedBox(height: 12),
        const _Step(number: 1, title: 'Share your code or link', text: 'Send it to friends, family or clients.'),
        const _Step(number: 2, title: 'They join Housy Point', text: 'They list, buy, rent or book an inspection.'),
        const _Step(number: 3, title: 'You earn rewards', text: 'Commission lands in your balance — withdraw anytime.', isLast: true),
      ],
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.stats});

  final ReferralStats stats;

  @override
  Widget build(BuildContext context) {
    final code = stats.referralCode;
    final progress = (stats.tierProgress.toDouble() / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl + 4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.crown_1_copy, size: 14, color: AppColors.ink),
                    const SizedBox(width: 5),
                    Text(
                      stats.tier,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                progress >= 1 ? 'Top tier reached' : '${(progress * 100).round()}% of tiers unlocked',
                style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              color: AppColors.gold,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          if (stats.nextTierHint.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Next — ${stats.nextTierHint}',
              style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.75), fontSize: 11.5),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'Your referral code',
            style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    code.isEmpty ? '—' : code,
                    style: AppTextStyles.title.copyWith(color: Colors.white, letterSpacing: 2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _RoundButton(
                icon: Iconsax.copy_copy,
                onTap: code.isEmpty
                    ? null
                    : () async {
                        await ShareHelper.copy(code);
                        if (context.mounted) context.showSnackBar('Code copied');
                      },
              ),
              const SizedBox(width: 8),
              _RoundButton(
                icon: Iconsax.share_copy,
                filled: true,
                onTap: code.isEmpty
                    ? null
                    : () => ShareHelper.share(
                        'Join me on Housy Point — use my referral code $code when you sign up. '
                        '${stats.links.values.isEmpty ? '' : stats.links.values.first}',
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap, this.filled = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.gold : Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 48,
          child: Icon(icon, size: 20, color: filled ? AppColors.ink : Colors.white),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.sm + 2),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.title.copyWith(fontSize: 16)),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PdiCard extends StatelessWidget {
  const _PdiCard({required this.stats});

  final PdiReferralStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.shield_tick_copy, color: AppColors.goldDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${stats.bookings} inspection ${stats.bookings == 1 ? 'booking' : 'bookings'} via your link',
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            Formatters.price(stats.earnings).replaceAll('Price on request', '₹0'),
            style: AppTextStyles.label.copyWith(color: AppColors.goldDark, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.link_2_copy, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
                Text(url, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              await ShareHelper.copy(url);
              if (context.mounted) context.showSnackBar('Link copied');
            },
            icon: Icon(Iconsax.copy_copy, size: 18, color: AppColors.textSecondary),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => ShareHelper.share(url),
            icon: const Icon(Iconsax.share_copy, size: 18, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.text, this.isLast = false});

  final int number;
  final String title;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Text(
                  '$number',
                  style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 1.5, color: AppColors.primary.withValues(alpha: 0.2))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
                  Text(text, style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
