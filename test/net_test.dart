// تست خودکار شبکه‌ی CPU از راه ماژول وای‌فای: فهرست پنل‌های خانه، باز کردن یک پنل،
// برگشت به خانه و گزارش سلامت (همان پیام‌های fw_wmod در avrsim/twmod.js)

import 'dart:convert';

import 'package:bms/core/utils/globals.dart';
import 'package:bms/net/net_controller.dart';
import 'package:bms/net/net_screen.dart';
import 'package:bms/panel12/panel12_controller.dart';
import 'package:bms/panel12/panel12_screen.dart';
import 'package:bms/sd23/sd23_controller.dart';
import 'package:bms/sd23/sd23_screen.dart';
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
  testWidgets('CPU network: house list, a panel, back, health', (tester) async {
    isLoggerEnable = false;
    await _loadFonts();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    final c = Panel12Controller.instance;
    final n = NetController.instance;
    final s = Sd23Controller.instance;
    void rx(String m) => c.onRaw(utf8.encode(m));

    await tester.pumpWidget(_app(Panel12TabHost(home: Container(color: Colors.white))));
    await tester.pump();

    // ماژول وای‌فای خانه با ۳ پنل
    rx(r'$MDL=SDNET-03-1.0$');
    await tester.pump(const Duration(milliseconds: 800));
    expect(c.isNet.value, isTrue);
    expect(c.isSd23.value, isFalse);
    expect(find.byType(NetScreen), findsOneWidget);
    expect(n.panels.length, 3);
    expect(n.sentLog, containsAll(['@M_NET', '@M_NP#01', '@M_NP#02', '@M_NP#03']));
    rx(r'$NET#03$$NP#01#1#p4#سالن$$NP#02#1#e12#آشپزخانه$$NP#03#0#p6#خواب$');
    await tester.pump();
    expect(find.text('سالن'), findsOneWidget);
    expect(find.text('آشپزخانه'), findsOneWidget);
    expect(find.text('۱۲ اقتصادی'), findsOneWidget);
    expect(find.text('جواب نمی‌دهد'), findsOneWidget);
    expect(find.textContaining('۱ پنل جواب نمی‌دهد'), findsOneWidget);
    // پنل ۳ دوباره جواب داد
    rx(r'$NO#00000007$');
    await tester.pump();
    expect(n.onlineCount, 3);
    expect(find.text('۳ پنل، همه وصل'), findsOneWidget);

    // باز کردن آشپزخانه
    await tester.tap(find.text('آشپزخانه'));
    await tester.pump();
    expect(n.sentLog.last, '@P#02');
    rx(r'$P#02$');
    await tester.pump();
    expect(n.viewing.value, 2);
    expect(n.sentLog.last, '@M_MDL');
    rx(r'$MDL=SD23-e12-1.0$');
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.isNet.value, isTrue);
    expect(c.isSd23.value, isTrue);
    expect(s.model.value, 'e12');
    expect(find.byType(Sd23Screen), findsOneWidget);
    expect(find.byType(NetScreen), findsNothing);
    rx(r'$LAY#LLLLLLLLLLLL-----------$$CAP#A0R0W1S0V0N1$$K#000010$');
    await tester.pump(const Duration(milliseconds: 100));
    expect(s.isOn(4), isTrue);
    // پیام‌های خانه در صفحه‌ی پنل به خانه می‌رسند
    rx(r'$NO#00000003$');
    await tester.pump();
    expect(n.panels[2].online, isFalse);

    // برگشت به خانه
    await tester.tap(find.text('›  خانه'));
    await tester.pump();
    expect(n.sentLog.last, '@P#00');
    rx(r'$P#00$');
    rx(r'$MDL=SDNET-03-1.0$');
    await tester.pump(const Duration(milliseconds: 800));
    expect(c.isSd23.value, isFalse);
    expect(find.byType(NetScreen), findsOneWidget);
    expect(find.text('سالن'), findsOneWidget);

    // گزارش سلامت (نصاب)
    n.installer.value = true;
    await tester.pump();
    n.askHealth(3);
    expect(n.sentLog.last, '@M_HL#03');
    // جواب نمی‌دهد، ۱۲۰ ثانیه پیش آخرین جواب، شش پل، ۳۰ بی‌جواب
    rx(r'$HL#03#06#78#00#06#01#00#1E#00#02#00#05#00#03#0C$');
    await tester.pump();
    final h = n.health[3]!;
    expect(h.online, isFalse);
    expect(h.seenSecs, 120);
    expect(h.modelName, 'شش پل');
    expect(h.lost, 30);
    expect(h.healthy, isFalse);
    expect(find.text('قطع از'), findsOneWidget);
    expect(find.text('۲ دقیقه پیش'), findsOneWidget);
    expect(find.textContaining('سیم شبکه'), findsOneWidget);

    // پنل تنهای ۲۳ کلید بعد از آن: دیگر شبکه نیست
    rx(r'$MDL=SD23-a14-1.0$');
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.isNet.value, isFalse);
    expect(find.text('›  خانه'), findsNothing);
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('CPU network: the SIM panel through the module with all 27 keys (curtains 24..27)', (tester) async {
    isLoggerEnable = false;
    await _loadFonts();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    final c = Panel12Controller.instance;
    final n = NetController.instance;
    final s = Sd23Controller.instance;
    void rx(String m) => c.onRaw(utf8.encode(m));
    await tester.pumpWidget(_app(Panel12TabHost(home: Container(color: Colors.white))));
    await tester.pump();
    rx(r'$MDL=SDNET-01-1.0$');
    await tester.pump(const Duration(milliseconds: 800));
    rx(r'$NET#01$$NP#01#1#p12#دزدگیر$$NO#00000001$');
    await tester.pump();
    await tester.tap(find.text('دزدگیر'));
    await tester.pump();
    rx(r'$P#01$');
    await tester.pump();
    rx(r'$MDL=SD23-p12-1.0$');
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.model.value, 'p12');
    // همان پیام‌های fw_wmod در p12/sim/tp12wmod.js
    rx(r'$LAY#LLLLLLLLLLLLLLLSSSSXHMEUWUW$$CAP#A0R0W1S0V0N1$$K#4800010$');
    await tester.pump(const Duration(milliseconds: 100));
    expect(s.lay.value, 'LLLLLLLLLLLLLLLSSSSXHMEUWUW');
    expect(s.isOn(4), isTrue);
    expect(s.isOn(23), isTrue, reason: 'curtain 1 open (key 24)');
    expect(s.isOn(26), isTrue, reason: 'curtain 2 close (key 27)');
    expect(find.byType(Sim12Photo), findsOneWidget, reason: 'the SIM panel is drawn as itself');
    expect(s.lblCount, 27, reason: 'names of all 27 keys are asked');
    rx(r'$L24#پرده سالن$');
    await tester.pump();
    expect(s.labels[23], 'پرده سالن');
    await tester.pump(const Duration(seconds: 30));
  });
}
