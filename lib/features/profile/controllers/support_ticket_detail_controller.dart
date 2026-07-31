import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/support_ticket_detail.dart';
import '../repositories/support_tickets_repository.dart';
import 'support_tickets_controller.dart';

class SupportTicketDetailState {
  const SupportTicketDetailState({
    this.isLoading = false,
    this.isReplying = false,
    this.isClosing = false,
    this.errorMessage,
    this.ticket,
  });

  final bool isLoading;
  final bool isReplying;
  final bool isClosing;
  final String? errorMessage;
  final SupportTicketDetail? ticket;

  SupportTicketDetailState copyWith({
    bool? isLoading,
    bool? isReplying,
    bool? isClosing,
    String? errorMessage,
    SupportTicketDetail? ticket,
  }) {
    return SupportTicketDetailState(
      isLoading: isLoading ?? this.isLoading,
      isReplying: isReplying ?? this.isReplying,
      isClosing: isClosing ?? this.isClosing,
      errorMessage: errorMessage,
      ticket: ticket ?? this.ticket,
    );
  }
}

final supportTicketDetailControllerProvider = StateNotifierProvider.family<
    SupportTicketDetailController, SupportTicketDetailState, String>(
  (ref, ticketId) => SupportTicketDetailController(
    ticketId: ticketId,
    repository: ref.watch(supportTicketsRepositoryProvider),
    ref: ref,
  ),
);

class SupportTicketDetailController
    extends StateNotifier<SupportTicketDetailState> {
  SupportTicketDetailController({
    required String ticketId,
    required SupportTicketsRepository repository,
    required Ref ref,
  })  : _ticketId = ticketId,
        _repository = repository,
        _ref = ref,
        super(const SupportTicketDetailState());

  final String _ticketId;
  final SupportTicketsRepository _repository;
  final Ref _ref;

  Future<void> fetch() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final detail = await _repository.fetchTicketDetail(_ticketId);
      state = state.copyWith(isLoading: false, ticket: detail);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load ticket details. Please try again.',
      );
    }
  }

  Future<bool> reply({
    required String reason,
    required String message,
    File? screenshot,
  }) async {
    if (state.isReplying) return false;
    state = state.copyWith(isReplying: true, errorMessage: null);
    try {
      final ok = await _repository.reply(
        ticketId: _ticketId,
        reason: reason,
        message: message,
        screenshot: screenshot,
      );
      state = state.copyWith(isReplying: false);
      await fetch();
      _ref.read(supportTicketsControllerProvider.notifier).fetchTickets();
      return ok;
    } catch (_) {
      state = state.copyWith(
        isReplying: false,
        errorMessage: 'Unable to send reply. Please try again.',
      );
      return false;
    }
  }

  Future<bool> closeTicket() async {
    if (state.isClosing) return false;
    state = state.copyWith(isClosing: true, errorMessage: null);
    try {
      final ok = await _repository.closeTicket(ticketId: _ticketId);
      state = state.copyWith(isClosing: false);
      await fetch();
      _ref.read(supportTicketsControllerProvider.notifier).fetchTickets();
      return ok;
    } catch (_) {
      state = state.copyWith(
        isClosing: false,
        errorMessage: 'Unable to close ticket. Please try again.',
      );
      return false;
    }
  }

  Future<bool> reopenTicketWithReason({
    required String reason,
    File? screenshot,
  }) async {
    if (state.isClosing) return false;
    state = state.copyWith(isClosing: true, errorMessage: null);
    try {
      final ok = await _repository.reopenTicket(
        ticketId: _ticketId,
        reason: reason,
        screenshot: screenshot,
      );
      state = state.copyWith(isClosing: false);
      await fetch();
      _ref.read(supportTicketsControllerProvider.notifier).fetchTickets();
      return ok;
    } catch (_) {
      state = state.copyWith(
        isClosing: false,
        errorMessage: 'Unable to reopen ticket. Please try again.',
      );
      return false;
    }
  }
}
