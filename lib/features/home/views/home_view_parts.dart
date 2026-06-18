// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_element, unused_element_parameter, unused_local_variable

part of 'home_view.dart';

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 14 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.lightBorder,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.onTap,
    this.icon,
    this.iconAsset,
    this.badgeCount,
    this.size = 36,
    this.iconSize = 18,
  }) : assert(icon != null || iconAsset != null);

  final VoidCallback onTap;
  final IconData? icon;
  final String? iconAsset;
  final int? badgeCount;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = size.r;
    final resolvedIconSize = iconSize.r;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(resolvedSize / 2),
      child: Container(
        height: resolvedSize,
        width: resolvedSize,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: iconAsset != null
                  ? Image.asset(
                      iconAsset!,
                      height: resolvedIconSize,
                      width: resolvedIconSize,
                      color: AppColors.textPrimary,
                    )
                  : Icon(
                      icon,
                      size: resolvedIconSize,
                      color: AppColors.textPrimary,
                    ),
            ),
            if ((badgeCount ?? 0) > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  child: Text(
                    (badgeCount ?? 0) > 9 ? '9+' : '${badgeCount ?? 0}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      decoration: TextDecoration.none,
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

class _PagerDots extends StatelessWidget {
  const _PagerDots();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(active: true),
        SizedBox(width: 6),
        _Dot(active: false),
        SizedBox(width: 6),
        _Dot(active: false),
      ],
    );
  }
}

class _BottomIcon extends StatelessWidget {
  const _BottomIcon({
    required this.asset,
    this.size = 26,
    this.color,
    this.yOffset = 0,
  });
  final String asset;
  final double size;
  final Color? color;
  final double yOffset;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (size * dpr).round();
    final icon = SizedBox(
      height: size,
      width: size,
      child: Center(
        child: Image.asset(
          asset,
          height: size,
          width: size,
          fit: BoxFit.cover,
          color: color,
          cacheWidth: cacheW,
          cacheHeight: cacheW,
        ),
      ),
    );
    if (yOffset == 0) return icon;
    return Transform.translate(offset: Offset(0, yOffset), child: icon);
  }
}

class _BottomIconWithBadge extends StatelessWidget {
  const _BottomIconWithBadge({
    required this.asset,
    this.size = 20,
    this.color,
    this.yOffset = 0,
  });

  final String asset;
  final double size;
  final Color? color;
  final double yOffset;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationBadgeService.unreadCount,
      builder: (context, unreadCount, _) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final cacheW = (size * dpr).round();
        final wrapper = size + 10;
        return SizedBox(
          height: wrapper,
          width: wrapper,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, yOffset),
                child: Image.asset(
                  asset,
                  height: size,
                  width: size,
                  fit: BoxFit.contain,
                  color: color,
                  cacheWidth: cacheW,
                  cacheHeight: cacheW,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 0,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GradientFabIcon extends StatelessWidget {
  const _GradientFabIcon({
    required this.asset,
    this.size = 24,
    this.iconColor,
  });
  final String asset;
  final double size;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65.h,
      width: 55.w,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Image.asset(
          asset,
          height: 35.h,
          width: 20.w,
          color: iconColor ?? Colors.white,
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.initials,
    required this.walletBalance,
    required this.onSearchTap,
    required this.onReferTap,
    required this.onProfileTap,
    this.compact = false,
  });

  final String initials;
  final double walletBalance;
  final VoidCallback onSearchTap;
  final VoidCallback onReferTap;
  final VoidCallback onProfileTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.plusJakartaSans(
      textStyle: Theme.of(context).textTheme.bodySmall,
    );
    final displayBalance = walletBalance == walletBalance.roundToDouble()
        ? walletBalance.toStringAsFixed(0)
        : walletBalance.toStringAsFixed(2);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onProfileTap,
              child: _ProfileAvatar(
                initials: initials,
                size: compact ? 32 : 36,
              ),
            ),
            SizedBox(width: 8.w),
            _HeaderIconButton(
              icon: Icons.search,
              size: compact ? 32 : 36,
              iconSize: compact ? 16 : 18,
              onTap: onSearchTap,
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: onReferTap,
              child: Image.asset(
                FileConstants.referandearn,
                height: compact ? 26.h : 30.h,
                width: compact ? 120.w : 132.w,
                fit: BoxFit.contain,
              ),
            ),
            GestureDetector(
              onTap: () {
                context.push(RouteConstants.referAndEarnWallet);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      FileConstants.coin_3d,
                      width: compact ? 14.w : 16.w,
                      height: compact ? 14.w : 16.w,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      displayBalance,
                      style: textStyle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 10.sp : 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initials, required this.size});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size.r,
      width: size.r,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            textStyle: Theme.of(context).textTheme.bodySmall,
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(18.r),
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: GoogleFonts.plusJakartaSans(
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 6.w),
                Container(
                  height: 20.r,
                  width: 20.r,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 14.r,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HomeIconGrid extends StatelessWidget {
  const _HomeIconGrid({
    required this.services,
    required this.onTap,
    this.maxItems = 8,
    this.columns = 4,
    this.tileWidth = 64,
  });

  final List<QuickActionService> services;
  final Future<void> Function(String serviceName) onTap;
  final int maxItems;
  final int columns;
  final double tileWidth;

  @override
  Widget build(BuildContext context) {
    final visibleItems = services.take(maxItems).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final spacing = 12.w;
        final computedTileSize = (maxWidth - spacing * (columns - 1)) / columns;
        final tileSize =
            computedTileSize > tileWidth.r ? tileWidth.r : computedTileSize;
        return Wrap(
          spacing: spacing.w,
          runSpacing: 16.h,
          children: List.generate(visibleItems.length, (index) {
            final service = visibleItems[index];
            return SizedBox(
              width: tileSize,
              child: HomeIconTile(
                label: service.name,
                iconUrl: service.icon,
                offer: service.offers,
                onTap: () async {
                  await onTap(service.name);
                },
              ),
            );
          }),
        );
      },
    );
  }
}

