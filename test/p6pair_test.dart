// عکس اپ وقتی دزدگیردار ۱۲ پل و شش پل کریستال با شبکه به هم وصل‌اند (دو سربرگ پنل ۱ و پنل ۲).
// flutter test --update-goldens test/p6pair_test.dart  ->  test/goldens/p6pair_*.png

import 'dart:convert';

import 'package:bms/core/utils/globals.dart';
import 'package:bms/panel12/panel12_controller.dart';
import 'package:bms/panel12/panel12_screen.dart';
import 'package:bms/sd23/sd23_controller.dart';
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

void main() {
  testWidgets('alarm 12-pole + 6-pole crystal: two panel tabs', (tester) async {
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
    final s = Sd23Controller.instance;
    await tester.pumpWidget(_app(Panel12TabHost(home: Container(color: Colors.white))));
    c.onRaw(utf8.encode(r'$MDL=SD23-a12-1.0$'));
    c.onRaw(utf8.encode(r'$LAY#LLLLLLLLLLLLnc123456XEZ$$CAP#A1R1W1S1P1$$K#000025$$AL#0$'));
    c.onRaw(utf8.encode(r'$L01#16~لوستر پذیرایی$$L02#16~هالوژن$$L03#16~آشپزخانه$'));
    c.onRaw(utf8.encode(r'$P2#p6#LLLLLLXM---------------#1$$P2K#000005#1$'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
    expect(s.hasPeer.value, isTrue);
    expect(find.text('پنل ۱'), findsOneWidget);
    expect(find.text('پنل ۲'), findsOneWidget);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/p6pair_1_alarm12.png'));
    await tester.tap(find.text('پنل ۲'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
    expect(s.peerView, isTrue);
    expect(s.modelName, 'شش پل');
    expect(s.isOn(0) && s.isOn(2) && !s.isOn(1), isTrue);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/p6pair_2_sixpole.png'));
    await tester.pump(const Duration(seconds: 30));
  });
}
