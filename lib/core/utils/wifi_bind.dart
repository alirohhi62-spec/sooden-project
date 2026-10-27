import 'package:flutter/services.dart';

import 'globals.dart';

/// وای‌فای پنل اینترنت ندارد و اندروید با داده‌ی همراه روشن ارتباط را از داده می‌فرستد:
/// وقتی گوشی روی وای‌فای پنل یا مودم همان مکان است، ارتباط این اپ به وای‌فای بسته می‌شود.
/// بقیه‌ی برنامه‌های گوشی دست نمی‌خورند؛ بیرون از منزل آزاد می‌شود.
class WifiBind {
  WifiBind._();
  static const _ch = MethodChannel('sooden/sms');
  /// هر بار دوباره اعمال می‌شود (شبکه‌ی وای‌فای ممکن است عوض شده باشد)؛ عوض شدن وای‌فای را خود اندروید هم دنبال می‌کند
  static Future<void> set(bool on) async {
    try {
      final ok = await _ch.invokeMethod<bool>('bindWifi', {'on': on});
      doLogGlobal('wifi_bind', 'set', 'on $on -> $ok');
    } catch (_) {}
  }
}
