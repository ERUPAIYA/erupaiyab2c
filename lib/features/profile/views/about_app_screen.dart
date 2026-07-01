import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../utils/utils.dart';
import '../../../widgets/my_app_bar.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const MyAppBar(title: 'About App'),
          Expanded(
            child: Center(
              child: FutureBuilder<String>(
                future: Utils.getAppVersion(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.trim().isNotEmpty == true
                      ? snapshot.data!.trim()
                      : '--';
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        FileConstants.erupaiyaLogo,
                        width: 94.w,
                        height: 94.w,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        'eRupaiya',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Version $version',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
