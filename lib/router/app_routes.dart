/// Route paths — reference these, never raw strings.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String inspection = '/inspection';
  static const String myInspections = '/inspections';
  static const String consultation = '/consultation';
  static String consultationFor(String service) => '/consultation?service=$service';
  static const String myConsultations = '/consultations';
  static const String compare = '/compare';

  static const Set<String> authFlow = {login, otp};
}
