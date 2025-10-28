import 'package:flutter_riverpod/legacy.dart';
import '../db/db_helper.dart';
import '../models/transaction_model.dart';

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionNotifier() : super([]) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = await DBHelper.getAllTransactions();
  }

  Future<void> addTransaction(TransactionModel txn) async {
    await DBHelper.insertTransaction(txn);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await DBHelper.deleteTransaction(id);
    await loadTransactions();
  }

  Future<void> updateTransaction(TransactionModel txn) async {
    await DBHelper.updateTransaction(txn);
    await loadTransactions();
  }

  Future<void> restoreTransaction(TransactionModel txn) async {
    await DBHelper.insertTransaction(txn);
    await loadTransactions();
  }

  double get totalIncome =>
      state.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense =>
      state.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  /// Group expenses by category for chart
  Map<String, double> get expensesByCategory {
    final Map<String, double> data = {};
    for (var t in state.where((t) => !t.isIncome)) {
      data[t.category] = (data[t.category] ?? 0) + t.amount;
    }
    return data;
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<TransactionModel>>(
      (ref) => TransactionNotifier(),
    );
