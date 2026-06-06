import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/logger_service.dart';
import '../models/bill_pay_response_model.dart';
import '../models/biller_detail_model.dart';
import '../models/biller_detail_state.dart';
import '../models/biller_model.dart';
import '../models/recharge_status_result.dart';
import '../models/service_payment_order_result.dart';
import '../repositories/biller_repository.dart';

final billerDetailControllerProvider =
    StateNotifierProvider<BillerDetailController, BillerDetailState>(
  (ref) => BillerDetailController(
    repository: ref.watch(
      Provider<BillerRepository>((ref) => BillerRepository()),
    ),
  ),
);

class BillerDetailController extends StateNotifier<BillerDetailState> {
  BillerDetailController({required BillerRepository repository})
      : _repository = repository,
        super(const BillerDetailState());

  final BillerRepository _repository;
  static const Duration _processingPollInterval = Duration(seconds: 2);

  Future<RechargeStatusResult> _fetchStatusWithProcessingPoll({
    required String transactionRef,
  }) async {
    RechargeStatusResult status =
        await _repository.fetchRechargeStatus(transactionId: transactionRef);
    if (!status.isProcessing) return status;

    while (status.isProcessing) {
      await Future.delayed(_processingPollInterval);
      status =
          await _repository.fetchRechargeStatus(transactionId: transactionRef);
    }
    return status;
  }

  bool _isGasCylinderBillerName(String value) {
    final name = value.trim().toLowerCase();
    if (name.isEmpty) return false;
    return name.contains('gas') ||
        name.contains('lpg') ||
        name.contains('cylinder');
  }

  Map<String, String> _withBookGasServiceNameIfNeeded({
    required Biller biller,
    required BillerDetail detail,
    required Map<String, String> customerParams,
  }) {
    final isGas = _isGasCylinderBillerName(biller.billerName) ||
        _isGasCylinderBillerName(detail.billerCategoryName);
    if (!isGas) return customerParams;

    if (customerParams.containsKey('service_name')) return customerParams;
    return {
      ...customerParams,
      'service_name': 'Book Gas',
    };
  }

  void selectBiller(Biller biller) {
    state = const BillerDetailState().copyWith(selectedBiller: biller);
    _fetchBillerDetail(biller.billerId);
  }

  Future<void> _fetchBillerDetail(String billerId) async {
    state = state.copyWith(isFetchingDetail: true, errorMessage: null);
    try {
      final detail = await _repository.fetchBillerDetails(billerId: billerId);
      state = state.copyWith(
        isFetchingDetail: false,
        billerDetail: detail,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch biller detail',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetchingDetail: false,
        errorMessage: 'Failed to fetch provider details.',
      );
    }
  }

  Future<void> fetchBill({
    required Map<String, String> customerParams,
  }) async {
    final biller = state.selectedBiller;
    final detail = state.billerDetail;
    if (biller == null || detail == null) return;

    state = state.copyWith(
      isFetchingBill: true,
      errorMessage: null,
      billFetchNote: null,
      customerParamsInput: customerParams,
    );
    try {
      final paramsForApi = _withBookGasServiceNameIfNeeded(
        biller: biller,
        detail: detail,
        customerParams: customerParams,
      );
      final bill = await _repository.fetchBill(
        billerId: biller.billerId,
        customerParams: paramsForApi,
        planMdmRequirement: detail.planMdmRequirement.isNotEmpty
            ? detail.planMdmRequirement
            : 'NOT_SUPPORTED',
      );
      state = state.copyWith(
        isFetchingBill: false,
        billResponse: bill,
        errorMessage: null,
        billFetchNote: null,
      );
    } on BillerApiException catch (e, stackTrace) {
      logger.error(
        'Failed to fetch bill',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetchingBill: false,
        errorMessage: e.message,
        billFetchNote: (e.note ?? '').trim().isEmpty ? null : e.note!.trim(),
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch bill',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isFetchingBill: false,
        errorMessage: 'Something went wrong.Please try again.',
        billFetchNote: null,
      );
    }
  }

