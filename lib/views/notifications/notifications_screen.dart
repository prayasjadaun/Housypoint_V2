import 'package:flutter/material.dart';

import '../../theme/app_assets.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/page_scaffold.dart';

/// Notifications arrive as push messages (FCM); there is no in-app inbox
/// API yet, so this shows the empty state.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageScaffold(
      title: 'Notifications',
      body: Center(
        child: EmptyState(
          lottie: AppAssets.lottieEmpty,
          title: 'You’re all caught up',
          message: 'Booking updates, new matches and offers will show up here.',
        ),
      ),
    );
  }
}
