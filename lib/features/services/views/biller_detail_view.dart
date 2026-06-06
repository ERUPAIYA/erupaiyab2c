// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:developer';

import 'package:e_rupaiya/features/mobile_prepaid/components/recharge_quick_action_card.dart';
import 'package:e_rupaiya/features/paymentgateway/razorpay_guard.dart';
import 'package:e_rupaiya/features/paymentgateway/razorpay_service.dart';
import 'package:e_rupaiya/features/services/models/biller_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../services/permission_service.dart';
import '../../../utils/date_format_helper.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/bill_sample_terms_card.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/date_picker_field.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/param_dropdown_field.dart';
import '../../../widgets/payment_success_flow.dart';
import '../../../widgets/search_textfield.dart';
import '../../mobile_prepaid/components/payment_bottom_sheet.dart';
import '../../mobile_prepaid/controllers/contacts_cache_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/credit_card_pay_now/credit_card_pay_now_section.dart';
import '../components/piped_gas/piped_gas_bill_section.dart';
import '../components/service_error_banner.dart';
import '../controllers/biller_detail_controller.dart';
import '../models/bill_response_model.dart';
import '../models/biller_detail_args.dart';
import '../models/biller_detail_model.dart';

class BillerDetailView extends HookConsumerWidget {
  const BillerDetailView({super.key, this.args});

  final BillerDetailArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(billerDetailControllerProvider);
    final controller = ref.read(billerDetailControllerProvider.notifier);
    final biller = detailState.selectedBiller ?? args?.biller;
    final detail = detailState.billerDetail;
    final bill = detailState.billResponse;
    final profileState = ref.watch(profileControllerProvider);
    final customerParamsInput = detailState.customerParamsInput ?? {};
    final inputControllers =
        useMemoized(() => <String, TextEditingController>{});
    final billAmountController = useTextEditingController();
    final selectedAmountType = useState(_PaymentAmountType.totalOutstanding);
    final permissionService = useMemoized(() => const PermissionService());
    final contactsController =
        ref.read(contactsCacheControllerProvider.notifier);
    final isCreditCardFlow = args?.isCreditCard ?? false;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final mobilePrefill = args?.mobileNumber?.trim();
    final last4Prefill = args?.cardLast4?.trim();
    final autoFetchBill = args?.autoFetchBill ?? false;
    final autoOpenPaymentSheet = args?.autoOpenPaymentSheet ?? false;
    final loggedInMobile = profileState.profile?.mobile.trim();
    final isGasCylinder = useMemoized(
      () => _isGasCylinderCategory(args?.paymentType),
      [args?.paymentType],
    );
    final isPipedGas = useMemoized(
      () => _isPipedGasCategory(args?.paymentType),
      [args?.paymentType],
    );
    final isElectricity = useMemoized(
      () => (args?.paymentType ?? '').toLowerCase().contains('electric'),
      [args?.paymentType],
    );
    final showBillSample = useState(false);
    final fieldErrors = useState<Map<String, String?>>({});
    final gasPolicyMessage = useState<String?>(null);
    final pipedGasErrorMessage = useState<String?>(null);
    final creditCardErrorMessage = useState<String?>(null);
    final didAutoFetchBill = useRef(false);
    final isSubscription = _isSubscriptionFlow(
      paymentType: args?.paymentType,
      detailCategory: detail?.billerCategoryName,
      billerName: biller?.billerName,
    );
    final showSubscriptionSummary = isSubscription && bill != null;

    Map<String, String?> gasCylinderInlineErrors(BillerDetail detail) {
      final errors = <String, String?>{};
      final visible = detail.customerParams.where((p) => p.visibility).toList();
      if (visible.isEmpty) return errors;

      for (final p in visible) {
        final key = p.paramName.toLowerCase();
        final isLpg =
            key.contains('lpg') || key.contains('gas') || key.contains('id');
        final isContact = key.contains('contact') ||
            key.contains('mobile') ||
            key.contains('registered');
        if (isLpg || isContact) {
          errors[p.paramName] =
              'Please enter either Registered Contact Number or LPG ID.';
        }
      }

      // If we failed to match, fall back to marking all visible fields.
      if (errors.isEmpty) {
        for (final p in visible) {
          errors[p.paramName] =
              'Please enter either Registered Contact Number or LPG ID.';
        }
      }
      return errors;
    }

    Map<String, String?> mapFetchBillValidationToFields({
      required String message,
      required BillerDetail? detail,
      required bool isGasCylinder,
    }) {
      final trimmed = message.trim();
      if (trimmed.isEmpty || detail == null) return const {};

      String normalize(String input) =>
          input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      final normalizedMessage = normalize(trimmed);
      if (normalizedMessage.isEmpty) return const {};

      if (isGasCylinder &&
          (normalizedMessage.contains('lpg') ||
              normalizedMessage.contains('registeredcontact') ||
              normalizedMessage.contains('registeredmobil'))) {
        return gasCylinderInlineErrors(detail);
      }

      final errors = <String, String?>{};
      for (final param in detail.customerParams.where((p) => p.visibility)) {
        final name = param.paramName.trim();
        if (name.isEmpty) continue;
        final normalizedName = normalize(name);
        if (normalizedName.isEmpty) continue;
        if (normalizedMessage.contains(normalizedName)) {
          errors[param.paramName] = trimmed;
        }
      }
      return errors;
    }

