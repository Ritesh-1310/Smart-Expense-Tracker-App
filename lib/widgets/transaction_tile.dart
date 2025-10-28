import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel txn;
  const TransactionTile({super.key, required this.txn});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: txn.isIncome ? Colors.green : Colors.red,
        child: Icon(
          txn.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: Colors.white,
        ),
      ),
      title: Text(txn.title),
      subtitle: Text(txn.category),
      trailing: Text(
        '${txn.isIncome ? '+ ' : '- '}₹${txn.amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: txn.isIncome ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
