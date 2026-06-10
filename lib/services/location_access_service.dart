import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/storage_keys.dart';
import '../config/app_env.dart';

void _debugLog(String message) {
  if (!AppEnv.enableLogs) return;
  debugPrint(message);
}

class LocationAccessService {
  LocationAccessService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<bool> isEnabledPreference() async {
    final value = await _storage.read(key: StorageKeys.locationAccessEnabled);
    if (value == null) return true; // default enabled
    return value == '1' || value.toLowerCase() == 'true';
  }

  static Future<void> setEnabledPreference(bool enabled) async {
    await _storage.write(
      key: StorageKeys.locationAccessEnabled,
      value: enabled ? '1' : '0',
    );
  }

  static Future<bool> isPermissionGranted() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  static Future<bool> isLocationAccessActive() async {
    final enabled = await isEnabledPreference();
    if (!enabled) return false;
    return isPermissionGranted();
  }

  /// Tries to enable location:
  /// - Requests permission if needed
  /// - Returns `true` when permission is granted and preference is enabled
  static Future<bool> enableWithPermissionRequest() async {
    await setEnabledPreference(true);

    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      _debugLog('Location permission is permanently denied/restricted');
      return false;
    }

    final result = await Permission.locationWhenInUse.request();
    _debugLog('Location permission request result: $result');
    return result.isGranted;
  }

  /// Disables location usage in-app (cannot revoke OS permission).
  static Future<void> disable() async {
    await setEnabledPreference(false);
  }
}
