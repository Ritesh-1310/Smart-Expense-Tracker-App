import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker_app/models/transaction_model.dart';
import 'package:smart_expense_tracker_app/providers/transaction_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite FFI before any database operations
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('TransactionNotifier initial state is empty', () async {
    final notifier = TransactionNotifier();
    expect(notifier.state.isEmpty, true);
  });

  test('Add transaction updates state', () async {
    final notifier = TransactionNotifier();

    final txn = TransactionModel(
      title: 'Salary',
      amount: 5000,
      category: 'Income',
      date: DateTime.now(),
      isIncome: true,
    );

    await notifier.addTransaction(txn);

    expect(notifier.state.isNotEmpty, true);
    expect(notifier.state.first.title, 'Salary');
    expect(notifier.state.first.isIncome, true);
  });

  test('Delete transaction updates state', () async {
    final notifier = TransactionNotifier();

    final txn = TransactionModel(
      title: 'Groceries',
      amount: 1000,
      category: 'Food',
      date: DateTime.now(),
      isIncome: false,
    );

    await notifier.addTransaction(txn);
    final idToDelete = notifier.state.first.id!;

    await notifier.deleteTransaction(idToDelete);

    expect(
      notifier.state.any((t) => t.id == idToDelete),
      false,
    );
  });

  test('Total income, expense and balance calculated correctly', () async {
    final notifier = TransactionNotifier();

    await notifier.addTransaction(TransactionModel(
      title: 'Freelance',
      amount: 8000,
      category: 'Work',
      date: DateTime.now(),
      isIncome: true,
    ));

    await notifier.addTransaction(TransactionModel(
      title: 'Shopping',
      amount: 2000,
      category: 'Clothes',
      date: DateTime.now(),
      isIncome: false,
    ));

    expect(notifier.totalIncome, greaterThan(0));
    expect(notifier.totalExpense, greaterThan(0));
    expect(notifier.balance, notifier.totalIncome - notifier.totalExpense);
  });
}
