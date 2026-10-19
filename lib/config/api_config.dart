/// Base URL and endpoint path constants.
/// Reference `docs/API_REFERENCE.md` before adding a new endpoint.
class ApiConfig {
  ApiConfig._();

  static const String host = 'https://housypoint.com';
  static const String baseUrl = '$host/api/';
  static const String mediaCdn =
      'https://housymediabucket.blr1.cdn.digitaloceanspaces.com/media/';

  /// Sent as `X-API-Key`. Override per build with
  /// `--dart-define=HP_API_KEY=...`; the default is the V1 key.
  static const String apiKey = String.fromEnvironment(
    'HP_API_KEY',
    defaultValue: '2wirbRenwJCGrCJU98k6wLG1PpXUPFSE',
  );

  // Auth (A1–A9)
  static const String sendOtp = 'auth/send-otp/';
  static const String login = 'auth/login/';
  static const String profile = 'auth/profile/';
  static const String logout = 'auth/logout/';
  // V1 used `auth/fcm-token/`, which returns 404 on the server.
  static const String fcmToken = 'auth/update-fcm-token/';
  static const String processReferral = 'referrals/process-code';
  static const String myListings = 'user/listings/';
  static const String version = 'version';

  // Master data (M1–M2)
  static const String cities = 'cities/';
  static const String builders = 'builders/';

  static String builder(int id) => 'builders/$id/';
  static String builderProjects(int id) => 'builders/$id/projects/';
  static const String projects = 'projects/';
  static String project(int id) => 'projects/$id/';
  static const String newLaunches = 'new-launch/all/';
  static const String search = 'search/';

  // Listings (L1–L4). Trailing slash matters: without it the server 301s.
  static const String saleListings = 'listings/properties/';
  static const String rentListings = 'listings/rentals/';
  static String listing(int id, {required bool rental}) =>
      '${rental ? rentListings : saleListings}$id/';
  static const String listingCounts = 'listings/counts/';
  static const String distressDeals = 'distress-deals/';

  // Wishlist & interests (S1–S4)
  static const String wishlist = 'wishlist/';
  static const String wishlistToggle = 'wishlist/toggle/';
  static const String interests = 'interests/';
  static const String showInterest = 'interests/show_interest/';

  // Referral (R1–R7)
  static const String referralStats = 'referrals/earnings/detailed_stats/';
  static const String referralPdiStats = 'referrals/pdi-stats';
  static const String referralEarnings = 'referrals/earnings/earnings_history';
  static const String referralWithdrawals = 'referrals/withdrawals/';
  static const String referredUsers = 'referrals/referred-users/detailed';

  // Consultations (K1–K5)
  static const String consultations = 'consultations/';
  static const String consultationOptions = 'consultations/options/';
  static const String consultationBook = 'consultations/book/';
  static String consultationCancel(int id) => 'consultations/$id/cancel/';

  // PDI home inspection (P4–P10)
  static const String pdiPlans = 'pdi/plans/';
  static const String pdiDates = 'pdi/dates/';
  static const String pdiSlots = 'pdi/time-slots/';
  static const String pdiUploadFloorPlan = 'pdi/upload-floor-plan/';
  static const String pdiBook = 'pdi/book/';
  static const String pdiBookings = 'pdi/bookings/';
  static String pdiBooking(String id) => 'pdi/bookings/$id/';

  // Home loan (H1)
  static const String loanBanks = 'loan/banks/';

  // Sell / rent / buy wizards (W4–W9)
  static String wizardConfigurations(int projectId) => 'wizard/projects/$projectId/configurations/';
  static String wizardProjectImages(int projectId) => 'wizard/projects/$projectId/images/';
  static const String uploadImages = 'upload-images/';
  static const String sellListing = 'wizard/property-listing/';
  static const String rentListing = 'wizard/rent-listing/';
  static const String buyInterest = 'wizard/buy-interest/';

  /// Calls where a 401 means "wrong input", not "session expired".
  static const List<String> publicPaths = [sendOtp, login];

  // Web pages opened in the browser
  static const String privacyPolicyUrl = '$host/privacy_policy/';
  static const String termsUrl = '$host/terms_conditions/';
  static const String deleteAccountUrl = '$host/accounts/delete/';
}
