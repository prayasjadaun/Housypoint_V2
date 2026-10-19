import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../widgets/common/feature_placeholder.dart';

/// Bottom-nav tab — UI not built yet (see docs/V1_APP_FLOW.md).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      icon: Iconsax.home_2_copy,
      title: 'Home',
      message: 'Posters, city picker, listings and new launches go here.',
    );
  }
}
