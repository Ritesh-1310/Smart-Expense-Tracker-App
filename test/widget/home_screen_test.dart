import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker_app/db/db_helper.dart';
import 'package:smart_expense_tracker_app/models/budget_model.dart';
import 'package:smart_expense_tracker_app/models/transaction_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Home Screen DB Operations', () {
    test('Insert, Get, Update, and Delete Transactions', () async {
      final txn = TransactionModel(
        id: null,
        title: 'Test Transaction',
        amount: 100.5,
        category: 'Food',
        isIncome: false,
        date: DateTime.now(),
      );

      final insertId = await DBHelper.insertTransaction(txn);
      expect(insertId, isNonZero);

      final txns = await DBHelper.getAllTransactions();
      expect(txns.isNotEmpty, true);
      expect(txns.first.title, 'Test Transaction');

      final updatedTxn = TransactionModel(
        id: txns.first.id,
        title: 'Updated Transaction',
        amount: 200.0,
        category: 'Food',
        isIncome: true,
        date: txns.first.date,
      );

      final updatedRows = await DBHelper.updateTransaction(updatedTxn);
      expect(updatedRows, 1);

      final deletedRows = await DBHelper.deleteTransaction(txns.first.id!);
      expect(deletedRows, 1);
    });

    test('Insert and Get Budgets', () async {
      final budget = BudgetModel(
        id: null,
        category: 'Entertainment',
        limit: 5000.0,
      );

      final insertId = await DBHelper.upsertBudget(budget);
      expect(insertId, isNonZero);

      final budgets = await DBHelper.getAllBudgets();
      expect(budgets.isNotEmpty, true);
      expect(budgets.first.category, 'Entertainment');

      final deletedRows = await DBHelper.deleteBudget(budgets.first.id!);
      expect(deletedRows, 1);
    });

    test('Export transactions to CSV', () async {
      await DBHelper.insertTransaction(TransactionModel(
        id: null,
        title: 'CSV Test 1',
        amount: 50,
        category: 'Misc',
        isIncome: false,
        date: DateTime.now(),
      ));

      await DBHelper.insertTransaction(TransactionModel(
        id: null,
        title: 'CSV Test 2',
        amount: 100,
        category: 'Food',
        isIncome: true,
        date: DateTime.now(),
      ));

      final csvPath = await DBHelper.exportTransactionsToCsv();
      final file = File(csvPath);
      expect(file.existsSync(), true);

      final content = await file.readAsString();
      expect(content.contains('CSV Test 1'), true);
      expect(content.contains('CSV Test 2'), true);
    });
  });
}
