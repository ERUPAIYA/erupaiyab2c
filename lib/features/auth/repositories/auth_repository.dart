import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';
import '../../../services/login_device_context_service.dart';
import '../../../services/push_notification_service.dart';
import '../models/auth_flow.dart';

class AuthRepository {
  AuthRepository({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
  })  : _dio = dio ?? DioService.instance.client,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  FlutterSecureStorage get secureStorage => _secureStorage;

  Never _throwApiMessage(DioException e, {String fallback = 'Request failed'}) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        throw Exception(message.trim());
      }
    }
    throw Exception(fallback);
  }

  Future<AuthFlow> checkLogin({
    required String mobile,
    String? appHash,
  }) async {
    try {
      final deviceToken =
          (await PushNotificationService.ensureTokenReady())?.trim();
      if (deviceToken == null ||
          deviceToken.isEmpty ||
          deviceToken.toLowerCase() == 'null') {
        throw Exception(
          'Unable to fetch device token. Please try again in a moment.',
        );
      }

      final deviceContext = await const LoginDeviceContextService().collect();
      final response = await _dio.post(
        ApiConstants.checkLoginEndpoint,
        options: Options(
          contentType: Headers.jsonContentType,
          extra: const {
            'skipAuth': true,
            'skipAuthRefresh': true,
          },
        ),
        data: {
          'mobile': mobile,
          if (appHash != null && appHash.trim().isNotEmpty)
            'appHash': appHash.trim(),
          'device_token': deviceToken,
          ...deviceContext,
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message = payload?['message'] as String? ?? 'Request failed';
        throw Exception(message);
      }

      final data = payload?['data'] as Map<String, dynamic>? ?? {};
      final userId = data['user_id'] ?? data['id'];
      if (userId == null) {
        throw Exception('Invalid response');
      }

      await _secureStorage.write(key: 'userId', value: userId.toString());
      final flowValue = payload?['flow'] ?? data['flow'];
      return authFlowFromApi(flowValue) ?? AuthFlow.register;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'Unable to continue');
      }
      logger.error(
        'Check login failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    } catch (e) {
      logger.error(
        'Check login failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<void> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyOtpEndpoint,
        data: {
          'mobile': mobile,
          'otp': otp,
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message =
            payload?['message'] as String? ?? 'OTP verification failed';
        throw Exception(message);
      }
    } catch (e) {
      logger.error(
        'OTP verification failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> setPin({
    required String userId,
    required String pin,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.setPinEndpoint,
        data: {
          'user_id': userId,
          'pin': pin,
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message = payload?['message'] as String? ?? 'Set PIN failed';
        throw Exception(message);
      }
      final message = payload?['message'] as String? ?? 'PIN set successfully.';
      return message;
    } catch (e) {
      logger.error(
        'Set PIN failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<void> login({
    required String mobile,
    required String pin,
  }) async {
    try {
      final deviceToken =
          (await PushNotificationService.ensureTokenReady())?.trim();
      if (deviceToken == null ||
          deviceToken.isEmpty ||
          deviceToken.toLowerCase() == 'null') {
        throw Exception(
          'Unable to fetch device token. Please try again in a moment.',
        );
      }

      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        options: Options(
          contentType: Headers.jsonContentType,
          extra: const {
            // Auth is not required for login; avoid attaching stale tokens.
            'skipAuth': true,
            'skipAuthRefresh': true,
          },
        ),
        data: {
          'mobile': mobile,
          'pin': pin,
          'device_token': deviceToken,
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message = payload?['message'] as String? ?? 'Login failed';
        throw Exception(message);
      }

      final data = payload?['data'] as Map<String, dynamic>? ?? {};
      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;
      final tokenType = data['token_type'] as String?;
      final expiresIn = data['expires_in'] as int?;
      final userId = (data['user_id'] ?? data['id'])?.toString();

      if (accessToken == null || refreshToken == null || expiresIn == null) {
        throw Exception('Invalid login response');
      }

      final expiresAt =
          DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String();
      final refreshExpiry = _resolveRefreshExpiry(data);

      await _secureStorage.write(key: 'accessToken', value: accessToken);
      await _secureStorage.write(key: 'refreshToken', value: refreshToken);
      await _secureStorage.write(
        key: 'tokenType',
        value: tokenType ?? 'Bearer',
      );
      await _secureStorage.write(key: 'tokenExpiresAt', value: expiresAt);
      if (refreshExpiry != null) {
        await _secureStorage.write(
          key: 'refreshTokenExpiresAt',
          value: refreshExpiry.toIso8601String(),
        );
      }
      if (userId != null && userId.isNotEmpty) {
        await _secureStorage.write(key: 'userId', value: userId);
      }
      await _secureStorage.write(key: 'mobile', value: mobile);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'Login failed');
      }
      logger.error(
        'Login failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    } catch (e) {
      logger.error(
        'Login failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> pinLock({
    required String mobile,
    required String pin,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.pinLockEndpoint,
        data: {
          'mobile': mobile,
          'pin': pin,
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message =
            payload?['message'] as String? ?? 'PIN validation failed';
        throw Exception(message);
      }

      return payload?['message'] as String? ?? 'Login successful';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'PIN validation failed');
      }
      logger.error(
        'PIN lock failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    } catch (e) {
      logger.error(
        'PIN lock failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> requestForgotPinOtp({
    required String mobile,
    required String appHash,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.requestForgotPinOtpEndpoint,
        data: {
          'mobile': mobile,
          'appHash': appHash.trim(),
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message =
            payload?['message'] as String? ?? 'Failed to request OTP';
        throw Exception(message);
      }
      return payload?['message'] as String? ??
          'OTP sent to registered mobile number.';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'Failed to request OTP');
      }
      logger.error(
        'Request forgot PIN OTP failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    } catch (e) {
      logger.error(
        'Request forgot PIN OTP failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> forgotPin({
    required String userId,
    required String otp,
    required String pin,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPinEndpoint,
        data: {
          'user_id': userId,
          'otp': otp,
          'pin': pin,
        },
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message = payload?['message'] as String? ?? 'Failed to reset PIN';
        throw Exception(message);
      }
      return payload?['message'] as String? ?? 'PIN reset successfully.';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e, fallback: 'Failed to reset PIN');
      }
      logger.error(
        'Forgot PIN failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    } catch (e) {
      logger.error(
        'Forgot PIN failed: ${e.toString()}',
        error: e,
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refreshToken');
      if (refreshToken != null) {
        await _dio.post(
          ApiConstants.logoutEndpoint,
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (e) {
      logger.error('Logout API call failed: $e', error: e);
    } finally {
      await _secureStorage.delete(key: 'accessToken');
      await _secureStorage.delete(key: 'refreshToken');
      await _secureStorage.delete(key: 'tokenType');
      await _secureStorage.delete(key: 'tokenExpiresAt');
      await _secureStorage.delete(key: 'userId');
      await _secureStorage.delete(key: 'mobile');
    }
  }

  Future<bool> refreshSession() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refreshToken');
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await dio.post(
        ApiConstants.refreshTokenEndpoint,
        data: {'refresh_token': refreshToken},
      );

      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        return false;
      }

      final data = payload?['data'] as Map<String, dynamic>? ?? {};
      final accessToken = data['access_token'] as String?;
      final tokenType = data['token_type'] as String?;
      final expiresIn = data['expires_in'] as int?;

      if (accessToken == null || expiresIn == null) {
        return false;
      }

      final expiresAt =
          DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String();
      final refreshExpiry = _resolveRefreshExpiry(data);

      await _secureStorage.write(key: 'accessToken', value: accessToken);
      await _secureStorage.write(
        key: 'tokenType',
        value: tokenType ?? 'Bearer',
      );
      await _secureStorage.write(key: 'tokenExpiresAt', value: expiresAt);
      if (refreshExpiry != null) {
        await _secureStorage.write(
          key: 'refreshTokenExpiresAt',
          value: refreshExpiry.toIso8601String(),
        );
      }
      return true;
    } catch (e, stackTrace) {
      logger.error(
        'Refresh token failed: ${e.toString()}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}

DateTime? _resolveRefreshExpiry(Map<String, dynamic> data) {
  final refreshExpiresAt = data['refresh_expires_at'];
  if (refreshExpiresAt is String && refreshExpiresAt.isNotEmpty) {
    return DateTime.tryParse(refreshExpiresAt);
  }
  final refreshExpiresIn =
      data['refresh_expires_in'] ?? data['refresh_token_expires_in'];
  if (refreshExpiresIn is int) {
    return DateTime.now().add(Duration(seconds: refreshExpiresIn));
  }
  if (refreshExpiresIn is String) {
    final parsed = int.tryParse(refreshExpiresIn);
    if (parsed != null) {
      return DateTime.now().add(Duration(seconds: parsed));
    }
  }
  return null;
}
