import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../theme/app_text_styles.dart';
import 'app_network_image.dart';

/// Full-screen, swipeable, pinch-to-zoom photo viewer.
Future<void> showImageGallery(
  BuildContext context, {
  required List<String> images,
  int initialIndex = 0,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) =>
          _GalleryPage(images: images, initialIndex: initialIndex),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _GalleryPage extends StatefulWidget {
  const _GalleryPage({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<_GalleryPage> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: AppNetworkImage(url: widget.images[i], fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Iconsax.close_circle_copy, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  '${_index + 1} / ${widget.images.length}',
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
