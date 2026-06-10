// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';

class SearchTextfield extends StatelessWidget {
  const SearchTextfield({
    super.key,
    required this.hintText,
    required this.controller,
    this.prefixIcon,
    this.onChange,
    this.onFilterPressed,
  });

  final String hintText;
  final TextEditingController controller;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChange;
  final VoidCallback? onFilterPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChange,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
          ),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.textPrimary.withOpacity(0.4),
              fontWeight: FontWeight.w400,
              fontSize: 12.sp,
            ),
            prefixIcon: prefixIcon ??
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    FileConstants.orangeSearch,
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
            suffixIcon: onFilterPressed == null
                ? (value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          controller.clear();
                          onChange?.call('');
                        },
                      )
                    : null)
                : IconButton(
                    onPressed: onFilterPressed,
                    icon: Icon(
                      Icons.filter_list,
                      color: AppColors.textPrimary.withOpacity(0.6),
                    ),
                  ),
            filled: true,
            fillColor: Colors.white,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        );
      },
    );
  }
}
