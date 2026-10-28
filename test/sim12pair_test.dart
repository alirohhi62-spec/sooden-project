// عکس اپ وقتی پنل سیمکارتی و یک چهار پل با شبکه به هم وصل‌اند (دو سربرگ پنل ۱ و پنل ۲).
// flutter test --update-goldens test/sim12pair_test.dart  ->  test/goldens/sim12pair_*.png

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
  testWidgets('SIM panel + 4-pole: two panel tabs', (tester) async {
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
    // جواب‌های پنل سیمکارتی جفت‌شده با چهار پل (همان که شبیه‌ساز فریمور می‌دهد)
    c.onRaw(utf8.encode(r'$LAY#---------------------------$$K#0000001$$AL#0#0#0$$SIM#1#4#2#-$'));
    c.onRaw(utf8.encode(r'$CAP#A0R1W1S1P1$'));
    c.onRaw(utf8.encode(r'$P2#p4#LLLL-------------------#1$$P2K#000005#1$'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(s.hasPeer.value, isTrue);
    expect(s.peerKeys, [0, 1, 2, 3]);
    expect(s.peerOn(0) && !s.peerOn(1) && s.peerOn(2), isTrue);
    expect(s.peerModelName, 'چهار پل');
    expect(find.text('پنل ۱ (سیمکارتی)'), findsOneWidget);
    expect(find.text('پنل ۲'), findsOneWidget);

    await tester.runAsync(() async {
      await precacheImage(const AssetImage('assets/images/sim12_panel.jpg'), tester.element(find.byType(Sim12Screen)));
    });
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(Sim12Screen), matchesGoldenFile('goldens/sim12pair_1_sim.png'));

    await tester.tap(find.text('پنل ۲'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(s.peerView, isTrue);
    expect(find.text('کلید ۱'), findsOneWidget);
    expect(find.text('کلید ۴'), findsOneWidget);
    await expectLater(find.byType(Sim12Screen), matchesGoldenFile('goldens/sim12pair_2_peer.png'));

    // لمس کلید ۲: منتظر جواب پنل؛ با $P2K روشن می‌شود
    await tester.tap(find.text('کلید ۲'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(s.peerPending.contains(1), isTrue);
    expect(s.peerOn(1), isFalse);
    c.onRaw(utf8.encode(r'$P2A#02#1$$P2K#000007#1$'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.peerPending.contains(1), isFalse);
    expect(s.peerOn(1), isTrue);

    // پنل دوم قطع شد
    c.onRaw(utf8.encode(r'$P2K#000007#0$'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.peerOnline.value, isFalse);
    expect(find.textContaining('پنل ۲ به این پنل وصل نیست'), findsOneWidget);
    await expectLater(find.byType(Sim12Screen), matchesGoldenFile('goldens/sim12pair_3_offline.png'));

    // برگشت به پنل ۱
    await tester.tap(find.text('پنل ۱ (سیمکارتی)'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(s.peerView, isFalse);
    expect(find.text('سیمکارت'), findsWidgets);
    await tester.pump(const Duration(seconds: 30));
  });
}
