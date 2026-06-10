import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import 'logger_service.dart';

class DeviceIdService {
  const DeviceIdService();

  Future<String?> getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        final androidId = android.id.trim();
        if (androidId.isNotEmpty) {
          return androidId;
        }
      }
      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        final identifier = (ios.identifierForVendor ?? '').trim();
        if (identifier.isNotEmpty) {
          return identifier;
        }
      }
    } catch (e, stackTrace) {
      logger.error('Failed to resolve stable device ID', error: e, stackTrace: stackTrace);
    }
    return null;
  }
}
