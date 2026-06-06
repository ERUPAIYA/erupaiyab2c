enum SipUnit { rupees, grams }

extension SipUnitLabel on SipUnit {
  String get label => this == SipUnit.rupees ? 'In Rupees' : 'In Grams';
}

