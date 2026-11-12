import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../theme/app_colors.dart';

/// Cached network image with a soft placeholder and an icon fallback.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackIcon = Iconsax.gallery_copy,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallback();
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, _) => Container(color: AppColors.background),
      errorWidget: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() => Container(
    width: width,
    height: height,
    color: AppColors.background,
    alignment: Alignment.center,
    child: Icon(fallbackIcon, color: AppColors.textTertiary, size: 26),
  );
}