    useEffect(() {
      final argBiller = args?.biller;
      if (argBiller != null &&
          detailState.selectedBiller?.billerId != argBiller.billerId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          controller.selectBiller(argBiller);
        });
      }
      return null;
    }, [args?.biller.billerId]);

    // Fetch profile for gas cylinder flow mobile prefill (if needed).
    useEffect(() {
      if (!isGasCylinder) return null;
      Future.microtask(() async {
        if (loggedInMobile != null && loggedInMobile.isNotEmpty) return;
        if (profileState.isFetching) return;
        await ref.read(profileControllerProvider.notifier).fetchProfile();
      });
      return null;
    }, [isGasCylinder, loggedInMobile, profileState.isFetching]);

    // Prefetch contacts early so opening the picker is instant.
    useEffect(() {
      Future.microtask(() async {
        final granted = await permissionService.hasContactsPermission();
        if (!granted) return;
        await contactsController.fetchIfNeeded();
      });
      return null;
    }, const []);

    ref.listen<BillerDetailState>(billerDetailControllerProvider,
        (previous, next) {
      final message = next.errorMessage;
      if (message != null && message.isNotEmpty) {
        if (previous?.errorMessage != message) {
          // Inline validation errors for fetch-bill form (instead of snackbars).
          final isOnInputForm =
              next.billResponse == null && next.billerDetail != null;
          if (isOnInputForm) {
            if (isGasCylinder && _isGasBookingPolicyMessage(message)) {
              gasPolicyMessage.value = message;
              fieldErrors.value = {};
              return;
            }
            if (isPipedGas) {
              pipedGasErrorMessage.value = message;
              return;
            }
            if (isCreditCardFlow) {
              creditCardErrorMessage.value = message;
              return;
            }
            if (gasPolicyMessage.value != null) {
              gasPolicyMessage.value = null;
            }
            final inline = mapFetchBillValidationToFields(
              message: message,
              detail: next.billerDetail,
              isGasCylinder: isGasCylinder,
            );
            if (inline.isNotEmpty) {
              fieldErrors.value = {
                ...fieldErrors.value,
                ...inline,
              };

              return;
            }

            // Gas fetch-bill failures should be rendered inline (red cards)
            // beneath the form; never show a popup for gas.
            if (isGasCylinder) {
              return;
            }
          }
          // For gas/piped-gas/credit-card, avoid popups in any state.
          if (isGasCylinder) {
            AppSnackbar.show(
              message,
              behavior: SnackBarBehavior.fixed,
            );
            return;
          }
          if (isCreditCardFlow) {
            creditCardErrorMessage.value = message;
            return;
          }
          if (isOnInputForm) {
            // Gas bill fetch failures should be shown inline (red cards)
            // instead of a dialog.
            if (isGasCylinder) {
              return;
            }
            if (isPipedGas) {
              // Show inline banner for piped gas instead of popup.
              pipedGasErrorMessage.value = message;
              return;
            }
            // Fetch-bill failures should be shown as a friendly popup instead
            // of a snackbar since we support many billers/services.
            KDialog.instance.openDialog(
              barrierDismissible: true,
              dialog: _BillFetchFailedDialog(
                message: message,
                onContinue: () {
                  Navigator.of(context).pop();
                  controller.clearBill();
                },
              ),
            );
          } else {
            AppSnackbar.show(
              message,
              behavior: SnackBarBehavior.fixed,
            );
          }
        }
      }
    });

    final totalOutstanding =
        bill == null ? null : _resolveTotalOutstanding(bill);
    final minimumDue = bill == null ? null : _resolveMinimumDue(bill);
    final isFastTag = (() {
      bool hasFastTag(String? v) =>
          (v ?? '').toLowerCase().replaceAll('-', '').contains('fastag') ||
          (v ?? '').toLowerCase().replaceAll('-', '').contains('fasttag');
      return hasFastTag(detail?.billerCategoryName) ||
          hasFastTag(biller?.billerName);
    })();

    // Set bill amount when fetched
    useEffect(() {
      if (bill != null) {
        selectedAmountType.value = _PaymentAmountType.totalOutstanding;
        final amount = _resolveDateBasedAmount(bill);
        billAmountController.text = isFastTag
            ? _formatAmountForInput(amount)
            : amount.toStringAsFixed(2);
      }
      return null;
    }, [bill]);

    useEffect(() {
      if (bill != null || detailState.errorMessage == null) {
        if (gasPolicyMessage.value != null) {
          gasPolicyMessage.value = null;
        }
        if (pipedGasErrorMessage.value != null) {
          pipedGasErrorMessage.value = null;
        }
        if (creditCardErrorMessage.value != null) {
          creditCardErrorMessage.value = null;
        }
      }
      return null;
    }, [bill, detailState.errorMessage]);

    // Create controllers for each customer param
    if (detail != null) {
      for (final param in detail.customerParams) {
        if (param.visibility) {
          log(
            'Biller param: name=${param.paramName} '
            'type=${param.dataType} '
            'min=${param.minLength} '
            'max=${param.maxLength}',
          );
          inputControllers.putIfAbsent(
            param.paramName,
            () => TextEditingController(),
          );
          final tc = inputControllers[param.paramName];
          if (tc != null && tc.text.isEmpty) {
            final isMobileField = _isMobileParam(param.paramName) ||
                (isCreditCardFlow &&
                    param.dataType.toUpperCase() == 'NUMERIC' &&
                    param.maxLength == 10 &&
                    !_isLastFourParam(param.paramName));
            final isLastFourField = _isLastFourParam(param.paramName) ||
                (isCreditCardFlow &&
                    param.dataType.toUpperCase() == 'NUMERIC' &&
                    param.maxLength == 4);
            final isGasLockedMobile = isGasCylinder && isMobileField;
            log(
              'Prefill check: name=${param.paramName} '
              'mobile=$mobilePrefill last4=$last4Prefill '
              'isMobile=$isMobileField isLast4=$isLastFourField',
            );
            if (isGasLockedMobile &&
                loggedInMobile != null &&
                loggedInMobile.isNotEmpty) {
              tc.text = _sanitizePhone(loggedInMobile);
              log('Prefilled gas mobile for ${param.paramName}: ${tc.text}');
            } else if (mobilePrefill != null &&
                mobilePrefill.isNotEmpty &&
                !isLastFourField &&
                (isMobileField ||
                    _isIdentifierParam(param.paramName, param.dataType))) {
              tc.text =
                  isMobileField ? _sanitizePhone(mobilePrefill) : mobilePrefill;
              log('Prefilled identifier for ${param.paramName}: ${tc.text}');
            } else if (last4Prefill != null &&
                last4Prefill.isNotEmpty &&
                isLastFourField) {
              final digits = last4Prefill.replaceAll(RegExp(r'[^0-9]'), '');
              tc.text = digits.length > 4
                  ? digits.substring(digits.length - 4)
                  : digits;
              log(
                'Prefilled last4 for ${param.paramName}: ${tc.text}',
              );
            }
          }
        }
      }
    }

    useEffect(() {
      return () {
        for (final controller in inputControllers.values) {
          controller.dispose();
        }
      };
    }, const []);

    useEffect(() {
      if (detail == null) return null;
      for (final param in detail.customerParams) {
        if (!param.visibility) continue;
        final tc = inputControllers[param.paramName];
        if (tc == null || tc.text.isNotEmpty) continue;
        final isMobileField = _isMobileParam(param.paramName) ||
            (isCreditCardFlow &&
                param.dataType.toUpperCase() == 'NUMERIC' &&
                param.maxLength == 10 &&
                !_isLastFourParam(param.paramName));
        final isLastFourField = _isLastFourParam(param.paramName) ||
            (isCreditCardFlow &&
                param.dataType.toUpperCase() == 'NUMERIC' &&
                param.maxLength == 4);
        final isGasLockedMobile = isGasCylinder && isMobileField;
        if (isGasLockedMobile &&
            loggedInMobile != null &&
            loggedInMobile.isNotEmpty) {
          tc.text = _sanitizePhone(loggedInMobile);
        } else if (mobilePrefill != null &&
            mobilePrefill.isNotEmpty &&
            !isLastFourField &&
            isMobileField) {
          tc.text = _sanitizePhone(mobilePrefill);
        } else if (last4Prefill != null &&
            last4Prefill.isNotEmpty &&
            isLastFourField) {
          final digits = last4Prefill.replaceAll(RegExp(r'[^0-9]'), '');
          tc.text =
              digits.length > 4 ? digits.substring(digits.length - 4) : digits;
        }
      }
      return null;
    }, [detail, mobilePrefill, last4Prefill, loggedInMobile, isGasCylinder]);

    // Auto-fetch bill & open payment sheet for "Pay Now" from recent cards.
    useEffect(() {
      // Reset per biller/flag so navigating to another provider can auto-fetch once.
      didAutoFetchBill.value = false;
      return null;
    }, [autoFetchBill, biller?.billerId]);

    useEffect(() {
      if (!autoFetchBill) return null;
      if (detail == null || biller == null) return null;
      if (bill != null) return null;
      if (didAutoFetchBill.value) return null;
      if (detailState.isFetchingBill || detailState.isFetchingDetail)
        return null;

      didAutoFetchBill.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        final params = <String, String>{};
        for (final p in detail.customerParams.where((p) => p.visibility)) {
          final tc = inputControllers[p.paramName];
          final value = tc?.text.trim() ?? '';
          if (value.isNotEmpty) {
            params[p.paramName] = value;
          }
        }
        if (params.isEmpty) return;
        await controller.fetchBill(customerParams: params);
      });
      return null;
    }, [
      autoFetchBill,
      biller?.billerId,
      detail,
      bill,
      detailState.isFetchingBill,
      detailState.isFetchingDetail,
    ]);

    useEffect(() {
      if (!autoOpenPaymentSheet) return null;
      if (bill == null) return null;
      if (detailState.isFetchingBill) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final amountToPay = _resolveDateBasedAmount(bill);
        _showPaymentSheet(
          context,
          amountToPay,
          isCreditCardFlow: isCreditCardFlow,
          paymentTypeOverride: args?.paymentType,
          ecoinsRestrictionsPercent: bill.ecoinsRestrictionsPercent,
        );
      });
      return null;
    }, [autoOpenPaymentSheet, bill, detailState.isFetchingBill]);

    return PopScope(
      canPop: detailState.billResponse == null,
      onPopInvoked: (didPop) {
        if (didPop) return;
        controller.clearBill();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: MyAppBar(
            title: (isCreditCardFlow && detailState.billResponse != null)
                ? 'Pay Now'
                : 'Fetch Your Provider',
            showHelp: true,
            onBack: () {
              if (detailState.billResponse != null) {
                controller.clearBill();
              } else {
                controller.reset();
                context.pop();
              }
            },
            onHelp: () {},
          ),
        ),
        body: biller == null
            ? const Center(child: Text('No provider selected'))
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SimpleQuickActionCard(
                            title: biller.billerName,
                            subtitle: '',
                            leadingImageUrl: biller.iconUrl,
                            actionLabel: 'Change',
                            onAction: () {
                              controller.reset();
                              context.pop();
                            },
                          ),
                          // // Provider card
                          // QuickActionCard(
                          //   title: biller.billerName,
                          //   subtitle: '',
                          //   amount: 'Change',
                          //   buttonLabel: '',
                          //   imageUrl: biller.iconUrl,
                          //   showTail: true,
                          //   showLeadingImage: true,
                          //   onTap: () {
                          //     controller.reset();
                          //     context.pop();
                          //   },
                          // ),
                          const SizedBox(height: 24),

                          // --- Loading detail ---
                          if (detailState.isFetchingDetail)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: SpinKitCircle(
                                  color: AppColors.primary,
                                  size: 48,
                                ),
                              ),
                            )

                          // --- Input form (no bill yet) ---
                          else if (detail != null && bill == null) ...[
                            if (isGasCylinder) ...[
                              BillSampleTermsCard(
                                isExpanded: showBillSample.value,
                                onToggle: () => showBillSample.value =
                                    !showBillSample.value,
                                billImageUrl: detail.billImage,
                                termsText: detail.billTermsCond,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (isPipedGas &&
                                pipedGasErrorMessage.value != null &&
                                pipedGasErrorMessage.value!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ServiceErrorBanner(
                                  message: pipedGasErrorMessage.value!,
                                ),
                              ),
                            if (isSubscription) ...[
                              const _InfoNoteCard(
                                text:
                                    'Subscription starts immediately upon payment. Please check the phone number before proceeding.',
                                showLogo: false,
                              ),
                              const SizedBox(height: 16),
                            ],
                            ...detail.customerParams
                                .where((p) => p.visibility)
                                .map((param) {
                              final tc = inputControllers[param.paramName];
                              final isLastFour =
                                  _isLastFourParam(param.paramName);
                              final isMobile = _isMobileParam(param.paramName);
                              final isGasLockedMobile =
                                  isGasCylinder && isMobile;
                              final isDate =
                                  DateFormatHelper.isDateParam(param.paramName);
                              final dateFormat = isDate
                                  ? DateFormatHelper.extractFormat(
                                      param.paramName)
                                  : null;
                              final errorText =
                                  fieldErrors.value[param.paramName];
                              final label = isGasLockedMobile
                                  ? 'Mobile Number'
                                  : param.paramName;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            label,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        if (param.optional)
                                          Text(
                                            ' (Optional)',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.textPrimary
                                                      .withOpacity(0.5),
                                                ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (isDate)
                                      DatePickerField(
                                        controller: tc!,
                                        dateFormat: dateFormat!,
                                        errorText: errorText,
                                        onDatePicked: () {
                                          if (fieldErrors.value
                                              .containsKey(param.paramName)) {
                                            fieldErrors.value =
                                                Map.from(fieldErrors.value)
                                                  ..remove(param.paramName);
                                          }
                                          if (gasPolicyMessage.value != null) {
                                            gasPolicyMessage.value = null;
                                          }
                                        },
                                      )
                                    else if (param.hasDropdown)
                                      ParamDropdownField(
                                        controller: tc!,
                                        items: param.values,
                                        hintText: 'Select ${param.paramName}',
                                        errorText: errorText,
                                        onChanged: (_) {
                                          if (fieldErrors.value
                                              .containsKey(param.paramName)) {
                                            fieldErrors.value =
                                                Map.from(fieldErrors.value)
                                                  ..remove(param.paramName);
                                          }
                                          if (gasPolicyMessage.value != null) {
                                            gasPolicyMessage.value = null;
                                          }
                                        },
                                      )
                                    else
                                      TextField(
                                        controller: tc,
                                        readOnly: isGasLockedMobile,
                                        enableInteractiveSelection:
                                            !isGasLockedMobile,
                                        showCursor:
                                            isGasLockedMobile ? false : null,
                                        onTap: isGasLockedMobile
                                            ? () =>
                                                FocusScope.of(context).unfocus()
                                            : null,
                                        keyboardType:
                                            param.dataType == 'NUMERIC'
                                                ? TextInputType.number
                                                : TextInputType.text,
                                        maxLength:
                                            isLastFour ? 4 : param.maxLength,
                                        onChanged: (_) {
                                          if (fieldErrors.value
                                              .containsKey(param.paramName)) {
                                            fieldErrors.value =
                                                Map.from(fieldErrors.value)
                                                  ..remove(param.paramName);
                                          }
                                          if (gasPolicyMessage.value != null) {
                                            gasPolicyMessage.value = null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          hintText: _buildParamHint(param),
                                          errorText: errorText,
                                          counterText: '',
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          prefixIcon: isLastFour
                                              ? _MaskedPrefix()
                                              : null,
                                          suffixIcon: (isMobile &&
                                                  !isGasLockedMobile)
                                              ? IconButton(
                                                  icon: const Icon(
                                                    Icons.contact_phone,
                                                    color: AppColors.primary,
                                                  ),
                                                  onPressed: () async {
                                                    final picked =
                                                        await _pickContactNumber(
                                                      context,
                                                      permissionService,
                                                      contactsController:
                                                          contactsController,
                                                    );
                                                    if (picked != null &&
                                                        picked.isNotEmpty) {
                                                      tc?.text = picked;
                                                    }
                                                    if (gasPolicyMessage
                                                            .value !=
                                                        null) {
                                                      gasPolicyMessage.value =
                                                          null;
                                                    }
                                                  },
                                                )
                                              : null,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: AppColors.lightBorder),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: AppColors.lightBorder),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: AppColors.primary),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: Colors.red),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: Colors.red),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 16),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            if (isCreditCardFlow &&
                                creditCardErrorMessage.value != null &&
                                creditCardErrorMessage.value!
                                    .trim()
                                    .isNotEmpty) ...[
                              ServiceErrorBanner(
                                message: creditCardErrorMessage.value!,
                                onClose: () =>
                                    creditCardErrorMessage.value = null,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (gasPolicyMessage.value != null) ...[
                              _GasPolicyBanner(
                                message: gasPolicyMessage.value!,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (isGasCylinder &&
                                (detailState.errorMessage ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                              _GasErrorBanner(
                                message: detailState.errorMessage!.trim(),
                              ),
                              const SizedBox(height: 12),
                              if ((detailState.billFetchNote ?? '')
                                  .trim()
                                  .isNotEmpty) ...[
                                _GasErrorBanner(
                                  message: detailState.billFetchNote!.trim(),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ]

                          // --- Subscription summary ---
                          else if (detail != null &&
                              showSubscriptionSummary) ...[
                            _SubscriptionSummaryCard(
                              mobileNumber: _resolveSubscriptionMobile(
                                  customerParamsInput),
                              plan:
                                  _resolveSubscriptionPlan(customerParamsInput),
                              amount: _resolveSubscriptionAmount(
                                customerParamsInput,
                                billAmountController.text,
                                bill,
                              ),
                              onChange: () {
                                controller.clearBill();
                              },
                            ),
                            const SizedBox(height: 12),
                          ]

                          // --- Compact bill view ---
                          else if (bill != null &&
                              !detailState.showFullDetails) ...[
                            _CompactBillSection(
                              bill: bill,
                              customerParams: customerParamsInput,
                              billAmountController: billAmountController,
                              onToggle: controller.toggleFullDetails,
                              selectedAmountType: selectedAmountType.value,
                              onAmountTypeChanged: (next) {
                                selectedAmountType.value = next;
                                if (next ==
                                    _PaymentAmountType.totalOutstanding) {
                                  final amount = _resolveDateBasedAmount(bill);
                                  billAmountController.text = isFastTag
                                      ? _formatAmountForInput(amount)
                                      : amount.toStringAsFixed(2);
                                } else if (next ==
                                    _PaymentAmountType.minimumDue) {
                                  final amount = minimumDue ??
                                      totalOutstanding ??
                                      bill.amountInRupees;
                                  billAmountController.text = isFastTag
                                      ? _formatAmountForInput(amount)
                                      : amount.toStringAsFixed(2);
                                }
                              },
                              totalOutstanding: totalOutstanding,
                              minimumDue: minimumDue,
                              isCreditCardFlow: isCreditCardFlow,
                              isPipedGas: isPipedGas,
                              allowCustomAmount: isFastTag,
                              isElectricity: isElectricity,
                              showFullDetailsInline: isFastTag,
                              hideAmountDisplayCard: isFastTag,
                            ),
                          ]

                          // --- Full details view ---
                          else if (bill != null &&
                              detailState.showFullDetails) ...[
                            _FullDetailsSection(
                              bill: bill,
                              customerParams: customerParamsInput,
                              onToggle: controller.toggleFullDetails,
                            ),
                          ],

                          if (detail != null &&
                              (bill == null || showSubscriptionSummary)) ...[
                            const SizedBox(height: 12),
                            const _InfoNoteCard(
                              text:
                                  'By proceeding further, you allow E-Rupaiya to store your bill details, fetch current and future bills, and send you reminders.',
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Loading bill spinner
                          if (detailState.isFetchingBill)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: SpinKitCircle(
                                  color: AppColors.primary,
                                  size: 48,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom button
                  if (detail != null &&
                      !detailState.isFetchingDetail &&
                      !detailState.isFetchingBill)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: billAmountController,
                            builder: (context, value, _) {
                              final payLabel = showSubscriptionSummary
                                  ? 'Pay Now'
                                  : (bill != null
                                      ? (isCreditCardFlow
                                          ? 'Proceed'
                                          : 'Proceed to Pay')
                                      : 'CONFIRM');
                              final enteredAmount =
                                  _parseEnteredAmount(value.text);
                              final subscriptionAmount = showSubscriptionSummary
                                  ? _resolveSubscriptionAmount(
                                      customerParamsInput,
                                      value.text,
                                      bill,
                                    )
                                  : null;
                              final shouldDisablePay = showSubscriptionSummary
                                  ? (subscriptionAmount ?? 0) <= 0
                                  : (bill != null &&
                                      ((enteredAmount ?? 0) <= 0 ||
                                          (isPipedGas &&
                                              ((enteredAmount ?? 0) <
                                                      PipedGasBillSection
                                                          .minAmount ||
                                                  (enteredAmount ?? 0) >
                                                      PipedGasBillSection
                                                          .maxAmount))));
                              return CustomElevatedButton(
                                onPressed: shouldDisablePay
                                    ? null
                                    : () async {
                                        if (showSubscriptionSummary) {
                                          final amountToPay =
                                              subscriptionAmount ?? 0;
                                          final mobile =
                                              _resolveSubscriptionMobile(
                                            customerParamsInput,
                                          );
                                          final name = (biller.billerName ?? '')
                                                  .trim()
                                                  .isNotEmpty
                                              ? biller.billerName.trim()
                                              : 'Subscription';
                                          if (!RazorpayGuard.ensureNotPaused(
                                            ref,
                                          )) {
                                            return;
                                          }
                                          final paymentType =
                                              (args?.paymentType ?? '')
                                                      .trim()
                                                      .isNotEmpty
                                                  ? args!.paymentType!.trim()
                                                  : 'Subscription';
                                          final order = await controller
                                              .createPayAllServicesOrder(
                                            amount: amountToPay,
                                            paymentType: paymentType,
                                            walletAmount: 0,
                                            razorpayAmount: amountToPay,
                                            isCreditCardFlow: isCreditCardFlow,
                                          );
                                          if (!context.mounted) return;
                                          if (order == null ||
                                              order.orderId.isEmpty ||
                                              order.key.isEmpty ||
                                              order.transactionRef.isEmpty) {
                                            AppSnackbar.show(
                                              ref
                                                      .read(
                                                        billerDetailControllerProvider,
                                                      )
                                                      .payErrorMessage ??
                                                  'Unable to start payment. Please try again.',
                                              type: AppSnackbarType.error,
                                            );
                                            return;
                                          }

                                          Future<void> verifyAndShowResult({
                                            required String fallbackMessage,
                                          }) async {
                                            if (!context.mounted) return;
                                            showDialog<void>(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (dialogContext) {
                                                return const PopScope(
                                                  canPop: false,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                );
                                              },
                                            );
                                            final status = await controller
                                                .verifyPayAllServicesStatus(
                                              transactionRef:
                                                  order.transactionRef,
                                            );
                                            if (context.mounted) {
                                              Navigator.of(
                                                context,
                                                rootNavigator: true,
                                              ).pop();
                                            }
                                            if (!context.mounted) return;
                                            final normalized = (status?.status
                                                    .trim()
                                                    .toUpperCase() ??
                                                '');
                                            final isSuccess =
                                                normalized == 'SUCCESS';
                                            final isPending =
                                                normalized == 'PENDING' ||
                                                    normalized == 'PROCESSING';
                                            final title = isSuccess
                                                ? 'Payment Successful!'
                                                : (isPending
                                                    ? 'Payment Pending'
                                                    : 'Payment Failed!');
                                            final subtitle = status?.message
                                                        .trim()
                                                        .isNotEmpty ==
                                                    true
                                                ? status!.message
                                                : fallbackMessage;
                                            final txId = status?.transactionId
                                                        .trim()
                                                        .isNotEmpty ==
                                                    true
                                                ? status!.transactionId.trim()
                                                : order.transactionRef;

                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    PaymentResultScreen(
                                                  title: title,
                                                  subtitle: subtitle,
                                                  details: [
                                                    PaymentDetailItem(
                                                      label: 'Amount',
                                                      value:
                                                          '₹ ${amountToPay.toStringAsFixed(2)}',
                                                    ),
                                                    PaymentDetailItem(
                                                      label: 'To',
                                                      value: name,
                                                    ),
                                                    PaymentDetailItem(
                                                      label: 'Transaction ID',
                                                      value: '#$txId',
                                                      copyable: true,
                                                    ),
                                                  ],
                                                  continueText: 'Continue',
                                                  onContinue: (c) =>
                                                      Navigator.of(c).pop(),
                                                  showFailureActions:
                                                      !isSuccess,
                                                  showBackButton: !isSuccess,
                                                  statusIcon: isSuccess
                                                      ? Icons.check
                                                      : (isPending
                                                          ? Icons.hourglass_top
                                                          : Icons.close),
                                                  statusIconColor: Colors.white,
                                                  statusIconBorderColor:
                                                      Colors.white,
                                                  headerGradientColors:
                                                      isSuccess
                                                          ? const [
                                                              Color(
                                                                0xFF0D5C32,
                                                              ),
                                                              Color(
                                                                0xFF0E7340,
                                                              )
                                                            ]
                                                          : (isPending
                                                              ? const [
                                                                  Color(
                                                                    0xFFF59E0B,
                                                                  ),
                                                                  Color(
                                                                    0xFFD97706,
                                                                  )
                                                                ]
                                                              : const [
                                                                  Color(
                                                                    0xFFB91C1C,
                                                                  ),
                                                                  Color(
                                                                    0xFFDC2626,
                                                                  )
                                                                ]),
                                                ),
                                              ),
                                            );
                                          }

                                          await RazorpayService.instance
                                              .openCheckout(
                                            amount: amountToPay,
                                            name: name,
                                            description:
                                                'Subscription bill payment',
                                            orderId: order.orderId,
                                            keyOverride: order.key,
                                            prefill: {
                                              if (mobile.isNotEmpty)
                                                'contact': mobile,
                                            },
                                            onSuccess: (_) async {
                                              await verifyAndShowResult(
                                                fallbackMessage:
                                                    'Your payment was completed successfully.',
                                              );
                                            },
                                            onFailure: (message) async {
                                              await verifyAndShowResult(
                                                fallbackMessage: message.isEmpty
                                                    ? 'Payment failed. Please try again.'
                                                    : message,
                                              );
                                            },
                                            onExternalWallet: (_) async {
                                              await verifyAndShowResult(
                                                fallbackMessage:
                                                    'We are verifying your payment. Please wait a moment.',
                                              );
                                            },
                                          );
                                          return;
                                        }
                                        if (bill == null) {
                                          // Validate all visible params
                                          final visibleParams = detail
                                              .customerParams
                                              .where((p) => p.visibility)
                                              .toList();
                                          if (visibleParams.isEmpty) return;

                                          final errors = <String, String?>{};
                                          final values = <String, String>{};
                                          for (final param in visibleParams) {
                                            final value = inputControllers[
                                                        param.paramName]
                                                    ?.text
                                                    .trim() ??
                                                '';
                                            final error =
                                                _validateParam(param, value);
                                            if (error != null) {
                                              errors[param.paramName] = error;
                                            } else if (value.isNotEmpty) {
                                              values[param.paramName] = value;
                                            }
                                          }

                                          if (errors.isNotEmpty) {
                                            fieldErrors.value = errors;
                                            return;
                                          }
                                          fieldErrors.value = {};

                                          if (isGasCylinder &&
                                              visibleParams.isNotEmpty &&
                                              values.isEmpty) {
                                            fieldErrors.value =
                                                gasCylinderInlineErrors(detail);
                                            return;
                                          }

                                          if (values.isNotEmpty) {
                                            if (gasPolicyMessage.value !=
                                                null) {
                                              gasPolicyMessage.value = null;
                                            }
                                            controller.fetchBill(
                                              customerParams: values,
                                            );
                                          }
                                        } else if (!detailState
                                            .showFullDetails) {
                                          // Open payment bottom sheet (details expansion is via the
                                          // down-arrow in the bill card, not the pay CTA).
                                          final amountToPay = enteredAmount ??
                                              bill.amountInRupees;
                                          _showPaymentSheet(
                                            context,
                                            amountToPay,
                                            isCreditCardFlow: isCreditCardFlow,
                                            paymentTypeOverride:
                                                args?.paymentType,
                                            ecoinsRestrictionsPercent:
                                                bill.ecoinsRestrictionsPercent,
                                          );
                                        } else {
                                          // Open payment bottom sheet
                                          final amountToPay = enteredAmount ??
                                              bill.amountInRupees;
                                          _showPaymentSheet(
                                            context,
                                            amountToPay,
                                            isCreditCardFlow: isCreditCardFlow,
                                            paymentTypeOverride:
                                                args?.paymentType,
                                            ecoinsRestrictionsPercent:
                                                bill.ecoinsRestrictionsPercent,
                                          );
                                        }
                                      },
                                label: payLabel,
                                showArrow: false,
                                uppercaseLabel: false,
                                height: 38.h,
                              );
                            },
                          ),
                          // if (bill == null) ...[
                          //   const SizedBox(height: 10),
                          //   Row(
                          //     mainAxisAlignment: MainAxisAlignment.center,
                          //     children: [
                          //       Text(
                          //         'Powered by',
                          //         style: Theme.of(context)
                          //             .textTheme
                          //             .bodySmall
                          //             ?.copyWith(
                          //               color: AppColors.textPrimary
                          //                   .withOpacity(0.6),
                          //               fontWeight: FontWeight.w600,
                          //             ),
                          //       ),
                          //       const SizedBox(width: 8),
                          //       Image.asset(
                          //         FileConstants.bharatConnectColor,
                          //         height: 20,
                          //         fit: BoxFit.contain,
                          //       ),
                          //     ],
                          //   ),
                          // ],
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  void _showPaymentSheet(
    BuildContext context,
    double amount, {
    required bool isCreditCardFlow,
    String? paymentTypeOverride,
    double? ecoinsRestrictionsPercent,
  }) {
    KDialog.instance.openSheet(
      dialog: PaymentBottomSheet(
        amount: amount,
        isCreditCardFlow: isCreditCardFlow,
        paymentTypeOverride: paymentTypeOverride,
        ecoinsRestrictionsPercent: ecoinsRestrictionsPercent,
      ),
    );
  }

  String _buildParamHint(BillerCustomerParam param) {
    return '';
  }

  String? _validateParam(BillerCustomerParam param, String value) {
    if (value.isEmpty) {
      return param.optional ? null : 'Please enter ${param.paramName}';
    }
    final min = param.minLength;
    final max = param.maxLength;
    if (min != null && value.length < min) {
      return max != null && min == max
          ? '${param.paramName} must be $min characters'
          : '${param.paramName} must be at least $min characters';
    }
    final regexStr = param.regex?.trim();
    if (regexStr != null && regexStr.isNotEmpty) {
      try {
        if (!RegExp(regexStr).hasMatch(value)) {
          if (min != null && max != null) {
            return 'Enter a valid ${param.paramName.toLowerCase()} ($min–$max characters)';
          }
          return 'Invalid ${param.paramName.toLowerCase()}';
        }
      } catch (_) {
        // Skip malformed regex
      }
    }
    return null;
  }
}

class _InfoNoteCard extends StatelessWidget {
  const _InfoNoteCard({
    required this.text,
    this.showLogo = true,
  });

  final String text;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightBorder.withOpacity(0.7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showLogo) ...[
            Image.asset(FileConstants.bharatConnectColor, height: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              softWrap: true,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: Colors.black,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GasPolicyBanner extends StatelessWidget {
  const _GasPolicyBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDB0101),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        message.trim(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
      ),
    );
  }
}

class _GasErrorBanner extends StatelessWidget {
  const _GasErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDB0101),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.trim(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionSummaryCard extends StatelessWidget {
  const _SubscriptionSummaryCard({
    required this.mobileNumber,
    required this.plan,
    required this.amount,
    required this.onChange,
  });

  final String mobileNumber;
  final String plan;
  final double amount;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final resolvedMobile = mobileNumber.trim().isEmpty ? '-' : mobileNumber;
    final resolvedPlan = plan.trim().isEmpty ? '-' : plan;
    final amountText = amount <= 0 ? '-' : '₹${amount.toStringAsFixed(2)}';

    Widget stackedField({
      required String label,
      required String value,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stackedField(label: 'Mobile Number', value: resolvedMobile),
          const SizedBox(height: 16),
          stackedField(label: 'Plan', value: resolvedPlan),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Amount To Pay',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                amountText,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

bool _isGasCylinderCategory(String? paymentType) {
  final value = (paymentType ?? '').trim().toLowerCase();
  if (value.isEmpty) return false;
  // Only LPG cylinder booking ("Book Gas") should use cylinder-specific UI
  // (bill sample/terms + registered mobile prefills). Exclude Piped Gas (PNG).
  final isPipedGas = value.contains('piped') ||
      value.contains('pipe') ||
      value.contains('png');
  if (isPipedGas) return false;

  return value.contains('lpg') ||
      value.contains('cylinder') ||
      (value.contains('book') && value.contains('gas'));
}

bool _isPipedGasCategory(String? paymentType) {
  final value = (paymentType ?? '').trim().toLowerCase();
  if (value.isEmpty) return false;
  return value.contains('piped') ||
      value.contains('pipe') ||
      value.contains('png') ||
      (value.contains('gas') && value.contains('pipe'));
}

bool _isGasBookingPolicyMessage(String message) {
  final text = message.trim().toLowerCase();
  if (text.isEmpty) return false;
  if (!text.contains('dear customer')) return false;
  return text.contains('booking policy') ||
      text.contains('eligible booking date') ||
      text.contains('lpg refill') ||
      text.contains('refill was delivered');
}

bool _isSubscriptionFlow({
  required String? paymentType,
  required String? detailCategory,
  required String? billerName,
}) {
  bool isSubscriptionText(String? value) {
    final text = (value ?? '').trim().toLowerCase();
    if (text.isEmpty) return false;
    return text == 'subscription' || text.contains('subscription');
  }

  if (isSubscriptionText(paymentType)) return true;
  if (isSubscriptionText(detailCategory)) return true;

  final name = (billerName ?? '').trim().toLowerCase();
  if (name.isEmpty) return false;
  const hints = [
    'subscription',
    'hotstar',
    'ott',
    'netflix',
    'prime',
    'sony',
    'zee',
  ];
  return hints.any(name.contains);
}

String _resolveSubscriptionMobile(Map<String, String> params) {
  if (params.isEmpty) return '';
  for (final entry in params.entries) {
    final key = entry.key.toLowerCase();
    if (key.contains('mobile') ||
        key.contains('phone') ||
        key.contains('contact')) {
      return entry.value.trim();
    }
  }
  return params.values.first.trim();
}

String _resolveSubscriptionPlan(Map<String, String> params) {
  if (params.isEmpty) return '';
  for (final entry in params.entries) {
    final key = entry.key.toLowerCase();
    if (key.contains('plan') ||
        key.contains('package') ||
        key.contains('product')) {
      return entry.value.trim();
    }
  }
  if (params.values.length >= 2) {
    return params.values.elementAt(1).trim();
  }
  return '';
}

double _resolveSubscriptionAmount(
  Map<String, String> params,
  String enteredAmountRaw,
  BillResponse? bill,
) {
  final entered = _parseEnteredAmount(enteredAmountRaw);
  if (entered != null && entered > 0) return entered;
  if (bill != null) return bill.amountInRupees;

  final plan = _resolveSubscriptionPlan(params);
  final parsed = _parseAmountFromPlan(plan);
  if (parsed != null && parsed > 0) return parsed;

  return 0;
}

double? _parseAmountFromPlan(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final explicit = RegExp(
    r'(?:₹|rs\.?|inr|@)\s*([0-9]+(?:\.[0-9]+)?)',
    caseSensitive: false,
  ).firstMatch(text);
  if (explicit != null) {
    return double.tryParse(explicit.group(1) ?? '');
  }

  final numbers = RegExp(r'([0-9]+(?:\.[0-9]+)?)').allMatches(text).toList();
  if (numbers.isEmpty) return null;
  return double.tryParse(numbers.last.group(1) ?? '');
}

class _MaskedPrefix extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '\u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              letterSpacing: 1.2,
              color: AppColors.textPrimary.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

bool _isNoBillDueMessage(String message) {
  return message.toLowerCase().contains('no bill due');
}

class _NoBillDueDialog extends StatelessWidget {
  const _NoBillDueDialog({
    required this.title,
    required this.message,
    required this.onContinue,
  });

  final String title;
  final String message;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE5F8EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF1BA13F),
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.75),
                  ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onContinue,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white),
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

class _BillFetchFailedDialog extends StatelessWidget {
  const _BillFetchFailedDialog({
    required this.message,
    required this.onContinue,
  });

  final String message;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF2B9A6)),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 44,
              ),
            ),
            // const SizedBox(height: 16),
            // Text(
            //   'Unable to fetch bill',
            //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
            //         fontWeight: FontWeight.bold,
            //         color: AppColors.textPrimary,
            //       ),
            // ),
            const SizedBox(height: 8),
            Text(
              message.trim().isEmpty
                  ? 'We couldn\u2019t fetch your bill right now. Please recheck the details and try again in a moment.'
                  : message.trim(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.75),
                  ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onContinue,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
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

bool _isLastFourParam(String name) {
  final normalized = name.toLowerCase();
  return normalized.contains('last 4') ||
      normalized.contains('last4') ||
      normalized.contains('last four') ||
      normalized.contains('last digits');
}

bool _isMobileParam(String name) {
  final normalized = name.toLowerCase();
  return normalized.contains('mobile') ||
      normalized.contains('phone') ||
      normalized.contains('contact');
}

bool _isIdentifierParam(String name, String dataType) {
  final normalized = name.toLowerCase();
  final isNumeric = dataType.toUpperCase() == 'NUMERIC';
  if (!isNumeric) return false;
  return normalized.contains('customer') ||
      normalized.contains('consumer') ||
      normalized.contains('account') ||
      normalized.contains('service') ||
      normalized.contains('subscriber') ||
      normalized.contains('ca') ||
      normalized.contains('connection');
}

String _sanitizePhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length > 10) {
    return digits.substring(digits.length - 10);
  }
  return digits;
}

Future<String?> _pickContactNumber(
    BuildContext context, PermissionService permissionService,
    {required ContactsCacheController contactsController}) async {
  final status = await Permission.contacts.status;
  if (status.isPermanentlyDenied) {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Contacts permission'),
          content: const Text(
            'Contacts permission is required to pick a number.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
    if (openSettings == true) {
      await openAppSettings();
    }
    return null;
  }

  final granted = status.isGranted || await permissionService.requestContacts();
  if (!granted) {
    AppSnackbar.show(
      'Contacts permission is required.',
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    return null;
  }

  // Open the sheet immediately; contacts load inside via cache controller.
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return _ContactPickerSheetHost(
        onReload: contactsController.reload,
        onEnsureLoaded: contactsController.fetchIfNeeded,
      );
    },
  );
}

class _ContactPickerSheetHost extends HookConsumerWidget {
  const _ContactPickerSheetHost({
    required this.onReload,
    required this.onEnsureLoaded,
  });

  final Future<void> Function() onReload;
  final Future<void> Function() onEnsureLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contactsCacheControllerProvider);

    useEffect(() {
      Future.microtask(onEnsureLoaded);
      return null;
    }, const []);

    final contacts = state.contacts;
    final isLoading = state.isLoading;
    final error = state.errorMessage;

    if (isLoading && contacts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 10),
            Text('Loading contacts...'),
          ],
        ),
      );
    }

    if (error != null && error.isNotEmpty && contacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unable to load contacts.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReload,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ),
          ],
        ),
      );
    }

    return _ContactPickerSheet(contacts: contacts);
  }
}

