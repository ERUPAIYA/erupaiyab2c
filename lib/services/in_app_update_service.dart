import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';

import '../config/app_env.dart';

void _debugLog(String message) {
  if (!AppEnv.enableLogs || !kDebugMode) return;
  debugPrint(message);
}

class InAppUpdateService {
  const InAppUpdateService._();

  static bool _hasChecked = false;

  static Future<void> checkForImmediateUpdate() async {
    if (_hasChecked || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _hasChecked = true;

    try {
      final info = await InAppUpdate.checkForUpdate();
      _debugLog(
        'in_app_update: availability=${info.updateAvailability} immediateAllowed=${info.immediateUpdateAllowed} installStatus=${info.installStatus}',
      );

      final shouldStartImmediateUpdate =
          info.updateAvailability == UpdateAvailability.updateAvailable &&
              info.immediateUpdateAllowed;
      final shouldResumeImmediateUpdate =
          info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress;

      if (shouldStartImmediateUpdate || shouldResumeImmediateUpdate) {
        await InAppUpdate.performImmediateUpdate();
      }
    } on PlatformException catch (e) {
      _debugLog(
        'in_app_update failed: code=${e.code} message=${e.message ?? ""}',
      );
    } catch (e) {
      _debugLog('in_app_update failed: $e');
    }
  }
}
