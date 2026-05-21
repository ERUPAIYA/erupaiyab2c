class BillerDetail {
  const BillerDetail({
    required this.billerId,
    required this.billerName,
    required this.billerAliasName,
    required this.billerCategoryName,
    required this.fetchRequirement,
    required this.planMdmRequirement,
    required this.paymentAmountExactness,
    required this.customerParams,
    required this.additionalInfo,
    required this.paymentModes,
    this.billImage,
    this.billTermsCond,
  });

  factory BillerDetail.fromJson(Map<String, dynamic> json) {
    final outerData = json['data'] as Map<String, dynamic>? ?? {};
    final data = outerData['data'] as Map<String, dynamic>? ?? outerData;

    final params = data['billerCustomerParams'] as List<dynamic>? ?? [];
    final additional = data['billerAdditionalInfo'] as List<dynamic>? ?? [];
    final paymentModes = data['billerPaymentModes'] as List<dynamic>? ?? [];

    return BillerDetail(
      billerId: data['billerId'] as String? ?? '',
      billerName: data['billerName'] as String? ?? '',
      billerAliasName: data['billerAliasName'] as String? ?? '',
      billerCategoryName: data['billerCategoryName'] as String? ?? '',
      fetchRequirement: data['fetchRequirement'] as String? ?? '',
      planMdmRequirement: data['planMdmRequirement'] as String? ?? '',
      paymentAmountExactness:
          data['paymentAmountExactness'] as String? ?? '',
      billImage: (data['bill_image'] ?? data['billImage'])?.toString(),
      billTermsCond: (data['bill_terms_cond'] ?? data['billTermsCond'])
          ?.toString(),
      customerParams: params
          .map((e) => BillerCustomerParam.fromJson(e as Map<String, dynamic>))
          .toList(),
      additionalInfo: additional
          .map((e) => BillerAdditionalInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentModes: paymentModes
          .map((e) => BillerPaymentMode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String billerId;
  final String billerName;
  final String billerAliasName;
  final String billerCategoryName;
  final String fetchRequirement;
  final String planMdmRequirement;
  final String paymentAmountExactness;
  final String? billImage;
  final String? billTermsCond;
  final List<BillerCustomerParam> customerParams;
  final List<BillerAdditionalInfo> additionalInfo;
  final List<BillerPaymentMode> paymentModes;
}

class BillerCustomerParam {
  const BillerCustomerParam({
    required this.paramName,
    required this.dataType,
    this.optional = false,
    this.minLength,
    this.maxLength,
    this.regex,
    this.visibility = true,
    this.values = const [],
  });

  factory BillerCustomerParam.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] as String?;
    final values = (rawValues != null && rawValues.trim().isNotEmpty)
        ? rawValues
            .split('|')
            .map((v) => v.trim())
            .where((v) => v.isNotEmpty)
            .toList()
        : <String>[];
    return BillerCustomerParam(
      paramName: json['paramName'] as String? ?? '',
      dataType: json['dataType'] as String? ?? '',
      optional: json['optional'] == 'true',
      minLength: int.tryParse(json['minLength']?.toString() ?? ''),
      maxLength: int.tryParse(json['maxLength']?.toString() ?? ''),
      regex: json['regex'] as String?,
      visibility: json['visibility'] != 'false',
      values: values,
    );
  }

  final String paramName;
  final String dataType;
  final bool optional;
  final int? minLength;
  final int? maxLength;
  final String? regex;
  final bool visibility;
  final List<String> values;

  bool get hasDropdown => values.isNotEmpty;
}

class BillerAdditionalInfo {
  const BillerAdditionalInfo({
    required this.paramName,
    required this.dataType,
    this.optional = false,
  });

  factory BillerAdditionalInfo.fromJson(Map<String, dynamic> json) {
    return BillerAdditionalInfo(
      paramName: json['paramName'] as String? ?? '',
      dataType: json['dataType'] as String? ?? '',
      optional: json['optional'] == 'true',
    );
  }

  final String paramName;
  final String dataType;
  final bool optional;
}

class BillerPaymentMode {
  const BillerPaymentMode({
    required this.paymentMode,
    this.maxLimit,
    this.minLimit,
  });

  factory BillerPaymentMode.fromJson(Map<String, dynamic> json) {
    return BillerPaymentMode(
      paymentMode: json['paymentMode'] as String? ?? '',
      maxLimit: json['maxLimit']?.toString(),
      minLimit: json['minLimit']?.toString(),
    );
  }

  final String paymentMode;
  final String? maxLimit;
  final String? minLimit;
}