// double _resolvedPayAmount(
//   TextEditingController controller,
//   BillResponse bill,
// ) {
//   final entered = _parseEnteredAmount(controller.text);
//   if (entered != null && entered > 0) return entered;
//   return bill.amountInRupees;
// }

double? _parseEnteredAmount(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

class _ContactPickerSheet extends StatefulWidget {
  const _ContactPickerSheet({required this.contacts});

  final List<Contact> contacts;

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = widget.contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final phone =
          contact.phones.isNotEmpty ? contact.phones.first.number : '';
      return name.contains(query) || phone.contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select Contact',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          SearchTextfield(
            hintText: 'Search contacts',
            controller: _searchController,
            onChange: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No contacts found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.6),
                          ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.textPrimary.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final contact = filtered[index];
                      final phone = contact.phones.isNotEmpty
                          ? contact.phones.first.number
                          : '';
                      return ListTile(
                        title: Text(contact.displayName),
                        subtitle: Text(phone),
                        onTap: phone.isEmpty
                            ? null
                            : () => Navigator.of(context)
                                .pop(_sanitizePhone(phone)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompactBillSection extends StatelessWidget {
  const _CompactBillSection({
    required this.bill,
    required this.customerParams,
    required this.billAmountController,
    required this.onToggle,
    required this.selectedAmountType,
    required this.onAmountTypeChanged,
    required this.totalOutstanding,
    required this.minimumDue,
    required this.isCreditCardFlow,
    required this.isPipedGas,
    this.allowCustomAmount = false,
    this.isElectricity = false,
    this.showFullDetailsInline = false,
    this.hideAmountDisplayCard = false,
  });

  final BillResponse bill;
  final Map<String, String> customerParams;
  final TextEditingController billAmountController;
  final VoidCallback onToggle;
  final _PaymentAmountType selectedAmountType;
  final ValueChanged<_PaymentAmountType> onAmountTypeChanged;
  final double? totalOutstanding;
  final double? minimumDue;
  final bool isCreditCardFlow;
  final bool isPipedGas;
  final bool allowCustomAmount;
  final bool isElectricity;
  final bool showFullDetailsInline;
  final bool hideAmountDisplayCard;

  @override
  Widget build(BuildContext context) {
    if (isCreditCardFlow) {
      final total = totalOutstanding ?? bill.amountInRupees;
      return CreditCardPayNowSection(
        bill: bill,
        totalOutstanding: total,
        minimumDue: minimumDue,
        selected: switch (selectedAmountType) {
          _PaymentAmountType.totalOutstanding =>
            CreditCardPayNowAmountType.total,
          _PaymentAmountType.minimumDue => CreditCardPayNowAmountType.minimum,
          _PaymentAmountType.custom => CreditCardPayNowAmountType.custom,
        },
        onChanged: (next) {
          onAmountTypeChanged(
            switch (next) {
              CreditCardPayNowAmountType.total =>
                _PaymentAmountType.totalOutstanding,
              CreditCardPayNowAmountType.minimum =>
                _PaymentAmountType.minimumDue,
              CreditCardPayNowAmountType.custom => _PaymentAmountType.custom,
            },
          );
        },
        amountController: billAmountController,
      );
    }

    if (isPipedGas) {
      return PipedGasBillSection(
        bill: bill,
        customerParams: customerParams,
        amountController: billAmountController,
      );
    }

    // Pick "Early Payment Date" from additionalParams if available
    final earlyPayDate = bill.additionalParams['Early Payment Date'] ?? '';
    final pc = bill.additionalParams['PC'] ?? '';
    final note = bill.note.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Details card (Electricity: white + arrow on card)
        (showFullDetailsInline && !isCreditCardFlow && !isPipedGas)
            ? _FullDetailsSection(
                bill: bill,
                customerParams: customerParams,
                onToggle: () {},
                showToggle: false,
              )
            : isElectricity
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E2E2)),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ...customerParams.entries.map(
                              (entry) => _ColonInfoRow(
                                label: entry.key,
                                value: entry.value,
                              ),
                            ),
                            if (earlyPayDate.isNotEmpty)
                              _ColonInfoRow(
                                label: 'Early Payment Date',
                                value: earlyPayDate,
                              ),
                            if (pc.isNotEmpty)
                              _ColonInfoRow(
                                label: 'PC',
                                value: pc,
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: -20,
                        child: _ToggleArrowButton(
                          isExpanded: false,
                          onTap: onToggle,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            ...customerParams.entries.map(
                              (entry) => _InfoRow(
                                  label: entry.key, value: entry.value),
                            ),
                            if (earlyPayDate.isNotEmpty)
                              _InfoRow(
                                label: 'Early Payment Date',
                                value: earlyPayDate,
                              ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _ToggleArrowButton(
                            isExpanded: false,
                            onTap: onToggle,
                          ),
                        ),
                      ),
                    ],
                  ),

        // Amount card (orange border)
        if (!hideAmountDisplayCard)
          Padding(
            padding: EdgeInsets.only(top: isElectricity ? 22 : 0),
            child: _AmountDisplayCard(bill: bill),
          ),

        const SizedBox(height: 16),

        // Additional fee note (prefer API `note` for Electricity)
        if (isElectricity && note.isNotEmpty) ...[
          _AdditionalNoteCard(text: note),
          const SizedBox(height: 20),
        ] else if (!isElectricity && bill.latePaymentFormatted.isNotEmpty) ...[
          Text(
            'Payments made after ${bill.dueDate} will incur an additional charge of ${_additionalCharge()}.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 20),
        ],

        const SizedBox(height: 8),

        // Bill Amount field
        Text(
          'Bill Amount',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: billAmountController,
          keyboardType: TextInputType.number,
          readOnly: !allowCustomAmount,
          onTap: () {
            // Make it easy to replace the prefilled amount (e.g. FASTag).
            billAmountController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: billAmountController.text.length,
            );
          },
          inputFormatters: [
            if (allowCustomAmount)
              FilteringTextInputFormatter.digitsOnly
            else
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (value) {
            if (selectedAmountType != _PaymentAmountType.custom) {
              onAmountTypeChanged(_PaymentAmountType.custom);
            }
          },
          onEditingComplete: () {
            if (selectedAmountType != _PaymentAmountType.custom) {
              onAmountTypeChanged(_PaymentAmountType.custom);
            }
          },
          decoration: InputDecoration(
            prefixText: '\u20B9  ',
            prefixStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  String _additionalCharge() {
    // late payment amount – bill amount
    final late =
        (int.tryParse(bill.otherDetails['Late Payment Amount'] ?? '') ?? 0) /
            100;
    final base = bill.amountInRupees;
    final diff = late - base;
    if (diff > 0) {
      return '\u20B9${diff.toStringAsFixed(0)}';
    }
    return bill.latePaymentFormatted;
  }
}

// ─── Amount Display Card ─────────────────────────────────────────────────────

class _AmountDisplayCard extends StatelessWidget {
  const _AmountDisplayCard({required this.bill});

  final BillResponse bill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: bill period chip + due date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_hasValidBillPeriod(_resolveBillMonth(bill)))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Bill for ${_formatBillPeriod(_resolveBillMonth(bill))}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              if (bill.dueDate.isNotEmpty)
                Text(
                  'Due on: ${DateFormatHelper.formatDisplayDate(bill.dueDate)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.red,
                        fontWeight: FontWeight.w700,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Amount
          Text(
            _resolvedAmountText(),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  /// Turn "2509" → "Sep '25", or return as-is
  String _formatBillPeriod(String period) {
    if (period.length == 4) {
      final yy = period.substring(0, 2);
      final mm = int.tryParse(period.substring(2));
      if (mm != null && mm >= 1 && mm <= 12) {
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
          'Dec',
        ];
        return "${months[mm - 1]} '$yy";
      }
    }
    return period;
  }

  String _resolveBillMonth(BillResponse bill) {
    final fromAdditional = bill.additionalParams['Bill Month']?.trim() ?? '';
    if (fromAdditional.isNotEmpty) return fromAdditional;
    return bill.billPeriod.trim();
  }

  bool _hasValidBillPeriod(String period) {
    final value = period.trim().toLowerCase();
    if (value.isEmpty) return false;
    if (value == 'na' || value == 'n/a' || value == 'null') return false;
    if (value == '-' || value == '--') return false;
    return true;
  }

  String _resolvedAmountText() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final earlyDate = _parseDueDate(
      bill.additionalParams['Early Payment Date'] ?? '',
    );
    final dueDate = _parseDueDate(bill.dueDate);

    // On or before early payment date → show early payment amount
    final earlyAmount =
        _parseAmountMaybe(bill.otherDetails['Early Payment Amount']);
    if (earlyDate != null &&
        earlyAmount != null &&
        !todayDate.isAfter(earlyDate)) {
      return _formatRupees(earlyAmount);
    }

    // After due date → show late payment amount
    final lateAmount =
        _parseAmountMaybe(bill.otherDetails['Late Payment Amount']);
    if (dueDate != null && lateAmount != null && todayDate.isAfter(dueDate)) {
      return _formatRupees(lateAmount);
    }

    // Between early payment date and due date → regular amount
    return bill.formattedAmount;
  }

  DateTime? _parseDueDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final iso = DateTime.tryParse(value);
    if (iso != null) {
      return iso.isUtc ? iso.toLocal() : iso;
    }

    final numeric = RegExp(r'^(\\d{1,2})[./-](\\d{1,2})[./-](\\d{2,4})$');
    final match = numeric.firstMatch(value);
    if (match != null) {
      final day = int.tryParse(match.group(1) ?? '');
      final month = int.tryParse(match.group(2) ?? '');
      var year = int.tryParse(match.group(3) ?? '');
      if (day == null || month == null || year == null) return null;
      if (year < 100) year += 2000;
      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      return DateTime(year, month, day);
    }
    return null;
  }

  String _formatRupees(double amount) {
    return '\u20B9${amount.toStringAsFixed(2)}';
  }
}

// ─── Full Details Section ────────────────────────────────────────────────────

class _FullDetailsSection extends StatelessWidget {
  const _FullDetailsSection({
    required this.bill,
    required this.customerParams,
    required this.onToggle,
    this.showToggle = true,
  });

  final BillResponse bill;
  final Map<String, String> customerParams;
  final VoidCallback onToggle;
  final bool showToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E2E2)),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Customer params
                  ...customerParams.entries.map(
                    (entry) =>
                        _ColonInfoRow(label: entry.key, value: entry.value),
                  ),

                  // All additional params
                  ...bill.additionalParams.entries.map(
                    (e) => _ColonInfoRow(label: e.key, value: e.value),
                  ),

                  // Account holder / Customer Name
                  if (bill.accountHolderName.isNotEmpty)
                    _ColonInfoRow(
                      label: 'Customer Name',
                      value: bill.accountHolderName,
                    ),

                  // Due Date
                  if (bill.dueDate.isNotEmpty)
                    _ColonInfoRow(
                      label: 'Due Date',
                      value: DateFormatHelper.formatDisplayDate(bill.dueDate),
                    ),

                  // Early payment date & amount
                  if (bill.earlyPaymentFormatted.isNotEmpty)
                    _ColonInfoRow(
                      label: 'Early payment date & amount',
                      value: _earlyPaymentText(),
                    ),

                  // Due payment date & amount
                  if (bill.dueDate.isNotEmpty)
                    _ColonInfoRow(
                      label: 'Due payment date & amount',
                      value: _duePaymentText(),
                    ),

                  // Late payment date & amount
                  if (bill.latePaymentFormatted.isNotEmpty)
                    _ColonInfoRow(
                      label: 'Late payment date & amount',
                      value: _latePaymentText(),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: -21,
              child: showToggle
                  ? Center(
                      child: _ToggleArrowButton(
                        isExpanded: true,
                        onTap: onToggle,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        SizedBox(height: showToggle ? 24 : 0),
      ],
    );
  }

  String _earlyPaymentText() {
    final earlyDate = bill.additionalParams['Early Payment Date'] ?? '';
    if (earlyDate.isNotEmpty) {
      return 'Before $earlyDate - ${bill.earlyPaymentFormatted}';
    }
    return bill.earlyPaymentFormatted;
  }

  String _duePaymentText() {
    final earlyDate = bill.additionalParams['Early Payment Date'] ?? '';
    final dueDate = bill.dueDate;
    final amount = bill.earlyPaymentFormatted.isNotEmpty
        ? bill.earlyPaymentFormatted
        : bill.formattedAmount;
    if (earlyDate.isNotEmpty && dueDate.isNotEmpty) {
      return '$earlyDate to $dueDate - $amount';
    }
    return '$dueDate - $amount';
  }

  String _latePaymentText() {
    final dueDate = bill.dueDate;
    if (dueDate.isNotEmpty) {
      return 'After $dueDate - ${bill.latePaymentFormatted}';
    }
    return bill.latePaymentFormatted;
  }
}

