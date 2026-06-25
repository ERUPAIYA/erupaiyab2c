import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

import '../constants/api_constants.dart';
import '../config/app_env.dart';
import '../config/ssl_pinning_config.dart';
import 'dio_interceptors.dart';

class DioService {
  static const Duration _defaultConnectTimeout = Duration(seconds: 15);
  static const Duration _defaultSendTimeout = Duration(seconds: 15);
  static const Duration _defaultReceiveTimeout = Duration(seconds: 30);

  // Private static instance
  static DioService? _instance;

  // Private late Dio instance
  late Dio _dio;

  // Private constructor
  DioService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: _defaultConnectTimeout,
        sendTimeout: _defaultSendTimeout,
        receiveTimeout: _defaultReceiveTimeout,
      ),
    );
    final host = Uri.tryParse(ApiConstants.baseUrl)?.host.trim().toLowerCase();
    final shouldEnablePinning =
        (!SslPinningConfig.enableInProductionOnly || AppEnv.isProduction) &&
            !kIsWeb &&
            host != null &&
            host.isNotEmpty &&
            SslPinningConfig.allowedHosts.contains(host) &&
            SslPinningConfig.sha256Fingerprints.isNotEmpty;
    if (shouldEnablePinning) {
      _dio.interceptors.add(
        CertificatePinningInterceptor(
          allowedSHAFingerprints: SslPinningConfig.sha256Fingerprints,
          timeout: 50,
        ),
      );
    }
    _dio.interceptors.add(DioInterceptors());
  }

  // Singleton getter
  static DioService get instance {
    _instance ??= DioService._internal();
    return _instance!;
  }

  // Getter for the Dio client
  Dio get client => _dio;
}
