enum TemporaryBlockFlowType {
  noKyc,
  kycVerified,
  deviceVerification,
}

class TemporaryBlockDebugConfig {
  const TemporaryBlockDebugConfig._();

  static const bool enabled = false;

  static const TemporaryBlockFlowType flowType =
      TemporaryBlockFlowType.noKyc;
}
