import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/language_chip.dart';
import '../components/policy_section_title.dart';

class AboutUsScreen extends HookWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final language = useState(LanguageOption.english);
    String t(String en, String hi) =>
        language.value == LanguageOption.hindi ? hi : en;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(title: t('About E-Rupaiya', 'About E-Rupaiya')),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t('About e-Rupaiya', 'About e-Rupaiya'),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      LanguageChip(
                        value: language.value,
                        onChanged: (value) => language.value = value,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  _AboutParagraph(
                    t(
                      'e-Rupaiya is a smart and rewarding digital payments '
                          'platform designed to make your everyday bill payments '
                          'simple, fast, and beneficial.',
                      'e-Rupaiya एक स्मार्ट और रिवॉर्डिंग डिजिटल पेमेंट्स '
                          'प्लेटफॉर्म है, जो आपके रोज़मर्रा के बिल भुगतान को '
                          'सरल, तेज़ और लाभकारी बनाता है।',
                    ),
                  ),
                  _AboutParagraph(
                    t(
                      'From mobile recharges and utility bills to other essential '
                          'payments, e-Rupaiya ensures a seamless experience with a '
                          'user-friendly interface built for everyone.',
                      'मोबाइल रिचार्ज और यूटिलिटी बिल से लेकर अन्य ज़रूरी '
                          'भुगतानों तक, e‑Rupaiya सभी के लिए सहज और '
                          'यूज़र‑फ्रेंडली अनुभव देता है।',
                    ),
                  ),
                  _AboutParagraph(
                    t(
                      'Our mission is to transform routine transactions into '
                          'rewarding experiences. With every payment you make, you '
                          'earn coins that can be used for future bill payments, '
                          'giving you real value back on your spending.',
                      'हमारा मिशन रोज़मर्रा के लेन‑देन को रिवॉर्डिंग अनुभव में '
                          'बदलना है। हर भुगतान पर आप कॉइन कमाते हैं, जिन्हें '
                          'आगे के बिल भुगतान में उपयोग किया जा सकता है।',
                    ),
                  ),
                  _AboutParagraph(
                    t(
                      'We believe payments shouldn’t just be easy — they should '
                          'also give something back to the user.',
                      'हम मानते हैं कि भुगतान केवल आसान ही नहीं, बल्कि '
                          'यूज़र को कुछ वापस भी देना चाहिए।',
                    ),
                  ),
                  _AboutParagraph(
                    t(
                      'At e-Rupaiya, security and trust are our top priorities. '
                          'We use reliable systems and secure processes to ensure '
                          'that your data and transactions remain safe at all times.',
                      'e‑Rupaiya में सुरक्षा और विश्वास हमारी सर्वोच्च प्राथमिकताएँ हैं। '
                          'हम आपके डेटा और लेन‑देन को सुरक्षित रखने के लिए '
                          'विश्वसनीय सिस्टम और सुरक्षित प्रक्रियाएँ अपनाते हैं।',
                    ),
                  ),
                  _AboutParagraph(
                    t(
                      'You can confidently manage your payments knowing your '
                          'information is protected.',
                      'आप निश्चिंत होकर भुगतान कर सकते हैं क्योंकि आपकी जानकारी सुरक्षित है।',
                    ),
                  ),
                  SizedBox(height: 12.h),
                  PolicySectionTitle(
                    text: t('Why e-Rupaiya?', 'Why e-Rupaiya?'),
                  ),
                  SizedBox(height: 8.h),
                  _Bullet(
                    t('Quick and hassle-free payments',
                        'तेज़ और बिना झंझट भुगतान'),
                  ),
                  _Bullet(
                    t('Rewards on every transaction', 'हर लेन‑देन पर रिवॉर्ड'),
                  ),
                  _Bullet(
                    t('Simple, clean and easy-to-use interface',
                        'सरल, साफ़ और उपयोग में आसान इंटरफ़ेस'),
                  ),
                  _Bullet(t('Secure & reliable', 'सुरक्षित और विश्वसनीय')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutParagraph extends StatelessWidget {
  const _AboutParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.75),
              height: 1.5,
            ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h),
            width: 6.w,
            height: 6.w,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
