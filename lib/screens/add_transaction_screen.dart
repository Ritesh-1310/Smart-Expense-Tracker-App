import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? existingTxn;
  const AddTransactionScreen({super.key, this.existingTxn});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  String category = 'Food';
  bool isIncome = false;

  final List<String> categories = ['Food', 'Travel', 'Bills', 'Shopping', 'Other'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingTxn?.title ?? '');
    _amountController =
        TextEditingController(text: widget.existingTxn?.amount.toString() ?? '');
    category = widget.existingTxn?.category ?? 'Food';
    isIncome = widget.existingTxn?.isIncome ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.existingTxn == null ? 'Add Transaction' : 'Edit Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  if (double.tryParse(v) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => category = v!),
              ),
              SwitchListTile(
                title: const Text('Income'),
                value: isIncome,
                onChanged: (v) => setState(() => isIncome = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final txn = TransactionModel(
                      id: widget.existingTxn?.id,
                      title: _titleController.text.trim(),
                      amount: double.parse(_amountController.text.trim()),
                      category: category,
                      isIncome: isIncome,
                      date: DateTime.now(),
                    );

                    if (widget.existingTxn == null) {
                      await ref.read(transactionProvider.notifier).addTransaction(txn);
                    } else {
                      await ref.read(transactionProvider.notifier).updateTransaction(txn);
                    }

                    if (mounted) Navigator.pop(context);
                  }
                },
                child: Text(widget.existingTxn == null ? 'Add' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
