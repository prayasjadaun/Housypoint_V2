import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../config/app_config.dart';
import '../../core/utils/launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/settings_tile.dart';

/// Help & support — call, WhatsApp, email and the office (V1 support screen).
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = PageScaffold.topInset(context);

    return PageScaffold(
      title: 'Help & support',
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.md, top + AppSpacing.md, AppSpacing.md, AppSpacing.xl),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl + 4),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How can we help?', style: AppTextStyles.title.copyWith(color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        'Our team answers in English, Hindi and regional languages.',
                        style: AppTextStyles.caption.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  child: const Icon(Iconsax.headphone_copy, color: Colors.white, size: 26),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _QuickContact(
                  icon: Iconsax.call_copy,
                  label: 'Call us',
                  color: AppColors.primary,
                  onTap: () => Launcher.call('+${AppConfig.supportPhone}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickContact(
                  icon: Iconsax.message_copy,
                  label: 'WhatsApp',
                  color: AppColors.success,
                  onTap: () => Launcher.whatsApp(
                    AppConfig.supportWhatsApp,
                    message: 'Hi, I need support regarding Housy Point.',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickContact(
                  icon: Iconsax.sms_copy,
                  label: 'Email',
                  color: AppColors.accentBlue,
                  onTap: () => Launcher.url('mailto:${AppConfig.supportEmail}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            title: 'Contact details',
            children: [
              SettingsTile(
                icon: Iconsax.call_copy,
                title: '+91 98713 55121',
                subtitle: 'Call us directly · 10 AM – 7 PM',
                onTap: () => Launcher.call('+${AppConfig.supportPhone}'),
              ),
              SettingsTile(
                icon: Iconsax.sms_copy,
                title: AppConfig.supportEmail,
                subtitle: 'We reply within a working day',
                color: AppColors.accentBlue,
                onTap: () => Launcher.url('mailto:${AppConfig.supportEmail}'),
              ),
              SettingsTile(
                icon: Iconsax.location_copy,
                title: 'Visit our office',
                subtitle: AppConfig.officeAddress,
                color: AppColors.accentAmber,
                onTap: () => Launcher.url(AppConfig.officeMapUrl),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickContact extends StatelessWidget {
  const _QuickContact({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 8),
              Text(label, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
