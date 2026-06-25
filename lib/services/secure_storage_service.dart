import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const FlutterSecureStorage instance = FlutterSecureStorage(
    aOptions: _androidOptions,
  );
}
