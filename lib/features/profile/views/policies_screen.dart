import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/routes_constant.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/policy_list_tile.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const MyAppBar(title: 'Policies'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
              children: [
                PolicyListTile(
                  title: 'About E-Rupaiya',
                  icon: Icons.info_outline,
                  onTap: () => context.push(RouteConstants.aboutUs),
                ),
                const Divider(height: 1, color: Color(0xFFEDEDED)),
                PolicyListTile(
                  title: 'Terms & Conditions',
                  icon: Icons.description_outlined,
                  onTap: () => context.push(RouteConstants.termsPrivacy),
                ),
                const Divider(height: 1, color: Color(0xFFEDEDED)),
                PolicyListTile(
                  title: 'Privacy Policy',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () => context.push(RouteConstants.privacyPolicy),
                ),
                const Divider(height: 1, color: Color(0xFFEDEDED)),
                PolicyListTile(
                  title: 'Refund Policy',
                  icon: Icons.currency_exchange_outlined,
                  onTap: () => context.push(RouteConstants.refundPolicy),
                ),
                const Divider(height: 1, color: Color(0xFFEDEDED)),
                PolicyListTile(
                  title: 'Grievance',
                  icon: Icons.report_outlined,
                  onTap: () => context.push(RouteConstants.grievance),
                ),
                const Divider(height: 1, color: Color(0xFFEDEDED)),
                PolicyListTile(
                  title: 'About App',
                  icon: Icons.apps_outlined,
                  onTap: () => context.push(RouteConstants.aboutApp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
