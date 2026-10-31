// عکس صفحه‌ی ۱۲ اقتصادی: تنها، و به‌عنوان پنل ۲ کنار دزدگیردار ۱۲ پل.
// flutter test --update-goldens test/e12_test.dart  ->  test/goldens/e12_*.png
import 'dart:convert';
import 'dart:io';

import 'package:bms/core/utils/globals.dart';
import 'package:bms/panel12/panel12_controller.dart';
import 'package:bms/panel12/panel12_screen.dart';
import 'package:bms/sd23/sd23_controller.dart';
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

Widget _app(Widget tab) => GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'dana'),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: Scaffold(body: Column(children: [Expanded(child: Stack(children: [tab])), Container(height: 56, color: const Color(0xFF202124))])),
    );

Future<void> _setup(WidgetTester tester) async {
  isLoggerEnable = false;
  await _loadFonts();
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final m = tester.binding.defaultBinaryMessenger;
  m.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (call) async => (Directory('/tmp/sooden_t_e12')..createSync(recursive: true)).path);   // (its own storage file: tests run side by side)
  await tester.runAsync(() => GetStorage.init());   // (the storage file read in real time, not on the test clock)
  m.setMockMethodCallHandler(const MethodChannel('sooden/sms_in'), (call) async => null);
}

void main() {
  testWidgets('12 economic alone: its own glass, the 3 scenarios on one line', (tester) async {
    await _setup(tester);
    final c = Panel12Controller.instance;
    final s = Sd23Controller.instance;
    await tester.pumpWidget(_app(Panel12TabHost(home: Container(color: Colors.white))));
    c.onRaw(utf8.encode(r'$MDL=SD23-e12-1.0$'));
    c.onRaw(utf8.encode(r'$LAY#LLLLLLLLUWSL--------XEZ$$CAP#A0R1W1S1$$K#100081$'));
    c.onRaw(utf8.encode(r'$L01#16~لوستر پذیرایی$$L02#16~هالوژن$'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
    expect(s.modelName, '۱۲ اقتصادی');
    expect(s.tabs.contains(Sd23Controller.gAlarm), isFalse);
    expect(s.isOn(0) && s.isOn(7) && s.isOn(20), isTrue);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/e12_1_alone.png'));
    await tester.pump(const Duration(seconds: 30));
  });
  testWidgets('alarm 12-pole + 12 economic as panel 2', (tester) async {
    await _setup(tester);
    final c = Panel12Controller.instance;
    final s = Sd23Controller.instance;
    await tester.pumpWidget(_app(Panel12TabHost(home: Container(color: Colors.white))));
    c.onRaw(utf8.encode(r'$MDL=SD23-a12-1.0$'));
    c.onRaw(utf8.encode(r'$LAY#LLLLLLLLLLLLnc123456XEZ$$CAP#A1R1W1S1P1$$K#000005$$AL#0$'));
    c.onRaw(utf8.encode(r'$P2#e12#LLLLLLLLLLLL--------XMZ#1$$P2K#000803#1$'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('پنل ۲'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
    expect(s.peerView, isTrue);
    expect(s.modelName, '۱۲ اقتصادی');
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/e12_2_peer.png'));
    await tester.pump(const Duration(seconds: 30));
  });
}
