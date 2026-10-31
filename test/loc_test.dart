// چند مکان: انتخاب خودکار مکان از روی وای‌فای گوشی، و صفحه‌ی «به کدام مکان وصل شویم؟»
// flutter test --update-goldens test/loc_test.dart  ->  test/goldens/loc_*.png
import 'dart:io';

import 'package:bms/data/data_sources/local_data_sources/database/model/location.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/connection_requests/wrappers/connection_wraper/connection_wraper_impl.dart';
import 'package:bms/presentation/widgets/location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

final home = Location(id: 1, name: 'منزل', panelWifiName: 'sooden-A1B2', mac: '5c:cf:7f:a1:b2:c3', modemName: 'TP-Link_Home', staticIp: '5.160.20.11');
final villa = Location(id: 2, name: 'ویلا', panelWifiName: 'sooden-77F0', mac: '84:f3:eb:77:f0:12', modemName: 'Villa@Net');
final shop = Location(id: 3, name: 'مغازه', panelWifiName: 'sooden-0C9D', mac: '48:3f:da:0c:9d:44', staticIp: '94.182.7.30');

void main() {
  /* matchLocation reads the panel used last on a modem (HomeSwitch, phone storage): its own storage folder */
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (call) async => (Directory('/tmp/sooden_t_loc')..createSync(recursive: true)).path);
    await GetStorage.init();
  });

  test('in range of a panel: picked by its Wi-Fi, its modem, or its BSSID', () {
    final all = [home, villa, shop];
    expect(ConnectionWrapperImpl.matchLocation(all, 'sooden-77F0', '')?.id, 2);
    expect(ConnectionWrapperImpl.matchLocation(all, 'TP-Link_Home', '')?.id, 1);
    expect(ConnectionWrapperImpl.matchLocation(all, 'Villa@Net', '')?.id, 2);
    // panel Wi-Fi renamed: soft-AP BSSID differs from the stored MAC only in the first byte
    expect(ConnectionWrapperImpl.matchLocation(all, 'my panel', '4a:3f:da:0c:9d:44')?.id, 3);
    // out of range of all: null -> the app asks
    expect(ConnectionWrapperImpl.matchLocation(all, 'Cafe', '11:22:33:44:55:66'), isNull);
    expect(ConnectionWrapperImpl.matchLocation(all, '', ''), isNull);
  });

  testWidgets('out of range of all: which location?', (tester) async {
    final loader = FontLoader('dana')
      ..addFont(rootBundle.load('assets/fonts/Dana_FaNum_Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Dana_FaNum_Bold.ttf'));
    await loader.load();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'dana'),
      home: const Scaffold(backgroundColor: Color(0xFF0B0C10), body: SizedBox.expand()),
    ));
    Location? got;
    LocationPicker.ask([home, villa, shop], home).then((l) => got = l);
    await tester.pumpAndSettle();
    expect(find.text('به کدام مکان وصل شویم؟'), findsOneWidget);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/loc_1_picker.png'));
    await tester.tap(find.text('ویلا'));
    await tester.pumpAndSettle();
    expect(got?.id, 2);
  });
}
