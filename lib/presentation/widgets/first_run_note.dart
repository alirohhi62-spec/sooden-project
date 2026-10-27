import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// پیام اولین اجرای اپ: نسخه‌ی اندروید لازم و آنچه برای وصل شدن به پنل لازم است (فقط یک بار)
class FirstRunNote {
  static const _key = 'first_run_note_v1';
  static const Color _bg = Color(0xFF15161B), _text = Color(0xFFF2F4F7), _muted = Color(0xB8F2F4F7), _red = Color(0xFFFF3B4E);

  static bool get shown {
    try {
      return GetStorage().read(_key) == true;
    } catch (_) {
      return true;
    }
  }

  /// نشان بده (اگر قبلاً نشان داده نشده) و بعد از «متوجه شدم» ادامه بده
  static Future<void>? _open;
  static Future<void> showOnce() {
    if (shown) return Future.value();
    return _open ??= _show();
  }

  static Future<void> _show() async {
    await Future.delayed(const Duration(milliseconds: 300));   // not inside a build
    await Get.dialog(const FirstRunNoteView(), barrierDismissible: false);
    try {
      GetStorage().write(_key, true);
    } catch (_) {}
  }
}

class FirstRunNoteView extends StatelessWidget {
  const FirstRunNoteView({super.key});

  static Widget _row(IconData i, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(i, color: FirstRunNote._red, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: const TextStyle(color: FirstRunNote._text, fontSize: 13.5, height: 1.75))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: FirstRunNote._bg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26), side: const BorderSide(color: Color(0x29FFFFFF))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('پیش از شروع', style: TextStyle(color: FirstRunNote._text, fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('برای اینکه اپ بتواند به پنل وصل شود:', style: TextStyle(color: FirstRunNote._muted, fontSize: 13)),
            const SizedBox(height: 14),
            _row(Icons.phone_android, 'گوشی باید اندروید ۹ یا بالاتر داشته باشد.'),
            _row(Icons.location_on_outlined,
                '«موقعیت مکانی (GPS)» گوشی روشن باشد و به اپ اجازه‌ی موقعیت بدهید. اندروید بدون این اجازه اسم وای‌فای را به اپ نمی‌گوید و اپ نمی‌فهمد گوشی کنار کدام پنل است.'),
            _row(Icons.wifi,
                'بار اول گوشی را به وای‌فای پنل (sooden-…) وصل کنید. اگر وای‌فای پنل دیده نمی‌شود، کلید وای‌فای پنل (در بیشتر پنل‌ها سناریوی سمت راست) را ۵ تا ۷ ثانیه نگه دارید.'),
            _row(Icons.signal_wifi_statusbar_connected_no_internet_4,
                'اگر گوشی گفت «این وای‌فای اینترنت ندارد»، گزینه‌ی «وصل بمان» (یا «بله») را بزنید؛ وای‌فای پنل اینترنت ندارد.'),
            const SizedBox(height: 4),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Get.back(),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(colors: [Color(0xFFFF4B5C), Color(0xFFE0283C)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                ),
                child: const Text('متوجه شدم', style: TextStyle(color: FirstRunNote._text, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
