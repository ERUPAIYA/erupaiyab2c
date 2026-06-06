import 'sip_frequency.dart';
import 'sip_unit.dart';

class SipDraft {
  const SipDraft({
    required this.isSip,
    required this.frequency,
    required this.unit,
    required this.amount,
    required this.agreedToTerms,
    this.investInBoth = false,
    this.goldSplitPercent = 20,
    this.weeklyDay = 1, // 1=Mon ... 7=Sun
    this.monthlyDay = 1, // 1..28/31 depending on backend support
  });

  final bool isSip; // true = Gold SIP, false = One Time
  final SipFrequency frequency;
  final SipUnit unit;
  final double amount; // ₹ or grams based on unit
  final bool agreedToTerms;
  final bool investInBoth;
  final double goldSplitPercent;
  final int weeklyDay;
  final int monthlyDay;

  SipDraft copyWith({
    bool? isSip,
    SipFrequency? frequency,
    SipUnit? unit,
    double? amount,
    bool? agreedToTerms,
    bool? investInBoth,
    double? goldSplitPercent,
    int? weeklyDay,
    int? monthlyDay,
  }) {
    return SipDraft(
      isSip: isSip ?? this.isSip,
      frequency: frequency ?? this.frequency,
      unit: unit ?? this.unit,
      amount: amount ?? this.amount,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      investInBoth: investInBoth ?? this.investInBoth,
      goldSplitPercent: goldSplitPercent ?? this.goldSplitPercent,
      weeklyDay: weeklyDay ?? this.weeklyDay,
      monthlyDay: monthlyDay ?? this.monthlyDay,
    );
  }
}
