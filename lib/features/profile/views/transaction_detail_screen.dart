// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/widgets/app_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_action_button.dart';
import '../../../widgets/transaction_status_app_bar.dart';
import '../../mobile_prepaid/models/recharge_quick_action_payload.dart';
import '../models/transaction_history_entry.dart';
import '../utils/receipt_actions.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, this.entry});

  final TransactionHistoryEntry? entry;

  @override
  Widget build(BuildContext context) {
    final tx = entry ??
        const TransactionHistoryEntry(
          paymentStatus: '',
          paymentType: '',
          billerName: '',
          maskedIdentifier: '',
          amount: '',
          platformFees: '',
          totalAmountCharged: '',
          customerMobile: '',
          iconUrl: '',
          transactionId: '',
          bankReferenceId: '',
          referenceId: '',
          transactionTime: '',
          method: '',
          methodIcon: '',
          paymentMode: '',
          vpa: '',
          rrn: '',
        );
    final statusMeta = _statusMeta(tx.paymentStatus);
    final paymentMethod = tx.method.trim();
    final status = tx.paymentStatus.trim().toUpperCase();
    final isFailed = status == 'FAILED' || status == 'FAIL';
    final isSuccessful = status == 'SUCCESS';
    final statusBackgroundGradient = isFailed
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF5D5D),
              Color(0xFFC04242),
              Color(0xFF981919),
              Color(0xFF8E0303),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          )
        : isSuccessful
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF004C1E),
                  Color(0xFF149248),
                  Color(0xFF136E3C),
                  Color(0xFF007340),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              )
            : null;
    final isProcessing = status == 'PENDING' || status == 'PROCESSING';
    final typeLower = tx.paymentType.trim().toLowerCase();
    final isRecharge = typeLower.contains('recharge');
    final isCreditCard = typeLower.contains('credit');
    final totalAmount = tx.totalAmountCharged.trim().isNotEmpty
        ? tx.totalAmountCharged
        : tx.amount;
    final showPlatformFees = _hasAmount(tx.platformFees);
    final amountLabel = isRecharge ? 'Recharge Amount' : 'Bill Amount';
    final infoRows = <_InfoRow>[
      _InfoRow(label: amountLabel, value: _formatAmount(tx.amount)),
      if (showPlatformFees)
        _InfoRow(
          label: 'Platform Fees',
          value: _formatAmount(tx.platformFees),
        ),
      // if (paymentMethod.isNotEmpty)
      //   _InfoRow(label: 'Payment Method', value: paymentMethod),
      _InfoRow(
        label: 'Total Amount',
        value: _formatAmount(totalAmount),
        emphasize: true,
      ),
    ];
    final txnId = tx.transactionId.trim();
    final bankRefId = tx.bankReferenceId.trim();
    final refId = tx.referenceId.trim();
    final rrn = tx.rrn.trim();
    final vpa = tx.vpa.trim();
    final paymentMode = tx.paymentMode.trim();
    final isUpi = paymentMethod.toLowerCase() == 'upi' || vpa.isNotEmpty;
    final txnIdLabel = isUpi ? 'UPI Transaction ID' : 'Transaction ID';
    const referenceLabel = 'Reference ID';

    final canRetry = !isFailed || tx.routes.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          TransactionStatusAppBar(
            title: statusMeta.label,
            height: 130,
            backgroundColor: statusMeta.color,
            backgroundGradient: statusBackgroundGradient,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              // padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  // border: Border.all(
                  //   color: AppColors.lightBorder.withOpacity(0.8),
                  // ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isProcessing) ...[
                      _TransactionSummaryCard(item: tx),
                      SizedBox(height: 10.h),
                      const AppDivider(),
                      SizedBox(height: 10.h),
                    ],
                    if (!isFailed) ...[
                      if (bankRefId.isNotEmpty) ...[
                        const _TransactionInfoSection(
                          title: 'Transaction Details',
                          rows: [],
                        ),
                        SizedBox(height: 10.h),
                        _CopyRow(
                          label: 'Bank Reference ID',
                          value: bankRefId,
                        ),
                        SizedBox(height: 10.h),
                      ],
                      _TransactionInfoSection(
                        title: 'Payment Details',
                        rows: infoRows,
                      ),
                      SizedBox(height: 10.h),
                      if (txnId.isNotEmpty)
                        _CopyRow(
                          label: txnIdLabel,
                          value: txnId,
                        ),
                      if (refId.isNotEmpty)
                        _CopyRow(
                          label: referenceLabel,
                          value: refId,
                        ),
                      if (vpa.isNotEmpty)
                        _CopyRow(
                          label: 'VPA',
                          value: vpa,
                          showCopy: false,
                        ),
                      SizedBox(height: 10.h),
                      if (paymentMode.isNotEmpty || rrn.isNotEmpty)
                        _PaidFromRow(
                          iconUrl: tx.iconUrl,
                          utr: rrn,
                          amount: totalAmount,
                        ),
                      if (paymentMethod.isNotEmpty)
                        _CopyRow(
                          label: 'Payment Method',
                          value: paymentMethod,
                          showCopy: false,
                        ),
                      SizedBox(height: 18.h),
                      Row(
                        children: [
                          Expanded(
                            child: KActionButton(
                              label: 'Share Receipt',
                              icon: Icons.share_outlined,
                              onPressed: () =>
                                  ReceiptActions.handleReceiptAction(
                                context,
                                transactionId: _resolveReceiptTransactionId(
                                  refId: refId,
                                  txnId: txnId,
                                ),
                                action: ReceiptAction.share,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: KActionButton(
                              label: 'View Receipt',
                              icon: Icons.receipt_long_outlined,
                              onPressed: () => ReceiptActions.openReceiptViewer(
                                context,
                                transactionId: _resolveReceiptTransactionId(
                                  refId: refId,
                                  txnId: txnId,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      KActionButton(
                        label: 'Contact Support',
                        icon: Icons.headset_mic_outlined,
                        onPressed: () =>
                            context.push(RouteConstants.helpCenterChat),
                      ),
                      SizedBox(height: 14.h),
                      _PoweredByRow(),
                      // if (!isProcessing && isRecharge && !isCreditCard) ...[
                      //   SizedBox(height: 18.h),
                      //   CustomElevatedButton(
                      //     onPressed: () =>
                      //         context.push(RouteConstants.mobilePrepaid),
                      //     label: 'Recharge Now',
                      //     height: 40.h,
                      //     uppercaseLabel: false,
                      //     showArrow: false,
                      //   ),
                      // ],
                    ] else ...[
                      if (bankRefId.isNotEmpty) ...[
                        const _TransactionInfoSection(
                          title: 'Transaction Details',
                          rows: [],
                        ),
                        SizedBox(height: 10.h),
                        _CopyRow(
                          label: 'Transaction ID',
                          value: bankRefId,
                        ),
                        SizedBox(height: 10.h),
                      ],
                      const _TransactionInfoSection(
                        title: 'Payment Details',
                        rows: [],
                      ),
                      SizedBox(height: 10.h),
                      if (txnId.isNotEmpty)
                        _CopyRow(
                          label: txnIdLabel,
                          value: txnId,
                        ),
                      if (refId.isNotEmpty)
                        _CopyRow(
                          label: referenceLabel,
                          value: refId,
                        ),
                      SizedBox(height: 18.h),
                      Row(
                        children: [
                          Expanded(
                            child: KActionButton(
                              label: 'Share Receipt',
                              icon: Icons.share_outlined,
                              onPressed: () =>
                                  ReceiptActions.handleReceiptAction(
                                context,
                                transactionId: _resolveReceiptTransactionId(
                                  refId: refId,
                                  txnId: txnId,
                                ),
                                action: ReceiptAction.share,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: KActionButton(
                              label: 'Contact Support',
                              icon: Icons.headset_mic_outlined,
                              onPressed: () =>
                                  context.push(RouteConstants.helpCenterChat),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          canRetry && (isFailed || (isRecharge && !isCreditCard))
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                    child: CustomElevatedButton(
                      onPressed: () {
                        if (isFailed) {
                          if (_handleRetryFromRoutes(context, tx)) return;

                          if (isRecharge && !isCreditCard) {
                            final amountInt = int.tryParse(
                                    tx.amount.replaceAll(',', '').trim()) ??
                                0;
                            context.push(
                              RouteConstants.mobilePrepaid,
                              extra: RechargeQuickActionPayload(
                                phone: tx.maskedIdentifier,
                                amount: amountInt,
                                operatorName: tx.billerName,
                                iconUrl: tx.iconUrl,
                                autoOpenPaymentSheet: true,
                              ),
                            );
                            return;
                          }

                          if (isCreditCard) {
                            context.push(
                              RouteConstants.creditCardPay,
                              extra: <String, dynamic>{
                                'biller_name': tx.billerName,
                                'masked_identifier': tx.maskedIdentifier,
                                'customer_mobile': tx.customerMobile,
                                'amount': double.tryParse(
                                  tx.amount.replaceAll(',', '').trim(),
                                ),
                                'payment_type': tx.paymentType,
                                'icon': tx.iconUrl,
                              },
                            );
                            return;
                          }
                        }

                        context.push(RouteConstants.mobilePrepaid);
                      },
                      label: isFailed ? 'Retry' : 'Recharge Now',
                      height: 40.h,
                      uppercaseLabel: false,
                      showArrow: false,
                    ),
                  ),
                )
              : null,
    );
  }
}

class _TransactionSummaryCard extends StatelessWidget {
  const _TransactionSummaryCard({required this.item});

  final TransactionHistoryEntry item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.paymentType.isNotEmpty
                      ? item.paymentType
                      : 'Mobile Recharged',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                _formatTxnTime(item.transactionTime),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.6),
                    ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.4),
                  ),
                ),
                child: Center(
                  child: AppNetworkImage(
                    url: item.iconUrl,
                    width: 24.w,
                    height: 24.w,
                    fit: BoxFit.contain,
                    showShimmer: false,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.billerName.isNotEmpty ? item.billerName : 'Biller',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item.maskedIdentifier,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatAmount(item.amount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionInfoSection extends StatelessWidget {
  const _TransactionInfoSection({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15.sp,
              ),
        ),
        SizedBox(height: 10.h),
        Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        rows[i].label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: rows[i].emphasize
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimary.withOpacity(0.6),
                              fontWeight: rows[i].emphasize
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: rows[i].emphasize ? 13.sp : 12.sp,
                            ),
                      ),
                    ),
                    Text(
                      rows[i].value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: rows[i].emphasize
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: rows[i].emphasize ? 13.sp : 12.sp,
                          ),
                    ),
                  ],
                ),
              ),
              if (i == 1) ...[
                Divider(
                  color: AppColors.lightBorder.withOpacity(0.8),
                  height: 12.h,
                ),
              ],
            ],
          ],
        ),
      ],
    );
  }
}

