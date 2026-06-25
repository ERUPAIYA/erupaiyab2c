import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';

class ReferralWalletRepository {
  ReferralWalletRepository({Dio? dio})
      : _dio = dio ?? DioService.instance.client;

  final Dio _dio;
  final Random _random = Random.secure();

  Future<ReferralWalletSummary> fetchSummary() async {
    try {
      final response =
          await _dio.get(ApiConstants.referralWalletSummaryEndpoint);
      final payload = _asMap(response.data);
      return ReferralWalletSummary.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch referral wallet summary',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<WithdrawEcoinsResponse> withdrawEcoins({
    required int bankId,
    required int ecoins,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.withdrawEcoinsEndpoint,
        data: {
          'bank_id': bankId,
          'ecoins': ecoins,
          'idempotency_key': _generateUuid(),
          'operation': 'ECOINS_WITHDRAW',
        },
      );
      final payload = _asMap(response.data);
      return WithdrawEcoinsResponse.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to withdraw ecoins',
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
}

class ReferralWalletSummary {
  const ReferralWalletSummary({
    required this.status,
    required this.walletBalance,
    required this.totalEarnings,
    required this.milestones,
    required this.teamCount,
    required this.totalTeamEarnings,
    required this.myTeam,
    required this.recentReferrals,
  });

  factory ReferralWalletSummary.fromJson(Map<String, dynamic> json) {
    // Some backends wrap the payload under `data`.
    final root = (json['data'] is Map)
        ? (json['data'] as Map).map((k, v) => MapEntry(k.toString(), v))
        : json;
    final milestonesRaw = root['milestones'];
    final myTeamRaw = root['my_team'];
    final recentRaw = root['recent_referrals'];
    final milestones =
        milestonesRaw is List ? milestonesRaw : const <dynamic>[];
    final myTeam = myTeamRaw is List ? myTeamRaw : const <dynamic>[];
    final recent = recentRaw is List ? recentRaw : const <dynamic>[];
    return ReferralWalletSummary(
      status: root['status'] == true ||
          (root['status']?.toString().toUpperCase() == 'SUCCESS') ||
          (root['success'] == true),
      walletBalance: (root['wallet_balance'] ??
              root['walletBalance'] ??
              root['balance'] ??
              '')
          .toString(),
      totalEarnings: _parseInt(root['total_earnings'] ?? root['totalEarnings']),
      milestones:
          milestones.whereType<Map>().map(ReferralMilestone.fromJson).toList(),
      teamCount: _parseInt(root['team_count'] ?? root['teamCount']),
      totalTeamEarnings: _parseInt(
        root['total_team_earnings'] ?? root['totalTeamEarnings'],
      ),
      myTeam: myTeam.whereType<Map>().map(TeamMember.fromJson).toList(),
      recentReferrals:
          recent.whereType<Map>().map(RecentReferral.fromJson).toList(),
    );
  }

  final bool status;
  final String walletBalance;
  final int totalEarnings;
  final List<ReferralMilestone> milestones;
  final int teamCount;
  final int totalTeamEarnings;
  final List<TeamMember> myTeam;
  final List<RecentReferral> recentReferrals;
}

class ReferralMilestone {
  const ReferralMilestone({
    required this.targetReferrals,
    required this.rewardCoins,
    required this.completed,
    required this.status,
  });

  factory ReferralMilestone.fromJson(Map json) {
    return ReferralMilestone(
      targetReferrals: _parseInt(json['target_referrals']),
      rewardCoins: _parseInt(json['reward_coins']),
      completed: json['completed'] == true,
      status: (json['status'] ?? '').toString(),
    );
  }

  final int targetReferrals;
  final int rewardCoins;
  final bool completed;
  final String status;
}

class TeamMember {
  const TeamMember({
    required this.name,
    required this.since,
    required this.earnings,
  });

  factory TeamMember.fromJson(Map json) {
    return TeamMember(
      name: (json['name'] ?? '').toString(),
      since: (json['since'] ?? '').toString(),
      earnings: _parseInt(json['earnings']),
    );
  }

  final String name;
  final String since;
  final int earnings;
}

class RecentReferral {
  const RecentReferral({
    required this.name,
    required this.joinedMessage,
    required this.earnings,
    required this.joinedOn,
  });

  factory RecentReferral.fromJson(Map json) {
    return RecentReferral(
      name: (json['name'] ?? '').toString(),
      joinedMessage: (json['joined_message'] ?? '').toString(),
      earnings: _parseInt(json['earnings']),
      joinedOn: (json['joined_on'] ?? '').toString(),
    );
  }

  final String name;
  final String joinedMessage;
  final int earnings;
  final String joinedOn;
}

class WithdrawEcoinsResponse {
  const WithdrawEcoinsResponse({
    required this.success,
    required this.message,
  });

  factory WithdrawEcoinsResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    final success =
        status == true || status?.toString().toUpperCase() == 'SUCCESS';
    return WithdrawEcoinsResponse(
      success: success,
      message: (json['message'] ?? '').toString(),
    );
  }

  final bool success;
  final String message;
}

Map<String, dynamic> _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is String && data.isNotEmpty) {
    final decoded = jsonDecode(data);
    if (decoded is Map<String, dynamic>) return decoded;
  }
  return <String, dynamic>{};
}

int _parseInt(dynamic raw) {
  if (raw == null) return 0;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString()) ?? 0;
}
