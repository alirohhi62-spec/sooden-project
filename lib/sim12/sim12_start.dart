import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../core/utils/loc_store.dart';
import 'sim12_controller.dart';

/// شروع اپ وقتی آخرین پنل، پنل سیمکارتی بوده و وای‌فای پنل در دسترس نیست:
/// پرسیده می‌شود با سیمکارت (پیامک) ادامه دهد؛ بار اول توضیح تأخیر پیامک؛ بعد وضعیت پنل با پیامک پرسیده می‌شود.
class Sim12Start {
  static const _kInfo = 'sim12_sms_info_seen';
  static const Color _bg = Color(0xFF2A2B30), _text = Color(0xFFF2F2F4), _muted = Color(0xFFB9BAC2), _amber = Color(0xFFE0A800);

  static bool lastWasSim12() {
    try {
      return LocStore.read<bool>('panel12_last_sim12') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Widget _dlg(String title, Widget body, List<Widget> actions) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _bg,
          title: Text(title, style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
          content: body,
          actions: actions,
        ),
      );

  static void ask({required VoidCallback onYes, required VoidCallback onNo}) {
    Get.dialog(
      _dlg(
        'ادامه با وای‌فای امکان‌پذیر نیست',
        const Text('پنل سیمکارتی از راه وای‌فای در دسترس نیست.\nمی‌خواهی با سیمکارت (پیامک) ادامه دهی؟',
            style: TextStyle(color: _muted, fontSize: 14, height: 1.8)),
        [
          TextButton(
              onPressed: () {
                Get.back();
                onNo();
              },
              child: const Text('خیر')),
          TextButton(
              onPressed: () {
                Get.back();
                _number(onYes);
              },
              child: const Text('ادامه با سیمکارت', style: TextStyle(color: _amber))),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// شماره‌ی سیمکارت پنل، اگر هنوز وارد نشده
  static void _number(VoidCallback onYes) {
    final c = Sim12Controller.instance;
    if (c.panelNumber.value.isNotEmpty) return _info(onYes);
    final t = TextEditingController();
    Get.dialog(
      _dlg(
        'شماره سیمکارت پنل',
        TextField(
          controller: t,
          autofocus: true,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          style: const TextStyle(color: _text, fontSize: 18),
          decoration: const InputDecoration(hintText: '09xxxxxxxxx', hintStyle: TextStyle(color: _muted)),
        ),
        [
          TextButton(
              onPressed: () {
                final n = t.text.replaceAll(RegExp(r'[^0-9+]'), '');
                if (n.length < 10) return;
                c.setPanelNumber(n);
                Get.back();
                _info(onYes);
              },
              child: const Text('ادامه', style: TextStyle(color: _amber))),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// بار اول: توضیح پیامک؛ بعد وضعیت پنل پرسیده می‌شود
  static void _info(VoidCallback onYes) {
    bool seen = false;
    try {
      seen = (GetStorage().read(_kInfo) as bool?) ?? false;
    } catch (_) {}
    void go() {
      onYes();
      final c = Sim12Controller.instance;
      c.updateLink();
      c.refresh(); // پیامکی: #STATUS
    }

    if (seen) return go();
    Get.dialog(
      _dlg(
        'ارتباط با پیامک',
        const Text(
            'وضعیت‌ها و فرمان‌ها از راه پیامک به سیمکارت پنل فرستاده می‌شود و ممکن است کمی با تأخیر همراه باشد.\n'
            'همین الان آخرین وضعیت پنل پرسیده می‌شود. هر وقت وای‌فای پنل در دسترس شد، اپ خودش به وای‌فای برمی‌گردد.',
            style: TextStyle(color: _muted, fontSize: 14, height: 1.8)),
        [
          TextButton(
              onPressed: () {
                try {
                  GetStorage().write(_kInfo, true);
                } catch (_) {}
                Get.back();
                go();
              },
              child: const Text('متوجه شدم', style: TextStyle(color: _amber))),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
