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
  static const String fcmToken = 'auth/fcm-token/';
  static const String processReferral = 'referrals/process-code';
  static const String version = 'version';

  /// Calls where a 401 means "wrong input", not "session expired".
  static const List<String> publicPaths = [sendOtp, login];

  // Web pages opened in the browser
  static const String privacyPolicyUrl = '$host/privacy_policy/';
  static const String termsUrl = '$host/terms_conditions/';
  static const String deleteAccountUrl = '$host/accounts/delete/';
}
