import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../data/repositories/firebase_transaction_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return FirebaseTransactionRepository();
});

final userTransactionsProvider = StreamProvider<List<TransactionEntity>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.id;

  if (userId == null || userId.isEmpty) {
    return Stream.value([]);
  }

  return ref.read(transactionRepositoryProvider).getUserTransactions(userId);
});

class TransactionController extends AsyncNotifier<void> {
  late final TransactionRepository _repository;

  @override
  Future<void> build() async {
    _repository = ref.watch(transactionRepositoryProvider);
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addTransaction(transaction);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTransaction(TransactionEntity transaction) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTransaction(transaction);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTransaction(transactionId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final transactionControllerProvider = AsyncNotifierProvider<TransactionController, void>(() {
  return TransactionController();
});

// Additional computed providers for Dashboard metrics
final totalBalanceProvider = Provider<double>((ref) {
  final transactions = ref.watch(userTransactionsProvider).value ?? [];
  return transactions.fold(0.0, (sum, tx) {
    return tx.type == TransactionType.income ? sum + tx.amount : sum - tx.amount;
  });
});

final totalIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(userTransactionsProvider).value ?? [];
  return transactions
      .where((tx) => tx.type == TransactionType.income)
      .fold(0.0, (sum, tx) => sum + tx.amount);
});

final totalExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(userTransactionsProvider).value ?? [];
  return transactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold(0.0, (sum, tx) => sum + tx.amount);
});
