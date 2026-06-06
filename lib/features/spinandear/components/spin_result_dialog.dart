// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../models/spin_reward.dart';

class SpinResultDialog extends StatefulWidget {
  const SpinResultDialog({
    super.key,
    required this.reward,
    required this.onPrimaryTap,
  });

  final SpinReward reward;
  final Future<void> Function() onPrimaryTap;

  @override
  State<SpinResultDialog> createState() => _SpinResultDialogState();
}

class _SpinResultDialogState extends State<SpinResultDialog> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    final isBetterLuck = reward.type == SpinRewardType.betterLuck;
    final isExtraSpin = reward.type == SpinRewardType.extraSpin;

    final title = isBetterLuck
        ? 'Better Luck\nNext Time!'
        : isExtraSpin
            ? 'Woww,\nYou Got An Extra Spin!'
            : reward.type == SpinRewardType.jackpot
                ? 'Woww,\nJackpot Spin!'
                : 'Woww,\nYou Have Won ${reward.coins ?? 0}e-Coins';

    final subtitle = isBetterLuck
        ? "Don't give up! Spin again for another\nchance to win amazing rewards."
        : isExtraSpin
            ? 'Rock this chance and earn e-Coins for real\nuse. Spin now and boost your wallet!'
            : 'Use your earned e-Coins for real-world\nbenefits like mobile recharges, electricity\nbills, or credit card payments. Spin now\nand boost your wallet!';

    final buttonLabel = isBetterLuck || isExtraSpin ? 'Try Again' : 'Claim Now';

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Image.asset(
                FileConstants.coin_3d,
                width: 58.w,
                height: 58.h,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title.replaceAll('e-Coins', 'E-Coins'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isBetterLuck
                        ? Colors.grey.shade700
                        : AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.7),
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);
                        try {
                          await widget.onPrimaryTap();
                          if (!context.mounted) return;
                          Navigator.of(context, rootNavigator: true).pop();
                        } finally {
                          if (mounted) setState(() => _isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isBetterLuck ? Colors.grey.shade500 : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
