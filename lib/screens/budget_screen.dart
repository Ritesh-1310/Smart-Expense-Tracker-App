import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/budget_provider.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  double _limit = 0;
  String _category = 'Food';
  final categories = ['Food', 'Travel', 'Bills', 'Shopping', 'Other'];

  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(budgetProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(children: [
                DropdownButtonFormField<String>(
                  value: _category,
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                TextFormField(
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monthly limit (e.g. 5000)'),
                  validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter valid number' : null,
                  onSaved: (v) => _limit = double.parse(v!),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    _formKey.currentState!.save();
                    await ref.read(budgetProvider.notifier).setBudget(_category, _limit);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Budget saved')));
                  },
                  child: const Text('Save budget'),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            const Text('Existing budgets', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (budgets.isEmpty) const Text('No budgets set'),
            ...budgets.map((b) => ListTile(
                  title: Text(b.category),
                  trailing: Text('₹${b.limit.toStringAsFixed(2)}'),
                )),
          ],
        ),
      ),
    );
  }
}
