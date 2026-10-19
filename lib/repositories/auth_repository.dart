import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../config/app_config.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/utils/device_info_helper.dart';
import '../models/auth/user_model.dart';

/// Result of OTP verification: who logged in and whether they still
/// have to fill in their profile (new user = sign up).
class LoginResult {
  const LoginResult({required this.user, required this.needsProfile});

  final UserModel user;
  final bool needsProfile;
}

/// Every auth API call (docs/API_REFERENCE.md §2). Controllers depend on
/// this, never on Dio directly.
class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;

  /// A1 — [phone] is country code + number without `+`, e.g. `919876543210`.
  Future<void> sendOtp(String phone) async {
    try {
      await _dio.post(ApiConfig.sendOtp, data: {'phone': phone});
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not send OTP. Please try again.');
    }
  }

  /// A2 — verifies the 5-digit OTP. New users come back with
  /// `requires_profile_update: true`.
  Future<LoginResult> verifyOtp({
    required String phone,
    required String otp,
    String? referralCode,
  }) async {
    final device = await DeviceDetails.load();
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {
          'phone': phone,
          'otp': otp,
          'device_id': device.id,
          'device_name': device.name,
          'device_type': device.type,
          'app_version': AppConfig.appVersion,
          if (referralCode != null && referralCode.isNotEmpty)
            'referral_code': referralCode,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw const ApiException(ApiErrorMessages.generic);
      }

      final userJson = data['user'] as Map<String, dynamic>? ?? {'phone': phone};
      final user = UserModel.fromJson(userJson);

      await _storage.saveToken(token);
      await _storage.saveUserJson(jsonEncode(user.toJson()));

      if (referralCode != null && referralCode.isNotEmpty) {
        await _processReferral(referralCode);
      }

      return LoginResult(
        user: user,
        needsProfile: data['requires_profile_update'] == true,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Invalid OTP. Please try again.');
    }
  }

  /// A4 — completes sign up (or edits the profile later).
  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    String address = '',
  }) async {
    try {
      final response = await _dio.put(
        ApiConfig.profile,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email_id': email,
          'address': address,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(
        (data['user'] ?? data) as Map<String, dynamic>,
      );
      await _storage.saveUserJson(jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      throw ApiException.fromDio(e, 'Could not save your details.');
    }
  }

  /// Restores the session saved on this device, if any.
  Future<UserModel?> getSavedUser() async {
    final token = await _storage.getToken();
    final userJson = await _storage.getUserJson();
    if (token == null || userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConfig.logout);
    } on DioException {
      // Local session is cleared regardless of the server response.
    } finally {
      await _storage.clear();
    }
  }

  /// A7 — best effort; a bad code must not block login.
  Future<void> _processReferral(String code) async {
    try {
      await _dio.post(ApiConfig.processReferral, data: {'referral_code': code});
    } on DioException {
      // ignore
    }
  }
}
