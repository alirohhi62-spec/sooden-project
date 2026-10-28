// پیش‌نمایش اصلاحات شکل پنل‌ها (۱۲ اقتصادی، شش پل، ۱ / ۲ / ۳ / ۴ پل به‌عنوان پنل ۲، نوشته‌ی زیر عکس).
// flutter test --update-goldens test/preview_test.dart  ->  test/goldens/preview_*.png

import 'dart:convert';

import 'package:bms/core/utils/globals.dart';
import 'package:bms/panel12/panel12_controller.dart';
import 'package:bms/panel12/panel12_screen.dart';
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
  final m = tester.binding.defaultBinaryMessenger;
  m.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (call) async => '/tmp');
  m.setMockMethodCallHandler(const MethodChannel('sooden/sms_in'), (call) async => null);
}


Future<void> _shot(WidgetTester tester, String name, List<String> msgs, {bool peer = false}) async {
  await _setup(tester);
  final c = Panel12Controller.instance;
  await tester.pumpWidget(_app(Panel12TabHost(home: Container(color: Colors.white))));
  for (final m in msgs) {
    c.onRaw(utf8.encode(m));
  }
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 600));
  if (peer) {
    await tester.tap(find.text('پنل ۲'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
  }
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/preview_$name.png'));
  if (peer) await tester.tap(find.text('پنل ۱'));
  await tester.pump(const Duration(seconds: 30));
}

const _own = [r'$MDL=SD23-a14-1.0$', r'$LAY#LLLLLLLLLLLLnc1234UWXEZ$$CAP#A1R1W1S1P1$$K#000005$$AL#0$'];

void main() {
  testWidgets('e12', (t) => _shot(t, '1_e12', [r'$MDL=SD23-e12-1.0$', r'$LAY#LLLLLLLLLLLL--------MTX$$CAP#A0R1W1S1$$K#000005$']));
  testWidgets('e12 with scenarios on 9..12', (t) => _shot(t, '2_e12scn', [r'$MDL=SD23-e12-1.0$', r'$LAY#LLLLLLLLUWSZ--------MTX$$CAP#A0R1W1S1$$K#000005$']));
  testWidgets('6-pole', (t) => _shot(t, '3_p6', [r'$MDL=SD23-p6-1.0$', r'$LAY#LLLLLLXM---------------$$CAP#A0R1W1C1V0$$K#000005$']));
  testWidgets('1-pole as panel 2', (t) => _shot(t, '4_p1', [..._own, r'$P2#p1#L----------------------#1$$P2K#000001#1$'], peer: true));
  testWidgets('2-pole as panel 2', (t) => _shot(t, '5_p2', [..._own, r'$P2#p2#LL---------------------#1$$P2K#000001#1$'], peer: true));
  testWidgets('3-pole + master as panel 2', (t) => _shot(t, '6_p3m', [..._own, r'$P2#p3m#LLLM-------------------#1$$P2K#000001#1$'], peer: true));
  testWidgets('4-pole as panel 2', (t) => _shot(t, '7_p4', [..._own, r'$P2#p4#LLLL-------------------#1$$P2K#000005#1$'], peer: true));
  testWidgets('14-pole alarm (tab names)', (t) => _shot(t, '8_a14', _own));
}
