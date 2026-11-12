import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_network_image.dart';

/// Back face of [PropertyCard]: the listing's video with the cover photo as
/// a poster, a centre play button, a scrub bar and a full-screen button.
///
/// The controller is created when this face is built (i.e. once the card has
/// flipped) and disposed when it leaves the tree, so cards that are never
/// flipped never touch the network for video.
class PropertyVideoFace extends StatefulWidget {
  const PropertyVideoFace({
    super.key,
    required this.videoUrl,
    required this.posterUrl,
    required this.title,
    required this.onFlipBack,
  });

  final String videoUrl;
  final String posterUrl;
  final String title;
  final VoidCallback onFlipBack;

  @override
  State<PropertyVideoFace> createState() => _PropertyVideoFaceState();
}

class _PropertyVideoFaceState extends State<PropertyVideoFace> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final url = widget.videoUrl;
    // `assets/...` paths are bundled placeholders; everything else is remote.
    final VideoPlayerController controller;
    if (url.startsWith('assets/')) {
      controller = VideoPlayerController.asset(url);
    } else {
      final uri = Uri.tryParse(url);
      if (uri == null || url.isEmpty) {
        setState(() => _failed = true);
        return;
      }
      controller = VideoPlayerController.networkUrl(uri);
    }
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    AppHaptics.selection();
    c.value.isPlaying ? c.pause() : c.play();
  }

  Future<void> _openFullscreen() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    AppHaptics.tap();
    if (!c.value.isPlaying) c.play();
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => PropertyVideoFullscreen(controller: c, title: widget.title),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        AppNetworkImage(url: widget.posterUrl),
        if (ready) _CoverVideo(controller: c),
        // Darker than the front so the controls always read
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.25, 0.6, 1],
              colors: [Color(0x66000000), Color(0x1A000000), Color(0x26000000), Color(0xCC000000)],
            ),
          ),
        ),
        // Tap anywhere on the video to play / pause
        Positioned.fill(
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _togglePlay),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 60,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _Pill(icon: Iconsax.video_play_copy, text: 'Video tour'),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: CardGlassButton(icon: Iconsax.gallery_copy, onTap: widget.onFlipBack),
        ),
        Center(
          child: _failed
              ? _Message(icon: Iconsax.video_slash_copy, text: 'Video unavailable')
              : !ready
              ? const SizedBox.square(
                  dimension: 34,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: c,
                  builder: (_, v, _) => _CenterPlayButton(
                    playing: v.isPlaying,
                    buffering: v.isBuffering,
                    onTap: _togglePlay,
                  ),
                ),
        ),
        if (ready)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _ControlBar(controller: c, onFullscreen: _openFullscreen),
          ),
      ],
    );
  }
}

/// Fills the card like `BoxFit.cover`, cropping instead of letterboxing.
class _CoverVideo extends StatelessWidget {
  const _CoverVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width == 0 ? 16 : size.width,
          height: size.height == 0 ? 9 : size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

class _CenterPlayButton extends StatelessWidget {
  const _CenterPlayButton({required this.playing, required this.buffering, required this.onTap});

  final bool playing;
  final bool buffering;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (playing && buffering) {
      return const SizedBox.square(
        dimension: 34,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    }
    // Fades out while playing; tapping the video brings it back via pause.
    return AnimatedOpacity(
      opacity: playing ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: playing,
        child: Material(
          color: Colors.white.withValues(alpha: 0.22),
          shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1.2)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox.square(
              dimension: 64,
              child: Icon(Icons.play_arrow_rounded, size: 38, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({required this.controller, required this.onFullscreen});

  final VideoPlayerController controller;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (_, v, _) {
        final muted = v.volume == 0;
        return Row(
          children: [
            CardGlassButton(
              icon: muted ? Iconsax.volume_slash_copy : Iconsax.volume_high_copy,
              size: 32,
              onTap: () {
                AppHaptics.selection();
                controller.setVolume(muted ? 1 : 0);
              },
            ),
            const SizedBox(width: 10),
            Expanded(child: _Scrubber(controller: controller)),
            const SizedBox(width: 10),
            Text(
              '${_fmt(v.position)} / ${_fmt(v.duration)}',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 10),
            CardGlassButton(icon: Iconsax.maximize_copy, size: 32, onTap: onFullscreen),
          ],
        );
      },
    );
  }
}

class _Scrubber extends StatelessWidget {
  const _Scrubber({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: VideoProgressIndicator(
        controller,
        allowScrubbing: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        colors: VideoProgressColors(
          playedColor: AppColors.gold,
          bufferedColor: Colors.white.withValues(alpha: 0.4),
          backgroundColor: Colors.white.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

/// Full-screen player sharing the card's controller, so playback continues
/// seamlessly in both directions. Unlocks rotation while open.
class PropertyVideoFullscreen extends StatefulWidget {
  const PropertyVideoFullscreen({super.key, required this.controller, required this.title});

  final VideoPlayerController controller;
  final String title;

  @override
  State<PropertyVideoFullscreen> createState() => _PropertyVideoFullscreenState();
}

class _PropertyVideoFullscreenState extends State<PropertyVideoFullscreen> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Back to the app-wide defaults set in main.dart
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _togglePlay() {
    AppHaptics.selection();
    final c = widget.controller;
    c.value.isPlaying ? c.pause() : c.play();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: c.value.aspectRatio,
                child: VideoPlayer(c),
              ),
            ),
            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: [
                            CardGlassButton(
                              icon: Iconsax.arrow_left_copy,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: c,
                          builder: (_, v, _) => v.isPlaying && v.isBuffering
                              ? const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)
                              : CardGlassButton(
                                  icon: v.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 68,
                                  iconSize: 38,
                                  onTap: _togglePlay,
                                ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 12,
                        child: _FullscreenBar(controller: c),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenBar extends StatelessWidget {
  const _FullscreenBar({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (_, v, _) {
        final muted = v.volume == 0;
        final timeStyle = AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
        return Row(
          children: [
            Text(_fmt(v.position), style: timeStyle),
            const SizedBox(width: 12),
            Expanded(child: _Scrubber(controller: controller)),
            const SizedBox(width: 12),
            Text(_fmt(v.duration), style: timeStyle),
            const SizedBox(width: 8),
            CardGlassButton(
              icon: muted ? Iconsax.volume_slash_copy : Iconsax.volume_high_copy,
              size: 36,
              onTap: () {
                AppHaptics.selection();
                controller.setVolume(muted ? 1 : 0);
              },
            ),
            const SizedBox(width: 8),
            CardGlassButton(
              icon: Icons.fullscreen_exit_rounded,
              size: 36,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}

/// Translucent round button that reads on any photo or video frame.
class CardGlassButton extends StatelessWidget {
  const CardGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 38,
    this.iconSize,
    this.background,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double? iconSize;

  /// Solid fill instead of glass.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? Colors.white.withValues(alpha: 0.18),
      shape: CircleBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: background == null ? 0.3 : 0)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, size: iconSize ?? size * 0.47, color: Colors.white),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.ink),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 30, color: Colors.white.withValues(alpha: 0.85)),
        const SizedBox(height: 8),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

String _fmt(Duration d) {
  final m = d.inMinutes.remainder(60).toString();
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:${m.padLeft(2, '0')}:$s' : '$m:$s';
}
