import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(categoryExpensesProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final totalExpense = expenses.fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: expenses.isEmpty
          ? const Center(child: Text('No expense data available.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Expenses by Category',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        sections: _generateChartSections(expenses, totalExpense),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final item = expenses[index];
                      final percentage = (item.amount / totalExpense) * 100;
                      return ListTile(
                        leading: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getColorForIndex(index),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(item.category),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currencyFormat.format(item.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  List<PieChartSectionData> _generateChartSections(List<dynamic> expenses, double total) {
    return List.generate(expenses.length, (i) {
      final item = expenses[i];
      final percentage = (item.amount / total) * 100;

      return PieChartSectionData(
        color: _getColorForIndex(i),
        value: item.amount,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Color _getColorForIndex(int index) {
    final colors = <Color>[
      const Color(0xFF2563EB), // Blue
      const Color(0xFF059669), // Emerald
      const Color(0xFFD97706), // Amber
      const Color(0xFFDC2626), // Red
      const Color(0xFF0891B2), // Cyan
      const Color(0xFFEA580C), // Orange
      const Color(0xFF475569), // Slate
      const Color(0xFF65A30D), // Lime
    ];
    return colors[index % colors.length];
  }
}
