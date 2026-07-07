// ignore_for_file: deprecated_member_use, use_build_context_synchronously

part of 'mobile_prepaid_view.dart';

class _ContactsSection extends StatelessWidget {
  const _ContactsSection({
    required this.hasContactsPermission,
    required this.onRequestPermission,
    required this.recentPayments,
    required this.banners,
    required this.myNumberForApi,
    required this.contactsSectionKey,
    required this.isLoading,
    required this.contacts,
    required this.allContacts,
    required this.visibleCount,
    required this.contactSearchController,
    required this.manualNumberController,
    required this.numericFocusNode,
    required this.alphaFocusNode,
    required this.searchMode,
    required this.onSearchModeChange,
    required this.onQueryChange,
    required this.onReload,
    required this.onLoadMore,
    required this.onSelect,
    required this.onManualProceed,
    required this.onRepeatRecent,
    required this.onMyNumberRecharge,
    required this.onViewAllRecent,
  });

  final bool hasContactsPermission;
  final VoidCallback onRequestPermission;
  final AsyncValue<List<LatestTransaction>> recentPayments;
  final AsyncValue<List<BannerModel>> banners;
  final String myNumberForApi;
  final GlobalKey contactsSectionKey;
  final bool isLoading;
  final List<Contact> contacts;
  final List<Contact> allContacts;
  final int visibleCount;
  final TextEditingController contactSearchController;
  final TextEditingController manualNumberController;
  final FocusNode numericFocusNode;
  final FocusNode alphaFocusNode;
  final _MobilePrepaidSearchMode searchMode;
  final ValueChanged<_MobilePrepaidSearchMode> onSearchModeChange;
  final ValueChanged<String> onQueryChange;
  final VoidCallback onReload;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onSelect;
  final Future<void> Function(String mobile) onManualProceed;
  final ValueChanged<LatestTransaction> onRepeatRecent;
  final ValueChanged<String> onMyNumberRecharge;
  final VoidCallback onViewAllRecent;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          onLoadMore();
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          if (searchMode == _MobilePrepaidSearchMode.abc) ...[
            _MobilePrepaidBanner(banners: banners),
            const SizedBox(height: 14),
          ],
          _MobilePrepaidSearchSwitcher(
            searchMode: searchMode,
            onSearchModeChange: onSearchModeChange,
            alphaController: contactSearchController,
            numericController: manualNumberController,
            numericFocusNode: numericFocusNode,
            alphaFocusNode: alphaFocusNode,
            onAlphaChanged: onQueryChange,
            contacts: allContacts,
            onProceed: onManualProceed,
          ),
          if (searchMode == _MobilePrepaidSearchMode.numeric) ...[
            const SizedBox(height: 12),
            const _SectionHeader(title: 'My Contacts'),
            const SizedBox(height: 10),
            if (!hasContactsPermission)
              ContactsPermissionCard(
                onAllow: onRequestPermission,
                outerPadding: EdgeInsets.zero,
              )
            else if (isLoading)
              const Center(
                child: SpinKitCircle(
                  color: AppColors.primary,
                  size: 48,
                ),
              )
            else if (contacts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No contacts found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.6),
                        ),
                  ),
                ),
              )
            else ...[
              ContactsList(
                contacts: contacts,
                visibleCount: visibleCount,
                onSelect: onSelect,
              ),
              if (contacts.length > visibleCount) ...[
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Scroll to load more',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.6),
                        ),
                  ),
                ),
              ],
            ],
          ] else ...[
            const SizedBox(height: 18),
            _MyNumberSection(
              numberForApi: myNumberForApi,
              onSelect: onSelect,
              onRecharge: onMyNumberRecharge,
            ),
            const SizedBox(height: 18),
            _RecentRechargesSection(
              recentPayments: recentPayments,
              onRepeatRecent: onRepeatRecent,
              onViewAllRecent: onViewAllRecent,
            ),
            const SizedBox(height: 18),
            SizedBox(key: contactsSectionKey),
            const _SectionHeader(title: 'My Contacts'),
            const SizedBox(height: 10),
            if (!hasContactsPermission)
              ContactsPermissionCard(
                onAllow: onRequestPermission,
                outerPadding: EdgeInsets.zero,
              )
            else if (isLoading)
              const Center(
                child: SpinKitCircle(
                  color: AppColors.primary,
                  size: 48,
                ),
              )
            else if (contacts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No contacts found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.6),
                        ),
                  ),
                ),
              )
            else ...[
              ContactsList(
                contacts: contacts,
                visibleCount: visibleCount,
                onSelect: onSelect,
              ),
              if (contacts.length > visibleCount) ...[
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Scroll to load more',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.6),
                        ),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _MobilePrepaidBanner extends StatelessWidget {
  const _MobilePrepaidBanner({required this.banners});

  final AsyncValue<List<BannerModel>> banners;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: banners.when(
          loading: () => const _BannerShimmer(),
          error: (_, __) => Image.asset(
            FileConstants.homeBanner2,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          data: (items) {
            final image = items.isNotEmpty ? items.first.image.trim() : '';
            if (image.isEmpty) {
              return Image.asset(
                FileConstants.homeBanner2,
                width: double.infinity,
                fit: BoxFit.cover,
              );
            }
            return AppNetworkImage(
              url: image,
              height: 92,
              width: double.infinity,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(16),
            );
          },
        ),
      ),
    );
  }
}

