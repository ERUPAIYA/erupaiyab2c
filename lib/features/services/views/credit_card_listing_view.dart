// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/infinite_scroll_listener.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/screen_wrapper.dart';
import '../../../widgets/search_textfield.dart';
import '../../mobile_prepaid/models/latest_transaction.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/service_recent_section.dart';
import '../controllers/biller_detail_controller.dart';
import '../controllers/biller_listing_controller.dart';
import '../controllers/service_extras_controller.dart';
import '../models/biller_detail_args.dart';
import '../models/biller_model.dart';

class CreditCardListingView extends HookConsumerWidget {
  const CreditCardListingView({super.key});

  static const String _categoryName = 'Credit Card';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingState = ref.watch(billerListingControllerProvider);
    final searchController = useTextEditingController();
    final profileState = ref.watch(profileControllerProvider);
    final recentTransactions =
        ref.watch(serviceLatestTransactionsProvider('Credit Card'));

    useEffect(() {
      Future.microtask(() {
        ref
            .read(billerListingControllerProvider.notifier)
            .fetchBillers(categoryName: _categoryName);
        searchController.clear();
        ref.read(billerListingControllerProvider.notifier).updateSearch('');
      });
      return null;
    }, const []);

    final billers = listingState.filteredBillers;
    final topPicks = billers.take(6).toList();
    final remaining = billers.skip(topPicks.length).toList();

    void openBillerFromRecent(LatestTransaction txn) {
      final normalizedBiller = txn.billerName.trim().toLowerCase();
      if (normalizedBiller.isEmpty) return;

      final match = billers.where((b) {
        return b.billerName.trim().toLowerCase() == normalizedBiller;
      }).toList();
      if (match.isEmpty) {
        AppSnackbar.show('Provider not found. Please select from the list.');
        return;
      }

      final digits = txn.serviceNo.replaceAll(RegExp(r'\\D'), '');
      final last4 =
          digits.length >= 4 ? digits.substring(digits.length - 4) : '';
      final mobile =
          (profileState.profile?.mobile ?? '').replaceAll(RegExp(r'\\D'), '');

      final canAutoFetch = mobile.length >= 10 && last4.length == 4;
      if (!canAutoFetch) {
        AppSnackbar.show(
          'Unable to auto fetch bill. Please enter details again.',
        );
      }

      final biller = match.first;
      ref.read(billerDetailControllerProvider.notifier).selectBiller(biller);
      context.push(
        RouteConstants.billerDetail,
        extra: BillerDetailArgs(
          biller: biller,
          isCreditCard: true,
          paymentType: 'Credit card',
          mobileNumber: mobile.isNotEmpty ? mobile : null,
          cardLast4: last4.length == 4 ? last4 : null,
          autoFetchBill: canAutoFetch,
          autoOpenPaymentSheet: false,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: 'Select Your Bank',
            onBack: () => context.pop(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SearchTextfield(
              hintText: 'Search bank name',
              controller: searchController,
              onChange: (value) => ref
                  .read(billerListingControllerProvider.notifier)
                  .updateSearch(value),
            ),
          ),
          Expanded(
            child: ScreenWrapper(
              isFetching: listingState.isFetching,
              isEmpty: billers.isEmpty,
              emptyMessage: 'No providers found',
              errorMessage: listingState.errorMessage,
              actions: listingState.errorMessage != null
                  ? [
                      TextButton(
                        onPressed: () => ref
                            .read(billerListingControllerProvider.notifier)
                            .fetchBillers(categoryName: _categoryName),
                        child: const Text('Retry'),
                      ),
                    ]
                  : null,
              child: InfiniteScrollListener(
                isLoading: listingState.isFetchingMore,
                hasMore: listingState.hasMore,
                onEndReached: () => ref
                    .read(billerListingControllerProvider.notifier)
                    .fetchNextPage(),
                child: SingleChildScrollView(
                  primary: false,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ServiceRecentSection(
                        recentTransactions: recentTransactions,
                        onPayNow: openBillerFromRecent,
                        onAction: () {},
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Popular Banks',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                const spacing = 12.0;
                                const columns = 3;
                                final tileWidth = (constraints.maxWidth -
                                        (spacing * (columns - 1))) /
                                    columns;
                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: [
                                    for (final biller in topPicks)
                                      SizedBox(
                                        width: tileWidth,
                                        child: _BillerGridTile(
                                          biller: biller,
                                          onTap: () {
                                            ref
                                                .read(
                                                  billerDetailControllerProvider
                                                      .notifier,
                                                )
                                                .selectBiller(biller);
                                            context.push(
                                              RouteConstants.billerDetail,
                                              extra: BillerDetailArgs(
                                                biller: biller,
                                                isCreditCard: true,
                                                paymentType: 'Credit card',
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'All Banks',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: [
                                for (final biller in remaining)
                                  _BillerListTile(
                                    biller: biller,
                                    onTap: () {
                                      ref
                                          .read(
                                            billerDetailControllerProvider
                                                .notifier,
                                          )
                                          .selectBiller(biller);
                                      context.push(
                                        RouteConstants.billerDetail,
                                        extra: BillerDetailArgs(
                                          biller: biller,
                                          isCreditCard: true,
                                          paymentType: 'Credit card',
                                        ),
                                      );
                                    },
                                  ),
                                if (listingState.isFetchingMore)
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SpinKitCircle(
                                        color: AppColors.primary,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillerGridTile extends StatelessWidget {
  const _BillerGridTile({required this.biller, this.onTap});

  final Biller biller;
  final VoidCallback? onTap;
  static const double _tileHeight = 112;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints.tightFor(height: _tileHeight),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ProviderIconFrame(
              child: _BillerIcon(
                name: biller.billerName,
                iconUrl: biller.iconUrl,
                size: 38,
                backgroundColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: Text(
                biller.billerName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillerListTile extends StatelessWidget {
  const _BillerListTile({required this.biller, this.onTap});

  final Biller biller;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _ProviderIconFrame(
              size: 44,
              child: _BillerIcon(
                name: biller.billerName,
                iconUrl: biller.iconUrl,
                size: 38,
                backgroundColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                biller.billerName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Image.asset(
              FileConstants.tiltArrow,
              height: 22,
              width: 22,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

class _BillerIcon extends StatelessWidget {
  const _BillerIcon({
    required this.name,
    required this.iconUrl,
    required this.size,
    required this.backgroundColor,
    required this.borderRadius,
  });

  final String name;
  final String? iconUrl;
  final double size;
  final Color backgroundColor;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '';
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );

    if (iconUrl == null || iconUrl!.isEmpty) {
      return fallback;
    }

    return AppNetworkImage(
      url: iconUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      borderRadius: borderRadius,
      placeholder: fallback,
      errorWidget: fallback,
    );
  }
}

class _ProviderIconFrame extends StatelessWidget {
  const _ProviderIconFrame({
    required this.child,
    this.size = 44,
  });

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightBorder, width: 1),
      ),
      child: child,
    );
  }
}
