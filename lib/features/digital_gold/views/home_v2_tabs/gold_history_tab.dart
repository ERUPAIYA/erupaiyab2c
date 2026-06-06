part of '../digital_gold_home_v2_view.dart';

class _GoldHistoryTab extends StatelessWidget {
  const _GoldHistoryTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 12.w, 8.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD8),
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: Text(
                      '₹ 16,144.25/gm',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.help_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1.h, color: AppColors.lightBorder.withOpacity(0.6)),
          Expanded(
            child: Center(
              child: Text(
                'History coming soon',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.6),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

