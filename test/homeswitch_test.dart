// پنل‌های یک خانه (همان مودم): نوار بالای صفحه (تا ۴ پنل زبانه، بیشتر فهرست)، انتخاب آخرین پنل همان مودم،
// و داده‌های قدیمیِ پیش از چند مکان که فقط یک بار به مکان اول می‌رسند.

import 'dart:convert';

import 'package:bms/core/utils/globals.dart';
import 'package:bms/core/utils/loc_store.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/location.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/connection_wraper/connection_wraper_impl.dart';
import 'package:bms/home/home_switch.dart';
import 'package:bms/panel12/panel12_controller.dart';
import 'package:bms/panel12/panel12_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

Future<void> _setup(WidgetTester tester) async {
  isLoggerEnable = false;
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final m = tester.binding.defaultBinaryMessenger;
  m.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (call) async => '/tmp');
  await tester.runAsync(() => GetStorage.init());
}

Widget _app(Widget tab) => GetMaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: Scaffold(body: Stack(children: [tab])),
    );

Location _loc(int id, String name, {String modem = 'HomeNet', String panelWifi = ''}) =>
    Location(id: id, name: name, modemName: modem, panelWifiName: panelWifi.isEmpty ? 'sooden-$id' : panelWifi);

void main() {
  testWidgets('the home modem: the panel used last on it, not the first one', (tester) async {
    await _setup(tester);
    final all = [_loc(1, 'سالن'), _loc(2, 'طبقه بالا'), _loc(3, 'دفتر', modem: 'Office')];
    GetStorage().remove('home_last_HomeNet');
    expect(ConnectionWrapperImpl.matchLocation(all, 'HomeNet', '')!.id, 1);
    HomeSwitch.setLast('HomeNet', 2);
    expect(ConnectionWrapperImpl.matchLocation(all, 'HomeNet', '')!.id, 2);
    expect(ConnectionWrapperImpl.matchLocation(all, 'sooden-1', '')!.id, 1, reason: 'on a panel\'s own Wi-Fi: that panel');
    expect(ConnectionWrapperImpl.matchLocation(all, 'Office', '')!.id, 3);
  });

  testWidgets('old data goes to the first location once; the others never inherit it', (tester) async {
    await _setup(tester);
    final b = GetStorage();
    b.remove('loc_legacy_moved');
    b.write('panel12_last_sim12', true);
    b.remove('loc7_panel12_last_sim12');
    b.remove('loc8_panel12_last_sim12');
    LocStore.firstId = 7;
    LocStore.moveLegacy();
    expect(b.read('loc7_panel12_last_sim12'), true);
    LocStore.id = 7;
    expect(LocStore.read<bool>('panel12_last_sim12'), true);
    LocStore.id = 8;
    expect(LocStore.read<bool>('panel12_last_sim12'), isNull);
    b.remove('loc7_panel12_last_sim12');
    LocStore.id = 7;
    expect(LocStore.read<bool>('panel12_last_sim12'), isNull, reason: 'after the move the old global key is not read any more');
    LocStore.id = null;
  });

  testWidgets('the bar: tabs up to 4 panels, a list above that; on a panel\'s own Wi-Fi the others are greyed', (tester) async {
    await _setup(tester);
    final h = HomeSwitch.instance;
    await tester.pumpWidget(_app(Panel12TabHost(home: Container(color: Colors.white))));
    Panel12Controller.instance.onRaw(utf8.encode(r'$MDL=SD23-a14-1.0$'));
    await tester.pump();
    expect(find.byType(HomeSwitchBar), findsNothing, reason: 'one panel: no bar');

    h.panels.assignAll([_loc(1, 'سالن'), _loc(2, 'طبقه بالا'), _loc(3, 'حیاط')]);
    h.current.value = 1;
    h.onModem.value = true;
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('switch-tab-2')), findsOneWidget);
    expect(find.text('طبقه بالا'), findsOneWidget);
    expect(find.byKey(const ValueKey('switch-title')), findsNothing);

    h.onModem.value = false;
    LocStore.via = 'panel';
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('فقط از راه مودم خانه'), findsOneWidget);

    h.onModem.value = true;
    h.panels.assignAll([for (int i = 1; i <= 5; i++) _loc(i, 'پنل $i')]);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('switch-title')), findsOneWidget, reason: '5 panels: the list');
    await tester.tap(find.byKey(const ValueKey('switch-title')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('پنل‌های این خانه'), findsOneWidget);
    expect(find.text('همین پنل'), findsOneWidget);
    h.panels.clear();
    LocStore.via = '';
    await tester.pump(const Duration(seconds: 30));
  });
}
