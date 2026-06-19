import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/logger_service.dart';
import '../../home/models/banner_model.dart';
import '../models/latest_transaction.dart';
import '../models/mobile_prepaid_state.dart';
import '../models/my_number_info.dart';
import '../models/operator_info.dart';
import '../models/plan_item.dart';
import '../models/prepaid_transaction_status.dart';
import '../models/recharge_order_result.dart';
import '../repositories/mobile_prepaid_repository.dart';

final mobilePrepaidRepositoryProvider = Provider<MobilePrepaidRepository>(
  (ref) => MobilePrepaidRepository(),
);

final mobilePrepaidControllerProvider =
    StateNotifierProvider<MobilePrepaidController, MobilePrepaidState>(
  (ref) => MobilePrepaidController(
    repository: ref.watch(mobilePrepaidRepositoryProvider),
  ),
);

final latestRechargeTransactionsProvider =
    FutureProvider.autoDispose<List<LatestTransaction>>(
  (ref) async {
    final repo = ref.watch(mobilePrepaidRepositoryProvider);
    return repo.fetchLatestTransactions(service: 'recharge');
  },
);

final mobilePrepaidBannersProvider =
    FutureProvider.autoDispose<List<BannerModel>>(
  (ref) async {
    final repo = ref.watch(mobilePrepaidRepositoryProvider);
    return repo.fetchMobilePrepaidBanners(lang: 'en');
  },
);

final mobilePrepaidMyNumberProvider =
    FutureProvider.autoDispose.family<MyNumberInfo, String>(
  (ref, number) async {
    final repo = ref.watch(mobilePrepaidRepositoryProvider);
    return repo.fetchMyNumber(number: number);
  },
);

class MobilePrepaidController extends StateNotifier<MobilePrepaidState> {
  MobilePrepaidController({required MobilePrepaidRepository repository})
      : _repository = repository,
        super(const MobilePrepaidState());

  final MobilePrepaidRepository _repository;
  static const Duration _processingPollInterval = Duration(seconds: 2);

  Future<PrepaidTransactionStatus> _fetchRechargeStatusWithProcessingPoll({
    required String transactionId,
  }) async {
    PrepaidTransactionStatus verified =
        await _repository.fetchRechargeStatus(transactionId: transactionId);
    if (!verified.isProcessing) return verified;

    while (verified.isProcessing) {
      await Future.delayed(_processingPollInterval);
      verified =
          await _repository.fetchRechargeStatus(transactionId: transactionId);
    }
    return verified;
  }

  void reset() {
    state = const MobilePrepaidState();
  }

  void updatePlanSearch(String query) {
    state = state.copyWith(planSearchQuery: query);
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }

  void selectCategory(String category) {
    state = state.copyWith(
      selectedCategory: category,
      selectedPlan: null,
    );
  }

  void selectPlan(PlanItem plan) {
    state = state.copyWith(selectedPlan: plan);
  }

  void deselectPlan() {
    state = MobilePrepaidState(
      mobile: state.mobile,
      operatorInfo: state.operatorInfo,
      plansByCategory: state.plansByCategory,
      validityFilters: state.validityFilters,
      dataFilters: state.dataFilters,
      filterTags: state.filterTags,
      appliedFilters: state.appliedFilters,
      selectedCategory: state.selectedCategory,
      planSearchQuery: state.planSearchQuery,
      ecoinsRestrictionsPercent: state.ecoinsRestrictionsPercent,
    );
  }

  Future<void> fetchOperatorAndPlans(String mobileInput) async {
    await fetchOperatorAndPlansWithFilters(mobileInput);
  }

