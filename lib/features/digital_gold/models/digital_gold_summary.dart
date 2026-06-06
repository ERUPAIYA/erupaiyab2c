class DigitalGoldSummary {
  const DigitalGoldSummary({
    required this.weightOfGold,
    required this.totalPrice,
    required this.gst,
    required this.finalAmount,
    required this.balanceEcoins,
  });

  factory DigitalGoldSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final dataMap =
        data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return DigitalGoldSummary(
      weightOfGold: (dataMap['weight_of_gold'] ?? '').toString(),
      totalPrice: DigitalGoldMoney.fromJson(
        (dataMap['total_price'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      gst: DigitalGoldTax.fromJson(
        (dataMap['gst'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      finalAmount: DigitalGoldMoney.fromJson(
        (dataMap['final_amount'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      balanceEcoins: ((dataMap['balance'] as Map?)?['ecoins'] ?? '').toString(),
    );
  }

  final String weightOfGold;
  final DigitalGoldMoney totalPrice;
  final DigitalGoldTax gst;
  final DigitalGoldMoney finalAmount;
  final String balanceEcoins;
}

class DigitalGoldMoney {
  const DigitalGoldMoney({
    required this.amount,
    required this.displayAmount,
  });

  factory DigitalGoldMoney.fromJson(Map<String, dynamic> json) {
    return DigitalGoldMoney(
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      displayAmount: (json['display_amount'] ?? '').toString(),
    );
  }

  final double amount;
  final String displayAmount;
}

class DigitalGoldTax {
  const DigitalGoldTax({
    required this.percentage,
    required this.amount,
    required this.displayAmount,
  });

  factory DigitalGoldTax.fromJson(Map<String, dynamic> json) {
    return DigitalGoldTax(
      percentage: (json['percentage'] ?? '').toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      displayAmount: (json['display_amount'] ?? '').toString(),
    );
  }

  final String percentage;
  final double amount;
  final String displayAmount;
}