class _BannerShimmer extends StatelessWidget {
  const _BannerShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE9E9E9),
      highlightColor: const Color(0xFFF6F6F6),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
      ),
    );
  }
}

enum _MobilePrepaidSearchMode { abc, numeric }

class _MobilePrepaidSearchSwitcher extends StatelessWidget {
  const _MobilePrepaidSearchSwitcher({
    required this.searchMode,
    required this.onSearchModeChange,
    required this.alphaController,
    required this.numericController,
    required this.numericFocusNode,
    required this.alphaFocusNode,
    required this.onAlphaChanged,
    required this.contacts,
    required this.onProceed,
  });

  final _MobilePrepaidSearchMode searchMode;
  final ValueChanged<_MobilePrepaidSearchMode> onSearchModeChange;
  final TextEditingController alphaController;
  final TextEditingController numericController;
  final FocusNode numericFocusNode;
  final FocusNode alphaFocusNode;
  final ValueChanged<String> onAlphaChanged;
  final List<Contact> contacts;
  final Future<void> Function(String mobile) onProceed;

  @override
  Widget build(BuildContext context) {
    final isNumeric = searchMode == _MobilePrepaidSearchMode.numeric;

    return Column(
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (!isNumeric) ...[
                Image.asset(
                  FileConstants.orangeSearch,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: isNumeric ? numericController : alphaController,
                  focusNode: isNumeric ? numericFocusNode : alphaFocusNode,
                  autofocus: true,
                  keyboardType:
                      isNumeric ? TextInputType.phone : TextInputType.text,
                  textInputAction:
                      isNumeric ? TextInputAction.done : TextInputAction.search,
                  inputFormatters: isNumeric
                      ? [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ]
                      : const [],
                  onChanged: isNumeric ? null : onAlphaChanged,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: isNumeric
                        ? 'Enter mobile number'
                        : 'Search by number or name',
                    prefixText: isNumeric ? '+91 ' : null,
                    prefixStyle:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.45),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              _SearchModeToggle(
                mode: searchMode,
                onChanged: onSearchModeChange,
              ),
            ],
          ),
        ),
        if (isNumeric)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: numericController,
            builder: (context, value, _) {
              final numericDigits = _normalizeMobile(value.text);
              final isEnabled = numericDigits.length == 10;
              return Column(
                children: [
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed:
                          isEnabled ? () => onProceed(numericDigits) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.35),
                        disabledForegroundColor: Colors.white.withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Proceed',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _SearchModeToggle extends StatelessWidget {
  const _SearchModeToggle({
    required this.mode,
    required this.onChanged,
  });

  final _MobilePrepaidSearchMode mode;
  final ValueChanged<_MobilePrepaidSearchMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, _MobilePrepaidSearchMode value) {
      final active = mode == value;
      return InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: active ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip('ABC', _MobilePrepaidSearchMode.abc),
          const SizedBox(width: 4),
          chip('123', _MobilePrepaidSearchMode.numeric),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String? actionText;
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
        if (actionText != null && onAction != null)
          InkWell(
            onTap: onAction,
            child: Text(
              actionText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFE85A2C),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
      ],
    );
  }
}

