// پیش‌نمایش جابه‌جایی بین پنل‌های یک خانه (۲) (زبانه‌ها / فهرست کشویی). قبلاً: پیش‌نمایش اصلاحات شکل پنل‌ها (۱۲ اقتصادی، شش پل، ۱ / ۲ / ۳ / ۴ پل به‌عنوان پنل ۲، نوشته‌ی زیر عکس).
// flutter test --update-goldens test/preview_test.dart  ->  test/goldens/preview_*.png

import 'dart:convert';

import 'package:bms/core/utils/globals.dart';
import 'package:bms/panel12/panel12_controller.dart';
import 'package:bms/panel12/panel12_screen.dart';
import 'package:bms/home/panel_switcher.dart';
import 'package:bms/sim12/sim12_controller.dart';
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



const _a14 = [r'$MDL=SD23-a14-1.0$', r'$LAY#LLLLLLLLLLLLnc1234UWXEZ$$CAP#A1R1W1S1P1$$K#000005$$AL#0$'];
const _e12 = [r'$MDL=SD23-e12-1.0$', r'$LAY#LLLLLLLLLLLL--------MTX$$CAP#A0R1W1S1$$K#000011$'];
const _home = [
  HomePanel(1, 'سالن', 'دزدگیردار ۱۴ پل'),
  HomePanel(2, 'طبقه بالا', '۱۲ اقتصادی'),
  HomePanel(3, 'حیاط', 'شش پل', online: false),
];

/// the panel page with the switcher above it; picking a panel feeds that panel's answers (like a real switch)
class _Host extends StatefulWidget {
  final SwitcherStyle style;
  final List<HomePanel> panels;
  final String? note;
  const _Host(this.style, this.panels, {this.note});
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int cur = 1;
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF0B0C10),
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            PanelSwitcher(
                panels: widget.panels,
                current: cur,
                style: widget.style,
                note: widget.note,
                onPick: (p) {
                  setState(() => cur = p.id);
                  for (final m in p.id == 2 ? _e12 : _a14) {
                    Panel12Controller.instance.onRaw(utf8.encode(m));
                  }
                }),
            Expanded(child: Panel12TabHost(home: Container(color: Colors.white))),
          ]),
        ),
      );
}

Future<void> _sw(WidgetTester tester, String name, SwitcherStyle st, {List<HomePanel> panels = _home, String? note, Future<void> Function()? act}) async {
  await _setup(tester);
  await tester.pumpWidget(_app(_Host(st, panels, note: note)));
  for (final m in _a14) {
    Panel12Controller.instance.onRaw(utf8.encode(m));
  }
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 600));
  if (act != null) await act();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/preview_$name.png'));
  await tester.pump(const Duration(seconds: 30));
}

void main() {
  testWidgets('tabs', (t) => _sw(t, 'sw1_tabs', SwitcherStyle.tabs));
  testWidgets('tabs: switched to the 12 economic', (t) => _sw(t, 'sw2_tabs_switched', SwitcherStyle.tabs, act: () async {
        await t.tap(find.byKey(const ValueKey('switch-tab-2')));
        await t.pump(const Duration(milliseconds: 400));
        await t.pump(const Duration(milliseconds: 600));
      }));
  testWidgets('tabs: on the panel Wi-Fi', (t) => _sw(t, 'sw3_tabs_panelwifi', SwitcherStyle.tabs,
      panels: const [HomePanel(1, 'سالن', 'دزدگیردار ۱۴ پل'), HomePanel(2, 'طبقه بالا', '۱۲ اقتصادی', reachable: false), HomePanel(3, 'حیاط', 'شش پل', reachable: false)],
      note: 'گوشی به وای‌فای خود «سالن» وصل است؛ بقیه‌ی پنل‌ها فقط از راه مودم خانه'));
  testWidgets('dropdown', (t) => _sw(t, 'sw4_drop', SwitcherStyle.dropdown));
  testWidgets('dropdown open', (t) => _sw(t, 'sw5_drop_open', SwitcherStyle.dropdown, act: () async {
        await t.tap(find.byKey(const ValueKey('switch-title')));
        await t.pump(const Duration(milliseconds: 500));
        await t.pump(const Duration(milliseconds: 500));
      }));
}
