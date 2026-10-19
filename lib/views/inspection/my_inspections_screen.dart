import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/pdi/pdi_models.dart';
import '../../repositories/pdi_repository.dart';
import '../../router/app_routes.dart';
import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/page_scaffold.dart';
import 'inspection_booking_screen.dart';

/// The user's inspection bookings (API ref P9).
class MyInspectionsScreen extends StatefulWidget {
  const MyInspectionsScreen({super.key});

  @override
  State<MyInspectionsScreen> createState() => _MyInspectionsScreenState();
}

class _MyInspectionsScreenState extends State<MyInspectionsScreen> {
  List<PdiBooking>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await context.read<PdiRepository>().getBookings();
      if (mounted) setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _book() async {
    await context.push(AppRoutes.inspection);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final top = PageScaffold.topInset(context);
    final items = _items;

    return PageScaffold(
      title: 'My inspections',
      actions: [
        IconButton(onPressed: _book, icon: const Icon(Iconsax.add_square_copy, color: AppColors.primary)),
      ],
      body: RefreshIndicatorWrapper(
        edgeOffset: top,
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.md, top + AppSpacing.md, AppSpacing.md, AppSpacing.xl),
          children: [
            if (items == null && _error == null)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: AppSpinner()),
              )
            else if (_error != null)
              EmptyState(
                lottie: AppAssets.lottieServerError,
                title: 'Couldn’t load',
                message: _error!,
                actionLabel: 'Try again',
                onAction: _load,
              )
            else if (items!.isEmpty)
              EmptyState(
                icon: Iconsax.shield_tick_copy,
                title: 'No inspections yet',
                message: 'Book a certified engineer to check your new home before possession.',
                actionLabel: 'Book inspection',
                onAction: _book,
              )
            else
              for (final b in items) _BookingCard(booking: b),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final PdiBooking booking;

  @override
  Widget build(BuildContext context) {
    final when = [
      if (booking.date != null) formatDate(booking.date!),
      if (booking.time.isNotEmpty) formatTime(booking.time),
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: const Icon(Iconsax.shield_tick_copy, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.project.isEmpty ? 'Home inspection' : booking.project,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      [
                        if (booking.plan.isNotEmpty) '${Formatters.humanize(booking.plan)} plan',
                        if (booking.unitNumber.isNotEmpty) 'Unit ${booking.unitNumber}',
                      ].join(' · '),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              PdiStatusPill(booking: booking),
            ],
          ),
          const Divider(height: 22, color: AppColors.border),
          Row(
            children: [
              const Icon(Iconsax.calendar_copy, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(child: Text(when.isEmpty ? '—' : when, style: AppTextStyles.caption)),
              Text(
                '₹${Formatters.grouped(booking.finalPrice)}',
                style: AppTextStyles.label.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (booking.bookingId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Booking ID: ${booking.bookingId}', style: AppTextStyles.caption.copyWith(fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