  // Deprecated: old API `api/bill/pay` is no longer used.
  // Use `createPayAllServicesOrder(...)` + `verifyPayAllServicesStatus(...)`.

  Future<ServicePaymentOrderResult?> createPayAllServicesOrder({
    required double amount,
    required String paymentType,
    double walletAmount = 0,
    double razorpayAmount = 0,
    bool isCreditCardFlow = false,
  }) async {
    final biller = state.selectedBiller;
    final detail = state.billerDetail;
    final bill = state.billResponse;
    final customerParams = state.customerParamsInput ?? {};
    if (biller == null || detail == null || bill == null) return null;

    state = state.copyWith(
      isPayingBill: true,
      payErrorMessage: null,
      payResponse: null,
    );
    try {
      final order = await _repository.createPayAllServicesOrder(
        billerId: biller.billerId,
        customerParams: customerParams,
        maskedIdentifier: _resolveMaskedIdentifier(
          detail.customerParams,
          customerParams,
          forceSecondIndex: isCreditCardFlow,
        ),
        amount: amount.toStringAsFixed(2),
        refId: bill.refId,
        paymentModes: detail.paymentModes
            .map((mode) => mode.paymentMode)
            .where((mode) => mode.trim().isNotEmpty)
            .toList(),
        billerName: biller.billerName,
        paymentType: paymentType,
        walletAmount: walletAmount,
        razorpayAmount: razorpayAmount,
      );
      state = state.copyWith(isPayingBill: false);
      if (!order.isSuccess) {
        state = state.copyWith(
          payErrorMessage: order.message.isNotEmpty
              ? order.message
              : 'Failed to create order. Please try again.',
        );
        return null;
      }
      return order;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to create pay-allservices order',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isPayingBill: false,
        payErrorMessage: 'Failed to create order. Please try again.',
      );
      return null;
    }
  }

  Future<RechargeStatusResult?> verifyPayAllServicesStatus({
    required String transactionRef,
  }) async {
    state = state.copyWith(isPayingBill: true, payErrorMessage: null);
    try {
      final status =
          await _fetchStatusWithProcessingPoll(transactionRef: transactionRef);
      state = state.copyWith(isPayingBill: false);
      return status;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to verify pay-allservices status',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isPayingBill: false,
        payErrorMessage: 'Unable to verify payment status. Please try again.',
      );
      return null;
    }
  }

  String _resolveMaskedIdentifier(
      List<BillerCustomerParam> params, Map<String, String> input,
      {bool forceSecondIndex = false}) {
    if (forceSecondIndex && params.length > 1) {
      final param = params[1];
      final value = input[param.paramName]?.trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    for (final param in params) {
      if (!param.visibility || param.optional) continue;
      final value = input[param.paramName]?.trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  void toggleFullDetails() {
    state = state.copyWith(showFullDetails: !state.showFullDetails);
  }

  void clearBill() {
    state = state.copyWith(
      billResponse: null,
      customerParamsInput: null,
      showFullDetails: false,
      isFetchingBill: false,
      payResponse: null,
      payErrorMessage: null,
      errorMessage: null,
    );
  }

  void reset() {
    state = const BillerDetailState();
  }

  String _resolvePayErrorMessage(BillPayResponse response) {
    final raw = response.message.trim();
    if (raw.isEmpty || RegExp(r'^\d{3}$').hasMatch(raw)) {
      return _fallbackMessageForCode(response.code);
    }
    return raw;
  }

  String _fallbackMessageForCode(int code) {
    switch (code) {
      case 400:
        return 'Payment request was invalid. Please verify the details.';
      case 401:
      case 403:
        return 'You are not authorized to complete this payment.';
      case 404:
        return 'Payment service is unavailable. Please try again shortly.';
      case 500:
        return 'Payment Failed due to server error. Please try again later.';
      case 502:
      case 503:
      case 504:
        return 'Payment service is down. Please try again later.';
      default:
        return 'Payment failed. Please try again.';
    }
  }
}
