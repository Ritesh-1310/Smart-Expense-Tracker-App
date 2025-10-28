import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../providers/transaction_provider.dart';

class ExpenseChart extends ConsumerWidget {
  const ExpenseChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);

    // Filter only expenses (not income)
    final expenses = transactions.where((t) => !t.isIncome).toList();

    if (expenses.isEmpty) {
      return const Center(child: Text('No expenses yet'));
    }

    // Group by category
    final Map<String, double> dataMap = {};
    for (var t in expenses) {
      dataMap[t.category] = (dataMap[t.category] ?? 0) + t.amount;
    }

    final data = dataMap.entries
        .map((e) => _ChartData(e.key, e.value))
        .toList();

    return SizedBox(
      height: 260,
      child: SfCircularChart(
        title: const ChartTitle(text: 'Expenses by Category'),
        legend: const Legend(isVisible: true, position: LegendPosition.bottom),
        series: <PieSeries<_ChartData, String>>[
          PieSeries<_ChartData, String>(
            dataSource: data,
            xValueMapper: (_ChartData d, _) => d.category,
            yValueMapper: (_ChartData d, _) => d.amount,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
            enableTooltip: true,
            animationDuration: 1000,
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String category;
  final double amount;
  _ChartData(this.category, this.amount);
}
