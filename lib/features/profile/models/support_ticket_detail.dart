class SupportTicketDetail {
  const SupportTicketDetail({
    required this.id,
    required this.transactionId,
    required this.service,
    required this.status,
    required this.issueType,
    required this.description,
    required this.createdAt,
    required this.username,
    required this.screenshot,
    required this.messages,
    required this.isReplyButtonEnabled,
  });

  final String id;
  final String transactionId;
  final String service;
  final String status;
  final String issueType;
  final String description;
  final String createdAt;
  final String username;
  final String? screenshot;
  final List<SupportTicketMessage> messages;
  final bool isReplyButtonEnabled;

  factory SupportTicketDetail.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    final messages = rawMessages is List
        ? rawMessages
            .whereType<Map>()
            .map((e) => SupportTicketMessage.fromJson(
                  e.map((k, v) => MapEntry('$k', v)),
                ))
            .toList()
        : <SupportTicketMessage>[];
    return SupportTicketDetail(
      id: (json['id'] ?? '').toString(),
      transactionId: (json['transaction_id'] ?? '').toString(),
      service: (json['service'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      issueType: (json['issue_type'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      screenshot:
          json['screenshot'] == null ? null : json['screenshot'].toString(),
      messages: messages,
      isReplyButtonEnabled: json['is_reply_button_enable'] == true,
    );
  }
}

class SupportTicketMessage {
  const SupportTicketMessage({
    required this.senderType,
    required this.message,
    required this.createdAt,
  });

  final String senderType;
  final String message;
  final String createdAt;

  bool get isAdmin => senderType.trim().toLowerCase() == 'admin';

  factory SupportTicketMessage.fromJson(Map<String, dynamic> json) {
    return SupportTicketMessage(
      senderType: (json['sender_type'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}
