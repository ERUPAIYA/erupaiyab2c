// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:e_rupaiya/core/barrel_file.dart';
import 'package:flutter/foundation.dart';

import '../../../constants/api_constants.dart';
import '../models/digital_gold_dashboard.dart';
import '../models/digital_gold_otp_response.dart';
import '../models/digital_gold_preview.dart';
import '../models/digital_gold_purchase_receipt.dart';
import '../models/digital_gold_summary.dart';
import '../models/recent_purchase.dart';

final digitalGoldRepoProvider = Provider<DigitalGoldRepo>(
  (ref) => DigitalGoldRepo(),
);

final recentPurchasesProvider =
    FutureProvider<RecentPurchasesResponse>((ref) async {
  final repo = ref.watch(digitalGoldRepoProvider);
  return repo.fetchRecentPurchases();
});

final goldBalanceProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(digitalGoldRepoProvider);
  try {
    final response = await repo.fetchProceedPreview(
      calculationType: 'A', // Amount based
      amount: '1', // Minimal amount
      quantity: '1',
      metalType: 'G', // Gold
    );
    return response.myGoldBalance;
  } catch (e) {
    // Return 0 if unable to fetch
    return 0.0;
  }
});

final digitalGoldDashboardProvider =
    FutureProvider<DigitalGoldDashboard>((ref) async {
  final repo = ref.watch(digitalGoldRepoProvider);
  return repo.fetchDashboard();
});

final digitalGoldSummaryProvider = FutureProvider.autoDispose
    .family<DigitalGoldSummary, DigitalGoldSummaryRequest>(
  (ref, request) async {
    final repo = ref.watch(digitalGoldRepoProvider);
    return repo.fetchSummary(
      weightOfGold: request.weightOfGold,
      totalPrice: request.totalPrice,
    );
  },
);

class DigitalGoldSummaryRequest {
  const DigitalGoldSummaryRequest({
    required this.weightOfGold,
    required this.totalPrice,
  });

  final String weightOfGold;
  final String totalPrice;

  @override
  bool operator ==(Object other) {
    return other is DigitalGoldSummaryRequest &&
        other.weightOfGold == weightOfGold &&
        other.totalPrice == totalPrice;
  }

  @override
  int get hashCode => Object.hash(weightOfGold, totalPrice);
}

