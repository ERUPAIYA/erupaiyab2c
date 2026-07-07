import 'dart:io';

import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';
import '../models/support_ticket.dart';
import '../models/support_ticket_detail.dart';

class SupportTicketsRepository {
  SupportTicketsRepository({Dio? dio})
      : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  Future<List<SupportTicket>> fetchTickets() async {
    try {
      final response = await _dio.get(ApiConstants.supportTicketsEndpoint);
      final payload = response.data;
      if (payload is Map) {
        final raw = payload['data'];
        if (raw is List) {
          return raw
              .map((e) => SupportTicket.fromJson(
                    (e as Map).map((k, v) => MapEntry('$k', v)),
                  ))
              .toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch support tickets',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<SupportTicketDetail?> fetchTicketDetail(String id) async {
    try {
      final response =
          await _dio.get(ApiConstants.supportTicketDetailsEndpoint(id));
      final payload = response.data;
      if (payload is Map) {
        final raw = payload['data'];
        if (raw is Map) {
          return SupportTicketDetail.fromJson(
            raw.map((k, v) => MapEntry('$k', v)),
          );
        }
      }
      return null;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch support ticket details',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> reply({
    required String ticketId,
    required String message,
    File? screenshot,
  }) async {
    try {
      final form = FormData.fromMap({
        'ticket_id': ticketId,
        'message': message,
        if (screenshot != null)
          'screenshot': await MultipartFile.fromFile(
            screenshot.path,
            filename: screenshot.uri.pathSegments.isNotEmpty
                ? screenshot.uri.pathSegments.last
                : 'screenshot.jpg',
          ),
      });
      final response = await _dio.post(
        ApiConstants.supportTicketReplyEndpoint,
        data: form,
      );
      final payload = response.data;
      if (payload is Map) {
        return payload['status'] == true || payload['success'] == true;
      }
      return true;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to reply to support ticket',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> closeTicket({
    required String ticketId,
  }) async {
    try {
      final parsedTicketId = int.tryParse(ticketId.trim());
      final response = await _dio.post(
        ApiConstants.supportTicketCloseEndpoint,
        data: {
          'ticket_id': parsedTicketId ?? ticketId,
        },
      );
      final payload = response.data;
      if (payload is Map) {
        return payload['status'] == true || payload['success'] == true;
      }
      return true;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to close support ticket',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
