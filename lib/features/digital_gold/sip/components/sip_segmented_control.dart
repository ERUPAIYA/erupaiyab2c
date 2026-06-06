import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SipSegmentedControl<T> extends StatelessWidget {
  const SipSegmentedControl({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.activeColor = const Color(0xFFE85A2C),
    this.inactiveColor = const Color(0xFFF3F4F6),
  });

  final T value;
  final List<SipSegmentItem<T>> items;
  final ValueChanged<T> onChanged;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: inactiveColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == item.value ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: value == item.value
                              ? Colors.white
                              : Colors.black.withOpacity(0.65),
                          fontWeight: FontWeight.w800,
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

class SipSegmentItem<T> {
  const SipSegmentItem({required this.value, required this.label});

  final T value;
  final String label;
}

