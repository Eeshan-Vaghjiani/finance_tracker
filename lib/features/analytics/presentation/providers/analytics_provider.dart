import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/category_expense_model.dart';
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
