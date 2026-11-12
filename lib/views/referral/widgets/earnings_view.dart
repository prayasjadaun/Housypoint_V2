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
            color: AppColors.referDarkRaised,
            borderRadius: BorderRadius.circular(AppRadius.xl + 4),
            border: Border.all(color: AppColors.referRule),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available balance', style: AppTextStyles.caption.copyWith(color: AppColors.referMuted)),
              const SizedBox(height: 4),
              Text(
                _money(stats.availableBalance),
                style: AppTextStyles.display.copyWith(color: AppColors.referGold),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Mini(label: 'Total earned', value: _money(stats.totalEarned)),
                  const SizedBox(width: 24),
                  _Mini(label: 'Pending', value: _money(stats.pendingEarnings)),
                  const Spacer(),
                  _WithdrawButton(
                    onPressed: stats.availableBalance > 0
                        ? () => showWithdrawSheet(context, available: stats.availableBalance)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Earnings history', style: AppTextStyles.title.copyWith(color: AppColors.referInk)),
        const SizedBox(height: 10),
        if (earnings.isEmpty)
          const EmptyState(
            icon: Iconsax.wallet_money_copy,
            title: 'No earnings yet',
            message: 'Share your link — rewards show up here as your friends transact.',
            goldStyle: true,
          )
        else
          for (final e in earnings)
            _Row(
              icon: Iconsax.money_add_copy,
              color: AppColors.referGreen,
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
          Text('Withdrawals', style: AppTextStyles.title.copyWith(color: AppColors.referInk)),
          const SizedBox(height: 10),
          for (final w in withdrawals)
            _Row(
              icon: Iconsax.money_send_copy,
              color: AppColors.referGold,
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

/// Gold-gradient pill; dims out when there's nothing to withdraw.
class _WithdrawButton extends StatelessWidget {
  const _WithdrawButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = enabled ? AppColors.referOnGold : AppColors.referMuted;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.referGoldGradient : null,
        color: enabled ? null : AppColors.referLine,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.money_send_copy, size: 16, color: fg),
                const SizedBox(width: 6),
                Text('Withdraw', style: AppTextStyles.label.copyWith(color: fg, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
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
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.referMuted, fontSize: 11)),
        Text(value, style: AppTextStyles.label.copyWith(color: AppColors.referInk, fontWeight: FontWeight.w600)),
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
        color: AppColors.referDarkRaised,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.referLine),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm + 2),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600, color: AppColors.referInk)),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.referMuted),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700, color: color)),
              if (status.isNotEmpty)
                Text(status, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.referMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
