class RechargeQuickActionPayload {
  const RechargeQuickActionPayload({
    required this.phone,
    required this.amount,
    this.desc,
    this.operatorName,
    this.iconUrl,
    this.autoOpenPaymentSheet = false,
  });

  final String phone;
  final int amount;
  final String? desc;
  final String? operatorName;
  final String? iconUrl;
  final bool autoOpenPaymentSheet;
}
