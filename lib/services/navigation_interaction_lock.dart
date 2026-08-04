import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final navigationInteractionLockProvider =
    Provider<NavigationInteractionLock>((ref) {
  final lock = NavigationInteractionLock();
  ref.onDispose(lock.dispose);
  return lock;
});

class NavigationInteractionLock extends NavigatorObserver with ChangeNotifier {
  static const _fallbackDuration = Duration(milliseconds: 450);
  static const _settleBuffer = Duration(milliseconds: 120);

  Timer? _unlockTimer;
  bool _isLocked = false;

  bool get isLocked => _isLocked;

  void _setLocked(bool value) {
    if (_isLocked == value) return;
    _isLocked = value;
    notifyListeners();
  }

  Duration _forwardDurationFor(Route<dynamic>? route) {
    if (route is TransitionRoute<dynamic>) {
      return route.transitionDuration;
    }
    return _fallbackDuration;
  }

  Duration _reverseDurationFor(Route<dynamic>? route) {
    if (route is TransitionRoute<dynamic>) {
      return route.reverseTransitionDuration;
    }
    return _fallbackDuration;
  }

  void _lockFor(Duration duration) {
    _unlockTimer?.cancel();
    _setLocked(true);
    _unlockTimer = Timer(duration + _settleBuffer, () {
      _setLocked(false);
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _lockFor(_forwardDurationFor(route));
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _lockFor(_forwardDurationFor(newRoute ?? oldRoute));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _lockFor(_reverseDurationFor(route));
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    super.didStartUserGesture(route, previousRoute);
    _unlockTimer?.cancel();
    _setLocked(true);
  }

  @override
  void didStopUserGesture() {
    super.didStopUserGesture();
    _lockFor(_fallbackDuration);
  }

  @override
  void dispose() {
    _unlockTimer?.cancel();
    super.dispose();
  }
}