class _CurvedIconGrid extends StatelessWidget {
  const _CurvedIconGrid({
    required this.services,
    required this.onTap,
    this.maxItems = 4,
    this.labelBuilder,
  });

  final List<QuickActionService> services;
  final Future<void> Function(String serviceName) onTap;
  final int maxItems;
  final String Function(QuickActionService service)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final visibleItems = services.take(maxItems).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 10.w;
        final tileWidth = (constraints.maxWidth - spacing * 3) / 4;
        final tileHeight = tileWidth * 1.45;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            final service =
                index < visibleItems.length ? visibleItems[index] : null;
            if (service == null) {
              return SizedBox(width: tileWidth, height: tileHeight);
            }
            return SizedBox(
              width: tileWidth,
              height: tileHeight,
              child: _CurvedIconTile(
                label: labelBuilder?.call(service) ?? service.name,
                iconUrl: service.icon ?? '',
                onTap: () async {
                  await onTap(service.name);
                },
              ),
            );
          }),
        );
      },
    );
  }
}

class _CurvedIconTile extends StatelessWidget {
  const _CurvedIconTile({
    required this.label,
    required this.iconUrl,
    required this.onTap,
  });

  final String label;
  final String iconUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelWords = label.trim().split(RegExp(r'\s+'));
    final isTwoWordLabel = labelWords.length == 2;
    final displayLabel =
        isTwoWordLabel ? '${labelWords.first}\n${labelWords.last}' : label;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffFAFAFA),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xffEAEAEA)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Image.asset(
                  FileConstants.bottomOrangeCurve,
                  height: 8.h,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(6.w, 10.h, 6.w, 8.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 50.r,
                      width: 50.r,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.5,
                          colors: [
                            Color(0xFFF9F9F9),
                            Color(0xFFF6F6F6),
                          ],
                        ),
                      ),
                      child: Center(
                        child: AppNetworkImage(
                          url: iconUrl,
                          width: 26.r,
                          height: 26.r,
                          fit: BoxFit.contain,
                          showShimmer: false,
                          errorWidget: Image.asset(
                            FileConstants.appLogo,
                            height: 26.r,
                            width: 26.r,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Flexible(
                      child: Center(
                        child: Text(
                          displayLabel,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmallSemibold(context),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
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

class _PayBillsCard extends StatelessWidget {
  const _PayBillsCard({
    required this.services,
    required this.onTap,
    required this.onExploreTap,
  });

  final List<QuickActionService> services;
  final Future<void> Function(String serviceName) onTap;
  final VoidCallback onExploreTap;

  QuickActionService? _findService(Set<String> used, List<String> names) {
    for (final name in names) {
      for (final service in services) {
        if (service.name == name && !used.contains(service.name)) {
          used.add(service.name);
          return service;
        }
      }
    }
    return null;
  }

  QuickActionService? _nextUnused(Set<String> used) {
    for (final service in services) {
      if (!used.contains(service.name)) {
        used.add(service.name);
        return service;
      }
    }
    return null;
  }

  String _labelForService(QuickActionService service) {
    return service.name;
  }

  Widget _serviceTile(QuickActionService service) {
    return HomeIconTile(
      label: _labelForService(service),
      iconUrl: service.icon,
      offer: service.offers,
      labelSpacing: 4.h,
      showHalfRing: _isBookGasService(service),
      onTap: () async {
        await onTap(service.name);
      },
    );
  }

  bool _isBookGasService(QuickActionService service) {
    final name = service.name.trim().toLowerCase();
    // Ring highlight only for "Book Gas" style actions (not all gas types).
    return name.contains('book') &&
        (name.contains('gas') || name.contains('lpg'));
  }

  @override
  Widget build(BuildContext context) {
    final used = <String>{};

    final electricity = _findService(used, const ['Electricity']);
    final recharge = _findService(
      used,
      const ['Mobile Prepaid', 'Mobile Postpaid', 'Recharge'],
    );
    final fastag = _findService(used, const ['Fastag', 'FASTag']);
    final credit = _findService(used, const ['Credit Card']);
    final bookGas = _findService(
          used,
          const ['LPG Gas', 'Book Gas Cylinder', 'Pipe Gas', 'Book Gas'],
        ) ??
        _nextUnused(used);

    final topRow = <QuickActionService?>[
      electricity ?? _nextUnused(used),
      recharge ?? _nextUnused(used),
      fastag ?? _nextUnused(used),
      credit ?? _nextUnused(used),
    ];

    const imageAspectRatio = 1960 / 1380;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = width / imageAspectRatio - 4.h;
            final tileWidth = width * 0.18;
            final bookTileWidth = width * 0.2;
            final horizontalInset = width * 0.06;
            final topRowSpacing =
                (width - (horizontalInset * 2) - (tileWidth * 4)) / 3;
            final firstTileCenter = horizontalInset + (tileWidth / 2);

            Widget positionedTile({
              required double x,
              required double y,
              required QuickActionService? service,
              required double tileW,
            }) {
              if (service == null) return const SizedBox.shrink();
              return Positioned(
                left: x - (tileW / 2),
                top: y,
                width: tileW,
                child: _serviceTile(service),
              );
            }

            return SizedBox(
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      FileConstants.homeIconSection,
                      fit: BoxFit.fill,
                    ),
                  ),
                  positionedTile(
                    x: firstTileCenter,
                    y: height * 0.08,
                    service: topRow[0],
                    tileW: tileWidth,
                  ),
                  positionedTile(
                    x: firstTileCenter + tileWidth + topRowSpacing,
                    y: height * 0.08,
                    service: topRow[1],
                    tileW: tileWidth,
                  ),
                  positionedTile(
                    x: firstTileCenter + ((tileWidth + topRowSpacing) * 2),
                    y: height * 0.08,
                    service: topRow[2],
                    tileW: tileWidth,
                  ),
                  positionedTile(
                    x: firstTileCenter + ((tileWidth + topRowSpacing) * 3),
                    y: height * 0.08,
                    service: topRow[3],
                    tileW: tileWidth,
                  ),
                  positionedTile(
                    x: width * 0.15,
                    y: height * 0.5,
                    service: bookGas,
                    tileW: bookTileWidth,
                  ),
                  if (bookGas != null)
                    Positioned(
                      left: width * 0.32,
                      right: 0,
                      top: height * 0.54,
                      child: _PromoStrip(
                        asset: FileConstants.bookLpgStrip,
                      ),
                    ),
                  Positioned(
                    right: width * 0.01,
                    // left: width * 0.01,
                    bottom: height * 0.01,
                    child: _ExploreUtilitiesRow(onTap: onExploreTap),
                  ),
                ],
              ),
            );
          },
        ),
        // SizedBox(height: 18.h),
        // const _ReferStrip(),
      ],
    );
  }
}

