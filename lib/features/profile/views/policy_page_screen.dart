import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/app_html.dart';
import '../components/language_chip.dart';
import '../controllers/policy_page_controller.dart';
import '../models/policy_page.dart';

class PolicyPageScreen extends HookConsumerWidget {
  const PolicyPageScreen({
    super.key,
    required this.slug,
    required this.title,
    this.showEnglishOnlyChip = false,
  });

  final String slug;
  final String title;
  final bool showEnglishOnlyChip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(policyPageControllerProvider(slug));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(title: title),
          Expanded(
            child: pageAsync.when(
              loading: () => const _PolicyPageShimmer(),
              error: (error, _) => RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref
                    .read(policyPageControllerProvider(slug).notifier)
                    .load(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 32.h),
                  children: [
                    Text(
                      'Failed to load. Pull to refresh.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '$error',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.7),
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              data: (page) => RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref
                    .read(policyPageControllerProvider(slug).notifier)
                    .load(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        if (showEnglishOnlyChip)
                          const LanguageChip.englishOnly(),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    if (page.banners.isNotEmpty) ...[
                      _Banners(banners: page.banners),
                      SizedBox(height: 14.h),
                    ],
                    AppHtml(html: page.content),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banners extends StatelessWidget {
  const _Banners({required this.banners});

  final List<PolicyPageBanner> banners;

  @override
  Widget build(BuildContext context) {
    final items = banners.where((b) => b.imageUrl.trim().isNotEmpty).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final banner in items) ...[
          _BannerCard(imageUrl: banner.imageUrl),
          SizedBox(height: 10.h),
        ],
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: AspectRatio(
        aspectRatio: 343 / 118,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFFF0F0F0),
          ),
          errorWidget: (context, url, error) => Container(
            color: const Color(0xFFF0F0F0),
            alignment: Alignment.center,
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.textPrimary.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicyPageShimmer extends StatelessWidget {
  const _PolicyPageShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
        children: [
          Container(
            height: 18.h,
            width: 180.w,
            color: Colors.white,
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: AspectRatio(
              aspectRatio: 343 / 118,
              child: Container(color: Colors.white),
            ),
          ),
          SizedBox(height: 14.h),
          const _ShimmerLine(width: 1.0),
          const _ShimmerLine(width: 0.92),
          const _ShimmerLine(width: 0.85),
          const _ShimmerLine(width: 0.95),
          SizedBox(height: 6.h),
          const _ShimmerLine(width: 0.78),
          const _ShimmerLine(width: 0.9),
          const _ShimmerLine(width: 0.8),
          const _ShimmerLine(width: 0.96),
          SizedBox(height: 6.h),
          const _ShimmerLine(width: 0.72),
          const _ShimmerLine(width: 0.88),
          const _ShimmerLine(width: 0.83),
          const _ShimmerLine(width: 0.6),
        ],
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: FractionallySizedBox(
        widthFactor: width.clamp(0.2, 1.0),
        alignment: Alignment.centerLeft,
        child: Container(
          height: 12.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
      ),
    );
  }
}
