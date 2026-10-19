import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/referral/referral_models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/empty_state.dart';

/// People who joined with the user's code.
class ReferredUsersView extends StatelessWidget {
  const ReferredUsersView({super.key, required this.users});

  final List<ReferredUser> users;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const EmptyState(
        icon: Iconsax.profile_2user_copy,
        title: 'No referrals yet',
        message: 'Friends who sign up with your code will be listed here.',
      );
    }
    return Column(
      children: [
        for (final u in users)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    u.name[0].toUpperCase(),
                    style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
                      if (u.joinedAt != null)
                        Text('Joined ${formatDate(u.joinedAt!)}', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (u.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Active',
                      style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
