import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constants/app_colors.dart';
import '../../models/bill_response_model.dart';

class PipedGasBillSection extends StatelessWidget {
  const PipedGasBillSection({
    super.key,
    required this.bill,
    required this.customerParams,
    required this.amountController,
  });

  final BillResponse bill;
  final Map<String, String> customerParams;
  final TextEditingController amountController;

  static const int minAmount = 1;
  static const int maxAmount = 200000;

  @override
  Widget build(BuildContext context) {
    final bpNo = _pickCustomerParam(['bp', 'bp no', 'bpno']);
    final customerName = bill.accountHolderName.trim();
    final billNumber = bill.billNumber.trim();
    final dueDate = _formatLongDate(bill.dueDate);
    final dueOn = dueDate.isEmpty ? '' : 'Due on $dueDate';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Column(
            children: [
              _ColonRow(label: 'Customer Name', value: customerName),
              _ColonRow(label: 'BP No', value: bpNo),
              _ColonRow(label: 'Bill Number', value: billNumber),
              _ColonRow(label: 'Due Date', value: dueDate),
            ],
          ),
        ),
        SizedBox(height: 18.h),
        Row(
          children: [
            Text(
              'Amount to Pay',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(width: 12.w),
            Container(
              width: 1,
              height: 16.h,
              color: AppColors.lightBorder,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                dueOn,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFE85A2C),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (_) => _clampAmount(),
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          ),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }

  void _clampAmount() {
    final raw = amountController.text.trim();
    if (raw.isEmpty) return;
    final value = int.tryParse(raw);
    if (value == null) return;
    if (value > maxAmount) {
      amountController.text = maxAmount.toString();
      amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: amountController.text.length),
      );
    }
  }

  String _pickCustomerParam(List<String> keys) {
    if (customerParams.isEmpty) return '';
    for (final entry in customerParams.entries) {
      final normalized = entry.key.trim().toLowerCase();
      if (keys.any((k) => normalized == k)) return entry.value;
    }
    for (final entry in customerParams.entries) {
      final normalized = entry.key.trim().toLowerCase();
      if (keys.any((k) => normalized.contains(k))) return entry.value;
    }
    return '';
  }

  String _formatLongDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final normalized = value.contains(' ') ? value.replaceFirst(' ', 'T') : value;
    final parsed = DateTime.tryParse(normalized) ?? DateTime.tryParse(value);
    if (parsed == null) return value;
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
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }
}

class _ColonRow extends StatelessWidget {
  const _ColonRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.65),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Text(
            ':',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.65),
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
