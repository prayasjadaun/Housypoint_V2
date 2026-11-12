import '../../theme/app_assets.dart';

/// One promo banner in the home ads carousel.
///
/// Abhi local assets se aate hain ([local]); baad me API se aayenge —
/// tab [image] network URL hoga aur [aspectRatio] API ki width/height se.
class AdBanner {
  const AdBanner({
    required this.id,
    required this.image,
    required this.aspectRatio,
    this.link,
  });

  final String id;

  /// Asset path, or an `http(s)` URL once banners come from the API.
  final String image;

  /// width / height of the artwork — the card takes this shape so nothing
  /// in the banner gets cropped.
  final double aspectRatio;

  /// Opened on tap (web URL or deep link). Null = not tappable.
  final String? link;

  bool get isNetwork => image.startsWith('http');

  static const local = [
    AdBanner(
      id: 'housypoint',
      image: AppAssets.adHousypoint,
      aspectRatio: 1412 / 318,
    ),
    AdBanner(id: 'inlobo', image: AppAssets.adInlobo, aspectRatio: 1942 / 809),
    AdBanner(
      id: 'inspection',
      image: AppAssets.adInspection,
      aspectRatio: 1412 / 308,
    ),
  ];
}
