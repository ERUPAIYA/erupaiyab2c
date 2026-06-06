import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/digital_metal.dart';
import 'digital_gold_invest_view.dart';
import 'digital_gold_home_v2_view.dart';
import 'digital_gold_trade_view.dart';

class DigitalGoldView extends ConsumerWidget {
  const DigitalGoldView({
    super.key,
    this.mode = GoldTradeMode.buy,
    this.metal = DigitalMetal.gold,
    this.validateRegistration = false,
    this.useLegacyDashboard = false,
  });

  final GoldTradeMode mode;
  final DigitalMetal metal;
  final bool validateRegistration;
  final bool useLegacyDashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When user enters from Home, show the "Invest In Gold" dashboard first.
    // Trade screen is reachable via quick actions.
    if (validateRegistration) {
      if (useLegacyDashboard) {
        return const DigitalGoldInvestView();
      }
      return const DigitalGoldHomeV2View();
    }

    return DigitalGoldTradeView(
      mode: mode,
      metal: metal,
      validateRegistration: validateRegistration,
    );
  }
}
