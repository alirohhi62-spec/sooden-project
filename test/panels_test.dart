// عکس صفحه‌ی اول اپ برای هر مدل پنل (همان شکلی که بالای صفحه نشان داده می‌شود).
// چیدمان هر مدل = چیدمان پیش‌فرض همان مدل در برنامه سودن.
// flutter test --update-goldens test/panels_test.dart  ->  test/goldens/panels_*.png

import 'dart:convert';
import 'dart:io';

import 'package:bms/core/utils/globals.dart';
import 'package:bms/panel12/panel12_controller.dart';
import 'package:bms/panel12/panel12_screen.dart';
import 'package:bms/sim12/sim12_controller.dart';
import 'package:bms/sim12/sim12_screen.dart';
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
  final m = tester.binding.defaultBinaryMessenger;
  m.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (call) async => (Directory('/tmp/sooden_t_panels')..createSync(recursive: true)).path);   // (its own storage file: tests run side by side)
  await tester.runAsync(() => GetStorage.init());   // (the storage file read in real time, not on the test clock)
  m.setMockMethodCallHandler(const MethodChannel('sooden/sms_in'), (call) async => null);
}

/// پنل‌های ۲۳ کلید و خانواده‌اش: [شماره‌ی عکس، مدل، حروف چیدمان، روشن‌ها]
const _sd23 = [
  ['03', 'a14', 'LLLLLLLLLLLLnc1234UWXEZ', '000005'],
  ['04', 'a12', 'LLLLLLLLLLLLnc123456XEZ', '000005'],
  ['05', 'a10', 'LLLLLLLLLLUWnc123456XEZ', '000005'],
  ['06', 'a8', '--LLLLLLLL--nc123456XEZ', '000014'],
  ['07', 'a6', '--LLLLLLUW--nc123456XEZ', '000014'],
  ['08', 'ac', 'LLLLLLLLLLLLnc1234LLXEZ', '000005'],
  ['09', 'ac6', 'LLLLLLLLLLLLnc123456XEZ', '000005'],
  ['10', 'p20', 'LLLLLLLLLLLLLLLLLLLLMTX', '000005'],
  ['11', 'p14', 'LLLLLLLLLLLLLLSSSSSSMTX', '000005'],
  ['12', 'pc', 'LLLLLLLLKFGLUWSSQLLLMXZ', '000005'],
  ['13', 'e12', 'LLLLLLLLLLLL--------MTX', '000005'],
  ['14', 'p6', 'LLLLLLXM---------------', '000005'],
];

void main() {
  testWidgets('01 RF-12 (old 12-key)', (tester) async {
    await _setup(tester);
    await tester.pumpWidget(_app(const Panel12DemoPage()));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/panels_01_rf12.png'));
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('02 SIM panel', (tester) async {
    await _setup(tester);
    final c = Panel12Controller.instance;
    final s = Sim12Controller.instance;
    await tester.pumpWidget(_app(Panel12TabHost(home: Container(color: Colors.white))));
    c.onRaw(utf8.encode(r'$MDL=SIM12-1.0$'));
    s.demo.value = true;
    s.updateLink();
    c.onRaw(utf8.encode(r'$LAY#LLLLLLLLLLLLLLLSSSSXHMEUWUW$$K#0000005$$AL#0#0#0$$SIM#1#4#2#-$'));
    await tester.pump();                                   // (the page is built on the next frame)
    await tester.runAsync(() async {
      await precacheImage(const AssetImage('assets/images/sim12_panel.jpg'), tester.element(find.byType(Sim12Screen)));
    });
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/panels_02_sim12.png'));
    s.demo.value = false;
    await tester.pump(const Duration(seconds: 30));
  });

  for (final p in _sd23) {
    testWidgets('${p[0]} ${p[1]}', (tester) async {
      await _setup(tester);
      final c = Panel12Controller.instance;
      await tester.pumpWidget(_app(Panel12TabHost(home: Container(color: Colors.white))));
      c.onRaw(utf8.encode('\$MDL=SD23-${p[1]}-1.0\$'));
      final alarm = p[2].contains('n');
      c.onRaw(utf8.encode('\$LAY#${p[2]}\$\$CAP#A${alarm ? 1 : 0}R1W1S1\$\$K#${p[3]}\$${alarm ? r'$AL#0$' : ''}'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/panels_${p[0]}_${p[1]}.png'));
      await tester.pump(const Duration(seconds: 30));
    });
  }

  testWidgets('15 four-pole as panel 2 (next to a 14-pole alarm panel)', (tester) async {
    await _setup(tester);
    final c = Panel12Controller.instance;
    await tester.pumpWidget(_app(Panel12TabHost(home: Container(color: Colors.white))));
    c.onRaw(utf8.encode(r'$MDL=SD23-a14-1.0$'));
    c.onRaw(utf8.encode(r'$LAY#LLLLLLLLLLLLnc1234UWXEZ$$CAP#A1R1W1S1P1$$K#000005$$AL#0$'));
    c.onRaw(utf8.encode(r'$P2#p4#LLLL-------------------#1$$P2K#000005#1$'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('پنل ۲'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/panels_15_p4peer.png'));
    await tester.tap(find.text('پنل ۱'));
    await tester.pump(const Duration(seconds: 30));
  });
}
