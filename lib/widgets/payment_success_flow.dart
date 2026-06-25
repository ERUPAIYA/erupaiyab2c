// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/file_constants.dart';
import '../utils/screenutil_ext.dart';
import 'app_snackbar.dart';
import 'custom_elevated_button.dart';
import 'k_dialog.dart';
import 'rating_bottom_sheet.dart';

class PaymentDetailItem {
  const PaymentDetailItem({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final String label;
  final String value;
  final bool copyable;
}

class PaymentThankYouScreen extends StatefulWidget {
  const PaymentThankYouScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.highlightedSubtitleText,
    this.gifPath = 'assets/gif/success.gif',
    this.poweredByText = 'Powered by',
    this.poweredByLogo = '',
    this.autoNavigateAfter = const Duration(milliseconds: 1500),
    this.onAutoNavigate,
    this.playSound = true,
  });

  final String title;
  final String subtitle;
  final String? highlightedSubtitleText;
  final String gifPath;
  final String poweredByText;
  final String poweredByLogo;
  final Duration autoNavigateAfter;
  final FutureOr<void> Function(BuildContext context)? onAutoNavigate;
  final bool playSound;

  @override
  State<PaymentThankYouScreen> createState() => _PaymentThankYouScreenState();
}

class _PaymentThankYouScreenState extends State<PaymentThankYouScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    if (widget.playSound) {
      _PaymentSoundController.play();
    }
    if (widget.onAutoNavigate != null) {
      _timer = Timer(widget.autoNavigateAfter, () {
        if (mounted) {
          widget.onAutoNavigate?.call(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w400,
          fontSize: 16.sp,
          height: 1.35,
        );
    return SlideTransition(
      position: _slideAnimation,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                const Spacer(flex: 5),
                Image.asset(
                  widget.gifPath,
                  height: 84.h,
                  width: 84.w,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 24.h),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 28.sp,
                        height: 1.1,
                      ),
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text.rich(
                    _buildSubtitleSpan(subtitleStyle),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(flex: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.poweredByText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w400,
                            fontSize: 13.sp,
                            height: 1,
                          ),
                    ),
                    SizedBox(width: 6.w),
                    Image.asset(
                      widget.poweredByLogo.isEmpty
                          ? FileConstants.bharatConnect
                          : widget.poweredByLogo,
                      height: 18.h,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                SizedBox(height: 26.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _buildSubtitleSpan(TextStyle? baseStyle) {
    final highlight = widget.highlightedSubtitleText?.trim() ?? '';
    if (highlight.isEmpty) {
      return TextSpan(text: widget.subtitle, style: baseStyle);
    }

    final fullText = widget.subtitle;
    final start = fullText.indexOf(highlight);
    if (start < 0) {
      return TextSpan(text: fullText, style: baseStyle);
    }

    final end = start + highlight.length;
    return TextSpan(
      style: baseStyle,
      children: [
        if (start > 0) TextSpan(text: fullText.substring(0, start)),
        TextSpan(
          text: fullText.substring(start, end),
          style: baseStyle?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (end < fullText.length) TextSpan(text: fullText.substring(end)),
      ],
    );
  }
}

class PaymentResultScreen extends StatefulWidget {
  const PaymentResultScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.details,
    this.detailsTitle = 'Transaction Details',
    this.onViewHistory,
    this.viewHistoryText = 'View Transaction History',
    this.onContinue,
    this.continueText = 'Continue to Home',
    this.showFailureActions = false,
    this.showBackButton = false,
    this.onContactSupport,
    this.onShareReceipt,
    this.statusIcon = Icons.check,
    this.statusIconAsset = '',
    this.statusIconColor = Colors.white,
    this.statusIconBorderColor = Colors.white,
    this.headerGradientColors = const [Color(0xFF0D5C32), Color(0xFF0E7340)],
    this.headerImageAsset = '',
    this.emphasizeSubtitle = false,
    this.subtitleBackgroundColor,
    this.poweredByText = 'Powered by',
    this.poweredByLogo = '',
    this.playSound = true,
    this.soundAsset = 'sounds/payment_success.mp3',
    this.stopSoundOnExit = true,
    this.showRatingSheet = false,
    this.transactionId = '',
    this.ratingSheetDelay = const Duration(milliseconds: 300),
  });

  final String title;
  final String subtitle;
  final List<PaymentDetailItem> details;
  final String detailsTitle;
  final FutureOr<void> Function(BuildContext context)? onViewHistory;
  final String viewHistoryText;
  final FutureOr<void> Function(BuildContext context)? onContinue;
  final String continueText;
  final bool showFailureActions;
  final bool showBackButton;
  final FutureOr<void> Function(BuildContext context)? onContactSupport;
  final FutureOr<void> Function(BuildContext context, String transactionId)?
      onShareReceipt;
  final IconData statusIcon;
  final String statusIconAsset;
  final Color statusIconColor;
  final Color statusIconBorderColor;
  final List<Color> headerGradientColors;
  final String headerImageAsset;
  final bool emphasizeSubtitle;
  final Color? subtitleBackgroundColor;
  final String poweredByText;
  final String poweredByLogo;
  final bool playSound;
  final String soundAsset;
  final bool stopSoundOnExit;
  final bool showRatingSheet;
  final String transactionId;
  final Duration ratingSheetDelay;

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  Timer? _ratingTimer;
  bool _ratingSheetOpened = false;

  @override
  void initState() {
    super.initState();
    if (widget.playSound) {
      _PaymentSoundController.play(asset: widget.soundAsset);
    }
    _scheduleRatingSheet();
  }

  @override
  void dispose() {
    _ratingTimer?.cancel();
    if (widget.stopSoundOnExit) {
      _PaymentSoundController.stop();
    }
    super.dispose();
  }

  void _scheduleRatingSheet() {
    if (!widget.showRatingSheet) return;
    if (widget.transactionId.trim().isEmpty) return;
    _ratingTimer?.cancel();
    _ratingTimer = Timer(widget.ratingSheetDelay, () {
      if (!mounted || _ratingSheetOpened) return;
      _ratingSheetOpened = true;
      KDialog.instance.openSheet(
        dialog: RatingBottomSheet(transactionId: widget.transactionId),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F7),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final headerHeight = height * 0.5;
          final cardTop = headerHeight * 0.82;

          return Stack(
            children: [
              Column(
                children: [
                  Container(
                    height: headerHeight,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: () {
                                  final colors = widget.headerGradientColors;
                                  if (colors.isEmpty) {
                                    return const [
                                      Color(0xFF0D5C32),
                                      Color(0xFF0E7340),
                                    ];
                                  }
                                  if (colors.length == 1) {
                                    return [colors.first, colors.first];
                                  }
                                  return colors;
                                }(),
                                stops: widget.headerGradientColors.length == 4
                                    ? const [0.0, 0.3446, 0.9055, 1.0]
                                    : null,
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          if (widget.headerImageAsset.isNotEmpty)
                            Image.asset(
                              widget.headerImageAsset,
                              fit: BoxFit.cover,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Expanded(
                    child: ColoredBox(color: Color(0xFFFFF9F7)),
                  ),
                ],
              ),
              Positioned(
                left: 24,
                right: 24,
                top: cardTop,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TransactionDetailsCard(
                      title: widget.detailsTitle,
                      details: widget.details,
                    ),
                    if (widget.showFailureActions) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onContactSupport == null
                                  ? null
                                  : () =>
                                      widget.onContactSupport?.call(context),
                              icon: const Icon(Icons.headset_mic_outlined),
                              label: const Text('Contact Support'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.textPrimary,
                                side: BorderSide(
                                  color: AppColors.lightBorder.withOpacity(0.8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onShareReceipt == null ||
                                      widget.transactionId.trim().isEmpty
                                  ? null
                                  : () => widget.onShareReceipt?.call(
                                        context,
                                        widget.transactionId,
                                      ),
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Share'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.textPrimary,
                                side: BorderSide(
                                  color: AppColors.lightBorder.withOpacity(0.8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: MediaQuery.of(context).padding.top + 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      child: Center(
                        child: widget.statusIconAsset.trim().isNotEmpty
                            ? Image.asset(
                                widget.statusIconAsset,
                                width: 44,
                                height: 44,
                                fit: BoxFit.contain,
                              )
                            : Icon(
                                widget.statusIcon,
                                color: widget.statusIconColor,
                                size: 44,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.emphasizeSubtitle)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: widget.subtitleBackgroundColor ??
                              (widget.showBackButton
                                  ? const Color(0xFF470601)
                                  : const Color(0xFF09301A)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                        ),
                      )
                    else
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              height: 1.4,
                            ),
                      ),
                  ],
                ),
              ),
              if (widget.showBackButton)
                Positioned(
                  left: 12,
                  top: MediaQuery.of(context).padding.top + 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onViewHistory != null) ...[
                          GestureDetector(
                            onTap: () => widget.onViewHistory?.call(context),
                            child: Text(
                              widget.viewHistoryText,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          20.hs,
                        ],
                        CustomElevatedButton(
                          onPressed: widget.onContinue == null
                              ? null
                              : () => widget.onContinue?.call(context),
                          label: widget.continueText,
                          uppercaseLabel: false,
                          showArrow: false,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.poweredByText,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.65),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Image.asset(
                          widget.poweredByLogo.isEmpty
                              ? FileConstants.bharatConnectColor
                              : widget.poweredByLogo,
                          height: 30.h,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaymentSoundController {
  static AudioPlayer? _player;
  static bool _isPlaying = false;

  static void play({String asset = 'sounds/payment_success.mp3'}) {
    if (_isPlaying) return;
    _player ??= AudioPlayer();
    _isPlaying = true;
    _player!.play(AssetSource(asset)).catchError((_) {
      _isPlaying = false;
    }).whenComplete(() {
      _isPlaying = false;
    });
  }

  static void stop() {
    _player?.stop();
    _isPlaying = false;
  }
}

class _TransactionDetailsCard extends StatelessWidget {
  const _TransactionDetailsCard({
    required this.title,
    required this.details,
  });

  final String title;
  final List<PaymentDetailItem> details;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              shadows: const [],
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.lightBorder.withOpacity(0.6)),
          const SizedBox(height: 8),
          ...details.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.7),
                          fontSize: 12,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            item.value,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                          ),
                        ),
                        if (item.copyable) ...[
                          6.vs,
                          InkWell(
                            onTap: () async {
                              await Clipboard.setData(
                                ClipboardData(text: item.value),
                              );
                              if (!context.mounted) return;
                              AppSnackbar.show(
                                'Copied to clipboard',
                                backgroundColor: AppColors.green,
                                textColor: Colors.white,
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Rating bottom sheet extracted to `lib/widgets/rating_bottom_sheet.dart`.
