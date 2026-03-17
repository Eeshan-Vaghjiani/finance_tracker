import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/category_expense_model.dart';
import '../../../../shared/models/monthly_analytics_model.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

final categoryExpensesProvider = Provider<List<CategoryExpense>>((ref) {
  final transactions = ref.watch(userTransactionsProvider).value ?? [];
  
  final Map<String, double> categoryMap = {};

  final expenses = transactions.where((tx) => tx.type == TransactionType.expense);

  for (final tx in expenses) {
    if (categoryMap.containsKey(tx.category)) {
      categoryMap[tx.category] = categoryMap[tx.category]! + tx.amount;
    } else {
      categoryMap[tx.category] = tx.amount;
    }
  }

  final categoryExpenses = categoryMap.entries
      .map((entry) => CategoryExpense(category: entry.key, amount: entry.value))
      .toList();

  categoryExpenses.sort((a, b) => b.amount.compareTo(a.amount));

  return categoryExpenses;
});

final monthlyAnalyticsProvider = Provider<List<MonthlyAnalytics>>((ref) {
  final transactions = ref.watch(userTransactionsProvider).value ?? [];
  final map = <String, MonthlyAnalytics>{};

  for (final tx in transactions) {
    // Format to "MMM yyyy" (e.g. Set 2024), we will do strict logic later, better to use "yyyy-MM" for sorting then format
    final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';

    if (!map.containsKey(key)) {
      map[key] = MonthlyAnalytics(monthYear: key, income: 0, expense: 0);
    }
    
    final current = map[key]!;
    if (tx.type == TransactionType.income) {
       map[key] = MonthlyAnalytics(monthYear: key, income: current.income + tx.amount, expense: current.expense);
    } else {
       map[key] = MonthlyAnalytics(monthYear: key, income: current.income, expense: current.expense + tx.amount);
    }
  }

  final sortedKeys = map.keys.toList()..sort();
  // Take last 6 months for example
  final recentKeys = sortedKeys.length > 6 ? sortedKeys.sublist(sortedKeys.length - 6) : sortedKeys;
  
  return recentKeys.map((k) => map[k]!).toList();
});
