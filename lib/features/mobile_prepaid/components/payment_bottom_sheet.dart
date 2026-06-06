// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/features/mobile_prepaid/models/plan_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/payment_success_flow.dart';
import '../../paymentgateway/razorpay_guard.dart';
import '../../paymentgateway/razorpay_service.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/utils/receipt_actions.dart';
import '../../services/controllers/biller_detail_controller.dart';
import '../../services/models/bill_pay_response_model.dart';
import '../../services/models/biller_detail_state.dart';
import '../../services/models/recharge_status_result.dart';
import '../controllers/mobile_prepaid_controller.dart';
import '../models/prepaid_transaction_status.dart';

enum _PaymentOutcome {
  success,
  pending,
  failure,
  insufficient,
}

_PaymentOutcome _resolvePaymentOutcome(
  BillPayResponse? response,
  String? errorMessage,
) {
  final status = response?.status.toUpperCase() ?? '';
  final message = (response?.message ?? errorMessage ?? '').toLowerCase();
  if (message.contains('insufficient')) {
    return _PaymentOutcome.insufficient;
  }
  if (status.contains('PENDING') || status.contains('PROCESSING')) {
    return _PaymentOutcome.pending;
  }
  if (response?.isSuccess == true) {
    return _PaymentOutcome.success;
  }
  return _PaymentOutcome.failure;
}

String _paymentTitle(_PaymentOutcome outcome) {
  switch (outcome) {
    case _PaymentOutcome.success:
      return 'Recharge Successful';
    case _PaymentOutcome.pending:
      return 'Recharge Pending';
    case _PaymentOutcome.failure:
      return 'Recharge Failed!';
    case _PaymentOutcome.insufficient:
      return 'Insufficient Balance!';
  }
}

String _paymentSubtitle(_PaymentOutcome outcome) {
  switch (outcome) {
    case _PaymentOutcome.success:
      return '100 eCoins earned from this transaction';
    case _PaymentOutcome.pending:
      return 'Your payment has been received but is currently being processed.\n'
          "Please wait a few moments - we'll notify you once the transaction is confirmed.";
    case _PaymentOutcome.failure:
      return 'Unfortunately, your transaction could not be completed.'
          'Please check your payment details or try again.';
    // 'If the amount has been deducted, it will be refunded automatically within a few business days.';
    case _PaymentOutcome.insufficient:
      return 'You do not have enough balance to complete this payment.';
  }
}

String _resultSubtitle(_PaymentOutcome outcome) {
  switch (outcome) {
    case _PaymentOutcome.success:
      return '100 eCoins earned from this transaction';
    default:
      return _paymentSubtitle(outcome);
  }
}

IconData _paymentStatusIcon(_PaymentOutcome outcome) {
  switch (outcome) {
    case _PaymentOutcome.success:
      return Icons.check;
    case _PaymentOutcome.pending:
      return Icons.hourglass_bottom;
    case _PaymentOutcome.failure:
      return Icons.close;
    case _PaymentOutcome.insufficient:
      return Icons.error_outline;
  }
}

String _paymentStatusIconAsset(_PaymentOutcome outcome) {
  switch (outcome) {
    case _PaymentOutcome.success:
      return FileConstants.successIcon;
    case _PaymentOutcome.pending:
      return FileConstants.pendingIcon;
    case _PaymentOutcome.failure:
    case _PaymentOutcome.insufficient:
      return FileConstants.failedIcon;
  }
}

Color _paymentStatusColor(_PaymentOutcome outcome) {
  switch (outcome) {
    case _PaymentOutcome.success:
      return Colors.white;
    case _PaymentOutcome.pending:
      return Colors.amber;
    case _PaymentOutcome.failure:
      return Colors.white;
    case _PaymentOutcome.insufficient:
      return Colors.white;
  }
}

List<Color> _paymentHeaderGradient(_PaymentOutcome outcome) {
  switch (outcome) {
    case _PaymentOutcome.success:
      return const [
        Color(0xFF004C1E),
        Color(0xFF149248),
        Color(0xFF136E3C),
        Color(0xFF007340),
      ];
    case _PaymentOutcome.pending:
      return const [
        Color(0xFFD3A30E),
        Color(0xFFD3A30E),
        Color(0xFF844E07),
        Color(0xFFD3A30E),
      ];
    case _PaymentOutcome.failure:
    case _PaymentOutcome.insufficient:
      return const [
        Color(0xFFFF5D5D),
        Color(0xFFC04242),
        Color(0xFF981919),
        Color(0xFF8E0303),
      ];
  }
}

