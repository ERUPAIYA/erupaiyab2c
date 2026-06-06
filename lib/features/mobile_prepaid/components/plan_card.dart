// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/app_divider.dart';
import '../../../widgets/k_dialog.dart';
import '../models/plan_item.dart';
import 'plan_details_sheet.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onTap,
    this.onViewDetails,
    this.onPayNow,
  });

  final PlanItem plan;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onViewDetails;
  final VoidCallback? onPayNow;

  void _openPlanDetailsSheet(BuildContext context) {
    KDialog.instance.openSheet(
      dialog: PlanDetailsSheet(
        plan: plan,
        onProceedToPay: onPayNow ?? onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assuredCoinsLabel =
        plan.eCoins > 0 ? 'Get Assured ${plan.eCoins} E-Coins' : '';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightBorder,
            width: isSelected ? 1.5.w : 1.w,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Price + E-Coins badge
              _PlanPriceRow(
                plan: plan,
                assuredLabel: assuredCoinsLabel,
                rightShift: 10.w,
              ),
              SizedBox(height: 12.h),
              // Row 2: Validity | Data | Benefit images
              _PlanInfoRow(
                plan: plan,
                onBenefitsTap: () => _openPlanDetailsSheet(context),
              ),
              SizedBox(height: 12.h),
              const AppDivider(),
              SizedBox(height: 10.h),
              // Description
              Text(
                plan.description.isEmpty
                    ? 'No description available.'
                    : plan.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.7),
                      height: 1.4,
                      fontSize: 10.sp,
                    ),
              ),
              SizedBox(height: 14.h),
              // View Details + Pay Now row
              Container(
                margin: EdgeInsets.only(bottom: 4.h),
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onViewDetails ?? onTap,
                      child: Text(
                        'View Details',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp,
                            ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 160.w,
                      child: _PlanPayNowButton(
                        onTap: onPayNow ?? onTap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanPriceRow extends StatelessWidget {
  const _PlanPriceRow({
    required this.plan,
    required this.assuredLabel,
    this.rightShift = 0,
  });

  final PlanItem plan;
  final String assuredLabel;
  final double rightShift;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '₹ ${plan.amount}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                fontSize: 28.sp,
              ),
        ),
        const Spacer(),
        if (assuredLabel.isNotEmpty)
          Transform.translate(
            offset: Offset(rightShift, 0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3554),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.r),
                  bottomLeft: Radius.circular(18.r),
                ),
              ),
              child: Text(
                assuredLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.sp,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanInfoRow extends StatelessWidget {
  const _PlanInfoRow({
    required this.plan,
    this.onBenefitsTap,
  });

  final PlanItem plan;
  final VoidCallback? onBenefitsTap;

  @override
  Widget build(BuildContext context) {
    final hasValidity = plan.validity.isNotEmpty;
    final dataValue = extractPlanDataValue(plan);
    final hasData = dataValue.isNotEmpty;
    final hasBenefitImages = plan.additionalBenefits.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasValidity)
                      _PlanInfoColumn(
                        label: 'Validity',
                        value: plan.validity,
                      ),
                    if (hasValidity && hasData) ...[
                      SizedBox(width: 14.w),
                      VerticalDivider(
                        width: 12.w,
                        thickness: 1,
                        color: AppColors.lightBorder,
                      ),
                      SizedBox(width: 14.w),
                    ],
                    if (hasData)
                      _PlanInfoColumn(
                        label: 'Data',
                        value: dataValue,
                      ),
                  ],
                ),
              ),
            ),
            if (hasBenefitImages)
              _PlanBenefitImages(
                benefits: plan.additionalBenefits,
                onTap: onBenefitsTap,
              ),
          ],
        );
      },
    );
  }
}

class _PlanInfoColumn extends StatelessWidget {
  const _PlanInfoColumn({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 8.sp,
              ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 10.sp,
              ),
        ),
      ],
    );
  }
}

class _PlanBenefitImages extends StatelessWidget {
  const _PlanBenefitImages({
    required this.benefits,
    this.onTap,
  });

  final List<AdditionalBenefit> benefits;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const maxVisible = 5;
    final visibleBenefits = benefits.take(maxVisible).toList();
    final remaining = benefits.length - maxVisible;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: (visibleBenefits.length * 22.0).w + 8.w,
            height: 26.h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < visibleBenefits.length; i++)
                  Positioned(
                    left: (i * 22.0).w,
                    child: _BenefitIconAvatar(benefit: visibleBenefits[i]),
                  ),
              ],
            ),
          ),
          if (remaining > 0)
            Text(
              '+$remaining',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                  ),
            ),
        ],
      ),
    );
  }
}

class _BenefitIconAvatar extends StatelessWidget {
  const _BenefitIconAvatar({required this.benefit});

  final AdditionalBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30.w,
      height: 30.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: benefit.image == null
            ? Container(
                color: Colors.grey.shade200,
                child: Icon(Icons.card_giftcard, size: 14.sp),
              )
            : Image.network(
                benefit.image!,
                width: 30.w,
                height: 30.w,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image, size: 14.sp),
                ),
              ),
      ),
    );
  }
}

class _PlanPayNowButton extends StatelessWidget {
  const _PlanPayNowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE85A2C),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          'Pay Now',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