class _ExpiryPill extends StatelessWidget {
  const _ExpiryPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF7C1D0F),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              height: 1,
            ),
      ),
    );
  }
}

class _OrangePillButton extends StatelessWidget {
  const _OrangePillButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE85A2C),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class _MyNumberCard extends StatelessWidget {
  const _MyNumberCard({
    required this.dueLabel,
    required this.operatorLabel,
    this.operatorIconUrl,
    required this.mobile,
    required this.lastOn,
    required this.onRecharge,
  });

  final String? dueLabel;
  final String operatorLabel;
  final String? operatorIconUrl;
  final String mobile;
  final String lastOn;
  final VoidCallback onRecharge;

  @override
  Widget build(BuildContext context) {
    // Keep sizing consistent across devices (avoid ScreenUtil scaling here).
    const titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      height: 1.1,
    );
    const subtitleStyle = TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xff7C7C7C));

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E2E2)),
          ),
          child: Row(
            children: [
              _OperatorBrandLogo(
                operatorLabel: operatorLabel,
                operatorIconUrl: operatorIconUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mobile,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Last On - $lastOn',
                      style: subtitleStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _OrangePillButton(
                label: 'Recharge',
                onPressed: onRecharge,
              ),
            ],
          ),
        ),
        if ((dueLabel ?? '').trim().isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            child: _ExpiryPill(dueLabel!.trim()),
          ),
      ],
    );
  }
}

class _OperatorBrandLogo extends StatelessWidget {
  const _OperatorBrandLogo({
    required this.operatorLabel,
    required this.operatorIconUrl,
  });

  final String operatorLabel;
  final String? operatorIconUrl;

  @override
  Widget build(BuildContext context) {
    return _OperatorIconBadge(
      label: operatorLabel,
      iconUrl: operatorIconUrl,
    );
  }
}

class _RecentRechargeRow extends StatelessWidget {
  const _RecentRechargeRow({
    required this.recentPayments,
    required this.onRepeat,
  });

  final AsyncValue<List<LatestTransaction>> recentPayments;
  final ValueChanged<LatestTransaction> onRepeat;

  @override
  Widget build(BuildContext context) {
    Widget buildScroller(Widget child) {
      return LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: 96,
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: constraints.maxWidth,
            maxWidth: constraints.maxWidth + 16,
            child: SizedBox(
              width: constraints.maxWidth + 16,
              child: child,
            ),
          ),
        ),
      );
    }

    return recentPayments.when(
      loading: () => buildScroller(
        ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, __) =>
              const MobilePrepaidRecentRechargeCardShimmer(),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemCount: 2,
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final display = items.take(10).toList();
        if (display.isEmpty) return const SizedBox.shrink();
        return buildScroller(
          ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) => _RecentRechargeCard(
              title: display[index].billerName.trim().isNotEmpty
                  ? display[index].billerName
                  : display[index].serviceNo,
              iconUrl: display[index].icon,
              mobile: display[index].serviceNo,
              amount: display[index].amount,
              lastOn:
                  (display[index].transactionTime?.trim().isNotEmpty ?? false)
                      ? _recentRechargeDateOnly(
                          display[index].transactionTime,
                        )
                      : '--',
              badgeLabel: _resolveDueOrExpiryLabel(
                dueDate: display[index].dueDate,
                expiresAt: display[index].expiresAt,
              ),
              onRepeat: () => onRepeat(display[index]),
            ),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: display.length,
          ),
        );
      },
    );
  }
}

String? _resolveDueOrExpiryLabel({
  required String? dueDate,
  required String? expiresAt,
}) {
  DateTime? parse(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || value.toLowerCase() == 'null') return null;
    return DateTime.tryParse(value);
  }

  final due = parse(dueDate);
  final exp = parse(expiresAt);
  final target = due ?? exp;
  if (target == null) return null;

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final days = target.difference(startOfToday).inDays;
  if (days <= 0) return (due != null) ? 'Due Today' : 'Expires Today';
  if (days == 1) return (due != null) ? 'Due In 1 Day' : 'Expires In 1 Day';
  return (due != null) ? 'Due In $days Days' : 'Expires In $days Days';
}