Future<void> _maybeShowEcoinsOverlay(
  BuildContext context, {
  required _PaymentOutcome outcome,
  required int ecoins,
}) async {
  if (outcome != _PaymentOutcome.success) return;
  if (ecoins <= 0) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'E-Coins earned',
      barrierColor: Colors.black.withOpacity(0.75),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, __) => _EcoinsRewardOverlay(ecoins: ecoins),
    );
  });
}

class _EcoinsRewardOverlay extends StatelessWidget {
  const _EcoinsRewardOverlay({required this.ecoins});

  final int ecoins;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = size.width * 0.86;
    final dialogHeight = size.height * 0.62;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Container(
              width: dialogWidth,
              height: dialogHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withOpacity(0.6),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: 0.32,
                    child: Image.asset(
                      FileConstants.spinRewardGif,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Congratulations',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: const Color(0xFFE7C35D),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You Earned',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: const Color(0xFFE7C35D),
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          ecoins.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                height: 0.9,
                                color: const Color(0xFFE7C35D),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Coins',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: const Color(0xFFE7C35D),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$ecoins eCoins are successfully added into your wallet',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB88500),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color? _paymentSubtitleBoxColor(_PaymentOutcome outcome) {
  switch (outcome) {
    case _PaymentOutcome.pending:
      // Match Figma: pending message box is dark brown/black-ish, not green.
      return const Color(0xFF3B2A00);
    case _PaymentOutcome.failure:
    case _PaymentOutcome.insufficient:
      return const Color(0xFF470601);
    case _PaymentOutcome.success:
      return null;
  }
}

void _openPaymentResultFlow(
  BuildContext context, {
  required _PaymentOutcome outcome,
  required double amount,
  required String billerName,
  required String txId,
  String? transactionDateTime,
  PrepaidTransactionStatus? prepaidStatus,
}) {
  void goHome(BuildContext localContext) {
    // Refresh wallet balance when returning home after any payment
    try {
      ProviderScope.containerOf(localContext)
          .read(profileControllerProvider.notifier)
          .fetchProfile();
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!localContext.mounted) return;
      navigatorKey.currentContext?.go(RouteConstants.home);
    });
  }

  String formatNow() {
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final yyyy = now.year.toString();
    var hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'pm' : 'am';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$dd/$mm/$yyyy:$hour:$minute$ampm';
  }

  final details = [
    PaymentDetailItem(
      label: 'Amount',
      value: '\u20B9 ${amount.toStringAsFixed(2)}',
    ),
    PaymentDetailItem(
      label: 'To',
      value: billerName,
    ),
    if (txId.isNotEmpty)
      PaymentDetailItem(
        label: 'Transaction ID',
        value: '#$txId',
        copyable: true,
      ),
    if (transactionDateTime != null)
      PaymentDetailItem(
        label: 'Date & Time',
        value: transactionDateTime.trim().isEmpty
            ? formatNow()
            : transactionDateTime.trim(),
      ),
    if (prepaidStatus != null && prepaidStatus.operatorName.isNotEmpty)
      PaymentDetailItem(
        label: 'Operator',
        value: prepaidStatus.operatorName,
      ),
    if (prepaidStatus != null && prepaidStatus.mobile.isNotEmpty)
      PaymentDetailItem(
        label: 'Mobile',
        value: prepaidStatus.mobile,
        copyable: true,
      ),
    if (prepaidStatus != null && prepaidStatus.paymentMode.isNotEmpty)
      PaymentDetailItem(
        label: 'Payment Mode',
        value: prepaidStatus.paymentMode,
      ),
    if (prepaidStatus != null && prepaidStatus.walletAmount.isNotEmpty)
      PaymentDetailItem(
        label: 'Wallet Amount',
        value: '\u20B9 ${prepaidStatus.walletAmount}',
      ),
    if (prepaidStatus != null && prepaidStatus.razorpayAmount.isNotEmpty)
      PaymentDetailItem(
        label: 'Razorpay Amount',
        value: '\u20B9 ${prepaidStatus.razorpayAmount}',
      ),
  ];
  final isFailure = outcome == _PaymentOutcome.failure ||
      outcome == _PaymentOutcome.insufficient;
  final showSupportShareActions =
      outcome == _PaymentOutcome.success || isFailure;
  final emphasizeSubtitle = outcome == _PaymentOutcome.pending || isFailure;
  void Function(BuildContext) onContinue = isFailure
      ? (screenContext) {
          Navigator.of(screenContext).pop();
        }
      : goHome;

