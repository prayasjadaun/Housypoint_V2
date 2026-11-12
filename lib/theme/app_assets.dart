/// Single source of truth for asset paths. Icons come from Iconsax (linear).
class AppAssets {
  AppAssets._();

  // Logos
  /// Same artwork as the app icon.
  static const String logo = 'assets/logo/housypoint_logo.png';

  // Lottie
  static const String lottieNotFound = 'assets/lottie/404.json';
  static const String lottieServerError = 'assets/lottie/500.json';
  static const String lottieConfetti = 'assets/lottie/confetti_effect.json';
  static const String lottieGift = 'assets/lottie/ref_gift.json';
  static const String lottieEmpty = 'assets/lottie/zero_notification.json';
  static const String lottieNoResults = 'assets/lottie/empty.json';
  static const String lottieBuilding = 'assets/lottie/building.json';

  // City landmark photos (credits: assets/CITY_IMAGE_CREDITS.md)
  static const _cityImages = {
    'gurgaon': 'assets/cities/gurgaon.jpg',
    'gurugram': 'assets/cities/gurgaon.jpg',
    'new delhi': 'assets/cities/new_delhi.jpg',
    'delhi': 'assets/cities/new_delhi.jpg',
    'noida': 'assets/cities/noida.jpg',
    'mumbai': 'assets/cities/mumbai.jpg',
    'bengaluru': 'assets/cities/bengaluru.jpg',
    'bangalore': 'assets/cities/bengaluru.jpg',
    'pune': 'assets/cities/pune.jpg',
    'hyderabad': 'assets/cities/hyderabad.jpg',
    'dubai': 'assets/cities/dubai.jpg',
    'abu dhabi': 'assets/cities/abu_dhabi.jpg',
  };

  /// Landmark photo for [city], or null if we don't have one.
  static String? cityImage(String city) =>
      _cityImages[city.trim().toLowerCase()];

  // Home ad banners (local placeholders until the ads API is wired)
  static const String adHousypoint = 'assets/adBanner/housypoint.png';
  static const String adInlobo = 'assets/adBanner/inlobo.png';
  static const String adInspection = 'assets/adBanner/inspection.png';
}
