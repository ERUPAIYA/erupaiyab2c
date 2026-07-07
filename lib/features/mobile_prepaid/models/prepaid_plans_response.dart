import 'plan_item.dart';

class PrepaidPlansResponse {
  const PrepaidPlansResponse({
    required this.plansByCategory,
    required this.validityFilters,
    required this.dataFilters,
    required this.filterTags,
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.limit,
    required this.hasMorePages,
    this.ecoinsRestrictionsPercent,
  });

  final Map<String, List<PlanItem>> plansByCategory;
  final List<String> validityFilters;
  final List<String> dataFilters;
  final List<String> filterTags;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final int limit;
  final bool hasMorePages;
  final double? ecoinsRestrictionsPercent;
}
