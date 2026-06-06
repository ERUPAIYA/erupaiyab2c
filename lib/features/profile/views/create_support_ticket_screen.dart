// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/support_transaction_card.dart';
import '../controllers/support_ticket_controller.dart';
import '../models/support_latest_transaction.dart';

class CreateSupportTicketScreen extends HookConsumerWidget {
  const CreateSupportTicketScreen({
    super.key,
    required this.transaction,
  });

  final SupportLatestTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportTicketControllerProvider);
    final controller = ref.read(supportTicketControllerProvider.notifier);

    final descriptionController = useTextEditingController();
    final isRelated = useState(true);
    final screenshot = useState<File?>(null);

    final service = useState(_serviceOptions.firstWhere(
      (e) => e.code == transaction.serviceCode,
      orElse: () => _serviceOptions.first,
    ));
    final issueType = useState(_issueTypes.first);

    final lastError = useRef<String?>(null);
    useEffect(() {
      if (state.errorMessage != null && state.errorMessage != lastError.value) {
        lastError.value = state.errorMessage;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade400,
            ),
          );
        });
      }
      return null;
    }, [state.errorMessage]);

    Future<void> pickScreenshot() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      final file = File(picked.path);
      final bytes = await file.length();
      if (bytes > 20 * 1024 * 1024) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('File size must be less than 20MB'),
            backgroundColor: Colors.red.shade400,
          ),
        );
        return;
      }
      screenshot.value = file;
    }

    Future<void> submit() async {
      final desc = descriptionController.text.trim();
      if (desc.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please describe your issue'),
            backgroundColor: Colors.red.shade400,
          ),
        );
        return;
      }

      final ok = await controller.submit(
        transactionId: transaction.transactionId,
        service: service.value.code,
        issueType: issueType.value,
        isTransactionRelated: isRelated.value,
        description: desc,
        screenshot: screenshot.value,
      );
      if (!ok || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket created successfully'),
          backgroundColor: AppColors.green,
        ),
      );
      Navigator.of(context).pop();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const MyAppBar(title: 'Write To Us'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Transaction',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 8.h),
                  _DisabledField(
                    value: 'Transaction ID: ${transaction.transactionId}',
                  ),
                  SizedBox(height: 14.h),
                  SupportTransactionCard(
                    transaction: transaction,
                    width: double.infinity,
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    'Services',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 8.h),
                  _DropdownField<_ServiceOption>(
                    value: service.value,
                    items: _serviceOptions,
                    itemLabel: (e) => e.label,
                    onChanged: (v) {
                      if (v == null) return;
                      service.value = v;
                    },
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Select Issue Type',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 8.h),
                  _DropdownField<String>(
                    value: issueType.value,
                    items: _issueTypes,
                    itemLabel: (e) => e,
                    onChanged: (v) {
                      if (v == null) return;
                      issueType.value = v;
                    },
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Is your query transaction related?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceChipButton(
                          selected: isRelated.value,
                          text: "Yes, It's Related",
                          onTap: () => isRelated.value = true,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _ChoiceChipButton(
                          selected: !isRelated.value,
                          text: "No, It's Not",
                          onTap: () => isRelated.value = false,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  InkWell(
                    onTap: pickScreenshot,
                    borderRadius: BorderRadius.circular(14.r),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14.w, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.upload_file_outlined),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              screenshot.value == null
                                  ? 'Upload Screenshot (Optional)'
                                  : (screenshot.value!.uri.pathSegments.isEmpty
                                      ? 'Screenshot selected'
                                      : screenshot
                                          .value!.uri.pathSegments.last),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_upward,
                            color: AppColors.textPrimary.withOpacity(0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Please note: File size should be lesser than 20MB',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.6),
                        ),
                  ),
                  SizedBox(height: 14.h),
                  TextField(
                    controller: descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Briefly Explain Your Issue For Faster Support',
                      hintStyle: TextStyle(
                        color: AppColors.textPrimary.withOpacity(0.45),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide:
                            const BorderSide(color: AppColors.lightBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide:
                            const BorderSide(color: AppColors.lightBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  SizedBox(
                    width: double.infinity,
                    height: 42.h,
                    child: ElevatedButton(
                      onPressed: state.isSubmitting ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA5A30),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                        elevation: 0,
                      ),
                      child: state.isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit'),
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

class _DisabledField extends StatelessWidget {
  const _DisabledField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items
          .map(
            (e) => DropdownMenuItem<T>(
              value: e,
              child: Text(itemLabel(e)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
      icon: const Icon(Icons.keyboard_arrow_down),
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.selected,
    required this.text,
    required this.onTap,
  });

  final bool selected;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFFFFE1D6) : Colors.white;
    final border = selected ? const Color(0xFFEA5A30) : AppColors.lightBorder;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        height: 46.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFFEA5A30)),
          ],
        ),
      ),
    );
  }
}

class _ServiceOption {
  const _ServiceOption({
    required this.code,
    required this.label,
  });

  final String code;
  final String label;
}

const List<_ServiceOption> _serviceOptions = [
  _ServiceOption(
    code: 'BBPS',
    label: 'Utility Payments',
  ),
  _ServiceOption(code: 'METAL', label: 'Metal Payments'),
  _ServiceOption(code: 'EDUCATION', label: 'Education Payments'),
];

const List<String> _issueTypes = [
  'Payment Issue',
  'Refund Issue',
];
