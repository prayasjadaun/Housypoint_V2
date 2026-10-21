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
  static const String myListings = '/profile/listings';
  static const String support = '/support';
  static const String search = '/search';
  static const String notifications = '/notifications';
  static const String sell = '/post/sell';
  static const String rentOut = '/post/rent';
  static const String buy = '/buy';
  static const String compare = '/compare';
  static const String homeLoan = '/home-loan';
  static const String inspection = '/inspection';
  static const String myInspections = '/inspections';
  static const String consultation = '/consultation';
  static String consultationFor(String service) => '/consultation?service=$service';
  static const String myConsultations = '/consultations';
  static const String builders = '/builders';
  static const String builder = '/builders/:id';
  static String builderPath(int id) => '/builders/$id';
  static const String listing = '/listing/:id';
  static const String project = '/project/:id';

  /// `/listing/515?rental=1` — pass the card's ListingModel as `extra`.
  static String listingPath(int id, {required bool rental, bool hotDeal = false}) =>
      '/listing/$id?rental=${rental ? 1 : 0}${hotDeal ? '&hot=1' : ''}';

  static String projectPath(int id) => '/project/$id';

  static const Set<String> authFlow = {login, otp};
}
