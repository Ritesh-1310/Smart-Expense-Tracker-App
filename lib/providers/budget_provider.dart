import 'package:flutter_riverpod/legacy.dart';
import '../db/db_helper.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';

class BudgetNotifier extends StateNotifier<List<BudgetModel>> {
  BudgetNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    state = await DBHelper.getAllBudgets();
  }

  Future<void> setBudget(String category, double limit) async {
    final b = BudgetModel(category: category, limit: limit);
    await DBHelper.upsertBudget(b);
    await load();
  }

  BudgetModel? forCategory(String category) {
    try {
      return state.firstWhere((b) => b.category == category);
    } catch (_) {
      return null;
    }
  }

  double spent(String category, List<TransactionModel> transactions) {
    return transactions
        .where((t) => t.category == category && !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// 'no_budget', 'ok', 'warning', 'over'
  String status(String category, List<TransactionModel> transactions) {
    final b = forCategory(category);
    if (b == null) return 'no_budget';
    final s = spent(category, transactions);
    if (s > b.limit) return 'over';
    if (s >= 0.9 * b.limit) return 'warning';
    return 'ok';
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, List<BudgetModel>>(
  (ref) => BudgetNotifier(),
);
