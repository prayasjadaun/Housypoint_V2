import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'controllers/auth_controller.dart';
import 'core/network/dio_client.dart';
import 'core/storage/app_prefs.dart';
import 'core/storage/secure_storage_service.dart';
import 'firebase/firebase_setup.dart';
import 'firebase/notification_service.dart';
import 'firebase/remote_config_service.dart';
import 'repositories/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await AppConfig.init();
  await AppPrefs.init();
  await FirebaseSetup.init();
  unawaited(RemoteConfigService.instance.initialize());

  final storage = SecureStorageService();
  late final AuthController authController;
  final dioClient = DioClient(
    storage,
    onSessionExpired: () => authController.handleSessionExpired(),
  );
  final dio = dioClient.dio;

  authController = AuthController(
    AuthRepository(dio, storage),
    NotificationService(dio),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authController),
      ],
      child: const App(),
    ),
  );
}