String _recentRechargeDateOnly(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return '--';
  final commaIndex = value.indexOf(',');
  if (commaIndex <= 0) return value;
  return value.substring(0, commaIndex).trim();
}

class _RecentRechargeCard extends StatelessWidget {
  const _RecentRechargeCard({
    required this.title,
    required this.iconUrl,
    required this.mobile,
    required this.amount,
    required this.lastOn,
    required this.badgeLabel,
    required this.onRepeat,
  });

  final String title;
  final String iconUrl;
  final String mobile;
  final num amount;
  final String lastOn;
  final String? badgeLabel;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    // Keep sizing consistent across devices (avoid ScreenUtil scaling here).
    const titleStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      height: 1.1,
    );
    const secondaryStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xff7C7C7C),
    );

    final showBadge = (badgeLabel ?? '').trim().isNotEmpty;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Container(
          width: 380,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E2E2)),
          ),
          child: Row(
            children: [
              _OperatorIconBadge(
                label: title,
                iconUrl: iconUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mobile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amount > 0
                          ? 'Last Recharge ₹${amount.toString()} on $lastOn'
                          : 'Last Recharge on $lastOn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: secondaryStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _OrangePillButton(
                label: 'Repeat',
                onPressed: onRepeat,
              ),
            ],
          ),
        ),
        if (showBadge)
          Positioned(
            top: 0,
            left: 0,
            child: _ExpiryPill(badgeLabel!.trim()),
          ),
      ],
    );
  }
}

class _OperatorIconBadge extends StatelessWidget {
  const _OperatorIconBadge({
    required this.label,
    required this.iconUrl,
  });

  final String label;
  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    final trimmedLabel = label.trim();
    final trimmedIconUrl = iconUrl?.trim() ?? '';
    return Container(
      height: 45,
      width: 45,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: trimmedIconUrl.isNotEmpty
          ? AppNetworkImage(
              url: trimmedIconUrl,
              fit: BoxFit.contain,
              showShimmer: false,
            )
          : Center(
              child: Text(
                trimmedLabel.isEmpty ? 'R' : trimmedLabel[0].toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFE85A2C),
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
              ),
            ),
    );
  }
}

class _PlanSection extends HookWidget {
  const _PlanSection({
    required this.state,
    required this.controller,
    required this.planSearchController,
    required this.onPlanSearchChanged,
  });

  final MobilePrepaidState state;
  final MobilePrepaidController controller;
  final TextEditingController planSearchController;
  final ValueChanged<String> onPlanSearchChanged;

