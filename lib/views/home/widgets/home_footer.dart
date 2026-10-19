import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_logo.dart';

/// Quiet sign-off at the end of the home feed.
class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(opacity: 0.85, child: const AppLogo(size: 36)),
        const SizedBox(height: 10),
        Text(
          'Housy Point',
          style: AppTextStyles.title.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Made with ', style: AppTextStyles.caption),
            const Icon(Iconsax.heart_copy, size: 13, color: AppColors.accentRose),
            Text(' in India', style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }
}
