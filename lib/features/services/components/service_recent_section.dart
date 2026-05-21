import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/app_network_image.dart';
import '../../mobile_prepaid/models/latest_transaction.dart';

class ServiceRecentSection extends StatelessWidget {
  const ServiceRecentSection({
    super.key,
    required this.recentTransactions,
    required this.onPayNow,
    this.title = 'Recent',
    this.actionText = 'View all',
    this.onAction,
  });

  final AsyncValue<List<LatestTransaction>> recentTransactions;
  final ValueChanged<LatestTransaction> onPayNow;
  final String title;
  final String actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return recentTransactions.when(
      loading: () => Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: _SectionHeader(
                title: title,
                actionText: actionText,
                onAction: onAction,
              ),
            ),
            SizedBox(height: 10.h),
            _RecentRow(
              recentTransactions: recentTransactions,
              onPayNow: onPayNow,
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                child: _SectionHeader(
                  title: title,
                  actionText: actionText,
                  onAction: onAction,
                ),
              ),
              SizedBox(height: 10.h),
              _RecentRow(
                recentTransactions: AsyncValue.data(items),
                onPayNow: onPayNow,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  final String title;
  final String actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        const Spacer(),
        if (actionText.trim().isNotEmpty && onAction != null)
          InkWell(
            onTap: onAction,
            child: Text(
              actionText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFE85A2C),
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.recentTransactions,
    required this.onPayNow,
  });

  final AsyncValue<List<LatestTransaction>> recentTransactions;
  final ValueChanged<LatestTransaction> onPayNow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124.h,
      child: recentTransactions.when(
        loading: () => ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          scrollDirection: Axis.horizontal,
          itemCount: 2,
          separatorBuilder: (_, __) => SizedBox(width: 12.w),
          itemBuilder: (_, __) => const _RecentCardShimmer(),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (items) {
          if (items.isEmpty) return const SizedBox.shrink();
          final display = items.take(10).toList();
          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            itemCount: display.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) => _RecentCard(
              txn: display[index],
              onPayNow: () => onPayNow(display[index]),
            ),
          );
        },
      ),
    );
  }
}

class _RecentCardShimmer extends StatelessWidget {
  const _RecentCardShimmer();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: 280.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E2E2)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Container(
                    height: 38.w,
                    width: 38.w,
                    decoration: BoxDecoration(
                      color: AppColors.lightBorder.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12.h,
                          width: 160.w,
                          decoration: BoxDecoration(
                            color: AppColors.lightBorder.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          height: 10.h,
                          width: 110.w,
                          decoration: BoxDecoration(
                            color: AppColors.lightBorder.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    height: 18.h,
                    width: 18.h,
                    decoration: BoxDecoration(
                      color: AppColors.lightBorder.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.lightBorder.withOpacity(0.7)),
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16.h,
                          width: 120.w,
                          decoration: BoxDecoration(
                            color: AppColors.lightBorder.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          height: 10.h,
                          width: 130.w,
                          decoration: BoxDecoration(
                            color: AppColors.lightBorder.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    height: 30.h,
                    width: 78.w,
                    decoration: BoxDecoration(
                      color: AppColors.lightBorder.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                  ),
                ],
              ),
            ),
            // Prevent tiny RenderFlex overflow due to fractional dp rounding.
            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.txn, required this.onPayNow});

  final LatestTransaction txn;
  final VoidCallback onPayNow;

  @override
  Widget build(BuildContext context) {
    final title = txn.billerName.trim();
    final serviceNo = txn.serviceNo.trim();
    final amount = txn.amount;
    final dueLabel = _formatDueDate(txn.dueDate);

    return Container(
      width: 280.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Container(
                  height: 38.w,
                  width: 38.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: ClipOval(
                    child: txn.icon.trim().isEmpty
                        ? Icon(
                            Icons.bolt,
                            size: 18.sp,
                            color: AppColors.primary,
                          )
                        : AppNetworkImage(
                            url: txn.icon,
                            fit: BoxFit.contain,
                            showShimmer: false,
                          ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        serviceNo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_vert,
                  color: AppColors.textPrimary.withOpacity(0.45),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.lightBorder.withOpacity(0.7)),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      if (dueLabel.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          dueLabel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                SizedBox(
                  height: 30.h,
                  child: ElevatedButton(
                    onPressed: onPayNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE85A2C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22.r),
                      ),
                    ),
                    child: Text(
                      'Pay Now',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDueDate(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty || value.toLowerCase() == 'null') return '';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return 'Due On $value';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final m = months[parsed.month - 1];
  return 'Due On ${parsed.day} $m ${parsed.year}';
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value * 3 - 1;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              colors: [
                AppColors.lightBorder.withOpacity(0.2),
                AppColors.lightBorder.withOpacity(0.6),
                AppColors.lightBorder.withOpacity(0.2),
              ],
              stops: const [0.25, 0.5, 0.75],
              begin: const Alignment(-1, -0.3),
              end: const Alignment(1, 0.3),
              transform: _SlidingGradientTransform(value),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);
  final double slidePercent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

