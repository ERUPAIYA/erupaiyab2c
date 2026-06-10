// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../controllers/auth_controller.dart';

class OtpVerificationView extends HookConsumerWidget {
  const OtpVerificationView({super.key, this.phoneNumber});

  static const int _otpLength = 4;

  final String? phoneNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final otpController = useTextEditingController();
    final otpFocusNode = useFocusNode();
    final autoFilledCode = useState<String?>(null);

    useListenable(otpController);

    final remainingSeconds = useState(5);
    final errorText = useState<String?>(null);
    final timerRef = useRef<Timer?>(null);

    void startTimer() {
      timerRef.value?.cancel();
      timerRef.value = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingSeconds.value == 0) {
          timer.cancel();
          timerRef.value = null;
        } else {
          remainingSeconds.value--;
        }
      });
    }

    useEffect(() {
      startTimer();
      return () {
        timerRef.value?.cancel();
      };
    }, const []);

    final timerText =
        '${(remainingSeconds.value ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds.value % 60).toString().padLeft(2, '0')}';

    Future<void> handleVerify() async {
      final otp = otpController.text.trim();
      if (otp.length < _otpLength) {
        errorText.value = 'Please enter the $_otpLength-digit OTP.';
        return;
      }

      errorText.value = null;
      final success = await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(otp: otp, mobile: phoneNumber);
      if (success) {
        if (context.mounted) {
          context.go(RouteConstants.otpSuccess);
        }
      } else {
        final latestState = ref.read(authControllerProvider);
        errorText.value = latestState.errorMessage ??
            "Oops! That OTP doesn't seem right. Please check and re-enter.";
      }
    }

    Future<void> handleResend() async {
      final resolvedMobile = phoneNumber ?? authState.pendingMobile;
      if (resolvedMobile == null || resolvedMobile.isEmpty) {
        AppSnackbar.show('Missing mobile number. Please try again.');
        return;
      }

      final flow = await ref
          .read(authControllerProvider.notifier)
          .checkLogin(mobile: resolvedMobile);
      if (flow != null) {
        remainingSeconds.value = 59;
        errorText.value = null;
        startTimer();
        AppSnackbar.show('OTP resent to $resolvedMobile');
      } else {
        final latestState = ref.read(authControllerProvider);
        AppSnackbar.show(
          latestState.errorMessage ?? 'Failed to resend OTP. Please try again.',
        );
      }
    }

    void applyOtpCode(String code) {
      final digits = code.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) return;
      final trimmed =
          digits.length > _otpLength ? digits.substring(0, _otpLength) : digits;
      debugPrint('OTP autofill received: $trimmed');
      otpController.text = trimmed;
      otpFocusNode.unfocus();
      autoFilledCode.value = trimmed;
      errorText.value = null;
    }

    useEffect(() {
      var isDisposed = false;
      final autoFill = SmsAutoFill();
      debugPrint('init SMS autofill');
      final sub = autoFill.code.listen((code) {
        if (isDisposed) return;
        debugPrint('OTP SMS code stream: $code');
        applyOtpCode(code);
      });

      () async {
        try {
          final signature = await autoFill.getAppSignature;
          debugPrint(
            'SMS Retriever app signature: ${signature.isEmpty ? "<empty>" : signature}',
          );
          await autoFill.listenForCode(
            smsCodeRegexPattern: '\\d{$_otpLength}',
          );
          debugPrint('listenForCode started');
        } catch (e, st) {
          debugPrint(
            'OTP autofill init failed',
          );
        }
      }();

      return () {
        isDisposed = true;
        sub.cancel();
        autoFill.unregisterListener();
        debugPrint('dispose SMS autofill');
      };
    }, const []);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 6.h, 16.w, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.textPrimary,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Verify Your OTP',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                  Image.asset(
                    FileConstants.bharatConnectColor,
                    height: 22.h,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter OTP',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  SizedBox(height: 8.h),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.7),
                          ),
                      children: [
                        TextSpan(
                          text:
                              'Sent to ${phoneNumber ?? authState.pendingMobile ?? ''} ',
                        ),
                        TextSpan(
                          text: 'Change',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.go(RouteConstants.login),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Pinput(
                    length: _otpLength,
                    controller: otpController,
                    focusNode: otpFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: true,
                    onChanged: (_) => errorText.value = null,
                    onCompleted: (_) => handleVerify(),
                    defaultPinTheme: PinTheme(
                      width: 44.w,
                      height: 44.w,
                      textStyle:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD6D6D6)),
                      ),
                    ),
                    errorPinTheme: PinTheme(
                      width: 44.w,
                      height: 44.w,
                      textStyle:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red),
                      ),
                    ),
                    errorTextStyle:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                  ),
                  // if (autoFilledCode.value != null &&
                  //     autoFilledCode.value!.isNotEmpty) ...[
                  //   SizedBox(height: 8.h),
                  //   Text(
                  //     'Auto-filled OTP: ${autoFilledCode.value}',
                  //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  //           color: AppColors.textPrimary.withOpacity(0.6),
                  //           fontWeight: FontWeight.w600,
                  //         ),
                  //   ),
                  // ],
                  if (errorText.value != null &&
                      errorText.value!.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Text(
                      errorText.value!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                  SizedBox(height: 18.h),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        timerText,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap:
                            remainingSeconds.value == 0 ? handleResend : null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.refresh,
                              size: 18,
                              color: remainingSeconds.value == 0
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimary.withOpacity(0.35),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Resend OTP',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: remainingSeconds.value == 0
                                        ? AppColors.textPrimary
                                        : AppColors.textPrimary
                                            .withOpacity(0.35),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  CustomElevatedButton(
                    onPressed: authState.isSubmitting ? null : handleVerify,
                    label: authState.isSubmitting ? 'Verifying...' : 'Verify',
                    uppercaseLabel: false,
                    showArrow: false,
                    height: 42.h,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'OTP',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
