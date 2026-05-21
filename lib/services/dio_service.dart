import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
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
