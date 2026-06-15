class AuthLoginResult {
  const AuthLoginResult._({
    required this.isSuccess,
    required this.isSuspected,
    this.message,
    this.tempAccessToken,
    this.isKycVerified,
  });

  const AuthLoginResult.success()
      : this._(
          isSuccess: true,
          isSuspected: false,
        );

  const AuthLoginResult.suspected({
    required String tempAccessToken,
    required bool isKycVerified,
    String? message,
  }) : this._(
          isSuccess: false,
          isSuspected: true,
          tempAccessToken: tempAccessToken,
          isKycVerified: isKycVerified,
          message: message,
        );

  const AuthLoginResult.failure({String? message})
      : this._(
          isSuccess: false,
          isSuspected: false,
          message: message,
        );

  final bool isSuccess;
  final bool isSuspected;
  final String? message;
  final String? tempAccessToken;
  final bool? isKycVerified;
}
