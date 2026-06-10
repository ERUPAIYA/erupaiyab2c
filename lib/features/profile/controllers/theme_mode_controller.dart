import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/storage_keys.dart';

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  ThemeMode build() {
    _restoreThemeMode();
    return ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(
      key: StorageKeys.themeMode,
      value: mode.name,
    );
  }

  Future<void> _restoreThemeMode() async {
    final savedMode = await _storage.read(key: StorageKeys.themeMode);
    if (savedMode == null || savedMode.isEmpty) return;
    state = switch (savedMode) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }
}
