class RechargeStatusResult {
  const RechargeStatusResult({
    required this.status,
    required this.message,
    required this.transactionId,
    required this.updatedAt,
    required this.raw,
  });

  final String status;
  final String message;
  final String transactionId;
  final String updatedAt;
  final Map<String, dynamic> raw;

  bool get isSuccess => status.trim().toUpperCase() == 'SUCCESS';
  bool get isFailed => status.trim().toUpperCase() == 'FAILED';
  bool get isPending => status.trim().toUpperCase() == 'PENDING';
  bool get isProcessing => status.trim().toUpperCase() == 'PROCESSING';

  factory RechargeStatusResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : const <String, dynamic>{};

    String read(String key) {
      final nested = (data[key] ?? '').toString().trim();
      if (nested.isNotEmpty) return nested;
      return (json[key] ?? '').toString().trim();
    }

    final rawStatus = json['status'];
    final resolvedStatus =
        rawStatus is bool ? read('status') : (json['status'] ?? '').toString().trim();

    return RechargeStatusResult(
      status: resolvedStatus,
      message: read('message'),
      transactionId: read('transaction_id').isNotEmpty
          ? read('transaction_id')
          : (read('transactionId').isNotEmpty ? read('transactionId') : read('transaction_ref')),
      updatedAt: read('updated_at'),
      raw: json,
    );
  }
}
