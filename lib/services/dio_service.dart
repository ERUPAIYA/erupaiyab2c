import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

import '../constants/api_constants.dart';
import '../config/app_env.dart';
import '../config/ssl_pinning_config.dart';
import 'dio_interceptors.dart';

class DioService {
  // Private static instance
  static DioService? _instance;

  // Private late Dio instance
  late Dio _dio;

  // Private constructor
  DioService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        // NOTE: These values are meant to be in milliseconds.
        // Using seconds here causes requests to appear "stuck" (e.g. check-login)
        // for a very long time on slow / interrupted networks.
        connectTimeout: const Duration(milliseconds: 5000),
        sendTimeout: const Duration(milliseconds: 5000),
        receiveTimeout: const Duration(milliseconds: 15000),
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
