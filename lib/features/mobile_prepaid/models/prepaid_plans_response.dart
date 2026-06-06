import 'plan_item.dart';

class PrepaidPlansResponse {
  const PrepaidPlansResponse({
    required this.plansByCategory,
    required this.validityFilters,
    required this.dataFilters,
    required this.filterTags,
    this.ecoinsRestrictionsPercent,
  });

  final Map<String, List<PlanItem>> plansByCategory;
  final List<String> validityFilters;
  final List<String> dataFilters;
  final List<String> filterTags;
  final double? ecoinsRestrictionsPercent;
}
