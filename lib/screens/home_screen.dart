import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../db/db_helper.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/expense_chart.dart';
import 'add_transaction_screen.dart';
import 'budget_screen.dart';
import '../models/budget_model.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(transactionProvider);
    final txnNotifier = ref.watch(transactionProvider.notifier);

    // watch budgets (user-set) from DB
    final budgets = ref.watch(budgetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Expense Tracker'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'budget':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BudgetScreen()),
                  );
                  break;
                case 'export':
                  try {
                    final path = await DBHelper.exportTransactionsToCsv();
                    await Share.shareXFiles([
                      XFile(path),
                    ], text: 'Smart Expense Tracker - Transactions CSV');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transactions exported successfully!'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error exporting CSV: $e')),
                    );
                  }
                  break;
                case 'theme':
                  onToggleTheme();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'budget',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Manage Budgets'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.upload_file_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Export to CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.brightness_6_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Toggle Light/Dark Mode'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryTile(
                      'Income',
                      txnNotifier.totalIncome,
                      Colors.green,
                    ),
                    _summaryTile(
                      'Expense',
                      txnNotifier.totalExpense,
                      Colors.red,
                    ),
                    _summaryTile('Balance', txnNotifier.balance, Colors.teal),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const ExpenseChart(),
            const SizedBox(height: 10),
            Expanded(
              child: txns.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions yet.\nTap + to add one!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: txns.length,
                      itemBuilder: (context, index) {
                        final t = txns[index];

                        // compute spent for the category using transactions provider
                        final spent =
                            txnNotifier.expensesByCategory[t.category] ?? 0.0;

                        // find user's budget for this category (if any)
                        final BudgetModel? b = budgets.isEmpty
                            ? null
                            : budgets.firstWhere(
                                (x) => x.category == t.category,
                                orElse: () => BudgetModel(
                                  id: null,
                                  category: t.category,
                                  limit: 0,
                                ),
                              );

                        final limit = b?.limit ?? 0.0;
                        final usage = (limit <= 0.0) ? 0.0 : (spent / limit);

                        // color logic: over (>1.0) red, near (>=0.9) orange, ok green/neutral
                        final overBudget = usage > 1.0;
                        final nearLimit = usage >= 0.9 && usage <= 1.0;

                        Color subtitleColor;
                        if (overBudget) {
                          subtitleColor = Colors.red;
                        } else if (nearLimit) {
                          subtitleColor = Colors.orange;
                        } else {
                          subtitleColor = Colors.grey.shade600;
                        }

                        return Dismissible(
                          key: Key(t.id.toString()),
                          background: Container(
                            color: Colors.red.shade300,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          direction: DismissDirection.startToEnd,
                          onDismissed: (_) {
                            ref
                                .read(transactionProvider.notifier)
                                .deleteTransaction(t.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Transaction deleted'),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  onPressed: () {
                                    ref
                                        .read(transactionProvider.notifier)
                                        .addTransaction(t);
                                  },
                                ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 1,
                            child: ListTile(
                              title: Text(
                                t.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${t.category} • ${t.date.toLocal().toString().split(' ')[0]}',
                                style: TextStyle(color: subtitleColor),
                              ),
                              trailing: Text(
                                '${t.isIncome ? '+' : '-'}₹${t.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: t.isIncome ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddTransactionScreen(existingTxn: t),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _summaryTile(String title, double value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
