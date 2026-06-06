class PrepaidTransactionStatus {
  const PrepaidTransactionStatus({
    required this.status,
    required this.message,
    required this.amount,
    required this.operatorName,
    required this.mobile,
    required this.paymentMode,
    required this.walletAmount,
    required this.razorpayAmount,
    required this.transactionId,
    required this.updatedAt,
  });

  final String status;
  final String message;
  final String amount;
  final String operatorName;
  final String mobile;
  final String paymentMode;
  final String walletAmount;
  final String razorpayAmount;
  final String transactionId;
  final String updatedAt;

  bool get isSuccess => status.trim().toUpperCase() == 'SUCCESS';
  bool get isFailed => status.trim().toUpperCase() == 'FAILED';
  bool get isPending => status.trim().toUpperCase() == 'PENDING';
  bool get isProcessing => status.trim().toUpperCase() == 'PROCESSING';

  factory PrepaidTransactionStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final Map<String, dynamic> flattened = (data is Map)
        ? <String, dynamic>{
            ...json,
            ...data.map((key, value) => MapEntry(key.toString(), value)),
          }
        : json;

    String read(String key) => (flattened[key] ?? '').toString().trim();
    String readPreferRoot(String key) =>
        (json[key] ?? flattened[key] ?? '').toString().trim();

    // Some APIs return a boolean `status` at the root level plus a string
    // status inside `data.status` (e.g. SUCCESS/FAILED/PENDING).
    final resolvedStatus = (() {
      final raw = flattened['status'];
      if (raw is bool) {
        final nested = (data is Map) ? (data['status'] ?? '').toString() : '';
        return nested.trim();
      }
      return (raw ?? '').toString().trim();
    })();

    return PrepaidTransactionStatus(
      status: resolvedStatus,
      message: readPreferRoot('message'),
      amount: read('amount'),
      operatorName: read('operator'),
      mobile: read('mobile'),
      paymentMode: read('payment_mode'),
      walletAmount: read('wallet_amount'),
      razorpayAmount: read('razorpay_amount'),
      transactionId: read('transaction_id').isNotEmpty
          ? read('transaction_id')
          : read('transactionId'),
      updatedAt: read('updated_at'),
    );
  }
}
