class AuthState {
  const AuthState({
    required this.isAuthenticated,
    required this.hasTemporaryAccess,
    required this.isLoading,
    required this.isSubmitting,
    this.pendingMobile,
    this.postOtpToken,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(
        isAuthenticated: false,
        hasTemporaryAccess: false,
        isLoading: true,
        isSubmitting: false,
      );

  final bool isAuthenticated;
  final bool hasTemporaryAccess;
  final bool isLoading;
  final bool isSubmitting;
  final String? pendingMobile;
  final String? postOtpToken;
  final String? errorMessage;

  static const _sentinel = Object();

  AuthState copyWith({
    bool? isAuthenticated,
    bool? hasTemporaryAccess,
    bool? isLoading,
    bool? isSubmitting,
    Object? pendingMobile = _sentinel,
    Object? postOtpToken = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasTemporaryAccess: hasTemporaryAccess ?? this.hasTemporaryAccess,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      pendingMobile: pendingMobile == _sentinel
          ? this.pendingMobile
          : pendingMobile as String?,
      postOtpToken: postOtpToken == _sentinel
          ? this.postOtpToken
          : postOtpToken as String?,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
