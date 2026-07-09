// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/my_app_bar.dart';
import '../controllers/support_tickets_controller.dart';
import '../models/support_ticket.dart';

class SupportTicketsScreen extends HookConsumerWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportTicketsControllerProvider);
    final controller = ref.read(supportTicketsControllerProvider.notifier);

    useEffect(() {
      Future.microtask(controller.fetchTickets);
      return null;
    }, const []);

    final lastError = useRef<String?>(null);
    useEffect(() {
      if (state.errorMessage != null && state.errorMessage != lastError.value) {
        lastError.value = state.errorMessage;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade400,
            ),
          );
        });
      }
      return null;
    }, [state.errorMessage]);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: 'Tickets',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.fetchTickets,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
                children: [
                  Text(
                    'Open Tickets',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  SizedBox(height: 12.h),
                  if (state.isLoading && state.tickets.isEmpty)
                    Skeletonizer(
                      enabled: true,
                      child: IgnorePointer(
                        child: Column(
                          children: List.generate(
                            6,
                            (index) => Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: _TicketCard(
                                ticket: _SupportTicketSkeletons.ticket,
                                onTap: () {},
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (state.tickets.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 26.h),
                        child: Text(
                          'No tickets found',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.6),
                              ),
                        ),
                      ),
                    )
                  else
                    ...state.tickets.map(
                      (ticket) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _TicketCard(
                          ticket: ticket,
                          onTap: () => context.push(
                            RouteConstants.supportTicketDetail,
                            extra: ticket.id,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.onTap,
  });

  final SupportTicket ticket;
  final VoidCallback onTap;

  String get _title {
    final description = ticket.description.trim();
    if (description.isNotEmpty) return description;

    final issue = ticket.issueType.trim();
    if (issue.isNotEmpty) return issue;

    return 'Ticket';
  }

  String get _subtitle {
    final service =
        ticket.service.trim().isEmpty ? 'Service' : ticket.service.trim();
    final date = _formatDate(ticket.createdAtRaw);
    if (date.isEmpty) return service;
    return '$service  •  $date';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            _TicketStatusChip(status: ticket.status),
          ],
        ),
      ),
    );
  }
}

class _SupportTicketSkeletons {
  const _SupportTicketSkeletons._();

  static const ticket = SupportTicket(
    id: '0',
    transactionId: '',
    service: 'BBPS',
    issueType: 'Recharge',
    isTransactionRelated: true,
    description: '',
    status: 'Open',
    createdAtRaw: '2026-01-01 00:00:00',
    screenshot: null,
  );
}

class _TicketStatusChip extends StatelessWidget {
  const _TicketStatusChip({required this.status});

  final String status;

  Color get _color {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'resolved' || normalized == 'Resolved') {
      return const Color(0xFF0E8B3E);
    }
    if (normalized == 'Reopened' || normalized == 'reopened') {
      return const Color(0xFFB07B00);
    }
    if (normalized == 'Closed' || normalized == 'closed') {
      return Colors.red;
    }

    return const Color(0xFFB07B00);
  }

  String get _label {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) return 'Open';
    if (normalized == 'in_progress') return 'In Progress';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        _label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

String _formatDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return '';
  final parsed = DateTime.tryParse(s.replaceFirst(' ', 'T'));
  if (parsed == null) return s;
  return DateFormat("d MMM''yy").format(parsed);
}
