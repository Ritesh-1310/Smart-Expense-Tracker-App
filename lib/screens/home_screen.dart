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
    final budgets = ref.watch(budgetProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Smart Expense Tracker'),
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
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
                    await Share.shareXFiles(
                      [XFile(path)],
                      text: 'Smart Expense Tracker - Transactions CSV',
                    );
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
              _menuItem(Icons.account_balance_wallet_outlined, 'Manage Budgets', 'budget'),
              _menuItem(Icons.upload_file_rounded, 'Export to CSV', 'export'),
              _menuItem(Icons.brightness_6_rounded, 'Toggle Theme', 'theme'),
            ],
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryCards(txnNotifier, theme),
            const SizedBox(height: 20),
            _buildChartSection(),
            const SizedBox(height: 20),
            _buildTransactionList(context, ref, txns, txnNotifier, budgets, isDark),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text("Add Transaction"),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(IconData icon, String text, String value) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(TransactionNotifier txnNotifier, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final cardStyle = BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: colorScheme.primaryContainer.withOpacity(0.08),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _summaryCard('Income', txnNotifier.totalIncome, Colors.green, cardStyle),
        _summaryCard('Expense', txnNotifier.totalExpense, Colors.red, cardStyle),
        _summaryCard('Balance', txnNotifier.balance, Colors.teal, cardStyle),
      ],
    );
  }

  Widget _summaryCard(String title, double amount, Color color, BoxDecoration style) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: style,
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                '₹${amount.toStringAsFixed(0)}',
                key: ValueKey(amount),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: ExpenseChart(),
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    WidgetRef ref,
    List txns,
    TransactionNotifier txnNotifier,
    List<BudgetModel> budgets,
    bool isDark,
  ) {
    if (txns.isEmpty) {
      return const Center(
        child: Text(
          'No transactions yet.\nTap + to add one!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: txns.length,
      itemBuilder: (context, index) {
        final t = txns[index];
        final spent = txnNotifier.expensesByCategory[t.category] ?? 0.0;
        final b = budgets.firstWhere(
          (x) => x.category == t.category,
          orElse: () => BudgetModel(id: null, category: t.category, limit: 0),
        );

        final limit = b.limit;
        final usage = limit == 0 ? 0 : spent / limit;
        final overBudget = usage > 1.0;
        final nearLimit = usage >= 0.9 && usage <= 1.0;

        Color subtitleColor = overBudget
            ? Colors.red
            : nearLimit
                ? Colors.orange
                : isDark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600;

        // ✅ Swipe-to-delete with Undo
        return Dismissible(
          key: Key(t.id.toString()),
          background: Container(
            color: Colors.red.shade300,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.startToEnd,
          onDismissed: (_) async {
            final deletedTxn = t;

            // Delete from DB
            await ref.read(transactionProvider.notifier).deleteTransaction(deletedTxn.id!);

            // Show snackbar with Undo option
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Transaction deleted'),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'UNDO',
                  onPressed: () async {
                    try {
                      await ref
                          .read(transactionProvider.notifier)
                          .restoreTransaction(deletedTxn);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction restored')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error restoring: $e')),
                      );
                    }
                  },
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    t.isIncome ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                child: Icon(
                  t.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: t.isIncome ? Colors.green : Colors.red,
                ),
              ),
              title: Text(
                t.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
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
                  builder: (_) => AddTransactionScreen(existingTxn: t),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