  @override
  Widget build(BuildContext context) {
    const suggestedGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFDBCF),
        Colors.white,
        Color(0xFFFFDBCF),
      ],
      stops: [0.0, 0.5, 1.0],
    );

    const allFilterLabel = 'All';
    final quickFilters = state.filterTags
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != allFilterLabel)
        .toList();
    final applied = state.appliedFilters.map((e) => e.trim()).toSet();
    final isAllSelected = applied.isEmpty || applied.contains(allFilterLabel);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          controller.loadNextPlansPage();
        }
        return false;
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          0,
          10,
          0,
          24 + MediaQuery.of(context).viewPadding.bottom,
        ),
        children: [
          // Suggested plans block should be at the top (edge-to-edge gradient).
          if (!state.isFetching && state.currentPlans.isNotEmpty)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: suggestedGradient),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggested Plans',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontSize: 14.sp,
                        ),
                  ),
                  const SizedBox(height: 14),
                  _SuggestedPlanCards(
                    plans: state.currentPlans,
                    onSelect: controller.selectPlan,
                  ),
                ],
              ),
            ),

          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: SearchTextfield(
              hintText: 'Search a plan, eg 299, 5g, etc.',
              controller: planSearchController,
              onChange: onPlanSearchChanged,
            ),
          ),

          // Filters row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: SizedBox(
              height: 30.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 2 + quickFilters.length,
                separatorBuilder: (_, index) =>
                    SizedBox(width: index == 0 ? 12.w : 6.w),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return OutlinedButton.icon(
                      onPressed: () => KDialog.instance.openSheet(
                        dialog: FilterPlansSheet(
                          validityOptions: state.validityFilters,
                          dataOptions: state.dataFilters,
                          initialValiditySelected: applied
                              .where((t) => t != allFilterLabel)
                              .where((t) => state.validityFilters.contains(t))
                              .toSet(),
                          initialDataSelected: applied
                              .where((t) => t != allFilterLabel)
                              .where((t) => state.dataFilters.contains(t))
                              .toSet(),
                          onApply: (validity, data) async {
                            final selected = <String>[
                              ...validity,
                              ...data,
                            ];
                            final info = state.operatorInfo;
                            if (info == null) return;
                            await controller.fetchPlansForSelection(
                              mobileInput: state.mobile,
                              operatorName: info.operatorName,
                              circleName: info.circle,
                              circleCode: info.circleCode,
                              iconUrl: info.iconUrl,
                              search: state.planSearchQuery,
                              filters: selected,
                            );
                          },
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(
                          color: AppColors.textPrimary.withOpacity(0.12),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: Icon(
                        Icons.tune_rounded,
                        size: 16.sp,
                        color: AppColors.textPrimary,
                      ),
                      label: Text(
                        'Filter',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                        ),
                      ),
                    );
                  }
                  if (index == 1) {
                    return InkWell(
                      onTap: () async {
                        final info = state.operatorInfo;
                        if (info == null) return;
                        await controller.fetchPlansForSelection(
                          mobileInput: state.mobile,
                          operatorName: info.operatorName,
                          circleName: info.circle,
                          circleCode: info.circleCode,
                          iconUrl: info.iconUrl,
                          search: state.planSearchQuery,
                          filters: const [],
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAllSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isAllSelected
                                ? AppColors.primary.withOpacity(0.35)
                                : AppColors.textPrimary.withOpacity(0.08),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            allFilterLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isAllSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary.withOpacity(0.85),
                                ),
                          ),
                        ),
                      ),
                    );
                  }
                  final label = quickFilters[index - 2];
                  return InkWell(
                    onTap: () async {
                      final info = state.operatorInfo;
                      if (info == null) return;
                      await controller.fetchPlansForSelection(
                        mobileInput: state.mobile,
                        operatorName: info.operatorName,
                        circleName: info.circle,
                        circleCode: info.circleCode,
                        iconUrl: info.iconUrl,
                        search: state.planSearchQuery,
                        filters: [label],
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: applied.contains(label) && !isAllSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: applied.contains(label) && !isAllSelected
                              ? AppColors.primary.withOpacity(0.35)
                              : AppColors.textPrimary.withOpacity(0.08),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: applied.contains(label) && !isAllSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary.withOpacity(0.85),
                              ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Categories + plan list content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _CategoryTabs(
              categories: state.categories,
              selected: state.selectedCategory,
              onSelected: controller.selectCategory,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Builder(
              builder: (context) {
                if (state.isFetching && state.currentPlans.isEmpty) {
                  return const Center(
                    child: SpinKitCircle(
                      color: AppColors.primary,
                      size: 48,
                    ),
                  );
                }
                if (state.visiblePlans.isEmpty) {
                  return _EmptyPlansState(query: state.planSearchQuery);
                }
                return _PlanList(
                  plans: state.visiblePlans,
                  selectedPlan: state.selectedPlan,
                  onSelect: controller.selectPlan,
                  onPayNow: (plan) => KDialog.instance.openSheet(
                    dialog: PrepaidPaymentBottomSheet(
                      plan: plan,
                      billerName:
                          state.operatorInfo?.operatorName ?? 'Mobile Prepaid',
                      ecoinsRestrictionsPercent:
                          state.ecoinsRestrictionsPercent,
                    ),
                  ),
                );
              },
            ),
          ),
          if (state.isFetchingMorePlans)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Center(
                child: SpinKitCircle(
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PayNowSection extends StatelessWidget {
  const _PayNowSection({
    required this.state,
    required this.controller,
  });

  final MobilePrepaidState state;
  final MobilePrepaidController controller;

  @override
  Widget build(BuildContext context) {
    final plan = state.selectedPlan;
    if (plan == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Plan details card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 12,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Price + E-Coins badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹ ${plan.amount}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  fontSize: 28,
                                ),
                          ),
                          const Spacer(),
                          if (plan.eCoins > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B3554),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Get Assured ${plan.eCoins} E-Coins',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Row 2: Validity | Data | Benefit images
                      _buildInfoRow(context, plan),
                      const SizedBox(height: 14),
                      // Description
                      Text(
                        plan.description.isEmpty
                            ? 'No description available.'
                            : plan.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.7),
                              height: 1.4,
                              fontSize: 13,
                            ),
                      ),
                      const SizedBox(height: 18),
                      // Category name + Change Plan row
                      Row(
                        children: [
                          if (state.selectedCategory.isNotEmpty)
                            Text(
                              state.selectedCategory,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontSize: 14,
                                  ),
                            ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () => controller.deselectPlan(),
                            icon: const Icon(
                              Icons.sync,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text('Change Plan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B3554),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom Proceed To Pay button
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: state.isRecharging
                  ? null
                  : () => KDialog.instance.openSheet(
                        dialog: PrepaidPaymentBottomSheet(
                          plan: plan,
                          billerName: state.operatorInfo?.operatorName ??
                              'Mobile Prepaid',
                          ecoinsRestrictionsPercent:
                              state.ecoinsRestrictionsPercent,
                        ),
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                elevation: 0,
              ),
              child: state.isRecharging
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: SpinKitCircle(
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                  : Text(
                      'Proceed To Pay',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, PlanItem plan) {
    final hasValidity = plan.validity.isNotEmpty;
    final hasData = plan.data.isNotEmpty;
    final hasBenefitImages = plan.additionalBenefits.isNotEmpty;

    if (!hasValidity && !hasData && !hasBenefitImages) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (hasValidity)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Validity',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.5),
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                plan.validity,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
        if (hasValidity && hasData)
          Container(
            width: 1,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.grey.shade300,
          ),
        if (hasData)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.5),
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                plan.data,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
        if ((hasValidity || hasData) && hasBenefitImages) const Spacer(),
        if (hasBenefitImages) _buildBenefitImages(context, plan),
      ],
    );
  }

  Widget _buildBenefitImages(BuildContext context, PlanItem plan) {
    const maxVisible = 5;
    final benefits = plan.additionalBenefits;
    final visibleBenefits = benefits.take(maxVisible).toList();
    final remaining = benefits.length - maxVisible;

    return GestureDetector(
      onTap: () => KDialog.instance.openSheet(
        dialog: PlanDetailsSheet(
          plan: plan,
          onProceedToPay: () => KDialog.instance.openSheet(
            dialog: PrepaidPaymentBottomSheet(
              plan: plan,
              billerName: state.operatorInfo?.operatorName ?? 'Mobile Prepaid',
              ecoinsRestrictionsPercent: state.ecoinsRestrictionsPercent,
            ),
          ),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: (visibleBenefits.length * 26.0) + 10,
            height: 36,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < visibleBenefits.length; i++)
                  Positioned(
                    left: i * 26.0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: visibleBenefits[i].image == null
                            ? Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.card_giftcard,
                                  size: 16,
                                ),
                              )
                            : Image.network(
                                visibleBenefits[i].image!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image, size: 16),
                                ),
                              ),
                      ),
                    ),
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
                    fontSize: 13,
                  ),
            ),
        ],
      ),
    );
  }
}

