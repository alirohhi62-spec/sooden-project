// سه یا چهار پنل بدون CPU: پنل وای‌فای‌دار پنل‌های دیگر را هم نشان می‌دهد (یک زبانه برای هر پنل)
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

Widget _app(Widget tab) {
  return GetMaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    home: Scaffold(body: Column(children: [Expanded(child: Stack(children: [tab]))])),
  );
}

void main() {
  testWidgets('a 10-pole alarm panel shows the other two panels of the line', (tester) async {
    isLoggerEnable = false;
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final m = tester.binding.defaultBinaryMessenger;
    m.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (call) async => (Directory('/tmp/sooden_t_grp')..createSync(recursive: true)).path);   // (its own storage file: tests run side by side)
    await tester.runAsync(() => GetStorage.init());   // (the storage file read in real time, not on the test clock)
    m.setMockMethodCallHandler(const MethodChannel('sooden/sms_in'), (call) async => null);
    final c = Panel12Controller.instance;
    final s = Sd23Controller.instance;
    await tester.pumpWidget(_app(Panel12TabHost(home: Container(color: Colors.white))));
    c.onRaw(utf8.encode(r'$MDL=SD23-a10-1.0$'));
    c.onRaw(utf8.encode(r'$LAY#LLLLLLLLLLUWnc123456---$$CAP#A1R0W1S1X2$$K#000001$$AL#0$'));
    c.onRaw(utf8.encode(r'$PX#1#2#p6#LLLLLLXM---------------#1$$PX#2#3#p4#LLLL-------------------#0$'));
    c.onRaw(utf8.encode(r'$PXK#2#000005#1$$PXK#3#000002#0$'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
    expect(s.hasPeer.value, isTrue);
    expect(s.peerCount.value, 2);
    expect(find.text('پنل ۱'), findsOneWidget);
    expect(find.text('پنل ۲'), findsOneWidget);
    expect(find.text('پنل ۳'), findsOneWidget);
    expect(s.peerOnlineOf(1), isTrue);
    expect(s.peerOnlineOf(2), isFalse);

    await tester.tap(find.text('پنل ۲'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(s.peerView, isTrue);
    expect(s.modelName, 'شش پل');
    expect(s.isOn(0) && s.isOn(2) && !s.isOn(1), isTrue);

    await tester.tap(find.text('پنل ۳'));                     // from one other panel to the next
    await tester.pump(const Duration(milliseconds: 600));
    expect(s.peerView, isTrue);
    expect(s.peerIdx.value, 1);
    expect(s.modelName, 'چهار پل');
    expect(s.isOn(1) && !s.isOn(0), isTrue);
    c.onRaw(utf8.encode(r'$PXK#3#000003#1$'));                // its keys change: shown at once
    await tester.pump(const Duration(milliseconds: 400));
    expect(s.isOn(0) && s.isOn(1), isTrue);
    c.onRaw(utf8.encode(r'$PXK#2#000000#1$'));                // the other one changes: not on this page
    await tester.pump(const Duration(milliseconds: 400));
    expect(s.isOn(0), isTrue);

    await tester.tap(find.text('پنل ۱'));                     // back to the panel itself
    await tester.pump(const Duration(milliseconds: 600));
    expect(s.peerView, isFalse);
    expect(s.isOn(0) && !s.isOn(1), isTrue);
    await tester.pump(const Duration(seconds: 30));
  });
}
