import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'controllers/auth_controller.dart';
import 'controllers/home_controller.dart';
import 'controllers/listings_controller.dart';
import 'controllers/referral_controller.dart';
import 'controllers/saved_controller.dart';
import 'controllers/shell_controller.dart';
import 'core/network/connectivity_service.dart';
import 'core/network/dio_client.dart';
import 'core/storage/app_prefs.dart';
import 'core/storage/secure_storage_service.dart';
import 'firebase/firebase_setup.dart';
import 'firebase/notification_service.dart';
import 'firebase/remote_config_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/consultation_repository.dart';
import 'repositories/listing_repository.dart';
import 'repositories/loan_repository.dart';
import 'repositories/master_data_repository.dart';
import 'repositories/my_listings_repository.dart';
import 'repositories/pdi_repository.dart';
import 'repositories/project_repository.dart';
import 'repositories/referral_repository.dart';
import 'repositories/saved_repository.dart';
import 'repositories/wizard_repository.dart';

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
        ChangeNotifierProvider(create: (_) => ConnectivityService(), lazy: false),
        ChangeNotifierProvider(
          create: (_) => HomeController(
            MasterDataRepository(dio),
            ListingRepository(dio),
            ProjectRepository(dio),
          ),
        ),
        ChangeNotifierProvider(create: (_) => SavedController(SavedRepository(dio))),
        ChangeNotifierProvider(create: (_) => ShellController()),
        ChangeNotifierProvider(
          create: (_) => ListingsController(ListingRepository(dio)),
        ),
        // Repositories that screens use directly (detail pages, lists)
        ChangeNotifierProvider(create: (_) => ReferralController(ReferralRepository(dio))),
        Provider.value(value: ListingRepository(dio)),
        Provider.value(value: ProjectRepository(dio)),
        Provider.value(value: MyListingsRepository(dio)),
        Provider.value(value: MasterDataRepository(dio)),
        Provider.value(value: ConsultationRepository(dio)),
        Provider.value(value: PdiRepository(dio)),
        Provider.value(value: LoanRepository(dio)),
        Provider.value(value: WizardRepository(dio)),
      ],
      child: const App(),
    ),
  );
}