  if (outcome == _PaymentOutcome.success) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentThankYouScreen(
          title: _paymentTitle(outcome),
          subtitle: _paymentSubtitle(outcome),
          playSound: true,
          autoNavigateAfter: const Duration(seconds: 2),
          onAutoNavigate: (screenContext) {
            Navigator.of(screenContext).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PaymentResultScreen(
                  title: _paymentTitle(outcome),
                  subtitle: _resultSubtitle(outcome),
                  details: details,
                  statusIcon: _paymentStatusIcon(outcome),
                  statusIconAsset: _paymentStatusIconAsset(outcome),
                  statusIconColor: _paymentStatusColor(outcome),
                  statusIconBorderColor: _paymentStatusColor(outcome),
                  headerGradientColors: _paymentHeaderGradient(outcome),
                  headerImageAsset: '',
                  emphasizeSubtitle: emphasizeSubtitle,
                  subtitleBackgroundColor: _paymentSubtitleBoxColor(outcome),
                  showFailureActions: showSupportShareActions,
                  showBackButton: isFailure,
                  showRatingSheet: outcome == _PaymentOutcome.success,
                  transactionId: txId,
                  continueText:
                      isFailure ? 'Retry Payment' : 'Continue to Home',
                  playSound: outcome == _PaymentOutcome.success,
                  onContinue: onContinue,
                  onContactSupport: showSupportShareActions
                      ? (c) => c.push(RouteConstants.helpSupport)
                      : null,
                  onShareReceipt: showSupportShareActions
                      ? (c, transactionId) =>
                          ReceiptActions.handleReceiptAction(
                            c,
                            transactionId: transactionId,
                            action: ReceiptAction.share,
                          )
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentResultScreen(
          title: _paymentTitle(outcome),
          subtitle: _resultSubtitle(outcome),
          details: details,
          statusIcon: _paymentStatusIcon(outcome),
          statusIconAsset: _paymentStatusIconAsset(outcome),
          statusIconColor: _paymentStatusColor(outcome),
          statusIconBorderColor: _paymentStatusColor(outcome),
          headerGradientColors: _paymentHeaderGradient(outcome),
          headerImageAsset: '',
          emphasizeSubtitle: emphasizeSubtitle,
          subtitleBackgroundColor: _paymentSubtitleBoxColor(outcome),
          showFailureActions: showSupportShareActions,
          showBackButton: isFailure,
          showRatingSheet: outcome == _PaymentOutcome.success,
          transactionId: txId,
          continueText: isFailure ? 'Retry Payment' : 'Continue to Home',
          playSound: false,
          onContinue: onContinue,
          onContactSupport: showSupportShareActions
              ? (c) => c.push(RouteConstants.helpSupport)
              : null,
          onShareReceipt: showSupportShareActions
              ? (c, transactionId) => ReceiptActions.handleReceiptAction(
                    c,
                    transactionId: transactionId,
                    action: ReceiptAction.share,
                  )
              : null,
        ),
      ),
    );
  }
}

class PaymentBottomSheet extends ConsumerStatefulWidget {
  const PaymentBottomSheet({
    super.key,
    required this.amount,
    this.isCreditCardFlow = false,
    this.paymentTypeOverride,
    this.ecoinsRestrictionsPercent,
  });

  final double amount;
  final bool isCreditCardFlow;
  final String? paymentTypeOverride;
  final double? ecoinsRestrictionsPercent;

