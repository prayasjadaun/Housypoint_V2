import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/inspection_controller.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/formatters.dart';
import '../../models/pdi/pdi_models.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/success_sheet.dart';
import '../../widgets/common/wizard_scaffold.dart';
import 'widgets/inspection_steps.dart';

/// Home inspection (PDI) booking wizard. The controller is created by the
/// route, so each visit starts fresh.
class InspectionBookingScreen extends StatelessWidget {
  const InspectionBookingScreen({super.key});

  static const _steps = [LocationStep(), PropertyStep(), PlanStep(), ScheduleStep(), ReviewStep()];

  Future<void> _primary(BuildContext context, InspectionController c) async {
    if (!c.canContinue) {
      context.showSnackBar(c.missingHint, isError: true);
      return;
    }
    FocusScope.of(context).unfocus();
    if (c.step < InspectionController.stepCount - 1) {
      c.next();
      return;
    }
    final booking = await c.submit();
    if (!context.mounted) return;
    if (booking == null) {
      context.showSnackBar(c.error ?? 'Booking failed', isError: true);
      return;
    }
    await showSuccessSheet(
      context,
      title: 'Inspection booked!',
      message: [
        if (booking.bookingId.isNotEmpty) 'Booking ID ${booking.bookingId}.',
        'Our engineer will visit on ${c.date == null ? '' : formatDate(c.date!)} at ${c.slot?.label ?? ''}.',
      ].join(' '),
      buttonLabel: 'View my inspections',
    );
    if (context.mounted) context.pushReplacement(AppRoutes.myInspections);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InspectionController>();
    final isLast = c.step == InspectionController.stepCount - 1;

    return WizardScaffold(
      title: 'Home inspection',
      stepTitles: InspectionController.stepTitles,
      step: c.step,
      onBack: c.back,
      onPrimary: () => _primary(context, c),
      loading: c.isSubmitting,
      primaryLabel: isLast && c.plan != null ? 'Confirm · ₹${Formatters.grouped(c.plan!.total)}' : 'Continue',
      primaryIcon: isLast ? Iconsax.tick_circle_copy : Iconsax.arrow_right_3_copy,
      child: _steps[c.step],
    );
  }
}

/// Small status pill shared with the bookings list.
class PdiStatusPill extends StatelessWidget {
  const PdiStatusPill({super.key, required this.booking});

  final PdiBooking booking;

  @override
  Widget build(BuildContext context) {
    final color = switch (booking.status.toLowerCase()) {
      'completed' => AppColors.success,
      'cancelled' => AppColors.error,
      'confirmed' || 'assigned' => AppColors.accentBlue,
      _ => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(booking.statusLabel, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
