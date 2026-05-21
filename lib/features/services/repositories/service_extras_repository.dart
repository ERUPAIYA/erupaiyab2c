import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';
import '../../home/models/banner_model.dart';
import '../../mobile_prepaid/models/latest_transaction.dart';

class ServiceExtrasRepository {
  ServiceExtrasRepository({Dio? dio}) : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  Future<List<BannerModel>> fetchPageBanners({
    required String slug,
    String lang = 'en',
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.pageEndpoint(slug),
        queryParameters: {'lang': lang},
      );

      final raw = response.data;
      final Map<String, dynamic> payload;
      if (raw is Map<String, dynamic>) {
        payload = raw;
      } else if (raw is String) {
        payload = jsonDecode(raw) as Map<String, dynamic>;
      } else {
        payload = Map<String, dynamic>.from(raw as Map);
      }

      final ok = (payload['success'] == true) || (payload['status'] == true);
      if (!ok) {
        final message =
            payload['message'] as String? ?? 'Failed to fetch banners';
        throw Exception(message);
      }

      final dataMap = payload['data'] as Map<String, dynamic>? ?? {};
      final list = dataMap['banners'];
      if (list is! List) return const <BannerModel>[];
      return list
          .whereType<Map<String, dynamic>>()
          .map(BannerModel.fromJson)
          .toList();
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch page banners',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<LatestTransaction>> fetchLatestTransactions({
    required String service,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.latestTransactionsEndpoint(service: service),
      );
      final payload = _normalizePayload(response.data);
      final data = payload['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => LatestTransaction.fromJson(
                  e.map((key, value) => MapEntry(key.toString(), value)),
                ))
            .toList();
      }
      if (data is List<dynamic>) {
        return data
            .map((e) =>
                LatestTransaction.fromJson(e as Map<String, dynamic>? ?? {}))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch latest transactions',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Map<String, dynamic> _normalizePayload(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        return {};
      }
    }
    return {};
  }
}

