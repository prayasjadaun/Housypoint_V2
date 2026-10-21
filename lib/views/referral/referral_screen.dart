import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../widgets/common/feature_placeholder.dart';

/// Bottom-nav tab — UI not built yet (see docs/V1_APP_FLOW.md).
class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      icon: Iconsax.gift_copy,
      title: 'Refer & Earn',
      message: 'Invite friends and track your earnings.',
    );
  }
}
