// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:e_rupaiya/core/barrel_file.dart';
import 'package:e_rupaiya/features/home/components/quick_action_header_card.dart';

class SimpleQuickActionCard extends StatelessWidget {
  const SimpleQuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingAsset,
    this.leadingImageUrl,
    this.onTap,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? leadingAsset;
  final String? leadingImageUrl;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final hasAction = (actionLabel ?? '').trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        constraints: BoxConstraints(minHeight: 62.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffE2E2E2)),
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          // boxShadow: const [
          //   BoxShadow(
          //     color: AppColors.cardShadow,
          //     blurRadius: 18,
          //     offset: Offset(0, 8),
          //   ),
          // ],
        ),
        child: Row(
          children: [
            /// LEFT ICON
            Container(
              height: 45.h,
              width: 45.h,
              padding: EdgeInsets.all(8.w), // creates that inner spacing
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(16.r), // more rounded than current
                border: Border.all(color: const Color(0xffE2E2E2)),
              ),
              child: LeadingIcon(
                asset: leadingAsset,
                url: leadingImageUrl,
              ),
            ),
            // Container(
            //   height: 44.h,
            //   width: 44.h,
            //   alignment: Alignment.center,
            //   decoration: BoxDecoration(
            //     color: AppColors.white,
            //     borderRadius: BorderRadius.circular(10),
            //     border: Border.all(color: const Color(0xffE2E2E2)),
            //   ),
            //   child: LeadingIcon(
            //     asset: leadingAsset,
            //     url: leadingImageUrl,
            //   ),
            // ),

            SizedBox(width: 8.w),

            /// TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title.trim().isNotEmpty)
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 13.sp,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (title.trim().isNotEmpty && subtitle.trim().isNotEmpty)
                    SizedBox(height: 2.h),
                  if (subtitle.trim().isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.65),
                            fontSize: 8.sp,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (hasAction)
              GestureDetector(
                onTap: onAction ?? onTap,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE85A2C), // same as your UI
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    actionLabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
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
