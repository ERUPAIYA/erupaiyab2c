class DigitalGoldPurchaseReceipt {
  const DigitalGoldPurchaseReceipt({
    required this.weightOfGold,
    required this.amountPaid,
    required this.pricePerGram,
    required this.dateTime,
    required this.transactionId,
  });

  factory DigitalGoldPurchaseReceipt.fromApi(Map<String, dynamic> json) {
    String pickString(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    return DigitalGoldPurchaseReceipt(
      weightOfGold: pickString(const [
        'weight_of_gold',
        'gold_weight',
        'quantity',
        'qty',
        'weight',
      ]),
      amountPaid: pickString(const [
        'amount_paid',
        'paid_amount',
        'final_amount',
        'total_amount',
        'amount',
        'total',
      ]),
      pricePerGram: pickString(const [
        'price_per_gram',
        'rate_per_gram',
        'gold_price_per_gram',
        'rate',
        'price',
      ]),
      dateTime: pickString(const [
        'date_time',
        'datetime',
        'created_at',
        'createdAt',
        'timestamp',
        'date',
      ]),
      transactionId: pickString(const [
        'transaction_id',
        'transactionId',
        'txn_id',
        'txnid',
        'order_id',
        'orderId',
        'reference_id',
        'referenceId',
        'refid',
      ]),
    );
  }

  final String weightOfGold;
  final String amountPaid;
  final String pricePerGram;
  final String dateTime;
  final String transactionId;
}