// ─── Toggle Arrow Button ─────────────────────────────────────────────────────

class _ToggleArrowButton extends StatelessWidget {
  const _ToggleArrowButton({
    required this.isExpanded,
    required this.onTap,
  });

  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFF835C),
                Color(0xFFDD5428),
              ],
            ),
          ),
          child: Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 24,
          ),
        ));
  }
}

class _ColonInfoRow extends StatelessWidget {
  const _ColonInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.75),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            ':',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.75),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdditionalNoteCard extends StatelessWidget {
  const _AdditionalNoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE85A2C).withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline,
              color: Color(0xFFE85A2C),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Row ────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.6),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PaymentAmountType {
  totalOutstanding,
  minimumDue,
  custom,
}

/// Returns the amount to display/pay based on today's date vs early/due dates.
double _resolveDateBasedAmount(BillResponse bill) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  final earlyDate = _parseDateString(
    bill.additionalParams['Early Payment Date'] ?? '',
  );
  final dueDate = _parseDateString(bill.dueDate);

  final earlyAmount =
      _parseAmountMaybe(bill.otherDetails['Early Payment Amount']);
  if (earlyDate != null &&
      earlyAmount != null &&
      !todayDate.isAfter(earlyDate)) {
    return earlyAmount;
  }

  final lateAmount =
      _parseAmountMaybe(bill.otherDetails['Late Payment Amount']);
  if (dueDate != null && lateAmount != null && todayDate.isAfter(dueDate)) {
    return lateAmount;
  }

  return bill.amountInRupees;
}

