import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';

class BankAccountRepository {
  BankAccountRepository({Dio? dio}) : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  Future<BankVerifyResponse> verifyBank({
    required String accountNo,
    required String ifsc,
    String? bankName,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.bankVerifyEndpoint,
        data: {
          'account_no': accountNo,
          'ifsc': ifsc,
          if (bankName != null && bankName.trim().isNotEmpty)
            'bank_name': bankName.trim(),
        },
      );
      final payload = _asMap(response.data);
      return BankVerifyResponse.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to verify bank account',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<BankAddResponse> addBank({
    required String userId,
    required String accountNo,
    required String ifsc,
    required String accountHolderName,
    required String bankName,
    required String referenceId,
    String? branchName,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.bankAddEndpoint,
        data: {
          'user_id': userId,
          'account_no': accountNo,
          'ifsc': ifsc,
          'account_holder_name': accountHolderName,
          'bank_name': bankName,
          'reference_id': referenceId,
          if (branchName != null && branchName.isNotEmpty)
            'branch_name': branchName,
        },
      );
      final payload = _asMap(response.data);
      return BankAddResponse.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to add bank account',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<BankAddResponse> updateBank({
    required int bankId,
    required String referenceId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.bankEditEndpoint,
        data: {
          'bank_id': bankId,
          'reference_id': referenceId,
        },
      );
      final payload = _asMap(response.data);
      return BankAddResponse.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to update bank account',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<BankListResponse> fetchBanks() async {
    try {
      final response = await _dio.get(ApiConstants.bankListEndpoint);
      final payload = _asMap(response.data);
      return BankListResponse.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch bank list',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

class BankVerifyResponse {
  const BankVerifyResponse({
    required this.status,
    required this.message,
    required this.creditorName,
    required this.accountNumber,
    required this.ifsc,
    required this.transactionReferenceNumber,
  });

  factory BankVerifyResponse.fromJson(Map<String, dynamic> json) {
    return BankVerifyResponse(
      status: json['status'],
      message: (json['message'] ?? '').toString(),
      creditorName: (json['creditorName'] ?? '').toString(),
      accountNumber: (json['accountNumber'] ?? '').toString(),
      ifsc: (json['ifsc'] ?? '').toString(),
      transactionReferenceNumber:
          (json['transactionReferenceNumber'] ?? '').toString(),
    );
  }

  final Object? status;
  final String message;
  final String creditorName;
  final String accountNumber;
  final String ifsc;
  final String transactionReferenceNumber;

  bool get isSuccess {
    if (status is bool) return status as bool;
    final normalized = status?.toString().trim().toLowerCase() ?? '';
    return normalized == 'success' || normalized == 'true';
  }
}

class BankAddResponse {
  const BankAddResponse({
    required this.status,
    required this.message,
    required this.accountNumber,
  });

  factory BankAddResponse.fromJson(Map<String, dynamic> json) {
    return BankAddResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      accountNumber: (json['account_number'] ?? '').toString(),
    );
  }

  final bool status;
  final String message;
  final String accountNumber;
}

class BankListResponse {
  const BankListResponse({
    required this.status,
    required this.code,
    required this.message,
    required this.popularBanks,
    required this.allBanks,
  });

  factory BankListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final dataMap = data is Map<String, dynamic> ? data : <String, dynamic>{};
    return BankListResponse(
      status: json['status'] == true,
      code: json['code'] is int
          ? json['code'] as int
          : int.tryParse(json['code']?.toString() ?? '') ?? 0,
      message: (json['message'] ?? '').toString(),
      popularBanks: _parseBankList(dataMap['popular_banks']),
      allBanks: _parseBankList(dataMap['all_banks']),
    );
  }

  final bool status;
  final int code;
  final String message;
  final List<BankListItem> popularBanks;
  final List<BankListItem> allBanks;
}

class BankListItem {
  const BankListItem({
    required this.id,
    required this.bankName,
    required this.bankCode,
    this.logoUrl,
  });

  factory BankListItem.fromJson(Map<String, dynamic> json) {
    return BankListItem(
      id: (json['id'] ?? '').toString(),
      bankName: (json['bank_name'] ?? '').toString(),
      bankCode: (json['bank_code'] ?? '').toString(),
      logoUrl: _readFirstString(
        json,
        [
          'logo',
          'icon',
          'image',
          'bank_logo',
          'bank_icon',
          'bank_logo_url',
          'bank_image',
        ],
      ),
    );
  }

  final String id;
  final String bankName;
  final String bankCode;
  final String? logoUrl;
}

List<BankListItem> _parseBankList(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BankListItem.fromJson)
        .toList();
  }
  return const <BankListItem>[];
}

String? _readFirstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

Map<String, dynamic> _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is String && data.isNotEmpty) {
    final decoded = jsonDecode(data);
    if (decoded is Map<String, dynamic>) return decoded;
  }
  return <String, dynamic>{};
}
