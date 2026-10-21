import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../widgets/common/feature_placeholder.dart';

/// Bottom-nav tab — UI not built yet (see docs/V1_APP_FLOW.md).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      icon: Iconsax.user_copy,
      title: 'Profile',
      message: 'Your account, listings and settings.',
    );
  }
}
