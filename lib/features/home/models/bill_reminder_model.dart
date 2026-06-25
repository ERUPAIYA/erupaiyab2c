class BillReminderResponse {
  const BillReminderResponse({
    required this.status,
    required this.message,
    required this.currentPage,
    required this.limit,
    required this.totalRecords,
    required this.totalPages,
    required this.items,
  });

  factory BillReminderResponse.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    final rawData = json['data'];
    final items = rawData is List
        ? rawData
            .whereType<Map>()
            .map((e) => BillReminderItem.fromJson(
                  e.map((key, value) => MapEntry(key.toString(), value)),
                ))
            .toList()
        : const <BillReminderItem>[];
    return BillReminderResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      currentPage: _readInt(pagination['current_page']) ?? 1,
      limit: _readInt(pagination['limit']) ?? 20,
      totalRecords: _readInt(pagination['total_records']) ?? 0,
      totalPages: _readInt(pagination['total_pages']) ?? 1,
      items: items,
    );
  }

  final bool status;
  final String message;
  final int currentPage;
  final int limit;
  final int totalRecords;
  final int totalPages;
  final List<BillReminderItem> items;
}

class BillReminderItem {
  const BillReminderItem({
    required this.id,
    required this.billerId,
    required this.billerName,
    required this.paymentType,
    required this.billerIcon,
    required this.maskedIdentifier,
    required this.customerMobile,
    required this.lastBillAmount,
    required this.dueDate,
    required this.billGeneratedDate,
    required this.daysRemaining,
    required this.priority,
    required this.note,
    required this.description,
    required this.lastFetchedAt,
    required this.canPayNow,
  });

  factory BillReminderItem.fromJson(Map<String, dynamic> json) {
    return BillReminderItem(
      id: _readInt(json['id']) ?? 0,
      billerId: (json['biller_id'] ?? '').toString(),
      billerName: (json['biller_name'] ?? '').toString(),
      paymentType: (json['payment_type'] ?? '').toString(),
      billerIcon: (json['biller_icon'] ?? '').toString(),
      maskedIdentifier: (json['masked_identifier'] ?? '').toString(),
      customerMobile: (json['customer_mobile'] ?? '').toString(),
      lastBillAmount: _readDouble(json['last_bill_amount']) ?? 0,
      dueDate: (json['due_date'] ?? '').toString(),
      billGeneratedDate: (json['bill_generated_date'] ?? '').toString(),
      daysRemaining: _readInt(json['days_remaining']) ?? 0,
      priority: (json['priority'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      description: json['description']?.toString(),
      lastFetchedAt: (json['last_fetched_at'] ?? '').toString(),
      canPayNow: json['can_pay_now'] == true,
    );
  }

  final int id;
  final String billerId;
  final String billerName;
  final String paymentType;
  final String billerIcon;
  final String maskedIdentifier;
  final String customerMobile;
  final double lastBillAmount;
  final String dueDate;
  final String billGeneratedDate;
  final int daysRemaining;
  final String priority;
  final String note;
  final String? description;
  final String lastFetchedAt;
  final bool canPayNow;
}

int? _readInt(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString());
}

double? _readDouble(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString());
}
