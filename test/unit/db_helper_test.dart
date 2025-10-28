import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker_app/db/db_helper.dart';
import 'package:smart_expense_tracker_app/models/budget_model.dart';
import 'package:smart_expense_tracker_app/models/transaction_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() {
  // 👇 Add this line FIRST
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = join(await databaseFactory.getDatabasesPath(), 'transactions.db');
    if (File(dbPath).existsSync()) {
      File(dbPath).deleteSync();
    }

    await DBHelper.database;
  });

  tearDown(() async {
    final db = await DBHelper.database;
    await db.delete('transactions');
    await db.delete('budgets');
  });

  // ✅ All your tests remain the same
  test('Insert and retrieve transaction', () async {
    final txn = TransactionModel(
      title: 'Test Income',
      amount: 5000.0,
      category: 'Salary',
      date: DateTime.now(),
      isIncome: true,
    );

    await DBHelper.insertTransaction(txn);
    final txns = await DBHelper.getAllTransactions();

    expect(txns.length, 1);
    expect(txns.first.title, 'Test Income');
  });

  test('Update transaction', () async {
    final txn = TransactionModel(
      title: 'Groceries',
      amount: 1500.0,
      category: 'Food',
      date: DateTime.now(),
      isIncome: false,
    );

    final id = await DBHelper.insertTransaction(txn);

    final updatedTxn = TransactionModel(
      id: id,
      title: 'Groceries Updated',
      amount: 2000.0,
      category: 'Food',
      date: DateTime.now(),
      isIncome: false,
    );

    await DBHelper.updateTransaction(updatedTxn);
    final all = await DBHelper.getAllTransactions();

    expect(all.first.title, 'Groceries Updated');
    expect(all.first.amount, 2000.0);
  });

  test('Delete transaction', () async {
    final txn = TransactionModel(
      title: 'Electricity Bill',
      amount: 800.0,
      category: 'Utilities',
      date: DateTime.now(),
      isIncome: false,
    );

    final id = await DBHelper.insertTransaction(txn);
    await DBHelper.deleteTransaction(id);

    final txns = await DBHelper.getAllTransactions();
    expect(txns.isEmpty, true);
  });

  test('Insert and retrieve budget', () async {
    final budget = BudgetModel(category: 'Food', limit: 3000.0);
    await DBHelper.upsertBudget(budget);

    final budgets = await DBHelper.getAllBudgets();
    expect(budgets.length, 1);
    expect(budgets.first.category, 'Food');
  });

  test('Update existing budget with upsert', () async {
    await DBHelper.upsertBudget(BudgetModel(category: 'Travel', limit: 2000.0));
    await DBHelper.upsertBudget(BudgetModel(category: 'Travel', limit: 2500.0));

    final updated = await DBHelper.getBudgetForCategory('Travel');
    expect(updated!.limit, 2500.0);
  });

  test('Export transactions to CSV', () async {
    final txn = TransactionModel(
      title: 'Test Export',
      amount: 1000.0,
      category: 'Misc',
      date: DateTime.now(),
      isIncome: true,
    );

    await DBHelper.insertTransaction(txn);
    final path = await DBHelper.exportTransactionsToCsv();

    final file = File(path);
    expect(file.existsSync(), true);

    final content = await file.readAsString();
    expect(content.contains('Test Export'), true);
  });
}
