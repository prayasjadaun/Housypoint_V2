import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/post_property_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../router/app_routes.dart';
import '../../widgets/common/success_sheet.dart';
import '../../widgets/common/wizard_scaffold.dart';
import 'widgets/post_steps.dart';

/// Sell or rent-out wizard (controller provided by the route).
class PostPropertyScreen extends StatelessWidget {
  const PostPropertyScreen({super.key});

  static const _steps = [TypeStep(), ProjectStep(), DetailsStep(), PhotosStep(), PriceStep(), PostReviewStep()];

  Future<void> _primary(BuildContext context, PostPropertyController c) async {
    if (!c.canContinue) {
      context.showSnackBar(c.missingHint, isError: true);
      return;
    }
    FocusScope.of(context).unfocus();
    if (c.step < c.stepCount - 1) {
      c.next();
      return;
    }
    final ok = await c.submit();
    if (!context.mounted) return;
    if (!ok) {
      context.showSnackBar(c.error ?? 'Something went wrong', isError: true);
      return;
    }
    await showSuccessSheet(
      context,
      title: 'Listing submitted!',
      message: 'Our team will verify it shortly. You can track it under My listings.',
      buttonLabel: 'View my listings',
    );
    if (context.mounted) context.pushReplacement(AppRoutes.myListings);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PostPropertyController>();
    final isLast = c.step == c.stepCount - 1;

    return WizardScaffold(
      title: c.isRent ? 'Rent out property' : 'Sell property',
      stepTitles: PostPropertyController.stepTitles,
      step: c.step,
      onBack: c.back,
      onPrimary: () => _primary(context, c),
      loading: c.isSubmitting,
      primaryLabel: isLast ? 'Submit listing' : 'Continue',
      primaryIcon: isLast ? Iconsax.send_2_copy : Iconsax.arrow_right_3_copy,
      child: _steps[c.step],
    );
  }
}
