import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Stream<List<TransactionEntity>> getUserTransactions(String userId);
  
  Future<void> addTransaction(TransactionEntity transaction);
  
  Future<void> updateTransaction(TransactionEntity transaction);
  
  Future<void> deleteTransaction(String transactionId);
}
