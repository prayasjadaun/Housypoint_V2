import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/consultation/consultation_models.dart';
import '../../repositories/consultation_repository.dart';
import '../../router/app_routes.dart';
import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/page_scaffold.dart';

/// The user's consultation bookings with cancel (API ref K3/K5).
class MyConsultationsScreen extends StatefulWidget {
  const MyConsultationsScreen({super.key});

  @override
  State<MyConsultationsScreen> createState() => _MyConsultationsScreenState();
}

class _MyConsultationsScreenState extends State<MyConsultationsScreen> {
  List<Consultation>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await context.read<ConsultationRepository>().getMine();
      if (mounted) setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _cancel(Consultation c) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Cancel consultation?', style: AppTextStyles.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel it'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await context.read<ConsultationRepository>().cancel(c.id);
      if (!mounted) return;
      context.showSnackBar('Consultation cancelled');
      _load();
    } on ApiException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = PageScaffold.topInset(context);
    final items = _items;

    return PageScaffold(
      title: 'My consultations',
      actions: [
        IconButton(
          onPressed: () async {
            await context.push(AppRoutes.consultation);
            _load();
          },
          icon: const Icon(Iconsax.add_square_copy, color: AppColors.primary),
        ),
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
                icon: Iconsax.messages_2_copy,
                title: 'No consultations yet',
                message: 'Book a free call with a legal, tax or property expert.',
                actionLabel: 'Book a consultation',
                onAction: () async {
                  await context.push(AppRoutes.consultation);
                  _load();
                },
              )
            else
              for (final c in items) _ConsultationCard(item: c, onCancel: () => _cancel(c)),
          ],
        ),
      ),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({required this.item, required this.onCancel});

  final Consultation item;
  final VoidCallback onCancel;

  Color get _statusColor => switch (item.status) {
    'confirmed' => AppColors.accentBlue,
    'completed' => AppColors.success,
    'cancelled' => AppColors.error,
    _ => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: Text(item.service, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  item.statusLabel,
                  style: AppTextStyles.caption.copyWith(color: _statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _Meta(icon: Iconsax.house_2_copy, text: item.type),
              _Meta(icon: Iconsax.clock_copy, text: item.timeSlot),
              if (item.createdAt != null) _Meta(icon: Iconsax.calendar_copy, text: formatDate(item.createdAt!)),
            ],
          ),
          if (item.bookingId.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Booking ID: ${item.bookingId}', style: AppTextStyles.caption.copyWith(fontSize: 11)),
          ],
          if (item.canCancel)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Cancel'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.caption),
      ],
    );
  }
}