Future<void> _openOperatorSheet(
  WidgetRef ref, {
  required String mobile,
  required Future<void> Function(OperatorOption operator, RegionOption region)
      onSelected,
}) async {
  final metaController = ref.read(prepaidMetaControllerProvider.notifier);
  KDialog.instance.openDialog(
    dialog: const ScreenWrapper(
      isFetching: true,
      isEmpty: false,
      emptyMessage: '',
      child: SizedBox.shrink(),
    ),
    barrierDismissible: false,
  );
  await metaController.loadOperatorsIfNeeded();
  final currentContext = navigatorKey.currentContext;
  if (currentContext == null) return;
  Navigator.of(currentContext).pop();
  KDialog.instance.openConstraintsSheet(
    dialog: _OperatorSelectSheet(
      onSelected: (operator) async {
        KDialog.instance.openDialog(
          dialog: const ScreenWrapper(
            isFetching: true,
            isEmpty: false,
            emptyMessage: '',
            child: SizedBox.shrink(),
          ),
          barrierDismissible: false,
        );
        await metaController.loadRegionsIfNeeded();
        final regionContext = navigatorKey.currentContext;
        if (regionContext == null) return;
        Navigator.of(regionContext).pop();
        final size = MediaQuery.of(regionContext).size;
        KDialog.instance.openConstraintsSheet(
          dialog: _RegionSelectSheet(
            onSelected: (region) async {
              if (mobile.trim().isEmpty) return;
              await onSelected(operator, region);
            },
          ),
          maxHeight: size.height * 0.65,
        );
      },
    ),
    maxHeight: MediaQuery.of(currentContext).size.height * 0.6,
  );
}

