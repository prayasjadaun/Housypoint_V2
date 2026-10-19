import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'controllers/auth_controller.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'widgets/common/keyboard_dismisser.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Built once — the redirect re-runs on AuthController changes.
  late final GoRouter _router = createRouter(context.read<AuthController>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) =>
          KeyboardDismisser(child: child ?? const SizedBox.shrink()),
    );
  }
}
