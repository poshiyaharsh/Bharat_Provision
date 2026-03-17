import 'package:sqflite/sqflite.dart';

import '../../shared/models/expense_account_model.dart';
import '../../shared/models/expense_model.dart';

class ExpenseRepository {
  ExpenseRepository(this._db);

  final Database _db;

  Future<List<ExpenseAccount>> getExpenseAccounts() async {
    final results = await _db.query(
      'expense_accounts',
      where: 'is_active = ?',
      whereArgs: [1],
    );
    return results.map((row) => ExpenseAccount.fromMap(row)).toList();
  }

  Future<int> addExpense(Expense expense) async {
    final id = await _db.insert('expenses', expense.toMap());
    // TODO: Insert into khata_ledger as debit
    return id;
  }

  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    int? accountId,
  }) async {
    String where = '';
    List<dynamic> whereArgs = [];
    if (startDate != null) {
      where += 'date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'date < ?';
      whereArgs.add(endDate.toIso8601String());
    }
    if (accountId != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'expense_account_id = ?';
      whereArgs.add(accountId);
    }

    final results = await _db.query(
      'expenses',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );
    return results.map((row) => Expense.fromMap(row)).toList();
  }

  Future<void> deleteExpense(int id) async {
    await _db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
