import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/sms_service.dart';
import '../../../../core/utils/mpesa_parser.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final smsServiceProvider = Provider<SmsService>((ref) {
  return SmsService();
});

class SyncMpesaNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    return 0;
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
      
      int addedCount = 0;
      final txController = ref.read(transactionControllerProvider.notifier);
      
      for (var msg in messages.take(10)) {
        if (msg.body != null) {
          final tx = MPesaParser.parseMessage(msg.body!, user.id);
          if (tx != null) {
            await txController.addTransaction(tx);
            addedCount++;
          }
        }
      }

      state = AsyncValue.data(addedCount);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final syncMpesaProvider = AsyncNotifierProvider<SyncMpesaNotifier, int>(() {
  return SyncMpesaNotifier();
});
