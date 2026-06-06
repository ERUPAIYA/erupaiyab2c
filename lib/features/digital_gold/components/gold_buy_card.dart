import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/quick_amount_option.dart';
import 'gold_amount_chip.dart';
import 'gold_amount_input_card.dart';
import 'gold_live_price_row.dart';
import 'gold_toggle_option.dart';

class GoldBuyCard extends StatelessWidget {
  const GoldBuyCard({
    super.key,
    required this.isBuyingInRupees,
    required this.onUnitChanged,
    required this.amountController,
    required this.quickAmounts,
    required this.onAmountSelected,
    required this.leftToggleLabel,
    required this.rightToggleLabel,
    required this.priceText,
    required this.trailingText,
    required this.prefixText,
    this.unitText,
    required this.cardColor,
    this.chipGradient,
    required this.toggleActiveColor,
  });

  final bool isBuyingInRupees;
  final ValueChanged<bool> onUnitChanged;
  final TextEditingController amountController;
  final List<QuickAmountOption> quickAmounts;
  final ValueChanged<int> onAmountSelected;
  final String leftToggleLabel;
  final String rightToggleLabel;
  final String priceText;
  final String trailingText;
  final String prefixText;
  final String? unitText;
  final Color cardColor;
  final LinearGradient? chipGradient;
  final Color toggleActiveColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 16.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xffE6E6E6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GoldToggleOption(
                label: leftToggleLabel,
                selected: isBuyingInRupees,
                onTap: () => onUnitChanged(true),
                activeColor: toggleActiveColor,
              ),
              SizedBox(width: 24.w),
              GoldToggleOption(
                label: rightToggleLabel,
                selected: !isBuyingInRupees,
                onTap: () => onUnitChanged(false),
                activeColor: toggleActiveColor,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          GoldAmountInputCard(
            controller: amountController,
            trailingText: trailingText,
            prefixText: prefixText,
            unitText: unitText,
          ),
          SizedBox(height: 12.h),
          GoldLivePriceRow(
            priceText: priceText,
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: quickAmounts
                .map(
                  (option) => GoldAmountChip(
                    label: option.label,
                    onTap: () => onAmountSelected(option.value),
                    gradient: chipGradient,
                    color: null,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
