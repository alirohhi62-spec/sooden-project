// تست صفحه‌ی پنل ۱۲ پل سیمکارتی: پیام‌های پنل، ترتیب کلیدها، دزدگیر، سیمکارت، جواب پیامکی.
// عکس هر بخش در test/goldens/sim12_*.png ساخته می‌شود (flutter test --update-goldens test/sim12_test.dart).

import 'dart:convert';

import 'package:bms/core/utils/globals.dart';
import 'package:bms/panel12/panel12_controller.dart';
import 'package:bms/panel12/panel12_screen.dart';
import 'package:bms/sim12/sim12_controller.dart';
import 'package:bms/sim12/sim12_screen.dart';
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

void main() {
  testWidgets('SIM12 panel page', (tester) async {
    isLoggerEnable = false;
    await _loadFonts();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final m = tester.binding.defaultBinaryMessenger;
    m.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (call) async => '/tmp');
    m.setMockMethodCallHandler(const MethodChannel('sooden/sms_in'), (call) async => null);

    final c = Panel12Controller.instance;
    final s = Sim12Controller.instance;
    await tester.pumpWidget(GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'dana'),
      home: Scaffold(body: Panel12TabHost(home: Container(color: Colors.white))),
    ));
    await tester.pump();

    c.onRaw(utf8.encode(r'$MDL=SIM12-1.0$'));
    s.demo.value = true; // وای‌فای وصل حساب شود
    s.updateLink();
    await tester.pump();
    expect(s.smsMode, isFalse);
    expect(c.isSim12.value, isTrue);
    expect(find.byType(Sim12Screen), findsOneWidget);

    c.onRaw(utf8.encode(r'$LAY#---------------------------$$K#0000025$$AL#2#1#2$$SIM#1#4#2#1245000$'));
    c.onRaw(utf8.encode(r'$L01#FF~لوستر سالن$$L02#FF~هالوژن$$EV#09425.0495.2.0.1;09425.0100.3.2.0$'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.lay.value, Sim12Controller.defaultLay); // پنل بدون نقش: چیدمان پیش‌فرض
    expect(s.isOn(0), isTrue);
    expect(s.isOn(2), isTrue);
    expect(s.isOn(5), isTrue);
    expect(s.alarm.value, 2);
    expect(s.armedZones.value, 1);
    expect(s.openZones.value, 2);
    expect(s.bars.value, 4);
    expect(s.operator.value, 2);
    expect(s.credit.value, '1245000');
    expect(s.events.length, 2);
    expect(find.text('لوستر سالن'), findsOneWidget);

    // پل ۱ سمت راست و پل ۲ سمت چپ (مثل پنل و عکس بالای صفحه)
    final p1 = tester.getCenter(find.text('لوستر سالن'));
    final p2 = tester.getCenter(find.text('هالوژن'));
    expect(p1.dx > p2.dx, isTrue);
    expect((p1.dy - p2.dy).abs() < 2, isTrue);

    await tester.runAsync(() async {
      await precacheImage(const AssetImage('assets/images/sim12_panel.jpg'), tester.element(find.byType(Sim12Screen)));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(Sim12Screen), matchesGoldenFile('goldens/sim12_keys.png'));

    s.tab.value = 'alarm';
    await tester.pump();
    expect(find.text('نیمه‌فعال (انتخاب زون)'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(Sim12Screen), matchesGoldenFile('goldens/sim12_alarm.png'));

    s.tab.value = 'cur';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(Sim12Screen), matchesGoldenFile('goldens/sim12_curtain.png'));

    s.tab.value = 'scn';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(Sim12Screen), matchesGoldenFile('goldens/sim12_scn.png'));

    s.tab.value = 'sim';
    await tester.pump();
    expect(find.text('ایرانسل'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(Sim12Screen), matchesGoldenFile('goldens/sim12_sim.png'));

    // حالت نصاب: تنظیمات کلیدها از پنل خوانده و یک زمان عوض می‌شود
    s.tab.value = 'keys';
    s.startDemo();
    await tester.pump(const Duration(seconds: 12));
    s.setInstaller(true);
    await tester.pump(const Duration(seconds: 9));
    expect(s.cf[3]?.type, 3);
    expect(s.cf[19]?.seconds, 35);
    expect(s.darkSec.value, 60);
    s.saveTime(19, 'T', 120);
    await tester.pump(const Duration(seconds: 1));
    expect(s.cf[19]?.seconds, 120);
    expect(s.message.value, 'روی پنل ثبت شد');
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(Sim12Screen), matchesGoldenFile('goldens/sim12_installer.png'));
    s.setInstaller(false);
    await tester.pump(const Duration(seconds: 4));
    s.stopDemo();
    await tester.pump();

    // جواب پیامکی پنل (وقتی وای‌فای نیست)
    s.setPanelNumber('09121234567');
    s.demo.value = false;
    s.updateLink();
    expect(s.smsMode, isTrue);
    s.handleSmsText('#SD,0,0,0,0811,3,980000#');
    s.tab.value = 'keys';
    await tester.pump();
    expect(s.alarm.value, 0);
    expect(s.isOn(0), isTrue);
    expect(s.isOn(4), isTrue);
    expect(s.isOn(11), isTrue);
    expect(s.isOn(2), isFalse);
    expect(s.credit.value, '980000');
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(Sim12Screen), matchesGoldenFile('goldens/sim12_sms.png'));
    await tester.pump(const Duration(seconds: 100));
  });
}
