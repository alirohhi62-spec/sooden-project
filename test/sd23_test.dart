// تست خودکار صفحه‌ی پنل‌های ۲۳ کلید (دزدگیردار و ۲۰ پل).
// هر پنل خودش را معرفی می‌کند و صفحه از روی پیام‌های همان پنل ساخته می‌شود.

import 'dart:convert';

import 'package:bms/core/utils/globals.dart';
import 'package:bms/panel12/panel12_controller.dart';
import 'package:bms/panel12/panel12_screen.dart';
import 'package:bms/sd23/sd23_controller.dart';
import 'package:bms/sd23/sd23_editor.dart';
import 'package:bms/sd23/sd23_screen.dart';
import 'package:bms/sd23/sd23_vacation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Future<void> _loadFonts() async {
  final loader = FontLoader('dana')
    ..addFont(rootBundle.load('assets/fonts/Dana_FaNum_Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Dana_FaNum_Bold.ttf'));
  await loader.load();
}

Widget _app(Widget tab) {
  return GetMaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'dana'),
    builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    home: Scaffold(
      body: Column(children: [
        Expanded(child: Stack(children: [tab])),
        Container(height: 56, color: const Color(0xFF202124)),
      ]),
    ),
  );
}

Future<void> _setup(WidgetTester tester) async {
  isLoggerEnable = false;
  await _loadFonts();
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
}

