import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/referral/referral_models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/empty_state.dart';
import 'withdraw_sheet.dart';

String _money(num v) => v <= 0 ? '₹0' : Formatters.price(v);

/// Earnings: balance card + withdraw, earnings history, withdrawals.
class EarningsView extends StatelessWidget {
  const EarningsView({
    super.key,
    required this.stats,
    required this.earnings,
    required this.withdrawals,
  });

  final ReferralStats stats;
  final List<ReferralEarning> earnings;
  final List<Withdrawal> withdrawals;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl + 4),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1F2937), Color(0xFF111827)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available balance', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(
                _money(stats.availableBalance),
                style: AppTextStyles.display.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Mini(label: 'Total earned', value: _money(stats.totalEarned)),
                  const SizedBox(width: 24),
                  _Mini(label: 'Pending', value: _money(stats.pendingEarnings)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: stats.availableBalance > 0
                        ? () => showWithdrawSheet(context, available: stats.availableBalance)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.textPrimary,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
                      disabledForegroundColor: Colors.white54,
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Iconsax.money_send_copy, size: 16),
                    label: const Text('Withdraw'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Earnings history', style: AppTextStyles.title),
        const SizedBox(height: 10),
        if (earnings.isEmpty)
          const EmptyState(
            icon: Iconsax.wallet_money_copy,
            title: 'No earnings yet',
            message: 'Share your link — rewards show up here as your friends transact.',
          )
        else
          for (final e in earnings)
            _Row(
              icon: Iconsax.money_add_copy,
              color: AppColors.success,
              title: e.type.isEmpty ? 'Referral reward' : e.type,
              subtitle: [
                if (e.description.isNotEmpty) e.description,
                if (e.createdAt != null) formatDate(e.createdAt!),
              ].join(' · '),
              amount: '+${_money(e.amount)}',
              status: e.status,
            ),
        if (withdrawals.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Withdrawals', style: AppTextStyles.title),
          const SizedBox(height: 10),
          for (final w in withdrawals)
            _Row(
              icon: Iconsax.money_send_copy,
              color: AppColors.accentBlue,
              title: w.accountName.isEmpty ? 'Bank transfer' : 'To ${w.accountName}',
              subtitle: w.createdAt == null ? '' : formatDate(w.createdAt!),
              amount: '-${_money(w.amount)}',
              status: w.status,
            ),
        ],
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white60, fontSize: 11)),
        Text(value, style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm + 2),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700)),
              if (status.isNotEmpty)
                Text(status, style: AppTextStyles.caption.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
