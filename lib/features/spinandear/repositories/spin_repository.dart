import 'dart:math';

import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';

class SpinRepository {
  SpinRepository({Dio? dio}) : _dio = dio ?? DioService.instance.client;

  final Dio _dio;
  final Random _random = Random.secure();

  /// Returns a map of category → list of coin values.
  /// e.g. {"Normal": [2,4,6,8], "Jackpot Spin": [25,50,75,100]}
  Future<Map<String, List<int>>> fetchSpinOptions() async {
    try {
      final response = await _dio.get(ApiConstants.spinOptionsEndpoint);
      final payload = response.data as Map<String, dynamic>? ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      return data.map((key, value) {
        final list = (value as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            [];
        return MapEntry(key, list);
      });
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch spin options',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String _generateUuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String toHex(int value) => value.toRadixString(16).padLeft(2, '0');
    final hex = bytes.map(toHex).toList();

    return '${hex.sublist(0, 4).join()}'
        '${hex.sublist(4, 6).join()}-'
        '${hex.sublist(6, 8).join()}-'
        '${hex.sublist(8, 10).join()}-'
        '${hex.sublist(10, 16).join()}';
  }

  Future<void> recordSpin({
    required String spinType,
  }) async {
    try {
      final data = <String, dynamic>{
        'spin_type': spinType,
        'idempotency_key': _generateUuid(),
      };

      await _dio.post(
        ApiConstants.spinEndpoint,
        data: data,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to record spin',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
