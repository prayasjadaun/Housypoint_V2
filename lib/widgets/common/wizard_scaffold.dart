import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'app_button.dart';
import 'page_scaffold.dart';

/// Multi-step form frame: segmented progress, animated step body and a
/// Back / Continue bar. System back goes to the previous step first.
class WizardScaffold extends StatelessWidget {
  const WizardScaffold({
    super.key,
    required this.title,
    required this.stepTitles,
    required this.step,
    required this.child,
    required this.onBack,
    required this.onPrimary,
    this.primaryLabel = 'Continue',
    this.primaryIcon = Iconsax.arrow_right_3_copy,
    this.loading = false,
  });

  final String title;
  final List<String> stepTitles;
  final int step;
  final Widget child;
  final VoidCallback onBack;
  final VoidCallback onPrimary;
  final String primaryLabel;
  final IconData primaryIcon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final top = PageScaffold.topInset(context);

    return PopScope(
      canPop: step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: PageScaffold(
        title: title,
        backgroundColor: AppColors.surface,
        bottomBar: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            10,
            AppSpacing.md,
            MediaQuery.paddingOf(context).bottom + 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              if (step > 0) ...[
                Material(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                    onTap: onBack,
                    child: SizedBox.square(
                      dimension: 54,
                      child: Icon(
                        CupertinoIcons.back,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: AppButton(
                  label: primaryLabel,
                  icon: primaryIcon,
                  isLoading: loading,
                  onPressed: onPrimary,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            SizedBox(height: top),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < stepTitles.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <= step
                                  ? AppColors.primary
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step ${step + 1} of ${stepTitles.length} · ${stepTitles[step]}',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey(step), child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
