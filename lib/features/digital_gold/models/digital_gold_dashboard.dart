class DigitalGoldDashboard {
  const DigitalGoldDashboard({
    required this.quickActions,
    this.gold,
    this.silver,
  });

  factory DigitalGoldDashboard.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final dataMap =
        data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final rawActions = dataMap['quick_action'];
    final actions = rawActions is List
        ? rawActions
            .whereType<Map<String, dynamic>>()
            .map(DigitalGoldQuickAction.fromJson)
            .toList(growable: false)
        : const <DigitalGoldQuickAction>[];
    final goldMap = dataMap['gold'];
    final silverMap = dataMap['silver'];
    return DigitalGoldDashboard(
      quickActions: actions,
      gold: goldMap is Map<String, dynamic>
          ? DigitalGoldMetalRate.fromJson(goldMap)
          : null,
      silver: silverMap is Map<String, dynamic>
          ? DigitalGoldMetalRate.fromJson(silverMap)
          : null,
    );
  }

  final List<DigitalGoldQuickAction> quickActions;
  final DigitalGoldMetalRate? gold;
  final DigitalGoldMetalRate? silver;
}

class DigitalGoldQuickAction {
  const DigitalGoldQuickAction({
    required this.name,
    required this.imageUrl,
  });

  factory DigitalGoldQuickAction.fromJson(Map<String, dynamic> json) {
    return DigitalGoldQuickAction(
      name: (json['name'] ?? '').toString(),
      imageUrl: (json['image'] ?? '').toString(),
    );
  }

  final String name;
  final String imageUrl;
}

class DigitalGoldMetalRate {
  const DigitalGoldMetalRate({
    required this.rateToday,
    required this.previousRate,
    required this.difference,
    required this.direction,
    required this.graphImageUrl,
  });

  factory DigitalGoldMetalRate.fromJson(Map<String, dynamic> json) {
    return DigitalGoldMetalRate(
      rateToday: (json['rate_today'] ?? '').toString(),
      previousRate: (json['previous_rate'] ?? '').toString(),
      difference: (json['difference'] ?? '').toString(),
      direction: (json['direction'] ?? '').toString(),
      graphImageUrl: (json['graph_image'] ?? '').toString(),
    );
  }

  final String rateToday;
  final String previousRate;
  final String difference;
  final String direction;
  final String graphImageUrl;

  double get rateTodayValue => double.tryParse(rateToday.trim()) ?? 0.0;
  double get previousRateValue => double.tryParse(previousRate.trim()) ?? 0.0;
  double get differenceValue => double.tryParse(difference.trim()) ?? 0.0;

  double get percentChange {
    final prev = previousRateValue;
    if (prev == 0) return 0.0;
    return (differenceValue / prev) * 100.0;
  }

  bool get isUp => direction.trim().toLowerCase() == 'up';
  bool get isDown => direction.trim().toLowerCase() == 'down';
}