class _OperatorSelectSheet extends ConsumerWidget {
  const _OperatorSelectSheet({required this.onSelected});

  final ValueChanged<OperatorOption> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ref.watch(prepaidMetaControllerProvider);
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select Operator',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Divider(color: AppColors.lightBorder.withOpacity(0.7)),
          if (meta.isLoadingOperators)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: SpinKitCircle(
                color: AppColors.primary,
                size: 48,
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: meta.operators.length,
                itemBuilder: (_, index) {
                  final item = meta.operators[index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelected(item);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Row(
                        children: [
                          _OperatorLogo(iconUrl: item.iconUrl),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              item.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Transform.rotate(
                            angle: -0.65,
                            child: const Icon(
                              Icons.arrow_forward,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RegionSelectSheet extends ConsumerStatefulWidget {
  const _RegionSelectSheet({required this.onSelected});

  final ValueChanged<RegionOption> onSelected;

  @override
  ConsumerState<_RegionSelectSheet> createState() => _RegionSelectSheetState();
}

class _RegionSelectSheetState extends ConsumerState<_RegionSelectSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(prepaidMetaControllerProvider);
    final query = _searchController.text.trim().toLowerCase();
    final regions = query.isEmpty
        ? meta.regions
        : meta.regions
            .where((r) => r.name.toLowerCase().contains(query))
            .toList();

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select Your Circle',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Divider(color: AppColors.lightBorder.withOpacity(0.7)),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search region',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            ),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 8.h),
          if (meta.isLoadingRegions)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: SpinKitCircle(
                color: AppColors.primary,
                size: 48,
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: regions.length,
                separatorBuilder: (_, __) => Divider(
                  color: AppColors.lightBorder.withOpacity(0.7),
                  height: 1,
                ),
                itemBuilder: (_, index) {
                  final item = regions[index];
                  return ListTile(
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSelected(item);
                    },
                    title: Text(
                      item.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _OperatorLogo extends StatelessWidget {
  const _OperatorLogo({required this.iconUrl});

  final String iconUrl;

  @override
  Widget build(BuildContext context) {
    if (iconUrl.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: CircleAvatar(
          radius: 20.r,
          backgroundColor: AppColors.primary.withOpacity(0.08),
          child: Icon(
            Icons.sim_card,
            color: AppColors.primary,
            size: 20.r,
          ),
        ),
      );
    }
    final isSvg = iconUrl.toLowerCase().endsWith('.svg');
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: CircleAvatar(
        radius: 20.r,
        backgroundColor: Colors.white,
        child: isSvg
            ? SvgPicture.network(
                iconUrl,
                width: 24.r,
                height: 24.r,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => _logoPlaceholder(),
              )
            : Image.network(
                iconUrl,
                width: 24.r,
                height: 24.r,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _logoPlaceholder(),
              ),
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Icon(
      Icons.sim_card,
      size: 20.r,
      color: AppColors.primary,
    );
  }
}

class _SuggestedPlanCards extends StatelessWidget {
  const _SuggestedPlanCards({
    required this.plans,
    required this.onSelect,
  });

  final List<PlanItem> plans;
  final ValueChanged<PlanItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final displayPlans = plans.take(5).toList();
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(bottom: 2.h),
        itemCount: displayPlans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final plan = displayPlans[index];
          return _SuggestedPlanCard(
            plan: plan,
            onTap: () => onSelect(plan),
          );
        },
      ),
    );
  }
}

class _SuggestedPlanCard extends StatelessWidget {
  const _SuggestedPlanCard({
    required this.plan,
    required this.onTap,
  });

  final PlanItem plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightBorder),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(26, 130, 128, 128),
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 10.w,
              bottom: 65.h,
              child: IgnorePointer(
                child: Image.asset(
                  FileConstants.orangeRight,
                  width: 30.w,
                  height: 30.h,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 70, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹ ${plan.amount}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontSize: 22,
                        ),
                  ),
                  if (plan.planName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      plan.planName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0XFF222222),
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      plan.description.isEmpty
                          ? 'No description available.'
                          : plan.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0XFF222222),
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                            fontSize: 12,
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onTap,
                    child: Text(
                      'Details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyNumberSection extends ConsumerWidget {
  const _MyNumberSection({
    required this.numberForApi,
    required this.onSelect,
    required this.onRecharge,
  });

  final String numberForApi;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRecharge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = numberForApi.trim();
    if (resolved.isEmpty) return const SizedBox.shrink();
    final myNumberInfo = ref.watch(mobilePrepaidMyNumberProvider(resolved));
    return myNumberInfo.when(
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'My Number'),
          SizedBox(height: 10),
          MobilePrepaidMyNumberCardShimmer(),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) {
        final mobile = info.number.trim();
        if (mobile.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'My Number'),
            const SizedBox(height: 10),
            _MyNumberCard(
              dueLabel: (info.dueLabel?.trim().isNotEmpty ?? false)
                  ? info.dueLabel!.trim()
                  : null,
              operatorLabel: (info.operatorName?.trim().isNotEmpty ?? false)
                  ? info.operatorName!.trim()
                  : '',
              operatorIconUrl: info.operatorIcon,
              mobile: mobile,
              lastOn: (info.lastOn?.trim().isNotEmpty ?? false)
                  ? info.lastOn!.trim()
                  : '--',
              onRecharge: () => onRecharge(mobile),
            ),
          ],
        );
      },
    );
  }
}

