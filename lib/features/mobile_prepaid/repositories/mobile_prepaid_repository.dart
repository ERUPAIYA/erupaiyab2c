import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';
import '../models/operator_info.dart';
import '../models/operator_option.dart';
import '../models/latest_transaction.dart';
import '../models/my_number_info.dart';
import '../models/plan_item.dart';
import '../models/prepaid_transaction_status.dart';
import '../models/prepaid_plans_response.dart';
import '../models/recharge_order_result.dart';
import '../models/recharge_result.dart';
import '../models/region_option.dart';
import '../../home/models/banner_model.dart';

class MobilePrepaidRepository {
  MobilePrepaidRepository({Dio? dio})
      : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  Future<List<BannerModel>> fetchMobilePrepaidBanners({
    String lang = 'en',
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.pageEndpoint('mobile-prepaid'),
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
        'Failed to fetch mobile prepaid banners',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<MyNumberInfo> fetchMyNumber({
    required String number,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.rechargeMyNumberEndpoint,
        queryParameters: {'number': number},
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
            payload['message'] as String? ?? 'Failed to fetch my number';
        throw Exception(message);
      }

      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        final info = MyNumberInfo.fromJson(data);
        if (info.number.trim().isNotEmpty) return info;
      }
      return MyNumberInfo(number: number);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch my number',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<OperatorInfo> checkOperator({required String mobile}) async {
    try {
      final response = await _dio.post(
        ApiConstants.prepaidCheckOperatorEndpoint,
        data: {'mobile': mobile},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      final payload = _normalizePayload(response.data);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      return OperatorInfo.fromJson(data);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to check operator',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<PrepaidPlansResponse> fetchPlans({
    required String mobile,
    required String operatorName,
    required String circleCode,
    List<String> filters = const [],
  }) async {
    try {
      final normalizedFilters = filters
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final response = await _dio.post(
        ApiConstants.prepaidFetchPlansEndpoint,
        data: {
          'mobile': mobile,
          'operator': operatorName,
          'circlecode': circleCode,
          if (normalizedFilters.isNotEmpty)
            'filter': normalizedFilters.length == 1
                ? normalizedFilters.first
                : jsonEncode(normalizedFilters),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      final payload = _normalizePayload(response.data);
      final data = payload['data'] as Map<String, dynamic>? ?? {};

      final filtersMap = payload['filters'] as Map<String, dynamic>? ?? {};
      final validityFilters = (filtersMap['validity'] is List)
          ? (filtersMap['validity'] as List)
              .map((e) => e.toString())
              .toList()
          : const <String>[];
      final dataFilters = (filtersMap['data'] is List)
          ? (filtersMap['data'] as List).map((e) => e.toString()).toList()
          : const <String>[];
      final filterTags = (payload['filterTags'] is List)
          ? (payload['filterTags'] as List).map((e) => e.toString()).toList()
          : normalizedFilters;

      final result = <String, List<PlanItem>>{};
      data.forEach((key, value) {
        if (value is List) {
          result[key] = value
              .map((item) =>
                  PlanItem.fromJson(item as Map<String, dynamic>? ?? {}))
              .toList();
        }
      });
      return PrepaidPlansResponse(
        plansByCategory: result,
        validityFilters: validityFilters,
        dataFilters: dataFilters,
        filterTags: filterTags,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch plans',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<OperatorOption>> fetchOperators() async {
    try {
      final response = await _dio.get(
        ApiConstants.prepaidFetchOperatorsEndpoint,
      );
      final payload = _normalizePayload(response.data);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      final operators = data['operators'];
      if (operators is List) {
        return operators
            .map((item) =>
                OperatorOption.fromJson(item as Map<String, dynamic>? ?? {}))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch operators',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<RegionOption>> fetchRegions() async {
    try {
      final response = await _dio.get(
        ApiConstants.prepaidFetchRegionsEndpoint,
      );
      final payload = _normalizePayload(response.data);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      final regions = data['regions'];
      if (regions is List) {
        return regions
            .map((item) =>
                RegionOption.fromJson(item as Map<String, dynamic>? ?? {}))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch regions',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<RechargeResult> recharge({
    required String mobile,
    required int amount,
    required String operatorName,
    required String desc,
    String? referenceId,
    int useWallet = 0,
    double? walletAmount,
    double? razorpayAmount,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.prepaidRechargeEndpoint,
        data: {
          'mobile': mobile,
          'amount': amount.toString(),
          'operator': operatorName,
          'desc': desc,
          'use_wallet': useWallet.toString(),
          if (walletAmount != null)
            'wallet_amount': walletAmount.toStringAsFixed(2),
          if (razorpayAmount != null)
            'razorpay_amount': razorpayAmount.toStringAsFixed(2),
          // if (referenceId != null && referenceId.isNotEmpty)
          'reference_id': referenceId,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      final statusValue =
          payload['status'] ?? payload['code'] ?? payload['error'];
      final statusText = statusValue?.toString() ?? '';
      final message = _extractRechargeMessage(payload);
      final isSuccess = _isRechargeSuccess(statusValue, statusText);
      final transactionId = (payload['transaction_id'] ??
              payload['transactionId'] ??
              payload['transaction_id'.toUpperCase()] ??
              '')
          .toString()
          .trim();
      final dateTime =
          (payload['dateDate'] ?? payload['date_time'] ?? payload['date'] ?? '')
              .toString()
              .trim();

      return RechargeResult(
        status: statusText,
        message: message.isNotEmpty
            ? message
            : (isSuccess ? 'Recharge completed.' : 'Recharge failed.'),
        transactionId: transactionId,
        dateTime: dateTime,
        isSuccess: isSuccess,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to recharge',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<RechargeOrderResult> createRechargeOrder({
    required String mobile,
    required int amount,
    required String operatorName,
    required String desc,
    double walletAmount = 0,
    double razorpayAmount = 0,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.rechargeCreateOrderEndpoint,
        data: {
          'mobile': mobile,
          'amount': amount.toDouble().toStringAsFixed(2),
          'operator': operatorName,
          'wallet_amount': walletAmount.toStringAsFixed(2),
          'razorpay_amount': razorpayAmount.toStringAsFixed(2),
          'desc': desc,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return RechargeOrderResult.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to create recharge order',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<PrepaidTransactionStatus> fetchTransactionStatus({
    required String transactionId,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.transactionStatusEndpoint(transactionId),
        options: Options(
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return PrepaidTransactionStatus.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch prepaid transaction status',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<PrepaidTransactionStatus> fetchRechargeStatus({
    required String transactionId,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.rechargeStatusEndpoint(transactionId),
        options: Options(
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return PrepaidTransactionStatus.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch recharge status',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  bool _isRechargeSuccess(Object? statusValue, String statusText) {
    final normalized = statusText.toLowerCase();
    if (normalized == 'success' || normalized == 'ok' || normalized == 'true') {
      return true;
    }
    if (normalized == 'failed' || normalized == 'failure') return false;
    if (statusValue is int) {
      return statusValue >= 200 && statusValue < 300;
    }
    final parsed = int.tryParse(statusText);
    if (parsed != null) {
      return parsed >= 200 && parsed < 300;
    }
    return false;
  }

  String _extractRechargeMessage(Map<String, dynamic> payload) {
    final messages = payload['messages'];
    if (messages is Map) {
      final err = messages['error']?.toString().trim() ?? '';
      if (err.isNotEmpty) return err;
    }

    final direct =
        (payload['message'] ?? payload['msg'] ?? payload['error'] ?? '')
            .toString()
            .trim();
    if (direct.isNotEmpty) return direct;
    return '';
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
      return data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {
        return {};
      }
    }
    return {};
  }
}
