import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/home/models/quick_actions_model.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';
import '../models/banner_model.dart';
import '../models/bill_reminder_model.dart';
import '../models/credit_card_item.dart';
import '../models/quick_action_model.dart';

class HomeRepository {
  HomeRepository({Dio? dio}) : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  Future<List<BannerModel>> fetchExploreAllServicesBanners({
    String lang = 'en',
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.pageEndpoint('explore-all-services'),
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
    } catch (e) {
      logger.error('Failed to fetch explore all services banners: $e', error: e);
      rethrow;
    }
  }

  Future<
      ({
        List<QuickActionCategory> categories,
        Map<String, List<BannerModel>> banners,
        bool? isNameEmailExist,
      })> fetchQuickActions({String? search}) async {
    try {
      final response = await _dio.get(
        ApiConstants.quickActionsEndpoint,
        queryParameters:
            (search == null || search.isEmpty) ? null : {'search': search},
      );
      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message =
            payload?['message'] as String? ?? 'Failed to fetch quick actions';
        throw Exception(message);
      }
      final dataMap = payload?['data'] as Map<String, dynamic>? ?? {};
      final categories = <QuickActionCategory>[];
      final banners = <String, List<BannerModel>>{};
      bool? isNameEmailExist;

      dataMap.forEach((key, value) {
        if (key == 'banners' && value is Map<String, dynamic>) {
          value.forEach((bKey, bValue) {
            if (bValue is List) {
              banners[bKey] = bValue
                  .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          });
        } else if (key == 'is_name_email_exist') {
          final normalized = (value ?? '').toString().trim().toLowerCase();
          if (normalized.isEmpty) return;
          isNameEmailExist =
              normalized == '1' || normalized == 'true' || normalized == 'yes';
        } else if (key != 'banners' && value is Map<String, dynamic>) {
          categories.add(QuickActionCategory.fromJson(value));
        }
      });

      return (
        categories: categories,
        banners: banners,
        isNameEmailExist: isNameEmailExist
      );
    } catch (e) {
      logger.error('Failed to fetch quick actions: $e', error: e);
      rethrow;
    }
  }

  Future<QuickActionModel> fetchAllQuickAction(String userId) async {
    try {
      final response = await _dio.get(
        ApiConstants.quickActionsDueEndpoint,
        queryParameters: {'user_id': userId},
      );

      final payload = response.data;
      Map<String, dynamic> json;
      if (payload is String) {
        json = jsonDecode(payload) as Map<String, dynamic>;
      } else if (payload is Map<String, dynamic>) {
        json = payload;
      } else {
        json = Map<String, dynamic>.from(payload as Map);
      }
      return QuickActionModel.fromJson(json);
    } catch (e) {
      logger.error('Failed to fetch all quick actions: $e', error: e);
      rethrow;
    }
  }

  Future<List<CreditCardItem>> fetchCreditCardActions(String userId) async {
    try {
      final response = await _dio.get(ApiConstants.myCardsEndpoint);
      final payload = response.data;
      Map<String, dynamic> json;
      if (payload is String) {
        json = jsonDecode(payload) as Map<String, dynamic>;
      } else if (payload is Map<String, dynamic>) {
        json = payload;
      } else {
        json = Map<String, dynamic>.from(payload as Map);
      }
      final dataList = json['data'];
      if (dataList is List) {
        return dataList
            .whereType<Map<String, dynamic>>()
            .map(CreditCardItem.fromJson)
            .toList();
      }
      if (dataList is Map<String, dynamic>) {
        final nested = dataList['cards'];
        if (nested is List) {
          return nested
              .whereType<Map<String, dynamic>>()
              .map(CreditCardItem.fromJson)
              .toList();
        }
      }
      final alt = json['cards'];
      if (alt is List) {
        return alt
            .whereType<Map<String, dynamic>>()
            .map(CreditCardItem.fromJson)
            .toList();
      }
      return const <CreditCardItem>[];
    } catch (e) {
      logger.error('Failed to fetch credit card actions: $e', error: e);
      rethrow;
    }
  }

  Future<bool> removeCreditCard(String maskedIdentifier) async {
    try {
      final response = await _dio.post(
        ApiConstants.removeCardEndpoint,
        data: {
          'masked_identifier': maskedIdentifier,
        },
      );
      final payload = response.data;
      Map<String, dynamic> json;
      if (payload is String) {
        json = jsonDecode(payload) as Map<String, dynamic>;
      } else if (payload is Map<String, dynamic>) {
        json = payload;
      } else {
        json = Map<String, dynamic>.from(payload as Map);
      }
      return json['success'] == true;
    } catch (e) {
      logger.error('Failed to remove credit card: $e', error: e);
      rethrow;
    }
  }

  Future<BillReminderResponse> fetchBillReminders({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.billRemindersEndpoint,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      final payload = response.data;
      Map<String, dynamic> json;
      if (payload is String) {
        json = jsonDecode(payload) as Map<String, dynamic>;
      } else if (payload is Map<String, dynamic>) {
        json = payload;
      } else {
        json = Map<String, dynamic>.from(payload as Map);
      }
      return BillReminderResponse.fromJson(json);
    } catch (e) {
      logger.error('Failed to fetch bill reminders: $e', error: e);
      rethrow;
    }
  }

  Future<List<Data>> fetchRechargeActions(String userId) async {
    try {
      final response = await _dio.get(
        ApiConstants.quickActionsDueEndpoint,
        queryParameters: {
          'user_id': userId,
          'payment_type': 'RECHARGE',
        },
      );
      final payload = response.data;
      Map<String, dynamic> json;
      if (payload is String) {
        json = jsonDecode(payload) as Map<String, dynamic>;
      } else if (payload is Map<String, dynamic>) {
        json = payload;
      } else {
        json = Map<String, dynamic>.from(payload as Map);
      }
      return QuickActionModel.fromJson(json).data ?? [];
    } catch (e) {
      logger.error('Failed to fetch recharge actions: $e', error: e);
      rethrow;
    }
  }
}
