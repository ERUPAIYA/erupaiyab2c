// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/grey_radio_tile.dart';
import '../models/language_option.dart';

class LanguageSelectionView extends HookConsumerWidget {
  const LanguageSelectionView({
    super.key,
    this.isSettingsFlow = false,
  });

  final bool isSettingsFlow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState(languageOptions.first);

    void handleContinue() {
      if (isSettingsFlow) {
        context.pop();
        return;
      }
      context.go(
        RouteConstants.kycOverview,
        extra: selectedLanguage.value.label,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: 'Choose Language',
        onBack: () => context.pop(),
        onHelp: () {},
        // trailing: TextButton(
        //   onPressed: handleContinue,
        //   child: const Text(
        //     'Skip',
        //     style: TextStyle(color: AppColors.primary),
        //   ),
        // ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Select your preferred language to personalize your app experience.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.8),
                    ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: languageOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final option = languageOptions[index];
                    return GreyRadioTile(
                      title: option.label,
                      isSelected: option.value == selectedLanguage.value.value,
                      onTap: () => selectedLanguage.value = option,
                      trailingIcon: Image.asset(
                        option.value == 'en'
                            ? FileConstants.ennglish
                            : FileConstants.hindi,
                        height: 28,
                        width: 28,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              CustomElevatedButton(
                onPressed: handleContinue,
                label: 'Continue',
                showArrow: false,
                uppercaseLabel: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
