import '../../../config/temporary_block_debug_config.dart';

class OtpVerificationArgs {
  const OtpVerificationArgs({
    this.phoneNumber,
    this.title = 'Verify Your OTP',
    this.heading = 'Enter OTP',
    this.description,
    this.primaryButtonLabel,
    this.resendSuccessMessage,
    this.successRoute,
    this.successRouteExtra,
    this.successDialogTitle,
    this.successDialogMessage,
    this.successButtonLabel,
    this.temporaryBlockFlowType,
  });

  final String? phoneNumber;
  final String title;
  final String heading;
  final String? description;
  final String? primaryButtonLabel;
  final String? resendSuccessMessage;
  final String? successRoute;
  final Object? successRouteExtra;
  final String? successDialogTitle;
  final String? successDialogMessage;
  final String? successButtonLabel;
  final TemporaryBlockFlowType? temporaryBlockFlowType;

  bool get hasCustomSuccessFlow =>
      successRoute != null ||
      successDialogTitle != null ||
      successDialogMessage != null ||
      successButtonLabel != null;
}
