// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../../paymentgateway/razorpay_guard.dart';
import '../../paymentgateway/razorpay_service.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/models/transaction_history_entry.dart';
import '../components/education_payment_sheets.dart';
import '../controllers/education_fees_controller.dart';
import '../models/education_fees_responses.dart';
import '../repositories/education_fees_repository.dart';

class EducationFeesTutorsView extends HookConsumerWidget {
  const EducationFeesTutorsView({
    super.key,
    required this.amount,
    required this.tutors,
  });

  final double amount;
  final List<EducationBeneficiary> tutors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(educationFeesRepositoryProvider);
    useEffect(() {
      Future.microtask(
        () =>
            ref.read(profileControllerProvider.notifier).fetchProfileIfNeeded(),
      );
      return null;
    }, const []);
    final selectedCard = useState<EducationCard?>(null);
    final expandedIndex = useState<int?>(null);

    useEffect(() {
      Future.microtask(() async {
        try {
          final response = await repository.fetchCardList();
          if (response.status && response.cards.isNotEmpty) {
            selectedCard.value = response.cards.first;
          }
        } catch (_) {}
      });
      return null;
    }, const []);

    void openSummary(EducationBeneficiary tutor) {
      KDialog.instance.openSheet(
        dialog: EducationPaymentSummarySheet(
          amount: amount,
          onPayNow: (payable) async {
            if (!await RazorpayGuard.ensureProfileReadyAndNotPaused(ref)) {
              return;
            }
            final card = selectedCard.value;
            EducationCreateOrderResponse order;
            try {
              order = await repository.createOrder(
                recipientName: tutor.name,
                accountNo: tutor.accountMasked,
                ifsc: tutor.ifsc,
                amount: payable,
              );
            } catch (e) {
              AppSnackbar.show(
                'Failed to create order. Please try again.',
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );
              return;
            }

            if (!order.status || order.orderId.isEmpty || order.key.isEmpty) {
              AppSnackbar.show(
                order.message.isNotEmpty
                    ? order.message
                    : 'Failed to create order. Please try again.',
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );
              return;
            }

            await RazorpayService.instance.openCheckout(
              amount: order.amount > 0 ? order.amount : payable,
              name: tutor.name.isEmpty ? 'Education Fees' : tutor.name,
              description: 'Tuition fee payment',
              orderId: order.orderId,
              keyOverride: order.key,
              onSuccess: (paymentId) async {
                final verified = await _verifyEducationPaymentStatus(
                  repository: repository,
                  transactionRefId: order.transactionRefId,
                );
                if (verified == null || !verified.isSuccess) {
                  if (!context.mounted) return;
                  AppSnackbar.show(
                    (verified?.message.isNotEmpty ?? false)
                        ? verified!.message
                        : 'Unable to verify payment status. Please try again.',
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                  return;
                }

                try {
                  await repository.reportPaymentSuccess(
                    recipientName: tutor.name,
                    accountNo: tutor.accountMasked,
                    ifsc: '',
                    amount: order.amount > 0 ? order.amount : payable,
                    paymentId: paymentId,
                    status: 'success',
                    cardToken: card?.cardToken ?? '',
                    last4: card?.last4 ?? '',
                    cardNetwork: card?.cardNetwork ?? '',
                    expiryMonth: card?.expiryMonth ?? '',
                    expiryYear: card?.expiryYear ?? '',
                  );
                } catch (_) {}
                if (context.mounted) {
                  context.push(
                    RouteConstants.transactionDetail,
                    extra: _buildEducationSuccessEntry(
                      recipientName: tutor.name,
                      maskedAccount: tutor.accountMasked,
                      amount: order.amount > 0 ? order.amount : payable,
                      paymentId: paymentId,
                    ),
                  );
                }
              },
              onFailure: (message) async {
                final verified = await _verifyEducationPaymentStatus(
                  repository: repository,
                  transactionRefId: order.transactionRefId,
                );
                if (verified != null && verified.isSuccess) {
                  if (!context.mounted) return;
                  context.push(
                    RouteConstants.transactionDetail,
                    extra: _buildEducationSuccessEntry(
                      recipientName: tutor.name,
                      maskedAccount: tutor.accountMasked,
                      amount: order.amount > 0 ? order.amount : payable,
                      paymentId: order.transactionRefId,
                    ),
                  );
                  return;
                }
                if (!context.mounted) return;
                AppSnackbar.show(
                  (verified?.message.isNotEmpty ?? false)
                      ? verified!.message
                      : message,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              },
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: 'Tutors',
        showHelp: true,
        onBack: () => Navigator.of(context).maybePop(),
        onHelp: () {},
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                itemCount: tutors.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final tutor = tutors[index];
                  final name = tutor.name.isEmpty
                      ? _fallbackTutorName(tutor)
                      : tutor.name;
                  final isExpanded = expandedIndex.value == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.lightBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                color: Colors.black),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(
                              height: 30.h,
                              child: ElevatedButton(
                                onPressed: () {
                                  expandedIndex.value =
                                      isExpanded ? null : index;
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.r),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 6.h,
                                  ),
                                ),
                                child: Text(
                                  isExpanded ? 'Hide Details' : 'View Details',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isExpanded) ...[
                          SizedBox(height: 12.h),
                          InkWell(
                            onTap: () => openSummary(tutor),
                            borderRadius: BorderRadius.circular(12.r),
                            child: Column(
                              children: [
                                _DetailRow(
                                  label: 'PAN Details',
                                  value: tutor.panMasked.isEmpty
                                      ? '-'
                                      : tutor.panMasked,
                                ),
                                _DetailRow(
                                  label: 'Account Number',
                                  value: tutor.accountMasked.isEmpty
                                      ? '-'
                                      : tutor.accountMasked,
                                ),
                                _DetailRow(
                                  label: 'IFSC Code',
                                  value: tutor.ifsc.isEmpty ? '-' : tutor.ifsc,
                                ),
                                SizedBox(height: 6.h),
                                SizedBox(height: 12.h),
                                CustomElevatedButton(
                                  onPressed: () => openSummary(tutor),
                                  label: 'Pay ₹${amount.toStringAsFixed(0)}',
                                  uppercaseLabel: false,
                                  showArrow: false,
                                  height: 36.h,
                                  width: 135.w,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
              child: CustomElevatedButton(
                onPressed: () =>
                    context.push(RouteConstants.educationFeesRecipient),
                label: '+ Add New',
                uppercaseLabel: false,
                showArrow: false,
                height: 48.h,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<EducationPaymentStatusResponse?> _verifyEducationPaymentStatus({
  required EducationFeesRepository repository,
  required String transactionRefId,
}) async {
  if (transactionRefId.trim().isEmpty) return null;
  var latest =
      await repository.fetchPaymentStatus(transactionRefId: transactionRefId);
  if (latest.isSuccess || latest.isFailed) return latest;

  const pollInterval = Duration(seconds: 2);
  for (var attempt = 0; attempt < 2; attempt++) {
    await Future.delayed(pollInterval);
    latest =
        await repository.fetchPaymentStatus(transactionRefId: transactionRefId);
    if (latest.isSuccess || latest.isFailed) return latest;
  }
  return latest;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.65),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          SizedBox(height: 8.h),
          const Divider(color: AppColors.lightBorder, height: 1),
          SizedBox(height: 8.h),
        ],
      ],
    );
  }
}

String _fallbackTutorName(EducationBeneficiary tutor) {
  if (tutor.accountMasked.isNotEmpty) {
    return 'Account ${tutor.accountMasked}';
  }
  return 'Beneficiary';
}

TransactionHistoryEntry _buildEducationSuccessEntry({
  required String recipientName,
  required String maskedAccount,
  required double amount,
  required String paymentId,
}) {
  final now = DateTime.now().toIso8601String();
  return TransactionHistoryEntry(
    paymentStatus: 'SUCCESS',
    paymentType: 'Education Fees',
    billerName: recipientName.isEmpty ? 'Recipient' : recipientName,
    maskedIdentifier: maskedAccount.isEmpty ? '****' : maskedAccount,
    amount: amount.toStringAsFixed(2),
    platformFees: '',
    totalAmountCharged: amount.toStringAsFixed(2),
    customerMobile: '',
    iconUrl: '',
    pgTransactionId: paymentId,
    ecoinsTransactionId: '',
    transactionId: paymentId,
    bankReferenceId: '',
    referenceId: paymentId,
    transactionTime: now,
    method: 'Card',
    methodIcon: '',
    paymentMode: 'Card',
    vpa: '',
    rrn: '',
  );
}
