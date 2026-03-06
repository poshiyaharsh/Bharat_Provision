import 'package:sqflite/sqflite.dart';

import '../models/bill.dart';
import '../models/bill_item.dart';

class BillRepository {
  BillRepository(this._db);

  final Database _db;

  Future<int> getNextBillNumber() async {
    final counter = await _db.rawQuery(
      "SELECT value FROM settings WHERE key = 'bill_counter'",
    );
    final current = counter.isNotEmpty
        ? int.tryParse(counter.first['value'] as String? ?? '1') ?? 1
        : 1;
    await _db.update(
      'settings',
      {'value': (current + 1).toString()},
      where: "key = 'bill_counter'",
    );
    return current;
  }

  Future<int> createBill({
    required int? customerId,
    required List<BillItemInput> items,
    required double discountAmount,
    required double paidAmount,
    required String paymentMode,
    int? userId,
  }) async {
    return _db.transaction((txn) async {
      final billNumber = await _getNextBillNumber(txn);
      final now = DateTime.now().millisecondsSinceEpoch;

      double subtotal = 0;
      for (final i in items) {
        subtotal += i.quantity * i.unitPrice;
      }
      final totalAmount = subtotal - discountAmount;

      final billId = await txn.insert('bills', {
        'bill_number': billNumber.toString(),
        'date_time': now,
        'customer_id': customerId,
        'subtotal': subtotal,
        'discount_amount': discountAmount,
        'tax_amount': 0,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'payment_mode': paymentMode,
        'created_by_user_id': userId,
      });

      for (final i in items) {
        final lineTotal = i.quantity * i.unitPrice;
        await txn.insert('bill_items', {
          'bill_id': billId,
          'item_id': i.itemId,
          'quantity': i.quantity,
          'unit_price': i.unitPrice,
          'line_total': lineTotal,
        });
        await txn.rawUpdate(
          'UPDATE items SET current_stock = current_stock - ? WHERE id = ?',
          [i.quantity, i.itemId],
        );
      }

      await txn.update(
        'settings',
        {'value': (billNumber + 1).toString()},
        where: "key = 'bill_counter'",
      );

      return billId;
    });
  }

  Future<int> _getNextBillNumber(Transaction txn) async {
    final counter = await txn.rawQuery(
      "SELECT value FROM settings WHERE key = 'bill_counter'",
    );
    return counter.isNotEmpty
        ? int.tryParse(counter.first['value'] as String? ?? '1') ?? 1
        : 1;
  }

  Future<Bill?> getById(int id) async {
    final maps = await _db.query('bills', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Bill.fromMap(maps.first);
  }

  Future<List<BillItem>> getBillItems(int billId) async {
    final maps = await _db.query(
      'bill_items',
      where: 'bill_id = ?',
      whereArgs: [billId],
    );
    return maps.map((m) => BillItem.fromMap(m)).toList();
  }

  Future<double> getSalesTotal(int startEpoch, int endEpoch) async {
    final result = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) as total
      FROM bills
      WHERE date_time >= ? AND date_time <= ?
      ''',
      [startEpoch, endEpoch],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> getBillCount(int startEpoch, int endEpoch) async {
    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) as cnt FROM bills
      WHERE date_time >= ? AND date_time <= ?
      ''',
      [startEpoch, endEpoch],
    );
    return result.first['cnt'] as int? ?? 0;
  }
}

class BillItemInput {
  BillItemInput({
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
  });
  final int itemId;
  final double quantity;
  final double unitPrice;
}