class _InfoRow {
  const _InfoRow({
    required this.label,
    required this.value,
    this.canCopy = false,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool canCopy;
  final bool emphasize;
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    this.showCopy = true,
  });

  final String label;
  final String value;
  final bool showCopy;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.6),
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          if (showCopy)
            InkWell(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: value));
                AppSnackbar.show('Copied to clipboard');
              },
              borderRadius: BorderRadius.circular(6.r),
              child: Padding(
                padding: EdgeInsets.all(6.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.copy_rounded,
                      size: 16.sp,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Copy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
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

class _PaidFromRow extends StatelessWidget {
  const _PaidFromRow({
    required this.iconUrl,
    required this.utr,
    required this.amount,
  });

  final String iconUrl;
  final String utr;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paid From',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.4),
                  ),
                ),
                child: Center(
                  child: AppNetworkImage(
                    url: iconUrl,
                    width: 14.w,
                    height: 14.w,
                    fit: BoxFit.contain,
                    showShimmer: false,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (utr.trim().isNotEmpty)
                      Text(
                        'UTR: ${utr.trim()}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    if (amount.trim().isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Text(
                          'Amount Debited: ${_formatAmount(amount)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PoweredByRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'powered by',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
        ),
        SizedBox(width: 6.w),
        Image.asset(
          FileConstants.bharatConnectColor,
          height: 16.h,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

bool _handleRetryFromRoutes(BuildContext context, TransactionHistoryEntry tx) {
  final routes = tx.routes;
  if (routes.isEmpty) return false;

  for (final route in routes) {
    final key = route.routeKey.trim().toLowerCase();
    final deeplink = route.deeplink.trim().toLowerCase();
    final params = route.params;

    // Mobile prepaid recharge retry.
    if (key == 'mobile_recharge' || deeplink.contains('mobile-recharge')) {
      final phone = (params['masked_identifier'] ??
              params['customer_mobile'] ??
              tx.maskedIdentifier)
          .toString()
          .trim();
      final operatorName =
          (params['biller_name'] ?? tx.billerName).toString().trim();
      final amountInt = _toInt(params['amount']) ??
          int.tryParse(tx.amount.replaceAll(',', '').trim()) ??
          0;

      context.push(
        RouteConstants.mobilePrepaid,
        extra: RechargeQuickActionPayload(
          phone: phone,
          amount: amountInt,
          operatorName: operatorName,
          iconUrl: tx.iconUrl,
          autoOpenPaymentSheet: true,
        ),
      );
      return true;
    }
  }

  // Unknown route type: fall back to existing logic.
  return false;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return int.tryParse(text) ?? double.tryParse(text)?.toInt();
}

class _StatusMeta {
  const _StatusMeta({required this.label, required this.color});

  final String label;
  final Color color;
}

_StatusMeta _statusMeta(String rawStatus) {
  final status = rawStatus.trim().toUpperCase();
  switch (status) {
    case 'SUCCESS':
      return const _StatusMeta(
        label: 'Transaction Successful',
        color: Color(0xFF007340),
      );
    case 'PENDING':
      return const _StatusMeta(
        label: 'Transaction Pending',
        color: Color(0xFFF59E0B),
      );
    case 'FAILED':
    case 'FAIL':
      return const _StatusMeta(
        label: 'Transaction Failed',
        color: Color(0xFF8E0303),
      );
    default:
      return const _StatusMeta(
        label: 'Transaction Details',
        color: Color(0xFF1AAE57),
      );
  }
}

String _formatAmount(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.startsWith('₹') ? trimmed : '₹ $trimmed';
}

String _resolveReceiptTransactionId({
  required String refId,
  required String txnId,
}) {
  return ReceiptActions.resolveReceiptTransactionId(refId: refId, txnId: txnId);
}

bool _hasAmount(String raw) {
  final trimmed = raw.trim();
  return trimmed.isNotEmpty;
}

String _formatTxnTime(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  final normalized = value.contains(' ') ? value.replaceFirst(' ', 'T') : value;
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return value;
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final day = parsed.day.toString().padLeft(2, '0');
  final month = months[parsed.month - 1];
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final ampm = parsed.hour >= 12 ? 'PM' : 'AM';
  return '$day $month ${parsed.year}, $hour:$minute$ampm';
}
