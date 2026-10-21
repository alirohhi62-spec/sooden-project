import 'dart:async';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// فرستادن و گرفتن پیامک از راه خود اندروید (MainActivity.kt)
class Sim12Sms {
  static const MethodChannel _ch = MethodChannel('sooden/sms');
  static const EventChannel _in = EventChannel('sooden/sms_in');

  static Stream<Map<String, String>>? _stream;

  /// پیامک‌های رسیده: {from, body}
  static Stream<Map<String, String>> get incoming {
    _stream ??= _in.receiveBroadcastStream().map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return {'from': '${m['from'] ?? ''}', 'body': '${m['body'] ?? ''}'};
    }).handleError((_) {}).asBroadcastStream();
    return _stream!;
  }

  static Future<bool> ensurePermission() async {
    try {
      final s = await [Permission.sms].request();
      return s[Permission.sms]?.isGranted ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> send(String number, String text) async {
    if (!await ensurePermission()) return false;
    try {
      final r = await _ch.invokeMethod<bool>('send', {'to': number, 'text': text});
      return r ?? false;
    } catch (_) {
      return false;
    }
  }
}
