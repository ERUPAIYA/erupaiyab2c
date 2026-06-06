import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';

class GoldLivePriceRow extends StatelessWidget {
  const GoldLivePriceRow({super.key, required this.priceText});

  final String priceText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Container(
                width: 6.w,
                height: 6.w,
                decoration: const BoxDecoration(
                  color: Color(0xffFF0000),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'Live',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xffFF0000),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            priceText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
