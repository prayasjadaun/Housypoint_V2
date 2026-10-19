import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/storage/app_prefs.dart';
import '../firebase/firebase_setup.dart';
import '../firebase/notification_service.dart';
import '../models/auth/user_model.dart';
import '../repositories/auth_repository.dart';

/// Where the user is in the auth flow — the router redirects on this.
enum AuthStatus { unknown, loggedOut, needsProfile, loggedIn }

/// Auth state for the whole app: phone → OTP → (sign up) → home.
class AuthController extends ChangeNotifier {
  AuthController(this._repository, this._notifications);

  final AuthRepository _repository;
  final NotificationService _notifications;

  AuthStatus status = AuthStatus.unknown;
  UserModel? user;

  bool isBusy = false;
  String? errorMessage;

  /// Number entered on the login screen, without country code.
  String phoneNumber = '';

  /// Dialling code without `+`, e.g. `91`.
  String countryCode = '91';

  /// ISO code of the picked country, e.g. `IN` — keeps the picker in sync.
  String countryIso = 'IN';
  String referralCode = '';

  String get fullPhone => '$countryCode$phoneNumber';

  /// First launch — show onboarding before login.
  bool get needsOnboarding => !AppPrefs.onboardingSeen;

  Future<void> completeOnboarding() async {
    await AppPrefs.setOnboardingSeen();
    notifyListeners();
  }

  /// Runs on app start (splash).
  Future<void> restoreSession() async {
    user = await _repository.getSavedUser();
    if (user == null) {
      status = AuthStatus.loggedOut;
    } else {
      // A user who quit mid sign-up has no name yet.
      status = user!.firstName.isEmpty
          ? AuthStatus.needsProfile
          : AuthStatus.loggedIn;
      _onLoggedIn();
    }
    notifyListeners();
  }

  Future<bool> sendOtp({
    required String phone,
    required String dialCode,
    required String iso,
    String referral = '',
  }) {
    phoneNumber = phone;
    countryCode = dialCode;
    countryIso = iso;
    referralCode = referral.trim();
    return _run(() => _repository.sendOtp(fullPhone));
  }

  Future<bool> resendOtp() => _run(() => _repository.sendOtp(fullPhone));

  Future<bool> verifyOtp(String otp) => _run(() async {
    final result = await _repository.verifyOtp(
      phone: fullPhone,
      otp: otp,
      referralCode: referralCode,
    );
    user = result.user;
    status = result.needsProfile ? AuthStatus.needsProfile : AuthStatus.loggedIn;
    _onLoggedIn();
  });

  Future<bool> completeProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) => _run(() async {
    user = await _repository.updateProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
    status = AuthStatus.loggedIn;
  });

  /// Edit profile (API ref A4). Phone can't change — it's the login.
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String address,
  }) => _run(() async {
    user = await _repository.updateProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      address: address,
    );
  });

  Future<void> logout() async {
    await _notifications.deleteToken();
    await _repository.logout();
    _clear();
  }

  /// DioClient saw a 401 — the token is already wiped.
  void handleSessionExpired() {
    if (status == AuthStatus.loggedOut) return;
    _clear();
  }

  void _clear() {
    user = null;
    phoneNumber = '';
    referralCode = '';
    status = AuthStatus.loggedOut;
    FirebaseSetup.setUser(null);
    notifyListeners();
  }

  void _onLoggedIn() {
    FirebaseSetup.setUser(user?.id);
    _notifications.initialize();
  }

  Future<bool> _run(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}
