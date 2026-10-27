// صفحه‌ی «تعریف مکان جدید» / «تنظیمات مکان» با ظاهر تازه، و پیام اولین اجرا
// flutter test --update-goldens test/newloc_test.dart  ->  test/goldens/newloc_*.png
import 'dart:io';

import 'package:bms/core/utils/globals.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/location.dart';
import 'package:bms/presentation/logic/new_location_logic.dart';
import 'package:bms/presentation/screens/tabs/settings/pages/new_location_screen.dart';
import 'package:bms/presentation/widgets/first_run_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bms/core/utils/loc_store.dart';

String wifi = 'sooden-3F2A';

Future<void> _setup(WidgetTester tester, {double h = 2340}) async {
  isLoggerEnable = false;
  final dana = FontLoader('dana')
    ..addFont(rootBundle.load('assets/fonts/Dana_FaNum_Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Dana_FaNum_Bold.ttf'));
  await dana.load();
  final root = Platform.environment['FLUTTER_ROOT'] ?? '';
  final f = File('$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
  if (f.existsSync()) {
    final b = f.readAsBytesSync();
    await (FontLoader('Roboto')..addFont(Future.value(ByteData.view(b.buffer)))).load();
  }
  final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final b = icons.readAsBytesSync();
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(b.buffer)))).load();
  }
  tester.view.physicalSize = Size(1080, h);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final m = tester.binding.defaultBinaryMessenger;
  m.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (call) async => '/tmp');
  m.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/network_info'),
      (call) async => call.method == 'wifiName' ? '"$wifi"' : null);
  Get.reset();
  await tester.runAsync(() => GetStorage.init());
}

Widget _app(Widget w) => GetMaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData(fontFamily: 'dana'), home: w);

final villa = Location(
    id: 2,
    name: 'ویلا',
    panelWifiName: 'sooden-3F2A',
    mac: '5c:cf:7f:3f:2a:10',
    modemName: 'MyHome-5G',
    modemPassword: 'home@1234',
    panelIpOnModem: '192.168.1.50',
    staticIp: '5.160.20.11');

void main() {
  test('Wi-Fi name / password rules and AT escapes', () {
    expect(NewLocationLogic.checkPanelWifi('@Soo_den"', ''), isNull);
    expect(NewLocationLogic.checkPanelWifi('سودن منزل', '12345678'), isNull);
    expect(NewLocationLogic.checkPanelWifi('x', '1234'), isNotNull);
    expect(NewLocationLogic.checkPanelWifi('', ''), isNotNull);
    expect(NewLocationLogic.checkPanelWifi('سودن' * 5, ''), isNotNull); // 40 bytes
    expect(NewLocationLogic.apCommand('@Soo_den"', ''), r'*AT+CWSAP="@Soo_den\"","",1,0*');
    expect(NewLocationLogic.apCommand('a,b', r'p\w12345'), r'*AT+CWSAP="a\,b","p\\w12345",1,4*');
    expect(NewLocationLogic.joinCommand('Home "A"', 'p#ss,1'), r'#AT+CWJAP="Home \"A\"","p#ss\,1"#');
  });

  testWidgets('new location: phone on the panel Wi-Fi', (tester) async {
    await _setup(tester);
    wifi = 'sooden-3F2A';
    await tester.pumpWidget(_app(NewLocationScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).first, 'منزل');
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/newloc_1_new.png'));
  });

  testWidgets('new location: panel did not answer, phone on the home Wi-Fi', (tester) async {
    await _setup(tester);
    wifi = 'MyHome-5G';
    await tester.pumpWidget(_app(NewLocationScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    final l = Get.find<NewLocationLogic>();
    l.locationNameController.text = 'منزل';
    l.connError = 'پنل جواب نداد';
    l.showMore = true;
    l.update();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('پنل جواب نداد'), findsOneWidget);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/newloc_2_error.png'));
  });

  testWidgets('location settings: all three steps', (tester) async {
    await _setup(tester, h: 5400);
    wifi = 'sooden-3F2A';
    await tester.pumpWidget(_app(NewLocationScreen(locationToEdit: villa)));
    await tester.pump(const Duration(milliseconds: 300));
    final l = Get.find<NewLocationLogic>();
    l.wifiNameController.text = '@Soo_den"';
    l.wifiPasswordController.text = '';
    l.wifiOk = false;
    l.wifiMsg = NewLocationLogic.checkPanelWifi('@Soo_den"', '1234');
    l.modemOk = true;
    l.modemMsg = 'پنل به مودم وصل شد.';
    LocStore.writeFor(2, 'net_upnp', 'ok');
    LocStore.writeFor(2, 'net_cgnat', false);
    l.showMore = true;
    l.update();
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/newloc_3_settings.png'));
  });

  testWidgets('first run: Android version and what is needed', (tester) async {
    await _setup(tester);
    await tester.pumpWidget(_app(const Scaffold(backgroundColor: Colors.black, body: SizedBox.expand())));
    Get.dialog(const FirstRunNoteView());
    await tester.pumpAndSettle();
    expect(find.textContaining('اندروید ۹'), findsOneWidget);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/newloc_4_first_run.png'));
  });
}
