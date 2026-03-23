import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/sms_service.dart';
import '../../../../core/utils/mpesa_parser.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

final smsServiceProvider = Provider<SmsService>((ref) {
  return SmsService();
});

class SyncMpesaNotifier extends AsyncNotifier<List<TransactionEntity>> {
  @override
  Future<List<TransactionEntity>> build() async {
    return [];
  }

  Future<void> syncMessages() async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        state = AsyncValue.error('User not logged in', StackTrace.current);
        return;
      }

      final smsService = ref.read(smsServiceProvider);
      final messages = await smsService.getMPesaMessages();

      List<TransactionEntity> addedTransactions = [];
      final txController = ref.read(transactionControllerProvider.notifier);

      for (var msg in messages.take(10)) {
        if (msg.body != null) {
          final tx = MPesaParser.parseMessage(msg.body!, user.id);
          if (tx != null) {
            await txController.addTransaction(tx);
            addedTransactions.add(tx);
          }
        }
      }

      state = AsyncValue.data(addedTransactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final syncMpesaProvider = AsyncNotifierProvider<SyncMpesaNotifier, List<TransactionEntity>>(() {
  return SyncMpesaNotifier();
});
