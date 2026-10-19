import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'app_network_image.dart';
import 'image_gallery_viewer.dart';

/// Swipeable photo header with page dots; tap opens the full-screen gallery.
class ImageCarousel extends StatefulWidget {
  const ImageCarousel({super.key, required this.images});

  final List<String> images;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isEmpty ? [''] : widget.images;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => GestureDetector(
            onTap: widget.images.isEmpty
                ? null
                : () => showImageGallery(context, images: images, initialIndex: i),
            child: AppNetworkImage(url: images[i]),
          ),
        ),
        // Darken the top for the floating buttons, bottom for the dots
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.25, 0.75, 1],
                colors: [
                  Color(0x59000000),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x40000000),
                ],
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? AppColors.surface
                          : AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
