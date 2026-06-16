class AuthLoginResult {
  const AuthLoginResult._({
    required this.isSuccess,
    required this.isSuspected,
    required this.requiresDeviceVerification,
    this.message,
    this.tempAccessToken,
    this.isKycVerified,
    this.verificationId,
    this.showPopup,
  });

  const AuthLoginResult.success()
      : this._(
          isSuccess: true,
          isSuspected: false,
          requiresDeviceVerification: false,
        );

  const AuthLoginResult.suspected({
    required String tempAccessToken,
    required bool isKycVerified,
    String? message,
  }) : this._(
          isSuccess: false,
          isSuspected: true,
          requiresDeviceVerification: false,
          tempAccessToken: tempAccessToken,
          isKycVerified: isKycVerified,
          message: message,
        );

  const AuthLoginResult.deviceVerificationRequired({
    required String verificationId,
    bool showPopup = true,
    String? message,
  }) : this._(
          isSuccess: false,
          isSuspected: false,
          requiresDeviceVerification: true,
          verificationId: verificationId,
          showPopup: showPopup,
          message: message,
        );

  const AuthLoginResult.failure({String? message})
      : this._(
          isSuccess: false,
          isSuspected: false,
          requiresDeviceVerification: false,
          message: message,
        );

  final bool isSuccess;
  final bool isSuspected;
  final bool requiresDeviceVerification;
  final String? message;
  final String? tempAccessToken;
  final bool? isKycVerified;
  final String? verificationId;
  final bool? showPopup;
}
