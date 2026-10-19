import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/inspection_controller.dart';
import '../controllers/post_property_controller.dart';
import '../models/listing/listing_model.dart';
import '../models/master/builder_model.dart';
import '../repositories/master_data_repository.dart';
import '../repositories/pdi_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/wizard_repository.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/otp_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/builders/builder_detail_screen.dart';
import '../views/builders/builders_screen.dart';
import '../views/buy/buy_requirement_screen.dart';
import '../views/compare/compare_projects_screen.dart';
import '../views/consultation/consultation_booking_screen.dart';
import '../views/consultation/my_consultations_screen.dart';
import '../views/inspection/inspection_booking_screen.dart';
import '../views/inspection/my_inspections_screen.dart';
import '../views/listings/listing_detail_screen.dart';
import '../views/loan/home_loan_screen.dart';
import '../views/notifications/notifications_screen.dart';
import '../views/onboarding/onboarding_screen.dart';
import '../views/post_property/post_property_screen.dart';
import '../views/profile/edit_profile_screen.dart';
import '../views/profile/my_listings_screen.dart';
import '../views/project/project_detail_screen.dart';
import '../views/search/search_screen.dart';
import '../views/shell/main_shell_screen.dart';
import '../views/splash/splash_screen.dart';
import '../views/support/support_screen.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Auth-driven routing: whenever [AuthController.status] changes, the
/// redirect sends the user to the right place (login / sign up / home).
GoRouter createRouter(AuthController auth) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      switch (auth.status) {
        case AuthStatus.unknown:
          return location == AppRoutes.splash ? null : AppRoutes.splash;
        case AuthStatus.loggedOut:
          if (auth.needsOnboarding) {
            return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
          }
          return AppRoutes.authFlow.contains(location) ? null : AppRoutes.login;
        case AuthStatus.needsProfile:
          return location == AppRoutes.register ? null : AppRoutes.register;
        case AuthStatus.loggedIn:
          final onAuthScreen = location == AppRoutes.splash ||
              location == AppRoutes.register ||
              AppRoutes.authFlow.contains(location);
          return onAuthScreen ? AppRoutes.home : null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, _) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const MainShellScreen(),
      ),
      GoRoute(
        path: AppRoutes.listing,
        builder: (_, state) => ListingDetailScreen(
          id: int.parse(state.pathParameters['id']!),
          rental: state.uri.queryParameters['rental'] == '1',
          isHotDeal: state.uri.queryParameters['hot'] == '1',
          initial: state.extra is ListingModel ? state.extra as ListingModel : null,
        ),
      ),
      GoRoute(path: AppRoutes.editProfile, builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: AppRoutes.myListings, builder: (_, _) => const MyListingsScreen()),
      GoRoute(path: AppRoutes.support, builder: (_, _) => const SupportScreen()),
      GoRoute(
        path: AppRoutes.consultation,
        builder: (_, state) => ConsultationBookingScreen(
          initialService: state.uri.queryParameters['service'],
        ),
      ),
      GoRoute(
        path: AppRoutes.inspection,
        builder: (context, _) => ChangeNotifierProvider(
          create: (_) => InspectionController(
            context.read<PdiRepository>(),
            context.read<MasterDataRepository>(),
            context.read<ProjectRepository>(),
            city: context.read<HomeController>().selectedCity,
          ),
          child: const InspectionBookingScreen(),
        ),
      ),
      for (final (path, rent) in [(AppRoutes.sell, false), (AppRoutes.rentOut, true)])
        GoRoute(
          path: path,
          builder: (context, _) => ChangeNotifierProvider(
            create: (_) => PostPropertyController(
              context.read<WizardRepository>(),
              context.read<MasterDataRepository>(),
              context.read<ProjectRepository>(),
              isRent: rent,
            ),
            child: const PostPropertyScreen(),
          ),
        ),
      GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.search, builder: (_, _) => const SearchScreen()),
      GoRoute(path: AppRoutes.buy, builder: (_, _) => const BuyRequirementScreen()),
      GoRoute(path: AppRoutes.compare, builder: (_, _) => const CompareProjectsScreen()),
      GoRoute(path: AppRoutes.homeLoan, builder: (_, _) => const HomeLoanScreen()),
      GoRoute(path: AppRoutes.myInspections, builder: (_, _) => const MyInspectionsScreen()),
      GoRoute(path: AppRoutes.myConsultations, builder: (_, _) => const MyConsultationsScreen()),
      GoRoute(path: AppRoutes.builders, builder: (_, _) => const BuildersScreen()),
      GoRoute(
        path: AppRoutes.builder,
        builder: (_, state) => BuilderDetailScreen(
          id: int.parse(state.pathParameters['id']!),
          initial: state.extra is BuilderModel ? state.extra as BuilderModel : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.project,
        builder: (_, state) =>
            ProjectDetailScreen(id: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
}