void main() {
  testWidgets('SD23 panels: own page from the panel, groups, alarm keypad, scenarios', (tester) async {
    await _setup(tester);
    final c = Panel12Controller.instance;
    final s = Sd23Controller.instance;

    await tester.pumpWidget(_app(Panel12TabHost(home: Container(color: Colors.white))));
    await tester.pump();

    // دزدگیردار ۱۴ پل وصل شد
    c.onRaw(utf8.encode(r'$MDL=SD23-a14-1.0$'));
    await tester.pump();
    expect(c.isSd23.value, isTrue);
    expect(c.isRf12.value, isFalse);
    expect(c.modelKnown.value, isTrue);
    expect(s.model.value, 'a14');
    expect(find.byType(Sd23Screen), findsOneWidget);
    expect(find.byType(Panel12Screen), findsNothing);

    c.onRaw(utf8.encode(r'$LAY#LLLLLLLLLLLLnc1234UWXEZ$$CAP#A1R1W1S1$$K#000005$$AL#2$'));
    c.onRaw(utf8.encode(r'$L01#16~لوستر پذیرایی$'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.lay.value, 'LLLLLLLLLLLLnc1234UWXEZ');
    expect(s.hasAlarm.value, isTrue);
    expect(s.hasSettings.value, isTrue);
    expect(s.tabs, [Sd23Controller.gPoles, Sd23Controller.gCurtain, Sd23Controller.gScn, Sd23Controller.gAlarm]);
    expect(s.isOn(0), isTrue);
    expect(s.isOn(1), isFalse);
    expect(s.alarm.value, 2);
    expect(s.maxDigit, 4);
    expect(s.labelOf(0), 'لوستر پذیرایی');
    expect(s.labelOf(2), 'چراغ ۳');
    expect(find.text('دزدگیردار ۱۴ پل'), findsOneWidget);
    expect(find.text('لوستر پذیرایی'), findsWidgets);
    expect(find.text('خاموش کردن همه'), findsOneWidget);

    // صفحه‌کلید دزدگیر
    s.tab.value = Sd23Controller.gAlarm;
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ON / OFF'), findsWidgets);
    await tester.tap(find.text('ON / OFF').last);
    await tester.pump();
    expect(s.entry.value, 'arm');
    await tester.tap(find.text('1').last);
    await tester.pump();
    expect(s.buf.value, '1');

    // لمس یک کلید روی تصویر پنل: زبانه‌ی همان کلید
    s.selectKey(18);
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.tab.value, Sd23Controller.gCurtain);
    expect(find.text('ایستاده'), findsOneWidget);

    // سناریوها با زمان از پنل
    c.onRaw(utf8.encode(r'$CF#21#0B#14#00#00#000000#000FFF#0000$'));
    s.tab.value = Sd23Controller.gScn;
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.cf[20]?.secs16, 20);
    expect(find.textContaining('خاموشی همه بعد از'), findsOneWidget);
    expect(find.text('EXIT'), findsWidgets);

    // پنل ۲۰ پل (فقط روشنایی) وصل شد: صفحه‌ی خودش
    c.onRaw(utf8.encode(r'$MDL=SD23-p20-1.0$'));
    c.onRaw(utf8.encode(r'$LAY#LLLL-LLLLLLLLLLLLLLLMTX$$CAP#A0R1W1S1$$K#000000$$AL#0$'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.model.value, 'p20');
    expect(s.hasAlarm.value, isFalse);
    expect(s.tabs, [Sd23Controller.gPoles, Sd23Controller.gScn]);
    expect(s.keysOf(Sd23Controller.gPoles).length, 19); // جای ۵ استفاده نمی‌شود
    expect(s.labelOf(0), 'چراغ ۱');
    expect(find.text('پنل ۲۰ پل'), findsOneWidget);
    expect(find.text('ON / OFF'), findsNothing);

    // پنل سفارشی: کولر آبی، پرده، سناریوی سفارشی و گروه
    c.onRaw(utf8.encode(r'$MDL=SD23-pc-1.0$'));
    c.onRaw(utf8.encode(r'$LAY#LLLLLLLLKFGLUWSSQLLLMXZ$$CAP#A0R1W1S1$$K#000200$'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.tabs, [Sd23Controller.gPoles, Sd23Controller.gCooler, Sd23Controller.gCurtain, Sd23Controller.gScn]);
    expect(s.coolerPairs, [
      [9, 10]
    ]);
    s.tab.value = Sd23Controller.gCooler;
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('کولر آبی'), findsOneWidget);
    expect(find.text('دور کند'), findsWidgets);
    c.onRaw(utf8.encode(r'$CF#15#0E#00#00#00#000003#00000C#0000$$CF#17#0F#00#00#00#000030#000000#0000$'));
    s.tab.value = Sd23Controller.gScn;
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.scnLine(14), contains('۲ پل روشن'));
    expect(s.scnLine(16), contains('۲ پل'));
    expect(find.text('ویرایش'), findsWidgets);

    // سناریوهای گوشی
    c.onRaw(utf8.encode(r'$S01#11222222222222222222F0010#شب بخیر$$S02#-$$PND#01F=0004#$'));
    await tester.pump();
    expect(s.phone[0]?.name, 'شب بخیر');
    expect(s.phone[0]?.tm, 'F');
    expect(s.phone[0]?.mins, 10);
    expect(s.phone[1], isNull);
    expect(s.pending[0], 'F4');

    // پنلی که بعداً با نسخه‌ی جدیدتر پروتکل ساخته شود
    c.onRaw(utf8.encode(r'$MDL=SD23-z30-2.0$'));
    await tester.pump();
    expect(s.tooNew.value, isTrue);
    expect(find.textContaining('جدیدتری'), findsOneWidget);

    // دوباره پنل RF-12
    c.onRaw(utf8.encode(r'$MDL=RF12-L10P1A1E1$'));
    await tester.pump();
    expect(c.isSd23.value, isFalse);
    expect(c.isRf12.value, isTrue);
    expect(find.byType(Sd23Screen), findsNothing);
    expect(find.byType(Panel12Screen), findsOneWidget);

    await tester.pump(const Duration(seconds: 30)); // زمان‌سنج‌ها تمام شوند
  });

  testWidgets('SD23 phone scenario tab and editor', (tester) async {
    await _setup(tester);
    final c = Panel12Controller.instance;
    final s = Sd23Controller.instance;
    c.onRaw(utf8.encode(r'$MDL=SD23-pc-1.0$'));
    c.onRaw(utf8.encode(r'$LAY#LLLLLLLLKFGLUWSSQLLLMXZ$$CAP#A0R1W1S1$$S01#11222222222222222222N0000#مهمان$'));
    await tester.pumpWidget(_app(const Sd23PhonePage()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('مهمان'), findsOneWidget);
    expect(find.text('سناریوی جدید'), findsOneWidget);
    await tester.tap(find.text('سناریوی جدید'));
    await tester.pumpAndSettle();
    expect(find.byType(Sd23MaskEditor), findsOneWidget);
    expect(find.text('ذخیره روی پنل'), findsOneWidget);
    expect(find.text('کولر'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('SD23 vacation page: program and clock from the panel', (tester) async {
    await _setup(tester);
    final c = Panel12Controller.instance;
    final s = Sd23Controller.instance;
    c.onRaw(utf8.encode(r'$MDL=SD23-pc-1.0$'));
    c.onRaw(utf8.encode(r'$LAY#LLLLLLLLKFGLUWSSQLLLMXZ$$CAP#A0R1W1S1$'));
    // برق رفته و ساعت پنل معلوم نیست؛ برنامه روی پنل هست
    c.onRaw(utf8.encode(r'$CLK#0$$V#1#09783#09784#3#118501003126000804153002008#159000000#0#-$'));
    await tester.pumpWidget(_app(const Sd23VacationPage()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.clockOk.value, isFalse);
    final v = s.vacation.value!;
    expect(v.steps.length, 3);
    expect(v.steps[0].t, 1185);
    expect(v.steps[0].has(0) && v.steps[0].has(1), isTrue);
    expect(v.steps[0].c, 'O');
    expect(v.steps[1].has(11), isTrue);
    expect(v.steps[2].t, 90);
    expect(v.steps[2].c, 'C');
    expect(v.te, 150);
    expect(v.nextDay(2), isTrue);
    expect(s.vacationCommand(v), 'Vac#1#09783#09784#3#118501003126000804153002008#159000000#');
    expect(s.vacLights, [0, 1, 2, 3, 4, 5, 6, 7, 11, 17, 18, 19]);
    expect(find.text('سناریو مسافرت'), findsOneWidget);
    expect(find.textContaining('ساعت پنل معلوم نیست'), findsOneWidget);
    expect(find.text('پرده باز'), findsWidgets);
    // ساعت از اینترنت رسید و مرحله‌ی ۳ اجرا شد
    c.onRaw(utf8.encode(r'$CLK#1#09784#0110#N$$V#1#09783#09784#3#118501003126000804153002008#159000000#1#3$'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.clockOk.value, isTrue);
    expect(s.clockSrc.value, 'N');
    expect(s.vacLast.value, '3');
    expect(find.textContaining('ساعت پنل معلوم نیست'), findsNothing);
    expect(find.textContaining('آخرین اجرا: مرحله‌ی ۳'), findsOneWidget);
    // برنامه‌ی پیش‌فرض اگر پنل برنامه ندارد
    c.onRaw(utf8.encode(r'$V#-#1#-$'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.vacation.value, isNull);
    expect(find.text('ذخیره روی پنل'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('SD23 two-panel network: the other panel in its own tab', (tester) async {
    await _setup(tester);
    final c = Panel12Controller.instance;
    final s = Sd23Controller.instance;
    await tester.pumpWidget(_app(Panel12TabHost(home: Container(color: Colors.white))));
    c.onRaw(utf8.encode(r'$MDL=SD23-a14-1.0$'));
    c.onRaw(utf8.encode(r'$LAY#LLLLLLLLLLLLnc1234UWXEZ$$CAP#A1R1W1S1P1$$K#000005$'));
    c.onRaw(utf8.encode(r'$L01#16~لوستر$'));
    c.onRaw(utf8.encode(r'$P2#p4#LLML-------------------#1$$P2K#000002#1$'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.hasPeer.value, isTrue);
    expect(s.peerOnline.value, isTrue);
    expect(find.text('پنل ۱'), findsOneWidget);
    expect(find.text('پنل ۲'), findsOneWidget);
    // پنل ۲
    await tester.tap(find.text('پنل ۲'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.peerView, isTrue);
    expect(s.lay.value.substring(0, 4), 'LLML');
    expect(s.isOn(1), isTrue);
    expect(s.isOn(0), isFalse);
    expect(s.tabs.contains(Sd23Controller.gAlarm), isFalse);
    expect(s.modelName, 'چهار پل');
    expect(s.labelOf(0), 'چراغ ۱');
    // پیام‌های خود پنل در این مدت کنار گذاشته می‌شوند
    c.onRaw(utf8.encode(r'$K#000001$'));
    c.onRaw(utf8.encode(r'$P2K#000003#1$'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(s.isOn(0) && s.isOn(1), isTrue);
    // قطع کابل
    c.onRaw(utf8.encode(r'$P2K#000003#0$'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(s.peerOnline.value, isFalse);
    expect(find.textContaining('کابل شبکه'), findsOneWidget);
    // متن کلید پنل ۲ روی گوشی
    s.saveKey(index: 0, iconId: '', label: 'آباژور');
    expect(s.labelOf(0), 'آباژور');
    // برنامه مسافرت و سناریوهای گوشی فقط برای پنل ۱
    await tester.pumpWidget(_app(const Sd23OwnOnly(what: 'برنامه‌ی مسافرت', child: Text('VAC'))));
    await tester.pump();
    expect(find.text('VAC'), findsNothing);
    expect(find.textContaining('برنامه‌ی مسافرت برای'), findsOneWidget);
    // برگشت به پنل ۱
    s.selectPanel(0);
    await tester.pump();
    expect(find.text('VAC'), findsOneWidget);
    expect(s.lay.value, 'LLLLLLLLLLLLnc1234UWXEZ');
    expect(s.isOn(0), isTrue);
    expect(s.isOn(2), isFalse);
    expect(s.labelOf(0), 'لوستر');
    expect(s.hasAlarm.value, isTrue);
    // اسم سربرگ
    s.renamePanel(1, 'پذیرایی');
    expect(s.panelName(1), 'پذیرایی');
    await tester.pump(const Duration(seconds: 30));
  });

  test('SD23 demo panel answers like the real one', () async {
    final s = Sd23Controller.instance;
    Panel12Controller.instance.isSd23.value = false; // نمایشی بدون پنل واقعی: بعد از آن چیزی فرستاده نمی‌شود
    s.startDemo('pc');
    await Future.delayed(const Duration(milliseconds: 400));
    expect(s.model.value, 'pc');
    await Future.delayed(const Duration(milliseconds: 1500));
    expect(s.lay.value, 'LLLLLLLLKFGLUWSSQLLLMXZ');
    s.press(0);
    await Future.delayed(const Duration(milliseconds: 400));
    expect(s.isOn(0), isTrue);
    s.stopDemo();
  });
}
