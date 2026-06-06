import 'transaction_history_entry.dart';

class TransactionHistoryPage {
  const TransactionHistoryPage({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.limit,
  });

  final List<TransactionHistoryEntry> items;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final int limit;

  bool get hasMore => currentPage < totalPages;

  factory TransactionHistoryPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    int readInt(String key, [int fallback = 0]) {
      final raw = pagination[key];
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '') ?? fallback;
    }

    final data = json['data'];
    final items = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(TransactionHistoryEntry.fromJson)
            .toList()
        : const <TransactionHistoryEntry>[];

    return TransactionHistoryPage(
      items: items,
      currentPage: readInt('current_page', 1),
      totalPages: readInt('total_pages', 1),
      totalRecords: readInt('total_records', items.length),
      limit: readInt('limit', items.length),
    );
  }
}

