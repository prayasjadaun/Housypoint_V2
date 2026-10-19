import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/otp_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/onboarding/onboarding_screen.dart';
import '../views/shell/main_shell_screen.dart';
import '../views/splash/splash_screen.dart';
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
    ],
  );
}
