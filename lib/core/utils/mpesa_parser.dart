import '../../features/transactions/domain/entities/transaction_entity.dart';
import 'package:uuid/uuid.dart';

class MPesaParser {
  // Typical MPESA receipt example: 
  // OGF4A1B2C3 Confirmed. Ksh1,500.00 paid to KPLC PREPAID. on 12/5/20 at 10:14 AM.New MPESA balance is Ksh4,500.00.
  // 
  // We will build a regex to capture amount, recipient/sender, date for basic parsing.
  
  static final RegExp sendMoneyRegex = RegExp(r'Ksh([0-9,.]+)\s+paid\s+to\s+(.+?)\.?\s+on\s+(\d{1,2}/\d{1,2}/\d{2})\s+at\s+(\d{1,2}:\d{2}\s+[AP]M)');
  static final RegExp receiveMoneyRegex = RegExp(r'You\s+have\s+received\s+Ksh([0-9,.]+)\s+from\s+(.+?)\s+on\s+(\d{1,2}/\d{1,2}/\d{2})\s+at\s+(\d{1,2}:\d{2}\s+[AP]M)');
  static final RegExp payBillRegex = RegExp(r'Ksh([0-9,.]+)\s+paid\s+to\s+(.+?)\.\s+on\s+(\d{1,2}/\d{1,2}/\d{2})');

  static TransactionEntity? parseMessage(String body, String userId) {
    // Send Money / PayBill (Expense)
    var match = sendMoneyRegex.firstMatch(body) ?? payBillRegex.firstMatch(body);
    if (match != null) {
      double amount = _parseAmount(match.group(1));
      String recipient = match.group(2)?.trim() ?? 'Unknown';
      
      return TransactionEntity(
        id: const Uuid().v4(),
        userId: userId,
        amount: amount,
        type: TransactionType.expense,
        category: 'MPesa (Auto)',
        note: 'To: $recipient',
        date: DateTime.now(), // Approximate to today since full parsing requires complex date building
        createdAt: DateTime.now(),
      );
    }

    // Receive Money (Income)
    match = receiveMoneyRegex.firstMatch(body);
    if (match != null) {
      double amount = _parseAmount(match.group(1));
      String sender = match.group(2)?.trim() ?? 'Unknown';

      return TransactionEntity(
        id: const Uuid().v4(),
        userId: userId,
        amount: amount,
        type: TransactionType.income,
        category: 'MPesa (Auto)',
        note: 'From: $sender',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  static double _parseAmount(String? val) {
    if (val == null) return 0.0;
    return double.tryParse(val.replaceAll(',', '')) ?? 0.0;
  }
}