String _formatAmountForInput(double amount) {
  final fixed = amount.toStringAsFixed(2);
  return fixed.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

DateTime? _parseDateString(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final iso = DateTime.tryParse(value);
  if (iso != null) return iso.isUtc ? iso.toLocal() : iso;
  final numeric = RegExp(r'^(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})$');
  final match = numeric.firstMatch(value);
  if (match != null) {
    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    var year = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }
  return null;
}

double _resolveTotalOutstanding(BillResponse bill) {
  final amount = _extractAmountFromDetails(
    bill,
    const [
      'Total Outstanding',
      'Total Outstanding Amount',
      'Total Amount Due',
      'Total Due',
      'Outstanding Amount',
      'Total Amount',
    ],
  );
  return amount ?? bill.amountInRupees;
}

double? _resolveMinimumDue(BillResponse bill) {
  return _extractAmountFromDetails(
    bill,
    const [
      'Minimum Amount Due',
      'Minimum Payable Amount',
      'MinimumDueAmount',
      'Minimum Due',
      'Minimum Payment',
      'Min Payable Amount',
      'Min Amount Due',
      'Min Due',
    ],
  );
}

double? _extractAmountFromDetails(BillResponse bill, List<String> keys) {
  double? scanMap(Map<String, String> source) {
    for (final key in keys) {
      final direct = source[key];
      final parsed = _parseAmountMaybe(direct);
      if (parsed != null) return parsed;
    }
    for (final entry in source.entries) {
      final normalized = entry.key.trim().toLowerCase();
      for (final key in keys) {
        if (normalized == key.toLowerCase()) {
          final parsed = _parseAmountMaybe(entry.value);
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  final fromOther = scanMap(bill.otherDetails);
  if (fromOther != null) return fromOther;

  final fromAdditional = scanMap(bill.additionalParams);
  if (fromAdditional != null) return fromAdditional;

  return null;
}

double? _parseAmountMaybe(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null) return null;
  if (raw.contains('.')) return value;
  if (cleaned.length > 4) return value / 100;
  return value;
}
