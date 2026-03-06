class Bill {
  final int? id;
  final String billNumber;
  final int dateTime;
  final int? customerId;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final String paymentMode;
  final int? createdByUserId;

  const Bill({
    this.id,
    required this.billNumber,
    required this.dateTime,
    this.customerId,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentMode,
    this.createdByUserId,
  });

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'] as int?,
      billNumber: map['bill_number'] as String,
      dateTime: map['date_time'] as int,
      customerId: map['customer_id'] as int?,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      paymentMode: map['payment_mode'] as String? ?? 'cash',
      createdByUserId: map['created_by_user_id'] as int?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'bill_number': billNumber,
      'date_time': dateTime,
      'customer_id': customerId,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'payment_mode': paymentMode,
      'created_by_user_id': createdByUserId,
    };
  }
}
