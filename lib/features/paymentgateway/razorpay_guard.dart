import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../widgets/app_snackbar.dart';
import '../profile/controllers/profile_controller.dart';

class RazorpayGuard {
  static const pausedMessage =
      'Oops! Payments are paused right now. We’ll be back shortly.';
  static const loadingMessage =
      'Unable to load your profile right now. Please try again.';

  static bool isPaused(WidgetRef ref) {
    return ref.read(profileControllerProvider).profile?.isRazorpayDisabled ??
        false;
  }

  static Future<bool> ensureProfileReadyAndNotPaused(WidgetRef ref) async {
    var profileState = ref.read(profileControllerProvider);
    if (profileState.profile == null) {
      await ref.read(profileControllerProvider.notifier).fetchProfileIfNeeded();
      profileState = ref.read(profileControllerProvider);
    }

    if (profileState.profile == null) {
      AppSnackbar.show(
        loadingMessage,
        type: AppSnackbarType.warning,
      );
      return false;
    }

    if (profileState.profile!.isRazorpayDisabled) {
      AppSnackbar.show(
        pausedMessage,
        type: AppSnackbarType.warning,
      );
      return false;
    }

    return true;
  }

  static bool ensureNotPaused(WidgetRef ref) {
    if (!isPaused(ref)) return true;
    AppSnackbar.show(
      pausedMessage,
      type: AppSnackbarType.warning,
    );
    return false;
  }
}