  @override
  ConsumerState<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends ConsumerState<PaymentBottomSheet> {
  bool _useECoins = false;

  double _availableECoins() {
    final balance =
        ref.watch(profileControllerProvider).profile?.walletBalance ?? 0;
    return balance.toDouble();
  }

  double _maxECoinsAllowed(double availableECoins) {
    final percent = widget.ecoinsRestrictionsPercent;
    final ratio = percent == null ? 0.05 : (percent / 100.0);
    final restrictionBase = widget.amount;
    final maxAllowed = restrictionBase * ratio;
    if (maxAllowed.isNaN || maxAllowed.isInfinite) return 0;
    final capped = maxAllowed > widget.amount ? widget.amount : maxAllowed;
    return capped.floorToDouble();
  }

  double _eCoinsApplied(double available) {
    if (!_useECoins) return 0.0;
    final maxAllowed = _maxECoinsAllowed(available);
    if (maxAllowed <= 0) return 0.0;
    final allowed = available < maxAllowed ? available : maxAllowed;
    return allowed;
  }

  double _restrictionPercent() {
    final raw = widget.ecoinsRestrictionsPercent;
    if (raw == null || raw.isNaN || raw.isInfinite) return 5;
    if (raw <= 0) return 0;
    return raw;
  }

  double _remainingAmount(double applied) {
    final remaining = widget.amount - applied;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> _runWithVerificationLoader(Future<void> Function() task) async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Row(
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Verifying payment…',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    try {
      await task();
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  String _resolvePaymentType(BillerDetailState detailState) {
    final override = widget.paymentTypeOverride?.trim() ?? '';
    if (override.isNotEmpty) return override;
    final category = detailState.billerDetail?.billerCategoryName.trim() ?? '';
    if (category.isNotEmpty) return category;
    return 'BILLPAY';
  }

  Future<void> _verifyAndShow({
    required String transactionRef,
    required double amount,
    required String billerName,
    required String fallbackMessage,
  }) async {
    final controller = ref.read(billerDetailControllerProvider.notifier);
    RechargeStatusResult? status;
    await _runWithVerificationLoader(() async {
      status = await controller.verifyPayAllServicesStatus(
        transactionRef: transactionRef,
      );
    });
    if (!mounted) return;

    // Close the sheet before showing result screen.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    final latestState = ref.read(billerDetailControllerProvider);
    final normalized = (status?.status ?? '').trim().toUpperCase();
    final outcome = normalized == 'SUCCESS'
        ? _PaymentOutcome.success
        : (normalized == 'PENDING'
            ? _PaymentOutcome.pending
            : _PaymentOutcome.failure);
    final txId = (status?.transactionId.trim().isNotEmpty == true)
        ? status!.transactionId.trim()
        : transactionRef;

    _openPaymentResultFlow(
      navigatorKey.currentContext ?? context,
      outcome: outcome,
      amount: amount,
      billerName: billerName,
      txId: txId,
      transactionDateTime: status?.updatedAt,
    );

    if (outcome == _PaymentOutcome.failure &&
        latestState.payErrorMessage?.trim().isNotEmpty == true) {
      AppSnackbar.show(
        latestState.payErrorMessage!,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } else if (outcome == _PaymentOutcome.failure &&
        fallbackMessage.isNotEmpty) {
      AppSnackbar.show(
        fallbackMessage,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _startRazorpay({
    required double amount,
    required String billerName,
    required String orderId,
    required String keyOverride,
    required String transactionRef,
  }) async {
    if (!RazorpayGuard.ensureNotPaused(ref)) return;
    await RazorpayService.instance.openCheckout(
      amount: amount,
      name: billerName,
      description: 'Bill payment',
      orderId: orderId,
      keyOverride: keyOverride,
      onSuccess: (_) async {
        await _verifyAndShow(
          transactionRef: transactionRef,
          amount: widget.amount,
          billerName: billerName,
          fallbackMessage: 'Your payment was completed successfully.',
        );
      },
      onFailure: (message) async {
        await _verifyAndShow(
          transactionRef: transactionRef,
          amount: widget.amount,
          billerName: billerName,
          fallbackMessage:
              message.isEmpty ? 'Payment failed. Please try again.' : message,
        );
      },
      onExternalWallet: (_) async {
        await _verifyAndShow(
          transactionRef: transactionRef,
          amount: widget.amount,
          billerName: billerName,
          fallbackMessage:
              'We are verifying your payment. Please wait a moment.',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(billerDetailControllerProvider);
    final controller = ref.read(billerDetailControllerProvider.notifier);
    final isPaying = detailState.isPayingBill;
    final availableECoins = _availableECoins();
    final maxAllowedECoins = _maxECoinsAllowed(availableECoins);
    final canUseECoins = availableECoins > 0;
    final eCoinsApplied = _eCoinsApplied(availableECoins);
    final remainingAmount = _remainingAmount(eCoinsApplied);
    final buttonLabel = remainingAmount == 0 ? 'Pay Now' : 'Proceed';
    return AbsorbPointer(
      absorbing: isPaying,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Payment Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                Text(
                  '\u20B9 ${widget.amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Orange progress bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // E-Coins option
            _PaymentOptionTile(
              icon: Icons.monetization_on_outlined,
              iconColor: AppColors.primary,
              title:
                  'E-Coins (${availableECoins.toStringAsFixed(0)}) (Max ${_restrictionPercent().round()}%)',
              subtitle: _useECoins
                  ? 'Using \u20B9${eCoinsApplied.toStringAsFixed(0)} (Max \u20B9${maxAllowedECoins.toStringAsFixed(0)})'
                  : 'Use E-Coins for payment',
              enabled: canUseECoins && maxAllowedECoins > 0,
              trailing: Checkbox(
                value: _useECoins,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (canUseECoins && maxAllowedECoins > 0)
                    ? (v) => setState(() => _useECoins = v ?? false)
                    : null,
              ),
              onTap: (canUseECoins && maxAllowedECoins > 0)
                  ? () => setState(() => _useECoins = !_useECoins)
                  : null,
            ),

            const SizedBox(height: 20),
            const SizedBox(height: 16),

            // Bottom bar: amount + PAY NOW
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '\u20B9 ${remainingAmount.toStringAsFixed(0)}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                    ),
                    const Spacer(),
                    CustomElevatedButton(
                      onPressed: isPaying
                          ? null
                          : () async {
                              final billerName =
                                  detailState.selectedBiller?.billerName ??
                                      'Biller';
                              final paymentType =
                                  _resolvePaymentType(detailState);

                              final walletAmount =
                                  _useECoins ? eCoinsApplied : 0.0;
                              final razorpayAmount =
                                  remainingAmount > 0 ? remainingAmount : 0.0;

                              final order =
                                  await controller.createPayAllServicesOrder(
                                amount: widget.amount,
                                paymentType: paymentType,
                                walletAmount: walletAmount,
                                razorpayAmount: razorpayAmount,
                                isCreditCardFlow: widget.isCreditCardFlow,
                              );

                              if (!context.mounted) return;
                              if (order == null ||
                                  order.orderId.trim().isEmpty ||
                                  order.key.trim().isEmpty ||
                                  order.transactionRef.trim().isEmpty) {
                                AppSnackbar.show(
                                  ref
                                          .read(billerDetailControllerProvider)
                                          .payErrorMessage ??
                                      'Unable to start payment. Please try again.',
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                                return;
                              }

                              if (remainingAmount <= 0) {
                                await _verifyAndShow(
                                  transactionRef: order.transactionRef,
                                  amount: widget.amount,
                                  billerName: billerName,
                                  fallbackMessage:
                                      'We are verifying your payment. Please wait a moment.',
                                );
                                return;
                              }

                              await _startRazorpay(
                                amount: remainingAmount,
                                billerName: billerName,
                                orderId: order.orderId,
                                keyOverride: order.key,
                                transactionRef: order.transactionRef,
                              );
                            },
                      label: buttonLabel,
                      isLoading: isPaying,
                      showArrow: false,
                      uppercaseLabel: true,
                      width: null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrepaidPaymentBottomSheet extends ConsumerStatefulWidget {
  const PrepaidPaymentBottomSheet({
    super.key,
    required this.plan,
    this.billerName = 'Mobile Prepaid',
    this.ecoinsRestrictionsPercent,
  });

  final PlanItem plan;
  final String billerName;
  final double? ecoinsRestrictionsPercent;

  @override
  ConsumerState<PrepaidPaymentBottomSheet> createState() =>
      _PrepaidPaymentBottomSheetState();
}

class _PrepaidPaymentBottomSheetState
    extends ConsumerState<PrepaidPaymentBottomSheet> {
  bool _useECoins = false;

  double _restrictionPercent() {
    final raw = widget.ecoinsRestrictionsPercent;
    if (raw == null || raw.isNaN || raw.isInfinite) return 5;
    if (raw <= 0) return 0;
    return raw;
  }

  Future<void> _runWithVerificationLoader(Future<void> Function() task) async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Row(
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Verifying payment…',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    try {
      await task();
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  double _availableECoins() {
    final balance =
        ref.watch(profileControllerProvider).profile?.walletBalance ?? 0;
    return balance.toDouble();
  }

  double _maxECoinsAllowed(double availableECoins) {
    final percent = widget.ecoinsRestrictionsPercent;
    final ratio = percent == null ? 0.05 : (percent / 100.0);
    final restrictionBase = widget.plan.amount.toDouble();
    final maxAllowed = restrictionBase * ratio;
    if (maxAllowed.isNaN || maxAllowed.isInfinite) return 0;
    final capped = maxAllowed > widget.plan.amount
        ? widget.plan.amount.toDouble()
        : maxAllowed;
    // Keep max as whole rupees.
    return capped.floorToDouble();
  }

  double _eCoinsApplied(double available) {
    if (!_useECoins) return 0.0;
    final maxAllowed = _maxECoinsAllowed(available);
    if (maxAllowed <= 0) return 0.0;
    final allowed = available < maxAllowed ? available : maxAllowed;
    return allowed;
  }

  double _remainingAmount(double applied) {
    final remaining = widget.plan.amount - applied;
    return remaining < 0 ? 0 : remaining.toDouble();
  }

  Future<void> _startRazorpay({
    required double amount,
    required String billerName,
    required double walletAmount,
    required double razorpayAmount,
    required String orderId,
    required String keyOverride,
    required String transactionRef,
    Map<String, String>? prefill,
  }) async {
    if (!RazorpayGuard.ensureNotPaused(ref)) return;
    await RazorpayService.instance.openCheckout(
      amount: amount,
      name: billerName,
      description: 'Recharge',
      orderId: orderId,
      keyOverride: keyOverride,
      prefill: prefill,
      onSuccess: (paymentId) async {
        if (!mounted) return;
        await _runWithVerificationLoader(() async {
          await ref
              .read(mobilePrepaidControllerProvider.notifier)
              .verifyRechargeStatus(transactionRef: transactionRef);
        });
        if (!mounted) return;
        final latestState = ref.read(mobilePrepaidControllerProvider);
        final verified = latestState.verifiedTransaction;
        final outcome = verified == null
            ? (latestState.errorMessage != null
                ? _resolvePaymentOutcome(null, latestState.errorMessage)
                : _PaymentOutcome.success)
            : (verified.isSuccess
                ? _PaymentOutcome.success
                : ((verified.isPending || verified.isProcessing)
                    ? _PaymentOutcome.pending
                    : _PaymentOutcome.failure));
        final resolvedTxId =
            (latestState.rechargeTransactionId ?? '').isNotEmpty
                ? latestState.rechargeTransactionId!
                : paymentId;
        _openPaymentResultFlow(
          context,
          outcome: outcome,
          amount: widget.plan.amount.toDouble(),
          billerName: billerName,
          txId: resolvedTxId,
          transactionDateTime: latestState.rechargeDateTime,
          prepaidStatus: verified,
        );
        final message = latestState.errorMessage?.trim().toLowerCase();
        if (latestState.errorMessage != null &&
            message != 'unable to process recharge') {
          AppSnackbar.show(
            latestState.errorMessage!,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      },
      onFailure: (message) async {
        if (!mounted) return;
        await _runWithVerificationLoader(() async {
          await ref
              .read(mobilePrepaidControllerProvider.notifier)
              .verifyRechargeStatus(transactionRef: transactionRef);
        });
        if (!mounted) return;
        final latestState = ref.read(mobilePrepaidControllerProvider);
        final verified = latestState.verifiedTransaction;
        final outcome = verified == null
            ? _PaymentOutcome.failure
            : (verified.isSuccess
                ? _PaymentOutcome.success
                : ((verified.isPending || verified.isProcessing)
                    ? _PaymentOutcome.pending
                    : _PaymentOutcome.failure));
        final resolvedTxId =
            (latestState.rechargeTransactionId ?? '').isNotEmpty
                ? latestState.rechargeTransactionId!
                : transactionRef;
        _openPaymentResultFlow(
          context,
          outcome: outcome,
          amount: widget.plan.amount.toDouble(),
          billerName: billerName,
          txId: resolvedTxId,
          transactionDateTime: latestState.rechargeDateTime,
          prepaidStatus: verified,
        );
        final fallbackMessage = message.trim().isEmpty
            ? 'Payment failed. Please try again.'
            : message;
        if (verified == null || outcome == _PaymentOutcome.failure) {
          AppSnackbar.show(
            latestState.errorMessage ?? fallbackMessage,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      },
      onExternalWallet: (_) async {
        if (!mounted) return;
        await _runWithVerificationLoader(() async {
          await ref
              .read(mobilePrepaidControllerProvider.notifier)
              .verifyRechargeStatus(transactionRef: transactionRef);
        });
        if (!mounted) return;
        final latestState = ref.read(mobilePrepaidControllerProvider);
        final verified = latestState.verifiedTransaction;
        final outcome = verified == null
            ? _PaymentOutcome.pending
            : (verified.isSuccess
                ? _PaymentOutcome.success
                : ((verified.isPending || verified.isProcessing)
                    ? _PaymentOutcome.pending
                    : _PaymentOutcome.failure));
        final resolvedTxId =
            (latestState.rechargeTransactionId ?? '').isNotEmpty
                ? latestState.rechargeTransactionId!
                : transactionRef;
        _openPaymentResultFlow(
          context,
          outcome: outcome,
          amount: widget.plan.amount.toDouble(),
          billerName: billerName,
          txId: resolvedTxId,
          transactionDateTime: latestState.rechargeDateTime,
          prepaidStatus: verified,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(mobilePrepaidControllerProvider.notifier);
    final state = ref.watch(mobilePrepaidControllerProvider);
    final isPaying = state.isRecharging;
    final availableECoins = _availableECoins();
    final maxAllowedECoins = _maxECoinsAllowed(availableECoins);
    final canUseECoins = availableECoins > 0;
    final eCoinsApplied = _eCoinsApplied(availableECoins);
    final remainingAmount = _remainingAmount(eCoinsApplied);
    final buttonLabel = remainingAmount == 0 ? 'Pay Now' : 'Proceed';

    return AbsorbPointer(
      absorbing: isPaying,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Payment Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                Text(
                  '\u20B9 ${widget.plan.amount}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Orange progress bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // E-Coins option
            _PaymentOptionTile(
              icon: Icons.monetization_on_outlined,
              iconColor: AppColors.primary,
              title:
                  'E-Coins (${availableECoins.toStringAsFixed(0)}) (Max ${_restrictionPercent().round()}%)',
              subtitle: _useECoins
                  ? 'Using \u20B9${eCoinsApplied.toStringAsFixed(0)} (Max \u20B9${maxAllowedECoins.toStringAsFixed(0)})'
                  : 'Use E-Coins for payment',
              enabled: canUseECoins && maxAllowedECoins > 0,
              trailing: Checkbox(
                value: _useECoins,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (canUseECoins && maxAllowedECoins > 0)
                    ? (v) => setState(() => _useECoins = v ?? false)
                    : null,
              ),
              onTap: (canUseECoins && maxAllowedECoins > 0)
                  ? () => setState(() => _useECoins = !_useECoins)
                  : null,
            ),

            const SizedBox(height: 20),
            const SizedBox(height: 16),

            // Bottom bar: amount + PAY NOW
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '\u20B9 ${remainingAmount.toStringAsFixed(0)}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                    ),
                    const Spacer(),
                    CustomElevatedButton(
                      onPressed: isPaying
                          ? null
                          : () async {
                              if (_useECoins && remainingAmount == 0) {
                                final order = await controller
                                    .createRechargeOrderWithPlan(
                                  plan: widget.plan,
                                  useWallet: _useECoins,
                                  walletAmount: eCoinsApplied,
                                  razorpayAmount: 0,
                                );
                                if (!context.mounted) return;
                                if (order == null) {
                                  final latest = ref.read(
                                    mobilePrepaidControllerProvider,
                                  );
                                  AppSnackbar.show(
                                    latest.errorMessage ??
                                        'Failed to create order. Please try again.',
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                  );
                                  return;
                                }
                                await _runWithVerificationLoader(() async {
                                  await controller.verifyRechargeStatus(
                                    transactionRef: order.transactionRef,
                                  );
                                });
                                if (!context.mounted) return;
                                final latestState =
                                    ref.read(mobilePrepaidControllerProvider);
                                Navigator.of(context).pop();
                                final verified =
                                    latestState.verifiedTransaction;
                                final outcome = verified == null
                                    ? (latestState.errorMessage != null
                                        ? _resolvePaymentOutcome(
                                            null,
                                            latestState.errorMessage,
                                          )
                                        : _PaymentOutcome.success)
                                    : (verified.isSuccess
                                        ? _PaymentOutcome.success
                                        : ((verified.isPending ||
                                                verified.isProcessing)
                                            ? _PaymentOutcome.pending
                                            : _PaymentOutcome.failure));
                                final resolvedTxId =
                                    (latestState.rechargeTransactionId ?? '')
                                            .isNotEmpty
                                        ? latestState.rechargeTransactionId!
                                        : '';
                                _openPaymentResultFlow(
                                  context,
                                  outcome: outcome,
                                  amount: widget.plan.amount.toDouble(),
                                  billerName: widget.billerName,
                                  txId: resolvedTxId,
                                  transactionDateTime:
                                      latestState.rechargeDateTime,
                                  prepaidStatus: verified,
                                );
                                if (latestState.errorMessage != null) {
                                  AppSnackbar.show(
                                    latestState.errorMessage!,
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                  );
                                }
                                return;
                              }

                              final order =
                                  await controller.createRechargeOrderWithPlan(
                                plan: widget.plan,
                                useWallet: _useECoins,
                                walletAmount: _useECoins ? eCoinsApplied : 0,
                                razorpayAmount: _useECoins
                                    ? remainingAmount
                                    : widget.plan.amount.toDouble(),
                              );
                              if (!context.mounted) return;
                              if (order == null) {
                                final latest = ref.read(
                                  mobilePrepaidControllerProvider,
                                );
                                AppSnackbar.show(
                                  latest.errorMessage ??
                                      'Failed to create order. Please try again.',
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                                return;
                              }
                              if (order.orderId.trim().isEmpty ||
                                  order.key.trim().isEmpty) {
                                AppSnackbar.show(
                                  order.message.isNotEmpty
                                      ? order.message
                                      : 'Unable to start payment right now. Please try again.',
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                                return;
                              }
                              await _startRazorpay(
                                amount: remainingAmount,
                                billerName: widget.billerName,
                                walletAmount: _useECoins ? eCoinsApplied : 0,
                                razorpayAmount: remainingAmount,
                                orderId: order.orderId,
                                keyOverride: order.key,
                                transactionRef: order.transactionRef,
                                prefill: () {
                                  final contact = state.mobile
                                      .replaceAll(RegExp(r'\D'), '')
                                      .trim();
                                  if (contact.isEmpty) return null;
                                  return {'contact': contact};
                                }(),
                              );
                            },
                      label: buttonLabel,
                      isLoading: isPaying,
                      showArrow: false,
                      uppercaseLabel: true,
                      width: null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        enabled ? iconColor : AppColors.textPrimary.withOpacity(0.35);
    final titleColor = enabled
        ? AppColors.textPrimary
        : AppColors.textPrimary.withOpacity(0.45);
    final subtitleColor = enabled
        ? AppColors.textPrimary.withOpacity(0.5)
        : AppColors.textPrimary.withOpacity(0.35);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: effectiveIconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: subtitleColor,
                          ),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
