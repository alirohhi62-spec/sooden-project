// تست خودکار صفحه‌های پنل RF-12 (پنل، سناریو، موشن لوگو).
// در GitHub قبل از ساخت APK اجرا می‌شود؛ اگر رد شود، APK ساخته و منتشر نمی‌شود.
// عکس‌های صفحه در test/goldens/ ساخته می‌شوند (flutter test --update-goldens).

import 'dart:convert';
import 'dart:io';

import 'package:bms/core/utils/globals.dart';
import 'package:bms/panel12/panel12_controller.dart';
import 'package:bms/panel12/panel12_scenarios.dart';
import 'package:bms/panel12/panel12_screen.dart';
import 'package:bms/panel12/panel12_vacation.dart';
import 'package:bms/panel12/sooden_splash_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

Future<void> _loadFonts() async {
  final loader = FontLoader('dana')
    ..addFont(rootBundle.load('assets/fonts/Dana_FaNum_Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Dana_FaNum_Bold.ttf'));
  await loader.load();
}

String _installerPin() {
  final t = DateTime.now();
  final s = '${t.hour.toString().padLeft(2, '0')}${t.minute.toString().padLeft(2, '0')}';
  return s.split('').reversed.join();
}

/// همان ترکیبی که در MainScreen هست: Column > Expanded > Stack > تب
Widget _app(Widget tab) {
  return GetMaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'dana'),
    builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    home: Scaffold(
      body: Column(children: [
        Expanded(child: Stack(children: [tab])),
        Container(height: 56, color: const Color(0xFF202124)), // جای منوی پایین
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
  final m = tester.binding.defaultBinaryMessenger;
  m.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  /* (the phone's storage and SMS: its own storage folder, tests run side by side) */
  m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (call) async => (Directory('/tmp/sooden_t_panel12')..createSync(recursive: true)).path);
  await tester.runAsync(() async {                       // (read in real time, not on the test clock; a new phone each test)
    await GetStorage.init();
    await GetStorage().erase();
  });
  m.setMockMethodCallHandler(const MethodChannel('sooden/sms_in'), (call) async => null);
}

void main() {
  testWidgets('RF-12 panel screen: mirror, layout, curtain, installer', (tester) async {
    await _setup(tester);
    final c = Panel12Controller.instance;

    await tester.pumpWidget(_app(Panel12TabHost(home: Container(color: Colors.white))));
    await tester.pump();

    // نوع پنل هنوز معلوم نیست: نه صفحه‌ی پنل، نه صفحه‌ی قدیمی (فقط زمینه‌ی تیره)
    expect(find.byType(Panel12Screen), findsNothing);

    c.onRaw(utf8.encode(r'$MDL=RF12-L10P1A1E1$'));
    await tester.pump();
    expect(c.isRf12.value, isTrue);
    expect(c.modelKnown.value, isTrue);
    expect(find.byType(Panel12Screen), findsOneWidget);

    final size = tester.getSize(find.byType(Panel12Screen));
    expect(size.width, greaterThan(350));
    expect(size.height, greaterThan(600));

    c.onRaw(utf8.encode('#T*A1/Uaeedfaacdh/Vp1*L+#X1*Z1++'));
    c.onRaw([...utf8.encode('@TA1U'), 0x90, 0x40, 0, 0, 0]);
    c.onRaw(utf8.encode('@TA1Vp1-4S'));
    c.onRaw(utf8.encode('@X1Z1on'));
    c.onRaw(utf8.encode(r'$L01#16~لوستر پذیرایی$'));
    c.onRaw(utf8.encode(r'$L03#34~دیوارکوب پذیرایی1$')); // ۱۷ حرف (قبلاً بیش از ۱۳ حرف جا نمی‌شد)
    await tester.pump(const Duration(milliseconds: 600)); // چراغ‌ها یکی‌یکی (۱۰۰ میلی‌ثانیه) مثل پنل

    expect(c.lights[0], isTrue);
    expect(c.lights[3], isTrue);
    expect(c.lights[9], isTrue);
    expect(c.lights[1], isFalse);
    expect(c.curtainPos.value, 4);
    expect(c.curtainClosed.value, closeTo(4 / 9, 0.001));
    expect(c.armed.value, isTrue);
    expect(c.labels[0], 'لوستر پذیرایی');
    expect(c.labels[2], 'دیوارکوب پذیرایی1');
    expect(c.iconOf(0), '16');
    expect(find.text('لوستر پذیرایی'), findsWidgets);

    // ستون چپ پنل: ۱، ۳، ۵، ۷، ۹، ۱۱
    c.selectZone(0);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('چراغ ۵'), findsNWidgets(2)); // تصویر بالا + کلید بزرگ
    expect(find.text('چراغ ۲'), findsOneWidget); // فقط در تصویر بالا (ستون راست)
    await expectLater(find.byType(Panel12Screen), matchesGoldenFile('goldens/panel12_left.png'));

    // Master از پنل: چراغ‌ها یکی‌یکی روشن می‌شوند
    c.onRaw([...utf8.encode('@TA1U'), 0xFF, 0xC0, 0, 0, 0]);
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.lights.where((e) => e).length, lessThan(10));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(c.lights.every((e) => e), isTrue);

    // Exit روی پنل زده شد
    c.onRaw(utf8.encode(r'$EV=E$'));
    await tester.pump();
    expect(c.flashing.contains('exit'), isTrue);

    // پرده در حال بسته شدن
    c.onRaw(utf8.encode('@TA1Vp1-4C'));
    await tester.pump(const Duration(seconds: 2));
    expect(c.curtainClosed.value, greaterThan(4 / 9));
    expect(find.textContaining('در حال بسته شدن'), findsWidgets);
    c.onRaw(utf8.encode('@TA1Vp1-5S'));
    await tester.pump();
    expect(c.curtainClosed.value, closeTo(5 / 9, 0.001));

    // بخش وسط
    c.selectZone(1);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('ON / OFF'), findsWidgets);
    expect(find.text('Master'), findsWidgets);
    await expectLater(find.byType(Panel12Screen), matchesGoldenFile('goldens/panel12_center.png'));
    await tester.tap(find.text('ON / OFF').last);
    await tester.pump();
    expect(c.entry.value, 'arm');
    await tester.tap(find.text('1').last);
    await tester.pump();
    expect(c.buf.value, '1');

    // ستون راست
    c.selectZone(2);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('چراغ ۱۲'), findsWidgets);

    // حالت نصاب
    c.selectZone(0);
    await tester.pump(const Duration(seconds: 1));
    await tester.longPress(find.text('پذیرایی'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), _installerPin());
    await tester.tap(find.text('ورود'));
    await tester.pumpAndSettle();
    expect(c.installer.value, isTrue);

    await tester.tap(find.text('چراغ ۵').last);
    await tester.pumpAndSettle();
    expect(find.text('ذخیره روی پنل'), findsOneWidget);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/panel12_installer.png'));
    await tester.enterText(find.byType(TextField), 'آویز راهرو طبقه‌ی اول ۲');
    await tester.ensureVisible(find.text('ذخیره روی پنل'));
    await tester.tap(find.text('ذخیره روی پنل'));
    await tester.pumpAndSettle();
    // متن فقط بعد از خواندن دوباره از پنل عوض می‌شود
    expect(c.labels[4], isNot('آویز راهرو طبقه‌ی اول ۲'));
    c.onRaw(utf8.encode(r'$L05#16~آویز راهرو طبقه‌ی اول ۲$'));
    await tester.pump();
    expect(c.labels[4], 'آویز راهرو طبقه‌ی اول ۲');

    await tester.pump(const Duration(seconds: 5)); // زمان‌سنج‌های ذخیره تمام شوند

    // فرمان بدون جواب پنل: کلید عوض نمی‌شود و پیام «اجرا نشد» می‌آید
    final before = c.lights[1];
    c.toggleLight(1);
    await tester.pump(const Duration(seconds: 4));
    expect(c.lights[1], before);
    expect(c.notice.value, contains('اجرا نشد'));

    // Master فقط با پیام پنل روشن می‌شود
    c.flashing.clear();
    c.master();
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.flashing.contains('master'), isFalse);
    c.onRaw(utf8.encode(r'$EV=M$'));
    await tester.pump();
    expect(c.flashing.contains('master'), isTrue);

    c.installer.value = false;
    await tester.pump(const Duration(seconds: 20));
  });

  testWidgets('RF-12 scenario tab: list, add, edit, timer', (tester) async {
    await _setup(tester);
    final c = Panel12Controller.instance;
    c.onRaw(utf8.encode(r'$MDL=RF12-L10P1A1E1$'));
    c.onRaw(utf8.encode(r'$S01#1110222222OF0090#شب بخیر$'));
    c.onRaw(utf8.encode(r'$S02#-$'));

    await tester.pumpWidget(_app(Panel12ScenarioTabHost(home: Container(color: Colors.white))));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(Panel12Scenarios), findsOneWidget);
    expect(c.scenarios[0]?.name, 'شب بخیر');
    expect(c.scenarios[0]?.tm, 'F');
    expect(c.scenarios[0]?.mins, 90);
    expect(find.text('شب بخیر'), findsOneWidget);
    expect(find.textContaining('خاموشی خودکار'), findsOneWidget);

    // تایمر در حال شمارش که پنل گزارش داده
    c.onRaw(utf8.encode(r'$P01#0045$'));
    await tester.pump();
    expect(find.textContaining('خاموشی تا'), findsOneWidget);
    expect(find.text('لغو'), findsOneWidget);
    await expectLater(find.byType(Panel12Scenarios), matchesGoldenFile('goldens/scenarios.png'));
    c.onRaw(utf8.encode(r'$P01#0000$'));
    await tester.pump();
    expect(find.text('لغو'), findsNothing);

    // پایان تایمر با فهرست پنل: تایمری که در فهرست نیامد تمام شده است
    c.onRaw(utf8.encode(r'$P01#0001$'));
    await tester.pump();
    expect(c.pending.containsKey(0), isTrue);
    c.askPending();
    c.onRaw(utf8.encode(r'$PE$'));
    await tester.pump();
    expect(c.pending.containsKey(0), isFalse);
    expect(find.textContaining('خاموشی خودکار بعد از'), findsOneWidget);

    // اجرای سناریو فقط با تأیید پنل نشان داده می‌شود
    c.onRaw(utf8.encode(r'$RUN=01R$'));
    await tester.pump();
    expect(c.scenarioRan.contains(0), isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(c.scenarioRan.contains(0), isFalse);

    // سناریوی جدید
    await tester.tap(find.text('＋ افزودن سناریو'));
    await tester.pumpAndSettle();
    expect(find.text('ذخیره'), findsOneWidget);
    await tester.tap(find.text('بسته'));
    await tester.tap(find.text('اجرا با تأخیر'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/scenario_edit.png'));
    await tester.ensureVisible(find.text('ذخیره'));
    await tester.tap(find.text('ذخیره'));
    await tester.pumpAndSettle();
    // فهرست فقط بعد از خواندن دوباره از پنل عوض می‌شود
    expect(c.scenarios[1], isNull);
    c.onRaw(utf8.encode(r'$S02#0000000000CD0060#سناریو ۲$'));
    await tester.pump();
    expect(c.notice.value, 'سناریو روی پنل ثبت شد');
    expect(c.scenarios[1]?.name, 'سناریو ۲');
    expect(c.scenarios[1]?.c, 'C');
    expect(c.scenarios[1]?.tm, 'D');
    expect(c.scenarios[1]?.mins, 60);

    await tester.pump(const Duration(seconds: 5));
  });

  test('vacation command: times after midnight, lights mask, curtain', () {
    final v = Panel12Vacation(on: true, d0: 9410, d1: 9417, steps: [
      Panel12VacStep(t: 18 * 60, k: [true, true, false, false, true, false, false, false, false, false], c: 'O'),
      Panel12VacStep(t: 21 * 60, k: [false, false, true, true, false, false, true, false, false, false]),
      Panel12VacStep(t: 23 * 60 + 30, k: [false, false, false, false, false, false, false, false, false, true], c: 'C'),
    ], te: 60, ce: 'C');
    expect(Panel12Controller.vacationCommand(v), 'Vac#1#09410#09417#3#1080013O126004C-1410200C#1500C#');
    expect(v.nextDay(3), isTrue); // پایان ساعت ۱ بامداد روز بعد
    expect(v.nextDay(2), isFalse);
    // دو مرحله هم‌زمان: نامعتبر
    final bad = v.copy()..steps[1].t = 18 * 60;
    expect(Panel12Controller.vacationCommand(bad), isNull);
    // بیش از یک شبانه‌روز: نامعتبر
    final bad2 = v.copy()
      ..steps[1].t = 10 * 60
      ..steps[2].t = 9 * 60;
    expect(Panel12Controller.vacationCommand(bad2), isNull);
    // شمارش روز مثل پنل: از ۱ ژانویه‌ی ۲۰۰۰
    expect(Panel12Controller.dayNumber(DateTime(2000, 1, 1)), 0);
    expect(Panel12Controller.dayNumber(DateTime(2026, 10, 7)), 9776);
    expect(Panel12Controller.dateOf(9776), DateTime(2026, 10, 7));
    expect(Jalali.dayText(9776), '۱۵ مهر');
    expect(Jalali.weekday(9776), 'چهارشنبه');
  });

  testWidgets('RF-12 vacation tab: read from panel, edit, save', (tester) async {
    await _setup(tester);
    final c = Panel12Controller.instance;
    c.onRaw(utf8.encode(r'$MDL=RF12-L10P1A1E1$'));
    final today = Panel12Controller.dayNumber(DateTime.now()) + 1;
    final d0 = today.toString().padLeft(5, '0'), d1 = (today + 6).toString().padLeft(5, '0');
    c.onRaw(utf8.encode('\$V#1#$d0#$d1#3#1080013O126004C-1410200C#1500C#1\$'));
    expect(c.vacation.value?.steps.length, 3);
    expect(c.vacation.value?.steps[2].t, 23 * 60 + 30);
    expect(c.vacation.value?.steps[0].k[4], isTrue);
    expect(c.vacation.value?.te, 60);
    expect(c.vacation.value?.repeat, isTrue);

    await tester.pumpWidget(_app(Panel12VacationTabHost(home: Container(color: Colors.white))));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Panel12VacationScreen), findsOneWidget);
    expect(find.text('سناریو مسافرت'), findsOneWidget);
    expect(find.textContaining('فعال · شروع'), findsOneWidget);
    expect(find.text('مرحله‌ی ۳'), findsOneWidget);
    expect(find.text('پایان: خاموشی کامل پنل'), findsOneWidget);
    expect(find.text('(روز بعد)'), findsOneWidget);
    expect(find.text('ذخیره شده ✓'), findsOneWidget);
    await expectLater(find.byType(Panel12VacationScreen), matchesGoldenFile('goldens/vacation.png'));

    // پنل مرحله‌ی ۲ را اجرا کرد
    c.onRaw(utf8.encode(r'$VS#2$'));
    await tester.pump();
    expect(find.textContaining('آخرین اجرا: مرحله‌ی ۲'), findsOneWidget);

    // افزودن مرحله و ذخیره
    await tester.ensureVisible(find.text('＋ افزودن مرحله'));
    await tester.tap(find.text('＋ افزودن مرحله'));
    await tester.pump();
    expect(find.text('مرحله‌ی ۴'), findsOneWidget);
    expect(find.text('ذخیره روی پنل'), findsOneWidget);
    expect(find.text('(روز بعد)'), findsNWidgets(2)); // مرحله‌ی ۴ ساعت ۰۰:۳۰ و پایان ۰۱:۰۰

    // پیش‌نمایش روی تصویر پنل
    await tester.ensureVisible(find.text('▶ پیش‌نمایش'));
    await tester.tap(find.text('▶ پیش‌نمایش'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.previewLights.value?[4], isTrue);
    expect(c.previewCurtain.value, 'O');
    await tester.pump(const Duration(milliseconds: 1600 * 5 + 200));
    expect(c.previewLights.value, isNull);

    await tester.ensureVisible(find.text('ذخیره روی پنل'));
    await tester.tap(find.text('ذخیره روی پنل'));
    await tester.pump();
    // تا پنل برنامه را برنگرداند، ذخیره تمام نیست
    expect(find.text('در حال ذخیره…'), findsOneWidget);
    expect(c.vacation.value?.steps.length, 3);
    c.onRaw(utf8.encode('\$V#1#$d0#$d1#4#1080013O126004C-1410200C1470000-#1500C#1\$'));
    await tester.pump();
    await tester.pump();
    expect(c.vacation.value?.steps.length, 4);
    expect(c.notice.value, 'برنامه‌ی مسافرت روی پنل ثبت شد');
    expect(find.text('ذخیره شده ✓'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Sooden logo motion', (tester) async {
    await _setup(tester);
    await tester.pumpWidget(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(backgroundColor: Colors.black, body: Center(child: SoodenSplashLogo())),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/splash_start.png'));
    await tester.pump(const Duration(seconds: 3));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/splash_end.png'));
  });
}
