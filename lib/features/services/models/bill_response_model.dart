class BillResponse {
  const BillResponse({
    required this.refId,
    required this.fetchRefId,
    required this.amountInPaisa,
    required this.accountHolderName,
    required this.dueDate,
    required this.billDate,
    required this.billPeriod,
    required this.billNumber,
    required this.otherDetails,
    required this.additionalParams,
    required this.approvalRefNum,
    required this.note,
    this.ecoinsRestrictionsPercent,
  });

  factory BillResponse.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? {};
    final billerResponse =
        payload['billerResponse'] as Map<String, dynamic>? ?? {};
    final otherDetails = _parseKeyValueMap(billerResponse['otherDetails']);
    final additionalParams = _parseKeyValueMap(payload['additionalParams']);

    final ecoinsRaw = json['ecoins_restrictions'];
    final ecoinsRestrictionsPercent = ecoinsRaw == null
        ? null
        : double.tryParse(ecoinsRaw.toString().trim());

    return BillResponse(
      refId: payload['refId'] as String? ?? '',
      fetchRefId: (json['fetch_ref_id'] ?? '').toString(),
      amountInPaisa: billerResponse['amount'] as String? ?? '0',
      accountHolderName: billerResponse['accountHolderName'] as String? ?? '',
      dueDate: billerResponse['dueDate'] as String? ?? '',
      billDate: billerResponse['billDate'] as String? ?? '',
      billPeriod: billerResponse['billPeriod'] as String? ?? '',
      billNumber: billerResponse['billNumber'] as String? ?? '',
      otherDetails: otherDetails,
      additionalParams: additionalParams,
      approvalRefNum: payload['approvalRefNum'] as String? ?? '',
      note: (json['note'] ?? '').toString(),
      ecoinsRestrictionsPercent: ecoinsRestrictionsPercent,
    );
  }

  final String refId;
  final String fetchRefId;
  final String amountInPaisa;
  final String accountHolderName;
  final String dueDate;
  final String billDate;
  final String billPeriod;
  final String billNumber;
  final Map<String, String> otherDetails;
  final Map<String, String> additionalParams;
  final String approvalRefNum;
  final String note;
  final double? ecoinsRestrictionsPercent;

  /// Convert paisa string to rupees (e.g. "139000" → 1390.00)
  double get amountInRupees {
    final paisa = int.tryParse(amountInPaisa) ?? 0;
    return paisa / 100;
  }

  String get formattedAmount {
    final rupees = amountInRupees;
    if (rupees == rupees.truncateToDouble()) {
      return '\u20B9${rupees.toStringAsFixed(2)}';
    }
    return '\u20B9${rupees.toStringAsFixed(2)}';
  }

  /// Early payment amount in rupees
  String get earlyPaymentFormatted {
    final raw = otherDetails['Early Payment Amount'];
    if (raw == null) return '';
    final paisa = int.tryParse(raw) ?? 0;
    return '\u20B9${(paisa / 100).toStringAsFixed(2)}';
  }

  /// Late payment amount in rupees
  String get latePaymentFormatted {
    final raw = otherDetails['Late Payment Amount'];
    if (raw == null) return '';
    final paisa = int.tryParse(raw) ?? 0;
    return '\u20B9${(paisa / 100).toStringAsFixed(2)}';
  }
}

Map<String, String> _parseKeyValueMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw.map((key, value) => MapEntry(key, value?.toString() ?? ''));
  }
  if (raw is Map) {
    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }
  if (raw is List) {
    final result = <String, String>{};
    for (final item in raw) {
      if (item is Map) {
        final key = _extractKey(item);
        final value = _extractValue(item);
        if (key != null && key.isNotEmpty) {
          result[key] = value ?? '';
        } else if (item.length == 1) {
          final entry = item.entries.first;
          result[entry.key.toString()] = entry.value?.toString() ?? '';
        }
      }
    }
    return result;
  }
  return <String, String>{};
}

String? _extractKey(Map<dynamic, dynamic> item) {
  const keyCandidates = [
    'key',
    'name',
    'label',
    'paramName',
    'field',
    'title',
  ];
  for (final candidate in keyCandidates) {
    if (item.containsKey(candidate)) {
      return item[candidate]?.toString();
    }
  }
  return null;
}

String? _extractValue(Map<dynamic, dynamic> item) {
  const valueCandidates = [
    'value',
    'val',
    'data',
    'paramValue',
  ];
  for (final candidate in valueCandidates) {
    if (item.containsKey(candidate)) {
      return item[candidate]?.toString();
    }
  }
  return null;
}
