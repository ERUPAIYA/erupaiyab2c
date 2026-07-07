class LatestTransaction {
  const LatestTransaction({
    required this.id,
    this.billerId = '',
    required this.paymentType,
    required this.billerName,
    required this.amount,
    required this.status,
    required this.transactionRef,
    required this.serviceNo,
    this.serviceNoFull,
    required this.icon,
    this.createdAt,
    this.expiresAt,
    this.dueDate,
    this.transactionTime,
  });

  final String id;
  final String billerId;
  final String paymentType;
  final String billerName;
  final num amount;
  final String status;
  final String transactionRef;
  final String serviceNo;
  final String? serviceNoFull;
  final String icon;
  final String? createdAt;
  final String? expiresAt;
  final String? dueDate;
  final String? transactionTime;

  factory LatestTransaction.fromJson(Map<String, dynamic> json) {
    return LatestTransaction(
      id: (json['id'] ?? '').toString(),
      billerId: (json['biller_id'] ?? json['provider_id'] ?? '').toString(),
      paymentType: (json['payment_type'] ?? '').toString(),
      billerName: (json['biller_name'] ?? '').toString(),
      amount: json['amount'] is num
          ? (json['amount'] as num)
          : num.tryParse((json['amount'] ?? '0').toString()) ?? 0,
      status: (json['status'] ?? '').toString(),
      transactionRef: (json['transaction_ref'] ?? '').toString(),
      serviceNo: (json['service_no'] ?? '').toString(),
      serviceNoFull:
          (json['service_no_full'] ?? json['serviceNoFull'])?.toString(),
      icon: (json['icon'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
      expiresAt: json['expires_at']?.toString(),
      dueDate: json['due_date']?.toString(),
      transactionTime: json['transaction_time']?.toString(),
    );
  }

  bool get isSuccess => status.trim().toLowerCase() == 'success';
}