  Future<void> fetchOperatorAndPlansWithFilters(
    String mobileInput, {
    String search = '',
    List<String> filters = const [],
  }) async {
    final mobile = _sanitizeMobile(mobileInput);
    if (mobile.length < 10) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid 10 digit mobile number.',
      );
      return;
    }
    state = state.copyWith(
      isFetching: true,
      isRefreshingPlans: false,
      errorMessage: null,
      rechargeMessage: null,
      mobile: mobile,
      operatorInfo: null,
      plansByCategory: const {},
      validityFilters: const [],
      dataFilters: const [],
      filterTags: const [],
      appliedFilters: filters,
      selectedCategory: '',
      selectedPlan: null,
      planSearchQuery: search,
      ecoinsRestrictionsPercent: null,
    );
    try {
      final operatorInfo = await _repository.checkOperator(mobile: mobile);
      final result = await _repository.fetchPlans(
        mobile: mobile,
        operatorName: operatorInfo.operatorName,
        circleCode: operatorInfo.circleCode,
        search: search,
        filters: filters,
      );
      final categories = result.plansByCategory.keys.toList();
      state = state.copyWith(
        isFetching: false,
        isRefreshingPlans: false,
        operatorInfo: operatorInfo,
        plansByCategory: result.plansByCategory,
        validityFilters: result.validityFilters,
        dataFilters: result.dataFilters,
        filterTags: result.filterTags,
        ecoinsRestrictionsPercent: result.ecoinsRestrictionsPercent,
        appliedFilters: filters.isNotEmpty ? filters : const ['All'],
        selectedCategory: categories.isNotEmpty ? categories.first : '',
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load operator/plans',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetching: false,
        isRefreshingPlans: false,
        errorMessage: 'Failed to fetch plans. Please try again.',
      );
    }
  }

  Future<void> fetchPlansForSelection({
    required String mobileInput,
    required String operatorName,
    required String circleName,
    required String circleCode,
    String? iconUrl,
    String search = '',
    List<String> filters = const [],
  }) async {
    final mobile = _sanitizeMobile(mobileInput);
    if (mobile.length < 10) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid 10 digit mobile number.',
      );
      return;
    }
    final hasExistingPlans =
        state.operatorInfo != null && state.plansByCategory.isNotEmpty;
    state = state.copyWith(
      isFetching: !hasExistingPlans,
      isRefreshingPlans: hasExistingPlans,
      errorMessage: null,
      rechargeMessage: null,
      mobile: mobile,
      operatorInfo: OperatorInfo.fromSelection(
        operatorName: operatorName,
        circle: circleName,
        circleCode: circleCode,
        iconUrl: iconUrl,
      ),
      plansByCategory: hasExistingPlans ? null : const {},
      validityFilters: hasExistingPlans ? null : const [],
      dataFilters: hasExistingPlans ? null : const [],
      filterTags: hasExistingPlans ? null : const [],
      appliedFilters: filters,
      selectedCategory: hasExistingPlans ? state.selectedCategory : '',
      selectedPlan: null,
      planSearchQuery: search,
      ecoinsRestrictionsPercent:
          hasExistingPlans ? state.ecoinsRestrictionsPercent : null,
    );
    try {
      final result = await _repository.fetchPlans(
        mobile: mobile,
        operatorName: operatorName,
        circleCode: circleCode,
        search: search,
        filters: filters,
      );
      final categories = result.plansByCategory.keys.toList();
      state = state.copyWith(
        isFetching: false,
        isRefreshingPlans: false,
        plansByCategory: result.plansByCategory,
        validityFilters: result.validityFilters,
        dataFilters: result.dataFilters,
        filterTags: result.filterTags,
        ecoinsRestrictionsPercent: result.ecoinsRestrictionsPercent,
        appliedFilters: filters.isNotEmpty ? filters : const ['All'],
        selectedCategory: categories.isNotEmpty ? categories.first : '',
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load operator/plans',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetching: false,
        isRefreshingPlans: false,
        errorMessage: 'Failed to fetch plans. Please try again.',
      );
    }
  }

  Future<RechargeOrderResult?> createRechargeOrderWithPlan({
    required PlanItem plan,
    bool useWallet = false,
  }) async {
    if (state.operatorInfo == null || state.mobile.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please select an operator before proceeding.',
      );
      return null;
    }

    state = state.copyWith(
      isRecharging: true,
      errorMessage: null,
      rechargeMessage: null,
      rechargeStatus: null,
      rechargeTransactionId: null,
      rechargeDateTime: null,
      verifiedTransaction: null,
    );
    try {
      final order = await _repository.createRechargeOrder(
        mobile: state.mobile,
        amount: plan.amount,
        desc: plan.description,
        operatorName: state.operatorInfo!.operatorName,
        useWallet: useWallet,
      );
      state = state.copyWith(isRecharging: false);
      if (!order.isSuccess) {
        state = state.copyWith(
          errorMessage: order.message.isNotEmpty
              ? order.message
              : 'Failed to create order. Please try again.',
        );
        return null;
      }
      return order;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to create recharge order',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isRecharging: false,
        errorMessage: _errorMessageFromException(e),
      );
      return null;
    }
  }

  Future<void> verifyRechargeStatus({required String transactionRef}) async {
    state = state.copyWith(
      isRecharging: true,
      errorMessage: null,
      rechargeMessage: null,
      rechargeStatus: null,
      rechargeTransactionId: null,
      rechargeDateTime: null,
      verifiedTransaction: null,
    );
    try {
      final verified = await _fetchRechargeStatusWithProcessingPoll(
        transactionId: transactionRef,
      );
      final effectiveSuccess = verified.isSuccess;
      final isPendingOrProcessing = verified.isPending || verified.isProcessing;
      final effectiveMessage = verified.message.trim();
      state = state.copyWith(
        isRecharging: false,
        rechargeStatus: verified.status,
        rechargeTransactionId: verified.transactionId.isNotEmpty
            ? verified.transactionId
            : transactionRef,
        rechargeDateTime: verified.updatedAt,
        verifiedTransaction: verified,
        rechargeMessage: effectiveSuccess ? effectiveMessage : null,
        errorMessage: isPendingOrProcessing
            ? null
            : (effectiveSuccess
                ? null
                : (effectiveMessage.isEmpty ? null : effectiveMessage)),
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to verify recharge status',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isRecharging: false,
        errorMessage: _errorMessageFromException(e),
      );
    }
  }

  String _sanitizeMobile(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      // Common case: "+91" numbers coming from UI/contacts.
      if (digits.startsWith('91') && digits.length >= 12) {
        digits = digits.substring(digits.length - 10);
      } else {
        digits = digits.substring(digits.length - 10);
      }
    }
    return digits;
  }

  String _errorMessageFromException(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return 'Recharge failed. Please try again.';
    }
    if (raw.startsWith('Exception:')) {
      final message = raw.replaceFirst('Exception:', '').trim();
      if (message.isNotEmpty && !RegExp(r'^\d{3}$').hasMatch(message)) {
        return message;
      }
    }
    // If the message is just a status code, return a user-friendly fallback
    return 'Recharge failed. Please try again.';
  }
}