class _PromoStrip extends StatelessWidget {
  const _PromoStrip({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        bottomLeft: Radius.circular(10),
      ),
      child: Image.asset(
        asset,
        height: 30.h,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _ExploreUtilitiesRow extends StatelessWidget {
  const _ExploreUtilitiesRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        height: 38.h,
        width: 220.w,
        padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFBE6DE),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Explore All Services',
              style: GoogleFonts.plusJakartaSans(
                textStyle: Theme.of(context).textTheme.bodyMedium,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              height: 24.r,
              width: 24.r,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward,
                size: 14.r,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferStrip extends StatelessWidget {
  const _ReferStrip();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ReferAndEarnView(),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          image: DecorationImage(
            image: AssetImage(FileConstants.referBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 18.r,
              width: 18.r,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                FileConstants.coin_3d,
                height: 12.r,
                width: 12.r,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Refer Your First Friend And Grab 1000 E-Coins',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  textStyle: Theme.of(context).textTheme.bodySmall,
                  color: Colors.white,
                  letterSpacing: -0.25,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvestmentTile extends StatelessWidget {
  const _InvestmentTile({
    required this.label,
    required this.iconAsset,
    required this.arrowAsset,
    required this.borderColor,
    required this.textColor,
    this.backgroundGradient,
  });

  final String label;
  final String iconAsset;
  final String arrowAsset;
  final Color borderColor;
  final Color textColor;
  final Gradient? backgroundGradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: backgroundGradient == null ? Colors.white : null,
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 20.r,
            width: 20.r,
            child: Image.asset(
              iconAsset,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                textStyle: Theme.of(context).textTheme.bodySmall,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          SizedBox(
            height: 22.r,
            width: 22.r,
            child: Image.asset(
              arrowAsset,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBanner extends StatelessWidget {
  const _ImageBanner({required this.asset, required this.height});
  final String asset;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cacheWidth = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .round();
    return Image.asset(
      asset,
      height: height,
      width: double.infinity,
      fit: BoxFit.contain,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.low,
    );
  }
}

class InsuranceBannerCarousel extends HookWidget {
  const InsuranceBannerCarousel({
    super.key,
    required this.onApply,
    this.banners = const [],
    this.isLoading = false,
    this.placeholderCount = 1,
  });

  final VoidCallback onApply;
  final List<BannerModel> banners;
  final bool isLoading;
  final int placeholderCount;

  @override
  Widget build(BuildContext context) {
    final controller = usePageController();
    final currentIndex = useState(0);

    final resolvedPlaceholderCount =
        placeholderCount < 1 ? 1 : placeholderCount;
    final total = (isLoading || banners.isEmpty)
        ? resolvedPlaceholderCount
        : banners.length;

    return Stack(
      children: [
        SizedBox(
          // height: 128,
          child: PageView.builder(
            controller: controller,
            itemCount: total,
            onPageChanged: (index) => currentIndex.value = index,
            itemBuilder: (context, index) {
              if (isLoading || banners.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: AppNetworkImage(
                    url: '',
                    // height: 128,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                );
              }

              final banner = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => BannerRedirectMapper.handle(
                    context,
                    banner.redirectUrl,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: AppNetworkImage(
                      url: banner.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        ///DOTS OVERLAY
        Positioned(
          left: 18.w, // match your padding
          bottom: 5.h, // just below button visually
          child: Row(
            children: List.generate(
              total,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(right: 4.w),
                height: 6.h,
                width: currentIndex.value == index ? 14.w : 6.w,
                decoration: BoxDecoration(
                  color: currentIndex.value == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsuranceBannerItem extends StatelessWidget {
  const _InsuranceBannerItem({
    required this.image,
    required this.onApply,
    required this.currentIndex,
    required this.total,
  });

  final String image;
  final VoidCallback onApply;
  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F8A4B),
            Color(0xFF0C6B3B),
          ],
        ),
      ),
      child: Row(
        children: [
          /// LEFT CONTENT
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Your Future',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Health, Motor & Life Insurance In\nMinutes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 10.h),

                /// APPLY BUTTON
                InkWell(
                  onTap: onApply,
                  borderRadius: BorderRadius.circular(18.r),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18.r),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFDD5428),
                          Color(0xFF772D16),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Apply Now',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(Icons.north_east, size: 12.r, color: Colors.white),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 8.h),

                Row(
                  children: List.generate(
                    total,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.only(right: 4.w),
                      height: 6.h,
                      width: currentIndex == index ? 14.w : 6.w,
                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 8.w),

          /// RIGHT IMAGE
          SizedBox(
            height: 96.h,
            width: 120.w,
            child: Image.asset(
              image,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsuranceBanner extends StatelessWidget {
  const _InsuranceBanner({required this.onApply});

  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F8A4B),
            Color(0xFF0C6B3B),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Your Future',
                  style: GoogleFonts.plusJakartaSans(
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Health, Motor & Life Insurance In\nMinutes',
                  style: GoogleFonts.plusJakartaSans(
                    textStyle: Theme.of(context).textTheme.bodySmall,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 10.h),
                InkWell(
                  onTap: onApply,
                  borderRadius: BorderRadius.circular(18.r),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18.r),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFFDD5428),
                          Color(0xFF772D16),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Apply Now',
                          style: GoogleFonts.plusJakartaSans(
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.north_east,
                          size: 12.r,
                          color: Colors.white,
                        ),
                        SizedBox(
                          height: 10.h,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            height: 96.h,
            width: 120.w,
            child: Image.asset(
              FileConstants.homeBannerGif,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

// class _MiniImageCard extends StatelessWidget {
//   const _MiniImageCard({
//     required this.asset,
//     required this.title,
//     required this.onTap,
//   });
//   final String asset;
//   final String title;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12.r),
//       child: Container(
//         padding: EdgeInsets.all(12.w),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12.r),
//           border: Border.all(color: AppColors.lightBorder),
//         ),
//         child: Row(
//           children: [
//             Image.asset(asset, height: 30.h, width: 30.h, fit: BoxFit.contain),
//             SizedBox(width: 8.w),
//             Expanded(
//               child: Text(
//                 title,
//                 style: GoogleFonts.plusJakartaSans(
//                   textStyle: Theme.of(context).textTheme.bodySmall,
//                   color: AppColors.textPrimary,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//             Container(
//               height: 20.r,
//               width: 20.r,
//               decoration: BoxDecoration(
//                 color: AppColors.primary.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.chevron_right,
//                 size: 14.r,
//                 color: AppColors.primary,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _MiniActionCard extends StatelessWidget {
  const _MiniActionCard({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.gradientBorder,
  });

  final String title;
  final String subtitle;
  final String asset;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradientBorder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: gradientBorder,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: gradientBorder == null
                ? Border.all(
                    color: borderColor ?? AppColors.lightBorder,
                    width: 0.5,
                  )
                : null,
          ),
          margin: gradientBorder == null
              ? EdgeInsets.zero
              : const EdgeInsets.all(0.5),
          child: Row(
            children: [
              Image.asset(asset,
                  height: 20.h, width: 20.h, fit: BoxFit.contain),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        textStyle: Theme.of(context).textTheme.bodySmall,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        textStyle: Theme.of(context).textTheme.bodySmall,
                        color: AppColors.textPrimary.withOpacity(0.6),
                        fontSize: 9.sp,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset(
                FileConstants.rightArrow,
                height: 28.r,
                width: 28.r,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Image.asset(FileConstants.faqIcon,
                height: 20.h, width: 20.h, fit: BoxFit.contain),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  textStyle: Theme.of(context).textTheme.bodySmall,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Image.asset(
              FileConstants.rightArrow,
              height: 28.r,
              width: 28.r,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends HookConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final hasInternet = ref.watch(connectivityStatusProvider).value ?? true;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bannerCacheWidth = (screenWidth * devicePixelRatio).round();

    final didShowCompleteProfile = useRef(false);
    final didShowTemporaryBlock = useRef(false);
    // Track auth transitions across navigation; initialize to false so that if
    // Home is already mounted (behind login) we still refresh once on login.
    final wasAuthenticated = useRef<bool>(false);

    useEffect(() {
      Future.microtask(() {
        ref.read(homeControllerProvider.notifier).fetchQuickActionsIfNeeded();
        ref
            .read(homeControllerProvider.notifier)
            .fetchAllQuickActionsIfNeeded();
        ref.read(spinOptionsControllerProvider.notifier).fetchSpinOptions();
        ref.read(profileControllerProvider.notifier).fetchProfileIfNeeded();
      });
      return null;
    }, const []);

    // If Home stays mounted across login (ex: PIN unlock/login), the initial
    // `useEffect(const [])` won't re-run. Trigger a refresh when auth flips
    // from unauthenticated -> authenticated.
    useEffect(() {
      final prev = wasAuthenticated.value;
      final next = authState.isAuthenticated;
      wasAuthenticated.value = next;
      if (prev == false && next == true) {
        Future.microtask(() {
          ref
              .read(homeControllerProvider.notifier)
              .fetchQuickActionsIfNeeded(force: true);
          ref
              .read(homeControllerProvider.notifier)
              .fetchAllQuickActionsIfNeeded(force: true);
          ref
              .read(profileControllerProvider.notifier)
              .fetchProfileIfNeeded(force: true);
        });
      }
      return null;
    }, [authState.isAuthenticated]);

    useEffect(() {
      final needsProfile =
          homeState.isNameEmailExist == false && homeState.quickActions != null;
      if (!needsProfile || didShowCompleteProfile.value) return null;
      didShowCompleteProfile.value = true;
      Future.microtask(() {
        KDialog.instance.openDialog(
          barrierDismissible: false,
          dialog: CompleteProfileDialog(
            onCompleted: () {
              ref
                  .read(profileControllerProvider.notifier)
                  .fetchProfileIfNeeded(force: true);
              ref
                  .read(homeControllerProvider.notifier)
                  .fetchQuickActionsIfNeeded(force: true);
            },
          ),
        );
      });
      return null;
    }, [homeState.isNameEmailExist, homeState.quickActions]);

    final temporaryBlockFlow = _resolveTemporaryBlockFlow(profileState.profile);
    useEffect(() {
      if (temporaryBlockFlow == null || didShowTemporaryBlock.value) {
        return null;
      }
      if (profileState.profile == null) {
        return null;
      }
      didShowTemporaryBlock.value = true;
      Future.microtask(() async {
        if (!context.mounted) return;
        await KDialog.instance.openDialog(
          barrierDismissible: false,
          dialog: TemporaryBlockDialog(
            flowType: temporaryBlockFlow,
            onSupportTap: () {
              Navigator.of(context, rootNavigator: true).pop();
              Future.microtask(() {
                if (!context.mounted) return;
                context.push(RouteConstants.helpSupport);
              });
            },
            onPrimaryTap: () {
              final profile = profileState.profile;
              final successRoute = temporaryBlockFlow ==
                      TemporaryBlockFlowType.noKyc
                  ? RouteConstants.kycVerification
                  : RouteConstants.temporaryBlockIdentityCompletion;
              final flowQueryValue =
                  temporaryBlockFlow == TemporaryBlockFlowType.noKyc
                      ? 'noKyc'
                      : 'kycVerified';
              Navigator.of(context, rootNavigator: true).pop();
              Future.microtask(() {
                if (!context.mounted) return;
                context.push(
                  '${RouteConstants.temporaryBlockOtp}?flow=$flowQueryValue&phone=${profile?.mobile ?? ''}',
                  extra: OtpVerificationArgs(
                    phoneNumber: profile?.mobile,
                    title: 'Verify Your Identity',
                    heading: 'Verify Your Identity',
                    description:
                        'Enter the OTPs sent to your registered mobile number and email address to verify your identity.',
                    primaryButtonLabel: 'Verify & Continue',
                    successDialogTitle:
                        'Mobile and Email verified successfully',
                    successDialogMessage:
                        'This device has been successfully verified and added to your trusted device list. You can now access your account securely.',
                    successButtonLabel: 'Complete KYC',
                    successRoute: successRoute,
                    successRouteExtra:
                        successRoute == RouteConstants.kycVerification
                            ? false
                            : null,
                    temporaryBlockFlowType: temporaryBlockFlow,
                  ),
                );
              });
            },
          ),
        );
      });
      return null;
    }, [temporaryBlockFlow, profileState.profile?.id]);

    final topBanners = homeState.banners?['top'] ?? [];
    final middleBanners = homeState.banners?['middle'] ?? [];
    final bottomBanners = homeState.banners?['bottom'] ?? [];
    final bankingInvestmentBanners =
        homeState.banners?['banking_investment'] ?? [];

    final topBannerPage = useState(0);
    final topBannerController = useMemoized(() => PageController(), const []);
    useEffect(() {
      if (topBanners.length < 2) return null;
      final timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!topBannerController.hasClients) return;
        final next = (topBannerPage.value + 1) % topBanners.length;
        topBannerController.animateToPage(
          next.toInt(),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
      return timer.cancel;
    }, [topBanners.length]);

    final quickActions = homeState.quickActions;

    final showBannerPlaceholder = topBanners.isEmpty &&
        homeState.errorMessage == null &&
        (homeState.isFetching || quickActions == null);
    final topBannerHeight = 120.h;
    final bannerAreaHeight = (topBanners.isNotEmpty || showBannerPlaceholder)
        ? topBannerHeight
        : 0.h;

    final middleBannerPage = useState(0);
    final middleBannerController =
        useMemoized(() => PageController(), const []);
    useEffect(() {
      if (middleBanners.length < 2) return null;
      final timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!middleBannerController.hasClients) return;
        final next = (middleBannerPage.value + 1) % middleBanners.length;
        middleBannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
      return timer.cancel;
    }, [middleBanners.length]);

    final bottomBannerPage = useState(0);
    final bottomBannerController =
        useMemoized(() => PageController(), const []);
    useEffect(() {
      if (bottomBanners.length < 2) return null;
      final timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!bottomBannerController.hasClients) return;
        final next = (bottomBannerPage.value + 1) % bottomBanners.length;
        bottomBannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
      return timer.cancel;
    }, [bottomBanners.length]);

    final bankingBannerPage = useState(0);
    final bankingBannerController =
        useMemoized(() => PageController(), const []);
    useEffect(() {
      if (bankingInvestmentBanners.length < 2) return null;
      final timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!bankingBannerController.hasClients) return;
        final next =
            (bankingBannerPage.value + 1) % bankingInvestmentBanners.length;
        bankingBannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
      return timer.cancel;
    }, [bankingInvestmentBanners.length]);

    QuickActionCategory? findCategory(
      List<QuickActionCategory> categories,
      List<String> keywords,
    ) {
      for (final category in categories) {
        final label = category.category.toLowerCase();
        if (keywords.any((keyword) => label.contains(keyword))) {
          return category;
        }
      }
      return categories.isNotEmpty ? categories.first : null;
    }

    Future<void> handleServiceTap(String serviceName) async {
      if (!hasInternet) {
        AppSnackbar.show('No internet connection. Please try again.');
        return;
      }
      if (serviceName == 'Credit Card') {
        await ref
            .read(homeControllerProvider.notifier)
            .fetchCreditCardActions();
        final cards = ref.read(homeControllerProvider).creditCardActions;
        if (cards != null && cards.isNotEmpty) {
          context.push(RouteConstants.creditCardMyCards);
        } else {
          context.push(RouteConstants.creditCardListing);
        }
      } else if (serviceName == 'Mobile Prepaid') {
        context.push(RouteConstants.mobileRecentRecharges);
      } else if (serviceName == 'Tuition Fees' ||
          serviceName == 'Tution Fees' ||
          serviceName == 'School Fees' ||
          serviceName == 'College Fees') {
        context.push(
          RouteConstants.educationFeesAmount,
          extra: serviceName,
        );
      } else {
        context.push(
          RouteConstants.billerListing,
          extra: serviceName,
        );
      }
    }

    final initials = profileState.profile?.initials.isNotEmpty == true
        ? profileState.profile!.initials
        : '';
    final walletBalance = profileState.profile?.walletBalance ?? 0.0;
    final payBillsCategory = quickActions == null
        ? null
        : findCategory(quickActions, ['utilities', 'bills', 'expenses']);
    final educationCategory = quickActions == null
        ? null
        : findCategory(quickActions, ['education', 'lifestyle']);
    final insuranceCategory = quickActions == null
        ? null
        : findCategory(quickActions, ['insurance', 'rent', 'property']);

    final activeTopBanner = topBanners.isEmpty
        ? null
        : topBanners[(topBannerPage.value.clamp(0, topBanners.length - 1))];
    final topBannerGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        activeTopBanner?.colorStart ?? const Color(0xFFFF835C),
        activeTopBanner?.colorEnd ?? const Color(0xFF994F37),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: topBannerGradient,
              ),
            ),
          ),
          RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => Future.wait([
                    ref
                        .read(homeControllerProvider.notifier)
                        .fetchQuickActions(),
                    ref
                        .read(homeControllerProvider.notifier)
                        .fetchAllQuickActions(),
                    ref
                        .read(spinOptionsControllerProvider.notifier)
                        .fetchSpinOptions(),
                    ref.read(profileControllerProvider.notifier).fetchProfile(),
                  ]),
              child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      automaticallyImplyLeading: false,
                      centerTitle: false,
                      titleSpacing: 0,
                      backgroundColor: const Color(0xffD66D4D),
                      elevation: 0,
                      toolbarHeight: 54.h,
                      expandedHeight: MediaQuery.of(context).padding.top +
                          36.h +
                          14.h +
                          bannerAreaHeight +
                          (topBanners.length > 1 ? 16.h : 0.h),
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.none,
                        background: Container(
                          decoration:
                              BoxDecoration(gradient: topBannerGradient),
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 16.w,
                              right: 16.w,
                              top: MediaQuery.of(context).padding.top +
                                  58.h +
                                  10.h,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 6.h),
                                if (showBannerPlaceholder)
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 4.w),
                                    child: AppNetworkImage(
                                      url: '',
                                      width: double.infinity,
                                      height: topBannerHeight,
                                      borderRadius: BorderRadius.circular(14.r),
                                    ),
                                  )
                                else if (topBanners.isNotEmpty)
                                  SizedBox(
                                    height: topBannerHeight,
                                    child: PageView.builder(
                                      controller: topBannerController,
                                      onPageChanged: (page) =>
                                          topBannerPage.value = page,
                                      itemCount: topBanners.length,
                                      itemBuilder: (_, index) {
                                        final banner = topBanners[index];
                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 4.w),
                                          child: GestureDetector(
                                            onTap: () {
                                              BannerRedirectMapper.handle(
                                                context,
                                                banner.redirectUrl,
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14.r),
                                              child: AppNetworkImage(
                                                url: banner
                                                    .image, // Access API url
                                                width: double.infinity,
                                                height: topBannerHeight,
                                                fit: BoxFit.contain,
                                                placeholder: AppNetworkImage(
                                                  url: '',
                                                  width: double.infinity,
                                                  height: topBannerHeight,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                SizedBox(height: 4.h),
                                if (topBanners.length > 1)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      topBanners.length,
                                      (index) => Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 3.w),
                                        child: _Dot(
                                            active:
                                                topBannerPage.value == index),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      title: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: _HomeTopBar(
                          initials: initials,
                          walletBalance: walletBalance,
                          compact: true,
                          onSearchTap: () {
                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: const HomeSearchView(),
                              withNavBar: false,
                            );
                          },
                          onReferTap: () {
                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: const ReferAndEarnView(),
                              withNavBar: false,
                            );
                          },
                          onProfileTap: () {
                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: const ProfileView(),
                              withNavBar: false,
                            );
                          },
                        ),
                      ),
                    ),
                    if (quickActions == null && homeState.errorMessage == null)
                      const HomeShimmer()
                    else if (homeState.errorMessage != null &&
                        quickActions == null)
                      SliverToBoxAdapter(
                        child: _HomeErrorState(
                          onRetry: () => ref
                              .read(homeControllerProvider.notifier)
                              .fetchQuickActions(),
                          onRestart: () => context.go(RouteConstants.splash),
                        ),
                      )
                    else if (quickActions != null)
                      SliverToBoxAdapter(
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18.r),
                            topRight: Radius.circular(18.r),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(18.r),
                                topRight: Radius.circular(18.r),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.cardShadow,
                                  blurRadius: 20,
                                  offset: Offset(0, -10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 2),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _SectionHeader(
                                        title: 'Pay Bills & Expenses',
                                        actionLabel: 'My Bills',
                                        onAction: () => context
                                            .push(RouteConstants.quickActions),
                                      ),
                                      SizedBox(height: 14.h),
                                      _PayBillsCard(
                                        services: payBillsCategory?.services ??
                                            const [],
                                        onTap: handleServiceTap,
                                        onExploreTap: () {
                                          context.push(
                                              RouteConstants.homeSearchView);
                                        },
                                      ),
                                      SizedBox(height: 12.h),
                                      const _SectionHeader(
                                          title: 'Banking & Investments'),
                                      SizedBox(height: 10.h),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                context.push(
                                                  '${RouteConstants.digitalGold}?entry=home',
                                                );
                                              },
                                              child: _InvestmentTile(
                                                label: 'Buy Gold',
                                                iconAsset: FileConstants
                                                    .digitalGoldGif,
                                                arrowAsset:
                                                    FileConstants.goldArrow,
                                                borderColor:
                                                    const Color(0xFFE0C46A),
                                                textColor:
                                                    const Color(0xFF8B6B12),
                                                // backgroundGradient:
                                                //     const LinearGradient(
                                                //   begin: Alignment.centerLeft,
                                                //   end: Alignment.centerRight,
                                                //   colors: [
                                                //     Color(0xFFFFFFFF),
                                                //     Color(0xFFFFF4D5),
                                                //   ],
                                                // ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                context.push(
                                                  '${RouteConstants.digitalGold}?metal=silver&entry=home',
                                                );
                                              },
                                              child: _InvestmentTile(
                                                label: 'Buy Silver',
                                                iconAsset: FileConstants
                                                    .digitalSilverGif,
                                                arrowAsset:
                                                    FileConstants.silverArrow,
                                                borderColor:
                                                    const Color(0xFFE1E1E1),
                                                textColor:
                                                    const Color(0xFF6B6B6B),
                                                // backgroundGradient:
                                                //     const LinearGradient(
                                                //   begin: Alignment.centerLeft,
                                                //   end: Alignment.centerRight,
                                                //   colors: [
                                                //     Color(0xFFFFFFFF),
                                                //     Color(0xFFF5F5F5),
                                                //   ],
                                                // ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (bankingInvestmentBanners.isNotEmpty) ...[
                                  SizedBox(height: 18.h),
                                  InkWell(
                                    onTap: () {
                                      final index = bankingBannerPage.value;
                                      final banner = index >= 0 &&
                                              index <
                                                  bankingInvestmentBanners
                                                      .length
                                          ? bankingInvestmentBanners[index]
                                          : null;
                                      final redirectUrl = banner?.redirectUrl;
                                      if (redirectUrl != null &&
                                          redirectUrl.trim().isNotEmpty) {
                                        BannerRedirectMapper.handle(
                                          context,
                                          redirectUrl,
                                        );
                                        return;
                                      }
                                      context.push(
                                        '${RouteConstants.digitalGold}?entry=home',
                                      );
                                    },
                                    child: SizedBox(
                                      height: 60.h,
                                      width: double.infinity,
                                      child: PageView.builder(
                                        controller: bankingBannerController,
                                        onPageChanged: (page) =>
                                            bankingBannerPage.value = page,
                                        itemCount:
                                            bankingInvestmentBanners.length,
                                        itemBuilder: (_, index) =>
                                            AppNetworkImage(
                                          url: bankingInvestmentBanners[index]
                                              .image,
                                          width: double.infinity,
                                          height: 60.h,
                                          fit: BoxFit.contain,
                                          placeholder: AppNetworkImage(
                                            url: '',
                                            width: double.infinity,
                                            height: 60.h,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                Padding(
                                  padding:
                                      EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _SectionHeader(
                                        title: 'Education & Lifestyle',
                                      ),
                                      SizedBox(height: 12.h),
                                      _CurvedIconGrid(
                                        services: educationCategory?.services ??
                                            const [],
                                        onTap: handleServiceTap,
                                      ),
                                      SizedBox(
                                        height: middleBanners.isNotEmpty
                                            ? 0.h
                                            : 18.h,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.w),
                                  child: Column(
                                    children: [
                                      if (middleBanners.isNotEmpty)
                                        SizedBox(height: 18.h),
                                      if (middleBanners.isNotEmpty)
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                          child: SizedBox(
                                            height: 110.h,
                                            child: PageView.builder(
                                              controller:
                                                  middleBannerController,
                                              onPageChanged: (page) =>
                                                  middleBannerPage.value = page,
                                              itemCount: middleBanners.length,
                                              itemBuilder: (_, index) =>
                                                  GestureDetector(
                                                onTap: () =>
                                                    BannerRedirectMapper.handle(
                                                  context,
                                                  middleBanners[index]
                                                      .redirectUrl,
                                                ),
                                                child: AppNetworkImage(
                                                  url: middleBanners[index]
                                                      .image,
                                                  width: double.infinity,
                                                  height: 110.h,
                                                  fit: BoxFit.contain,
                                                  placeholder: AppNetworkImage(
                                                    url: '',
                                                    width: double.infinity,
                                                    height: 110.h,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (middleBanners.isNotEmpty)
                                        SizedBox(height: 6.h),
                                      if (middleBanners.length > 1)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(
                                            middleBanners.length,
                                            (index) => Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 3.w),
                                              child: _Dot(
                                                active:
                                                    middleBannerPage.value ==
                                                        index,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (middleBanners.isNotEmpty)
                                        SizedBox(height: 18.h),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      16.w, 0.h, 16.w, 12.h),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _SectionHeader(
                                        title: 'Insurance & Rent',
                                        // actionLabel: 'View All',
                                        onAction: () => context
                                            .push(RouteConstants.quickActions),
                                      ),
                                      SizedBox(height: 12.h),
                                      _CurvedIconGrid(
                                        services: insuranceCategory?.services ??
                                            const [],
                                        onTap: handleServiceTap,
                                        labelBuilder: (service) {
                                          final name = service.name.trim();
                                          final lower = name.toLowerCase();
                                          if (lower.contains('insurance')) {
                                            return name;
                                          }
                                          if (lower == 'general' ||
                                              lower == 'health' ||
                                              lower == 'life') {
                                            return '$name Insurance';
                                          }
                                          return name;
                                        },
                                      ),
                                      SizedBox(height: 14.h),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: _ImageBanner(
                                    asset: FileConstants.homeBanner9,
                                    height: 60.h,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _MiniActionCard(
                                              title: 'Gift card',
                                              subtitle: 'Gift your friends',
                                              asset: FileConstants.giftGif,
                                              backgroundColor:
                                                  const Color(0xFFFFF3EE),
                                              gradientBorder:
                                                  const LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Color(0xFFFF9776),
                                                  Color(0xFFDD5428),
                                                ],
                                              ),
                                              onTap: () {},
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: _MiniActionCard(
                                              title: 'Spin & Win',
                                              subtitle: 'Win big prizes',
                                              asset: FileConstants.spinIcon,
                                              backgroundColor:
                                                  const Color(0xFFEAF2FF),
                                              borderColor:
                                                  const Color(0xFF002352),
                                              onTap: () => context.push(
                                                  RouteConstants.spinAndWin),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12.h),
                                      _SupportTile(
                                        title: 'FAQ & Support',
                                        onTap: () => context.push(
                                          RouteConstants.faq,
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                    ],
                                  ),
                                ),
                                if (bottomBanners.isNotEmpty) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    height: 130.h,
                                    child: PageView.builder(
                                      controller: bottomBannerController,
                                      onPageChanged: (page) =>
                                          bottomBannerPage.value = page,
                                      itemCount: bottomBanners.length,
                                      itemBuilder: (_, index) =>
                                          GestureDetector(
                                        onTap: () =>
                                            BannerRedirectMapper.handle(
                                          context,
                                          bottomBanners[index].redirectUrl,
                                        ),
                                        child: AppNetworkImage(
                                          url: bottomBanners[index].image,
                                          width: double.infinity,
                                          height: 130.h,
                                          fit: BoxFit.cover,
                                          placeholder: AppNetworkImage(
                                            url: '',
                                            width: double.infinity,
                                            height: 130.h,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  if (bottomBanners.length > 1)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        bottomBanners.length,
                                        (index) => Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 3.w,
                                          ),
                                          child: _Dot(
                                            active:
                                                bottomBannerPage.value == index,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0XFFFDFDFD),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        16.w, 20.h, 16.w, 24.h),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Powered by',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Image.asset(
                                          FileConstants.bharatConnectColor,
                                          height: 25.h,
                                          fit: BoxFit.contain,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ])),
        ],
      ),
    );
  }
}

TemporaryBlockFlowType? _resolveTemporaryBlockFlow(ProfileModel? profile) {
  if (TemporaryBlockDebugConfig.enabled) {
    return TemporaryBlockDebugConfig.flowType;
  }
  return null;
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({
    required this.onRetry,
    required this.onRestart,
  });

  final VoidCallback onRetry;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 32.h),
      child: Column(
        children: [
          Image.asset(
            FileConstants.somethingWentWrong,
            width: 170.w,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 20.h),
          Text(
            'Something Went Wrong',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 6.h),
          Text(
            'We’re facing a temporary issue loading your data. Please try again.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  height: 1.4,
                ),
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: CustomElevatedButton(
                  onPressed: onRetry,
                  label: 'Retry',
                  uppercaseLabel: false,
                  height: 35.h,
                  isBorder: true,
                  backgroundColor: Colors.white,
                  borderColor: AppColors.primary,
                  labelColor: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomElevatedButton(
                  onPressed: onRestart,
                  label: 'Restart',
                  uppercaseLabel: false,
                  height: 35.h,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
