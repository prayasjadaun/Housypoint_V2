import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'widgets/common/connectivity_banner.dart';
import 'widgets/common/keyboard_dismisser.dart';
import 'widgets/common/theme_switch_overlay.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Built once — the redirect re-runs on AuthController changes.
  late final GoRouter _router = createRouter(context.read<AuthController>());
  late final ThemeController _theme = context.read<ThemeController>();

  @override
  void initState() {
    super.initState();
    _theme.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _theme.removeListener(_onThemeChanged);
    super.dispose();
  }

  /// Screens read [AppColors] directly (not via Theme.of), so a theme
  /// change must rebuild every element — const widgets included — or they
  /// keep the old colors until something else rebuilds them.
  void _onThemeChanged() {
    setState(() {});
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }
    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.current,
      // ThemeSwitchOverlay draws the reveal; skip the default 200ms lerp.
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => RepaintBoundary(
        key: ThemeSwitchOverlay.rootBoundaryKey,
        child: KeyboardDismisser(
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const ConnectivityBanner(),
            ],
          ),
        ),
      ),
    );
  }
}
