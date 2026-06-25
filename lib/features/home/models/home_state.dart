import 'banner_model.dart';
import 'credit_card_item.dart';
import 'quick_action_model.dart';
import 'quick_actions_model.dart';

class HomeState {
  const HomeState({
    this.isFetching = false,
    this.isFetchingCreditCards = false,
    this.isFetchingRecharge = false,
    this.isServerUnavailable = false,
    this.errorMessage,
    this.allQuickActions,
    this.quickActions,
    this.creditCardActions,
    this.rechargeActions,
    this.banners,
    this.isNameEmailExist,
  });

  final bool isFetching;
  final bool isFetchingCreditCards;
  final bool isFetchingRecharge;
  final bool isServerUnavailable;
  final String? errorMessage;
  final List<Data>? allQuickActions;
  final List<QuickActionCategory>? quickActions;
  // null = not yet fetched, [] = fetched & empty, [...] = has data
  final List<CreditCardItem>? creditCardActions;
  final List<Data>? rechargeActions;
  final Map<String, List<BannerModel>>? banners;
  final bool? isNameEmailExist;

  static const _sentinel = Object();

  HomeState copyWith({
    bool? isFetching,
    bool? isFetchingCreditCards,
    bool? isFetchingRecharge,
    bool? isServerUnavailable,
    Object? errorMessage = _sentinel,
    List<Data>? allQuickActions,
    Object? quickActions = _sentinel,
    Object? creditCardActions = _sentinel,
    Object? rechargeActions = _sentinel,
    Object? banners = _sentinel,
    Object? isNameEmailExist = _sentinel,
  }) {
    return HomeState(
      isFetching: isFetching ?? this.isFetching,
      isFetchingCreditCards:
          isFetchingCreditCards ?? this.isFetchingCreditCards,
      isFetchingRecharge: isFetchingRecharge ?? this.isFetchingRecharge,
      isServerUnavailable:
          isServerUnavailable ?? this.isServerUnavailable,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      allQuickActions: allQuickActions ?? this.allQuickActions,
      quickActions: quickActions == _sentinel
          ? this.quickActions
          : quickActions as List<QuickActionCategory>?,
      creditCardActions: creditCardActions == _sentinel
          ? this.creditCardActions
          : creditCardActions as List<CreditCardItem>?,
      rechargeActions: rechargeActions == _sentinel
          ? this.rechargeActions
          : rechargeActions as List<Data>?,
      banners: banners == _sentinel
          ? this.banners
          : banners as Map<String, List<BannerModel>>?,
      isNameEmailExist: isNameEmailExist == _sentinel
          ? this.isNameEmailExist
          : isNameEmailExist as bool?,
    );
  }
}
