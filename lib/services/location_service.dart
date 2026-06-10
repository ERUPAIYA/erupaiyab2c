import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/app_env.dart';
import 'logger_service.dart';

void _debugLog(String message) {
  if (!AppEnv.enableLogs) return;
  debugPrint(message);
}

class LocationService {
  LocationService._();

  static Future<void> initialize({bool requestPermission = true}) async {
    if (!requestPermission) return;
    await _requestPermission();
  }

  static Future<void> _requestPermission() async {
    final status = await Permission.locationWhenInUse.status;

    if (status.isGranted) {
      logger.info('Location permission already granted');
      return;
    }

    if (status.isPermanentlyDenied) {
      _debugLog('Location permission permanently denied');
      logger.info('Location permission permanently denied');
      return;
    }

    final result = await Permission.locationWhenInUse.request();

    final message = 'Location permission result: $result';
    _debugLog(message);
    logger.info(message);

    if (Platform.isAndroid && result.isGranted) {
      // Request precise location on Android 12+ (API 31+)
      final precise = await Permission.locationAlways.status;
      _debugLog('Precise location status: $precise');
    }
  }
}
