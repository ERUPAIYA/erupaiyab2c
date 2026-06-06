class RechargeOrderResult {
  const RechargeOrderResult({
    required this.isSuccess,
    required this.message,
    required this.transactionRef,
    required this.txnId,
    required this.orderId,
    required this.key,
  });

  final bool isSuccess;
  final String message;
  final String transactionRef;
  final int txnId;
  final String orderId;
  final String key;

  factory RechargeOrderResult.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status'];
    final isSuccess =
        statusValue == true || statusValue?.toString().toLowerCase() == 'true';
    final message = () {
      final direct = (json['message'] ?? '').toString().trim();
      if (direct.isNotEmpty) return direct;

      final messages = json['messages'];
      if (messages is Map) {
        final nestedError = (messages['error'] ?? '').toString().trim();
        if (nestedError.isNotEmpty) return nestedError;
        final nestedMessage = (messages['message'] ?? '').toString().trim();
        if (nestedMessage.isNotEmpty) return nestedMessage;
      }
      return '';
    }();
    return RechargeOrderResult(
      isSuccess: isSuccess,
      message: message,
      transactionRef: (json['transaction_ref'] ?? '').toString().trim(),
      txnId: int.tryParse((json['txn_id'] ?? '').toString()) ?? 0,
      orderId: (json['order_id'] ?? '').toString().trim(),
      key: (json['key'] ?? '').toString().trim(),
    );
  }
}
