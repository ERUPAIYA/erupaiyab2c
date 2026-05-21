// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/app_network_image.dart';
import '../../home/models/banner_model.dart';

class CreditCardMyCardsBanner extends StatelessWidget {
  const CreditCardMyCardsBanner({
    super.key,
    required this.banners,
  });

  final AsyncValue<List<BannerModel>> banners;

  @override
  Widget build(BuildContext context) {
    return banners.when(
      loading: () => _fallback(),
      error: (_, __) => _fallback(),
      data: (items) {
        final banner = items.isNotEmpty ? items.first : null;
        final image = banner?.image.trim() ?? '';
        if (image.isEmpty) return _fallback();

        return AppNetworkImage(
          url: image,
          width: double.infinity,
          fit: BoxFit.contain,
          showShimmer: true,
          borderRadius: BorderRadius.circular(14.r),
        );
      },
    );
  }

  Widget _fallback() {
    return Container(
      height: 74.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        FileConstants.homeBanner4,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
