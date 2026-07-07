// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/support_feedback_sheets.dart';
import '../components/support_reply_sheet.dart';
import '../controllers/support_ticket_detail_controller.dart';
import '../models/support_ticket_detail.dart';

class SupportTicketDetailScreen extends HookConsumerWidget {
  const SupportTicketDetailScreen({
    super.key,
    required this.ticketId,
  });

  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportTicketDetailControllerProvider(ticketId));
    final controller =
        ref.read(supportTicketDetailControllerProvider(ticketId).notifier);

    useEffect(() {
      Future.microtask(controller.fetch);
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

    final ticket = state.ticket;
    final isClosedTicket =
        ticket != null && _isClosedTicketStatus(ticket.status);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const MyAppBar(title: 'Tickets'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.fetch,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 110.h),
                children: [
                  if (state.isLoading && ticket == null)
                    Skeletonizer(
                      enabled: true,
                      child: IgnorePointer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _HeaderRow(
                                ticket: _SupportTicketDetailSkeletons.ticket),
                            SizedBox(height: 12.h),
                            const _MetaGrid(
                                ticket: _SupportTicketDetailSkeletons.ticket),
                            SizedBox(height: 14.h),
                            const _DotDivider(),
                            SizedBox(height: 14.h),
                            const _SectionTitle(title: 'Issue Description'),
                            SizedBox(height: 10.h),
                            const _IssueDescriptionHeaderCard(
                              ticket: _SupportTicketDetailSkeletons.ticket,
                            ),
                            SizedBox(height: 14.h),
                            _QuestionText(
                                text: _SupportTicketDetailSkeletons
                                    .ticket.description),
                            SizedBox(height: 14.h),
                            const _AdminReplyCard(
                              message:
                                  _SupportTicketDetailSkeletons.adminMessage,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (ticket == null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 28.h),
                      child: Center(
                        child: Text(
                          'Ticket not found',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.6),
                              ),
                        ),
                      ),
                    )
                  else ...[
                    _HeaderRow(ticket: ticket),
                    SizedBox(height: 12.h),
                    _MetaGrid(ticket: ticket),
                    SizedBox(height: 14.h),
                    const _DotDivider(),
                    SizedBox(height: 14.h),
                    const _SectionTitle(title: 'Issue Description'),
                    SizedBox(height: 10.h),
                    _IssueDescriptionHeaderCard(ticket: ticket),
                    SizedBox(height: 14.h),
                    _QuestionText(text: ticket.description),
                    SizedBox(height: 14.h),
                    if (ticket.messages.isNotEmpty)
                      for (final message in ticket.messages) ...[
                        if (message.isAdmin)
                          _AdminReplyCard(message: message)
                        else
                          _QuestionText(text: message.message),
                        SizedBox(height: 12.h),
                      ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.black.withOpacity(0.06),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: ticket == null || state.isClosing
                      ? null
                      : () => isClosedTicket
                          ? _openReopenSheet(context)
                          : _openFeedbackFlow(
                              context,
                              controller: controller,
                            ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    isClosedTicket ? 'Reopen Ticket' : 'Close Ticket',
                  ),
                ),
              ),
              if (!isClosedTicket) ...[
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: ticket == null
                        ? null
                        : () => KDialog.instance.openSheet(
                              dialog: SupportReplySheet(ticketId: ticketId),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: const Text('Send Reply'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openFeedbackFlow(
    BuildContext context, {
    required SupportTicketDetailController controller,
  }) {
    KDialog.instance.openSheet(
      dialog: SupportExperienceSheet(
        onContinue: () async {
          final ok = await controller.closeTicket();
          if (!ok || !context.mounted) return;
          KDialog.instance.openSheet(
            dialog: SupportThankYouSheet(
              onContinue: () {
                if (!context.mounted) return;
                Navigator.of(context).maybePop();
              },
            ),
          );
        },
      ),
    );
  }

  void _openReopenSheet(BuildContext context) {
    KDialog.instance.openSheet(
      dialog: const _ReopenTicketSheet(),
    );
  }
}

bool _isClosedTicketStatus(String status) {
  final normalized = status.trim().toLowerCase();
  return normalized == 'closed' || normalized == 'resolved';
}

class _ReopenTicketSheet extends HookWidget {
  const _ReopenTicketSheet();

  static const _reasons = [
    'Issue Still Not Resolved',
    'Refund Not Received',
    'Payment Still Pending',
    'Incorrect Resolution Provided',
    'Need Additional Clarification',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final selectedReason = useState<String?>(null);
    final otherController = useTextEditingController();
    final otherText = useState('');
    final isOtherSelected = selectedReason.value == 'Other';

    final canSubmit = selectedReason.value != null &&
        (!isOtherSelected || otherText.value.trim().isNotEmpty);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Reopen Ticket',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Icon(Icons.close, size: 18.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            'Reason For Reopening',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            value: selectedReason.value,
            decoration: InputDecoration(
              hintText: 'Select',
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            items: _reasons
                .map(
                  (reason) => DropdownMenuItem<String>(
                    value: reason,
                    child: Text(reason),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) => selectedReason.value = value,
          ),
          if (isOtherSelected) ...[
            SizedBox(height: 14.h),
            Text(
              'Other',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: otherController,
              maxLines: 4,
              onChanged: (value) => otherText.value = value,
              decoration: InputDecoration(
                hintText: 'Describe Your Concern...',
                hintStyle: TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.42),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.lightBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.lightBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      canSubmit ? () => Navigator.of(context).pop() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.lightBorder,
                    disabledForegroundColor:
                        AppColors.textPrimary.withOpacity(0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: const Text('Reopen Ticket'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.ticket});

  final SupportTicketDetail ticket;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Ticket ID: ${ticket.id}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        _TicketStatusChip(status: ticket.status),
      ],
    );
  }
}

class _SupportTicketDetailSkeletons {
  const _SupportTicketDetailSkeletons._();

  static const ticket = SupportTicketDetail(
    id: '000000',
    transactionId: 'TXN000000',
    service: 'BBPS',
    status: 'Open',
    issueType: 'Recharge',
    description: 'Loading ticket details…',
    createdAt: '2026-01-01 00:00:00',
    username: 'User',
    messages: [],
  );

  static const adminMessage = SupportTicketMessage(
    senderType: 'admin',
    message: 'Loading reply…',
    createdAt: '2026-01-01 00:00:00',
  );
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.ticket});

  final SupportTicketDetail ticket;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetaItem(
                label: 'Category',
                value: _serviceLabel(ticket.service),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _MetaItem(
                label: 'Created On',
                value: ticket.createdAt,
                alignRight: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _MetaItem(
                label: 'Topic Of Query',
                value: ticket.issueType,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _MetaItem(
                label: 'Transaction ID',
                value: ticket.transactionId,
                alignRight: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.55),
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 4.h),
        Text(
          value.isEmpty ? '-' : value,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
      ),
    );
  }
}

class _IssueDescriptionHeaderCard extends StatelessWidget {
  const _IssueDescriptionHeaderCard({required this.ticket});

  final SupportTicketDetail ticket;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(ticket.username);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          _InitialAvatar(text: initials),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Issue Description',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  ticket.createdAt,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.55),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionText extends StatelessWidget {
  const _QuestionText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3.w,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6.r),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminReplyCard extends StatelessWidget {
  const _AdminReplyCard({required this.message});

  final SupportTicketMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.lightBorder),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team eRupaiya',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                SizedBox(height: 3.h),
                Text(
                  message.createdAt,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.55),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 10.h),
                Text(
                  message.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotDivider extends StatelessWidget {
  const _DotDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DividerDot(size: 5.r),
        Expanded(
          child: Divider(
            color: Colors.black.withOpacity(0.12),
            thickness: 1,
            height: 1,
          ),
        ),
        _DividerDot(size: 5.r),
      ],
    );
  }
}

class _DividerDot extends StatelessWidget {
  const _DividerDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34.w,
      height: 34.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.lightBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
      ),
    );
  }
}

class _TicketStatusChip extends StatelessWidget {
  const _TicketStatusChip({required this.status});

  final String status;

  Color get _color {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'resolved' || normalized == 'closed') {
      return const Color(0xFF0E8B3E);
    }
    if (normalized == 'in_progress' || normalized == 'in progress') {
      return const Color(0xFF9C6A00);
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

String _serviceLabel(String raw) {
  final code = raw.trim().toUpperCase();
  switch (code) {
    case 'BBPS':
      return 'Utility Payments';
    case 'EDUCATION':
      return 'Education Payments';
    case 'METAL':
      return 'Metal Payments';
    default:
      return raw.isEmpty ? 'Service' : raw;
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\\s+')).where((e) => e.isNotEmpty);
  final letters = parts.take(2).map((e) => e[0].toUpperCase()).join();
  return letters.isEmpty ? 'U' : letters;
}
