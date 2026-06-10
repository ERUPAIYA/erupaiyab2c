import 'notification_item.dart';

class NotificationsFeed {
  const NotificationsFeed({
    required this.unreadCount,
    required this.updates,
    required this.notifications,
    this.currentPage = 1,
    this.totalPages = 1,
    this.limit = 20,
    this.totalRecords = 0,
  });

  final int unreadCount;
  final List<NotificationItem> updates;
  final List<NotificationItem> notifications;
  final int currentPage;
  final int totalPages;
  final int limit;
  final int totalRecords;

  bool get hasMore => currentPage < totalPages;
}
