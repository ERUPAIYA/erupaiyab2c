enum SipFrequency { daily, weekly, monthly }

extension SipFrequencyLabel on SipFrequency {
  String get label {
    switch (this) {
      case SipFrequency.daily:
        return 'Daily';
      case SipFrequency.weekly:
        return 'Weekly';
      case SipFrequency.monthly:
        return 'Monthly';
    }
  }
}

