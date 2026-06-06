import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';

class PaymentDeviceContextService {
  const PaymentDeviceContextService();

  Future<Map<String, dynamic>> collect() async {
    final now = DateTime.now();
    final deviceId = await _deviceId();
    final vpn = await _isVpnLikely();
    final rooted = await _isRootedLikely();
    final location = await _safeLocation();

    return <String, dynamic>{
      'latitude': location.latitude,
      'longitude': location.longitude,
      'isMock': location.isMocked,
      'isVpn': vpn,
      'isRooted': rooted,
      'deviceId': deviceId,
      'device_id': deviceId,
      'timestamp': now.millisecondsSinceEpoch.toString(),
    };
  }

  Future<String> _deviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        final androidId = android.id;
        if (androidId.trim().isNotEmpty) {
          return androidId.trim();
        }
        return android.id.toString();
      }
      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return (ios.identifierForVendor ?? ios.name).toString();
      }
    } catch (_) {}
    return '';
  }

  Future<bool> _isVpnLikely() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: true,
      );
      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        if (name.contains('tun') ||
            name.contains('ppp') ||
            name.contains('ipsec') ||
            name.contains('utun') ||
            name.contains('wg')) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _isRootedLikely() async {
    try {
      if (Platform.isAndroid) {
        const paths = <String>[
          '/system/app/Superuser.apk',
          '/sbin/su',
          '/system/bin/su',
          '/system/xbin/su',
          '/data/local/xbin/su',
          '/data/local/bin/su',
          '/system/sd/xbin/su',
          '/system/bin/failsafe/su',
          '/data/local/su',
        ];
        for (final path in paths) {
          if (File(path).existsSync()) return true;
        }
      }
      if (Platform.isIOS) {
        const paths = <String>[
          '/Applications/Cydia.app',
          '/Library/MobileSubstrate/MobileSubstrate.dylib',
          '/bin/bash',
          '/usr/sbin/sshd',
          '/etc/apt',
        ];
        for (final path in paths) {
          if (File(path).existsSync()) return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<_LocationSnapshot> _safeLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return const _LocationSnapshot.empty();

      final permission = await Geolocator.checkPermission();
      // Do not request permission here; payment should never be blocked by a
      // permission prompt/denial. Just send empty coordinates if unavailable.
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const _LocationSnapshot.empty();
      }

      // Prefer last-known position to avoid blocking the payment flow.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return _LocationSnapshot(
          latitude: last.latitude.toString(),
          longitude: last.longitude.toString(),
          isMocked: last.isMocked,
        );
      }

      // Fall back to current position with a tight timeout.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 2),
      );
      return _LocationSnapshot(
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
        isMocked: position.isMocked,
      );
    } catch (_) {
      return const _LocationSnapshot.empty();
    }
  }
}

class _LocationSnapshot {
  const _LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.isMocked,
  });

  const _LocationSnapshot.empty()
      : latitude = '',
        longitude = '',
        isMocked = false;

  final String latitude;
  final String longitude;
  final bool isMocked;
}
