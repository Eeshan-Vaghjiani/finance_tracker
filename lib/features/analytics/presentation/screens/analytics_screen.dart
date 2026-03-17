import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/monthly_analytics_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(categoryExpensesProvider);
    final monthlyData = ref.watch(monthlyAnalyticsProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final totalExpense = expenses.fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMonthlyBarChart(monthlyData, context),
            
            if (expenses.isNotEmpty) ...[
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
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No categorical expense data available.'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBarChart(List<MonthlyAnalytics> monthlyData, BuildContext context) {
    if (monthlyData.isEmpty) return const SizedBox.shrink();

    double maxY = 0;
    for (var d in monthlyData) {
      if (d.income > maxY) maxY = d.income;
      if (d.expense > maxY) maxY = d.expense;
    }
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Income vs Expenses',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final isIncome = rodIndex == 0;
                    final format = NumberFormat.compactCurrency(symbol: '\$');
                    return BarTooltipItem(
                      '${isIncome ? 'Income' : 'Expense'}\n${format.format(rod.toY)}',
                      TextStyle(
                        color: isIncome ? AppColors.income : AppColors.expense,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= monthlyData.length) return const SizedBox.shrink();
                      final parts = monthlyData[index].monthYear.split('-');
                      if (parts.length != 2) return const SizedBox.shrink();
                      final monthInt = int.tryParse(parts[1]) ?? 1;
                      final monthStr = DateFormat('MMM').format(DateTime(2000, monthInt));
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(monthStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? maxY / 4 : 25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: monthlyData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data.income,
                      color: AppColors.income,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: data.expense,
                      color: AppColors.expense,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                  barsSpace: 4,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Income', AppColors.income),
            const SizedBox(width: 24),
            _buildLegendItem('Expense', AppColors.expense),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  List<PieChartSectionData> _generateChartSections(List<dynamic> expenses, double total) {
    return List.generate(expenses.length, (i) {
      final item = expenses[i];
      final percentage = (item.amount / total) * 100;
      
      final isSmall = percentage < 5;

      return PieChartSectionData(
        color: _getColorForIndex(i),
        value: item.amount,
        title: isSmall ? '' : '${percentage.toStringAsFixed(0)}%',
        radius: isSmall ? 50 : 60,
        showTitle: !isSmall,
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
