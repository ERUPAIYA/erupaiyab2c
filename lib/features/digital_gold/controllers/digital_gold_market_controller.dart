import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/digital_metal.dart';
import '../repo/digital_gold_repo.dart';

class DigitalGoldMarketInfo {
  const DigitalGoldMarketInfo({
    required this.pricePerGram,
    required this.changePercent,
    required this.qualityLabel,
  });

  final double pricePerGram;
  final double changePercent;
  final String qualityLabel;
}

final digitalGoldMarketProvider =
    FutureProvider.autoDispose.family<DigitalGoldMarketInfo, DigitalMetal>(
  (ref, metal) async {
    final repo = ref.watch(digitalGoldRepoProvider);
    // Best-effort market snapshot using the existing preview endpoint.
    // For now, treat `total_amount` as the indicative per-gram value for 1g.
    final preview = await repo.fetchProceedPreview(
      calculationType: 'Q',
      amount: '1',
      quantity: '1',
      metalType: metal == DigitalMetal.gold ? 'G' : 'S',
    );

    return DigitalGoldMarketInfo(
      pricePerGram: preview.totalAmount,
      changePercent: 1.135, // API not available yet
      qualityLabel: metal == DigitalMetal.gold
          ? '24k | 99% | Pure Gold'
          : '24k | 99% | Pure Silver',
    );
  },
);