class DigitalGoldRepo {
  DigitalGoldRepo({Dio? dio}) : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  Future<DigitalGoldDashboard> fetchDashboard() async {
    try {
      final response =
          await _dio.get(ApiConstants.digitalGoldDashboardEndpoint);
      final payload = response.data as Map<String, dynamic>? ?? {};
      if (payload['status'] == true) {
        return DigitalGoldDashboard.fromJson(payload);
      }
      final message =
          payload['message']?.toString() ?? 'Unable to fetch dashboard';
      throw Exception(message);
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString())
          : null;
      throw Exception(message ?? 'Unable to fetch dashboard');
    }
  }

  Future<DigitalGoldPreview> fetchProceedPreview({
    required String calculationType,
    required String amount,
    required String quantity,
    required String metalType,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.digitalGoldProceedEndpoint,
        data: {
          'calculation_type': calculationType,
          'amount': amount,
          'quantity': quantity,
          'metal_type': metalType,
        },
      );
      final data = response.data as Map<String, dynamic>? ?? {};
      if (data['status'] == true && data['data'] is Map<String, dynamic>) {
        return DigitalGoldPreview.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }
      if (data['status'] == false && data['message'] != null) {
        final message = data['message'].toString();
        throw Exception(message);
      }
      throw Exception(data['message'] ?? 'Unable to fetch preview');
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString())
          : null;
      throw Exception(message ?? 'Unable to fetch preview');
    }
  }

  Future<void> createCustomer({
    required String name,
    required String mobile,
    required String email,
    required String panNumber,
    required String billingAddressLine1,
    required String billingAddressLine2,
    required String billingCity,
    required String billingState,
    required String billingStateCode,
    required String billingZip,
    required String billingCountry,
    required String billingMobile,
    required String deliveryAddressLine1,
    required String deliveryAddressLine2,
    required String deliveryCity,
    required String deliveryState,
    required String deliveryStateCode,
    required String deliveryZip,
    required String deliveryCountry,
    required String deliveryMobile,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.digitalGoldCustomerCreateEndpoint,
        data: FormData.fromMap({
          'mobile': mobile,
          'name': name,
          'email': email,
          'pan_number': panNumber,
          'billing_address_line1': billingAddressLine1,
          'billing_address_line2': billingAddressLine2,
          'billing_city': billingCity,
          'billing_state': billingState,
          'billing_statecode': billingStateCode,
          'billing_zip': billingZip,
          'billing_country': billingCountry,
          'billing_mobile': billingMobile,
          'delivery_address_line1': deliveryAddressLine1,
          'delivery_address_line2': deliveryAddressLine2,
          'delivery_city': deliveryCity,
          'delivery_state': deliveryState,
          'delivery_statecode': deliveryStateCode,
          'delivery_zip': deliveryZip,
          'delivery_country': deliveryCountry,
          'delivery_mobile': deliveryMobile,
        }),
        options: Options(contentType: 'multipart/form-data'),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      final success = payload['success'] == true ||
          payload['status'] == true ||
          payload['status']?.toString().toLowerCase() == 'success';
      if (!success) {
        final message =
            payload['message']?.toString() ?? 'Unable to create customer';
        throw Exception(message);
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString())
          : null;
      throw Exception(message ?? 'Unable to create customer');
    }
  }

  Future<DigitalGoldOtpResponse> sendOtp({
    required String customerId,
    required String billingAddressId,
    required String quoteId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.digitalGoldSendOtpEndpoint,
        data: {
          'customer_id': customerId,
          'billing_address_id': billingAddressId,
          'quote_id': quoteId,
        },
      );
      final data = response.data as Map<String, dynamic>? ?? {};
      if (data['status'] == true && data['data'] is Map<String, dynamic>) {
        return DigitalGoldOtpResponse.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }
      if (data['status'] == false && data['message'] != null) {
        final message = data['message'].toString();
        throw Exception(message);
      }
      throw Exception(data['message'] ?? 'Unable to send OTP');
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString())
          : null;
      throw Exception(message ?? 'Unable to send OTP');
    }
  }

  Future<DigitalGoldPurchaseReceipt> buyGold({
    required String refId,
    required String billingAddressId,
    required String customerId,
    required String quoteId,
    required String stateResp,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.digitalGoldBuyEndpoint,
        data: {
          'refid': refId,
          'billing_address_id': billingAddressId,
          'customer_id': customerId,
          'quote_id': quoteId,
          'stateresp': stateResp,
          'otp': otp,
        },
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      if (payload['status'] == true) {
        final data = payload['data'];
        final dataMap =
            data is Map<String, dynamic> ? data : const <String, dynamic>{};
        return DigitalGoldPurchaseReceipt.fromApi(dataMap);
      }
      if (payload['status'] == false && payload['message'] != null) {
        final message = payload['message'].toString();
        throw Exception(message);
      }
      throw Exception(payload['message'] ?? 'Unable to buy gold');
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString())
          : null;
      throw Exception(message ?? 'Unable to buy gold');
    }
  }

  Future<DigitalGoldSummary> fetchSummary({
    required String weightOfGold,
    required String totalPrice,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.digitalGoldSummaryEndpoint,
        data: {
          'weight_of_gold': weightOfGold,
          'total_price': totalPrice,
        },
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      if (payload['status'] == true) {
        return DigitalGoldSummary.fromJson(payload);
      }
      final message =
          payload['message']?.toString() ?? 'Unable to fetch summary';
      throw Exception(message);
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString())
          : null;
      throw Exception(message ?? 'Unable to fetch summary');
    }
  }

  Future<RecentPurchasesResponse> fetchRecentPurchases() async {
    if (kDebugMode) {
      debugPrint('Fetching recent purchases...');
    }
    try {
      final response = await _dio.get(
        ApiConstants.digitalGoldRecentPurchasesEndpoint,
      );
      if (kDebugMode) {
        debugPrint('Response received: ${response.data}');
      }
      final data = response.data as Map<String, dynamic>? ?? {};
      if (data['status'] == true && data['data'] is List) {
        return RecentPurchasesResponse.fromJson(data);
      }
      if (data['status'] == false && data['message'] != null) {
        final message = data['message'].toString();
        throw Exception(message);
      }
      throw Exception(data['message'] ?? 'Unable to fetch recent purchases');
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('DioException: ${e.message}');
      }
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString())
          : null;
      throw Exception(message ?? 'Unable to fetch recent purchases');
    }
  }
}
