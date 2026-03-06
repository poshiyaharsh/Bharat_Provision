class BillItem {
  final int? id;
  final int billId;
  final int itemId;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  const BillItem({
    this.id,
    required this.billId,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'] as int?,
      billId: map['bill_id'] as int,
      itemId: map['item_id'] as int,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
      lineTotal: (map['line_total'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'bill_id': billId,
      'item_id': itemId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal,
    };
  }
}
