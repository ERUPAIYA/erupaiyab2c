import 'package:e_rupaiya/core/barrel_file.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/secure_storage_service.dart';

class Utils {
  static Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static Future<String?> getAccessToken() {
    const secureStorage = SecureStorageService.instance;
    return secureStorage.read(key: 'accessToken');
  }

  static Future<String?> getTemporaryAccessToken() {
    const secureStorage = SecureStorageService.instance;
    return secureStorage.read(key: 'tempAccessToken');
  }

  static Future<String?> getTokenType() {
    const secureStorage = SecureStorageService.instance;
    return secureStorage.read(key: 'tokenType');
  }

  static Future<String?> getUserId() {
    const secureStorage = SecureStorageService.instance;
    return secureStorage.read(key: 'userId');
  }

  static Future<DateTime?> getAccessTokenExpiry() async {
    const secureStorage = SecureStorageService.instance;
    final expiryValue = await secureStorage.read(key: 'tokenExpiresAt');
    if (expiryValue == null) {
      return null;
    }
    return DateTime.tryParse(expiryValue);
  }

  static Future<DateTime?> getRefreshTokenExpiry() async {
    const secureStorage = SecureStorageService.instance;
    final expiryValue = await secureStorage.read(key: 'refreshTokenExpiresAt');
    if (expiryValue == null) {
      return null;
    }
    return DateTime.tryParse(expiryValue);
  }

  static Future<bool> checkAuthentication() async {
    const secureStorage = SecureStorageService.instance;
    final accessToken = await secureStorage.read(key: 'accessToken');
    final tokenExpiry = await secureStorage.read(key: 'tokenExpiresAt');

    logger.info('Checking authentication');
    logger.info('tokenExpiresAt: $tokenExpiry');

    if (accessToken == null || tokenExpiry == null) {
      if (kDebugMode) debugPrint('User is not logged in');
      return false;
    }

    final expiryDateTime = DateTime.tryParse(tokenExpiry);
    if (expiryDateTime == null) {
      if (kDebugMode) debugPrint('User is not logged in');
      return false;
    }

    if (expiryDateTime.isAfter(DateTime.now())) {
      if (kDebugMode) debugPrint('User is logged in');
      return true;
    }

    if (kDebugMode) debugPrint('User is not logged in');
    return false; // User is not logged in
  }
}
