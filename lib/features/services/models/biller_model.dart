import '../../../constants/api_constants.dart';

class Biller {
  const Biller({
    required this.billerId,
    required this.billerName,
    this.icon,
  });

  factory Biller.fromJson(Map<String, dynamic> json) {
    return Biller(
      billerId: json['biller_id'] as String? ?? '',
      billerName: json['biller_name'] as String? ?? '',
      icon: json['icon']?.toString(),
    );
  }

  final String billerId;
  final String billerName;
  final String? icon;

  String? get iconUrl {
    final trimmed = icon?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.toLowerCase() == 'default.png') return null;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) return trimmed;
    return '${ApiConstants.billerIconBaseUrl}/$trimmed';
  }
}

class BillerListResponse {
  const BillerListResponse({
    required this.categoryName,
    required this.billers,
    this.currentPage = 1,
    this.totalPages = 1,
    this.limit = 20,
    this.totalRecords = 0,
  });

  factory BillerListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final billersList = data['billers'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return BillerListResponse(
      categoryName: data['category_name'] as String? ?? '',
      billers: billersList
          .map((e) => Biller.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: _parseInt(pagination['current_page']) ?? 1,
      totalPages: _parseInt(pagination['total_pages']) ?? 1,
      limit: _parseInt(pagination['limit']) ?? 20,
      totalRecords: _parseInt(pagination['total_records']) ?? 0,
    );
  }

  final String categoryName;
  final List<Biller> billers;
  final int currentPage;
  final int totalPages;
  final int limit;
  final int totalRecords;
}

int? _parseInt(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString());
}
