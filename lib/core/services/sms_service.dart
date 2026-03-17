import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();

  Future<bool> requestPermissions() async {
    final permission = await Permission.sms.request();
    return permission.isGranted;
  }

  Future<List<SmsMessage>> getMPesaMessages() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return [];

    // Filter messages from MPESA
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      address: 'MPESA',
    );

    return messages;
  }
}
