import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/temporary_block_debug_config.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/k_dialog.dart';
import '../components/new_device_verification_dialog.dart';
import '../components/temporary_block_dialog.dart';
import '../models/otp_verification_args.dart';

Future<void> launchTemporaryBlockedFlow({
  required BuildContext context,
  required String phoneNumber,
  required bool isKycVerified,
}) async {
  final flowType = isKycVerified
      ? TemporaryBlockFlowType.kycVerified
      : TemporaryBlockFlowType.noKyc;

  await KDialog.instance.openDialog(
    barrierDismissible: false,
    dialog: TemporaryBlockDialog(
      flowType: flowType,
      onSupportTap: () {
        Navigator.of(context, rootNavigator: true).pop();
        Future.microtask(() {
          if (!context.mounted) return;
          context.push(RouteConstants.helpSupport);
        });
      },
      onPrimaryTap: () {
        final successRoute = flowType == TemporaryBlockFlowType.noKyc
            ? RouteConstants.kycVerification
            : RouteConstants.temporaryBlockIdentityCompletion;
        final flowQueryValue =
            flowType == TemporaryBlockFlowType.noKyc ? 'noKyc' : 'kycVerified';
        Navigator.of(context, rootNavigator: true).pop();
        Future.microtask(() {
          if (!context.mounted) return;
          context.push(
            '${RouteConstants.temporaryBlockOtp}?flow=$flowQueryValue&phone=$phoneNumber',
            extra: OtpVerificationArgs(
              phoneNumber: phoneNumber,
              title: 'Verify Your Identity',
              heading: 'Verify Your Identity',
              description:
                  'Enter the OTPs sent to your registered mobile number and email address to verify your identity.',
              primaryButtonLabel: 'Verify & Continue',
              successDialogTitle: 'Mobile and Email verified successfully',
              successDialogMessage:
                  'This device has been successfully verified and added to your trusted devices. You can now access your account securely.',
              successButtonLabel: 'Complete KYC',
              successRoute: successRoute,
              successRouteExtra:
                  successRoute == RouteConstants.kycVerification ? false : null,
              temporaryBlockFlowType: flowType,
            ),
          );
        });
      },
    ),
  );
}

Future<void> launchNewDeviceVerificationFlow({
  required BuildContext context,
  required String phoneNumber,
  required String verificationId,
}) async {
  await KDialog.instance.openDialog(
    barrierDismissible: false,
    dialog: NewDeviceVerificationDialog(
      onPrimaryTap: () {
        Navigator.of(context, rootNavigator: true).pop();
        Future.microtask(() {
          if (!context.mounted) return;
          context.push(
            '${RouteConstants.temporaryBlockOtp}?flow=deviceVerification&phone=$phoneNumber&verification_id=$verificationId',
            extra: OtpVerificationArgs(
              phoneNumber: phoneNumber,
              title: 'Verify Your Identity',
              heading: 'Verify Your Identity',
              description:
                  'Enter the OTPs sent to your registered mobile number and email address to verify your identity.',
              primaryButtonLabel: 'Verify & Continue',
              successDialogTitle: 'Device Verified',
              successDialogMessage:
                  'This device has been successfully verified and added to your trusted devices. You can now access your account securely.',
              successButtonLabel: 'Continue to Login',
              successRoute: RouteConstants.login,
              successRouteUseGo: true,
              clearTemporaryAccessOnSuccess: false,
              deviceVerificationId: verificationId,
              temporaryBlockFlowType: TemporaryBlockFlowType.deviceVerification,
            ),
          );
        });
      },
    ),
  );
}
