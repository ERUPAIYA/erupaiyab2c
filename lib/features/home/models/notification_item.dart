import '../../../constants/file_constants.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.iconAsset,
    required this.section,
    this.iconUrl,
    this.showRemindButton = false,
    this.type,
    this.redirectScreen,
    this.referenceId,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      actionLabel: (json['actionLabel'] ?? '').toString(),
      iconAsset: (json['iconAsset'] ?? '').toString(),
      section: (json['section'] ?? '').toString(),
    );
  }

  factory NotificationItem.fromApi(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['message'] ?? '').toString(),
      actionLabel: _actionLabelFor(json),
      iconAsset: _iconFor(json),
      section: _sectionFor(json),
      iconUrl: (json['icon'] ?? '').toString(),
      showRemindButton: () {
        final raw = json['show_remind_button'];
        if (raw == true) return true;
        final normalized = (raw ?? '').toString().toLowerCase().trim();
        return normalized == 'true' || normalized == '1' || normalized == 'yes';
      }(),
      type: (json['type'] ?? '').toString(),
      redirectScreen: (json['redirect_screen'] ?? '').toString(),
      referenceId: (json['reference_id'] ?? '').toString(),
      isRead: (json['is_read'] ?? '').toString() == '1',
      createdAt: _parseCreatedAt(json['created_at']?.toString()),
    );
  }

  static List<NotificationItem> fromJsonList(List<dynamic> items) {
    return items
        .whereType<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .toList();
  }

  final String id;
  final String title;
  final String subtitle;
  final String actionLabel;
  final String iconAsset;
  final String section;
  final String? iconUrl;
  final bool showRemindButton;
  final String? type;
  final String? redirectScreen;
  final String? referenceId;
  final bool isRead;
  final DateTime? createdAt;

  String get _combinedText =>
      '${title.trim()} ${subtitle.trim()} ${(type ?? '').trim()} ${(redirectScreen ?? '').trim()}'
          .toLowerCase();

  bool get isBillPaymentSuccessNotification {
    final text = _combinedText;
    return (text.contains('bill payment successful') ||
            text.contains('payment successful') ||
            text.contains('payment success') ||
            text.contains('paid successfully')) &&
        !text.contains('reminder');
  }

  bool get isBillReminderNotification {
    if (isBillPaymentSuccessNotification) return false;
    final text = _combinedText;
    if (showRemindButton) return true;
    return text.contains('bill reminder') ||
        text.contains('due date') ||
        text.contains('due in') ||
        text.contains('remind');
  }

  static DateTime? _parseCreatedAt(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
    return DateTime.tryParse(normalized);
  }

  static String _sectionFor(Map<String, dynamic> json) {
    final createdAt = _parseCreatedAt(json['created_at']?.toString());
    if (createdAt == null) return 'Today';
    final now = DateTime.now();
    if (createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day) {
      return 'Today';
    }
    return 'Earlier';
  }

  static String _iconFor(Map<String, dynamic> json) {
    final title = (json['title'] ?? '').toString().toLowerCase();
    final message = (json['message'] ?? '').toString().toLowerCase();
    final combined = '$title $message';
    if (combined.contains('spin')) {
      return FileConstants.spincoin;
    }
    return FileConstants.erupaiyaLogo;
  }

  static String _actionLabelFor(Map<String, dynamic> json) {
    final title = (json['title'] ?? '').toString().toLowerCase();
    final message = (json['message'] ?? '').toString().toLowerCase();
    final combined = '$title $message';
    if (combined.contains('spin')) {
      return 'Play Now';
    }
    return 'View';
  }
}
