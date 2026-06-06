import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';

class GoldAmountChip extends StatelessWidget {
  const GoldAmountChip({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final LinearGradient? gradient;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final hasGradient = gradient != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          gradient: gradient,
          borderRadius: BorderRadius.circular(10.r),
          border: hasGradient
              ? null
              : Border.all(
                  color: AppColors.lightBorder.withOpacity(0.9),
                  width: 1,
                ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