class _RecentRechargesSection extends StatelessWidget {
  const _RecentRechargesSection({
    required this.recentPayments,
    required this.onRepeatRecent,
    required this.onViewAllRecent,
  });

  final AsyncValue<List<LatestTransaction>> recentPayments;
  final ValueChanged<LatestTransaction> onRepeatRecent;
  final VoidCallback onViewAllRecent;

  @override
  Widget build(BuildContext context) {
    return recentPayments.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Recents',
            actionText: 'View all',
            onAction: onViewAllRecent,
          ),
          const SizedBox(height: 10),
          _RecentRechargeRow(
            recentPayments: recentPayments,
            onRepeat: onRepeatRecent,
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Recents',
              actionText: 'View all',
              onAction: onViewAllRecent,
            ),
            const SizedBox(height: 10),
            _RecentRechargeRow(
              recentPayments: recentPayments,
              onRepeat: onRepeatRecent,
            ),
          ],
        );
      },
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 35,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 28),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = category == selected;
          return GestureDetector(
            onTap: () => onSelected(category),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive
                              ? AppColors.textPrimary
                              : AppColors.textPrimary.withOpacity(0.5),
                          fontSize: 14,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 2.5,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          isActive ? AppColors.textPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({
    required this.plans,
    required this.selectedPlan,
    required this.onSelect,
    required this.onPayNow,
  });

  final List<PlanItem> plans;
  final PlanItem? selectedPlan;
  final ValueChanged<PlanItem> onSelect;
  final ValueChanged<PlanItem> onPayNow;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: plans.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final plan = plans[index];
        return PlanCard(
          plan: plan,
          isSelected: selectedPlan == plan,
          onTap: () => onSelect(plan),
          onPayNow: () => onPayNow(plan),
        );
      },
    );
  }
}

class _EmptyPlansState extends StatelessWidget {
  const _EmptyPlansState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          query.isEmpty
              ? 'No plans available for this category.'
              : 'No plans match "$query".',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
        ),
      ),
    );
  }
}
