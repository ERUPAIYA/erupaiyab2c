class MyNumberInfo {
  const MyNumberInfo({
    required this.number,
    this.operatorName,
    this.operatorIcon,
    this.lastOn,
    this.dueLabel,
  });

  final String number;
  final String? operatorName;
  final String? operatorIcon;
  final String? lastOn;
  final String? dueLabel;

  factory MyNumberInfo.fromJson(Map<String, dynamic> json) {
    final number = (json['customer_mobile'] ??
            json['service_no'] ??
            json['serviceNo'] ??
            json['number'] ??
            json['mobile'] ??
            '')
        .toString();

    String? computeRelativeLabel(String prefix, Object? value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) return null;
      final now = DateTime.now();
      final days = parsed.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (days <= 0) return '$prefix Today';
      if (days == 1) return '$prefix In 1 Day';
      return '$prefix In $days Days';
    }

    final dueLabel = computeRelativeLabel('Due', json['due_date']) ??
        computeRelativeLabel('Expires', json['expires_at']);

    return MyNumberInfo(
      number: number,
      operatorName: (json['biller_name'] ??
              json['operator'] ??
              json['operator_name'] ??
              json['operatorName'])
          ?.toString(),
      operatorIcon:
          (json['icon'] ?? json['operator_icon'] ?? json['operatorIcon'])
              ?.toString(),
      lastOn: (json['transaction_time'] ??
              json['last_on'] ??
              json['lastOn'] ??
              json['last_recharge_on'] ??
              json['last_recharge_date'])
          ?.toString(),
      dueLabel: (json['due_label'] ?? json['dueLabel'] ?? json['expiry_label'])
              ?.toString() ??
          dueLabel,
    );
  }
}
