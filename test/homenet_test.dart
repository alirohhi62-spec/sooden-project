// شبکه‌ی منزل: شناختن پنل از روی مک، آی‌پی اینترنت خصوصی / مشترک، باز کردن پورت روی مودم (UPnP، مودم ساختگی)
import 'dart:convert';
import 'dart:io';

import 'package:bms/core/utils/home_net.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('private / shared addresses', () {
    expect(HomeNet.isPrivate('192.168.1.1'), isTrue);
    expect(HomeNet.isPrivate('10.20.0.5'), isTrue);
    expect(HomeNet.isPrivate('172.20.1.1'), isTrue);
    expect(HomeNet.isPrivate('100.72.3.4'), isTrue); // CGNAT
    expect(HomeNet.isPrivate('5.160.20.11'), isFalse);
    expect(HomeNet.isPrivate('172.32.1.1'), isFalse);
  });

  test('the panel is known by its MAC (soft-AP MAC differs in the first byte)', () async {
    final srv = await ServerSocket.bind('127.0.0.1', 0);
    srv.listen((c) {
      c.listen((d) {
        if (utf8.decode(d).contains('@M_IP')) c.add(utf8.encode('%5c:cf:7f:3f:2a:10+192.168.1.50    +MyHome%'));
      });
    });
    final l = Location(id: 1, port: srv.port, mac: '5e:cf:7f:3f:2a:10');
    expect(await HomeNet.isPanel('127.0.0.1', l), isTrue);
    final other = Location(id: 2, port: srv.port, mac: '84:f3:eb:77:f0:12');
    expect(await HomeNet.isPanel('127.0.0.1', other), isFalse);
    expect(await HomeNet.isPanel('127.0.0.1', Location(id: 3, port: 1, mac: l.mac)), isFalse); // nothing there
    await srv.close();
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('the panel says its address on the modem (@M_IP)', () async {
    final srv = await ServerSocket.bind('127.0.0.1', 0);
    var ip = '0.0.0.0         ';
    srv.listen((c) {
      c.listen((d) {
        if (utf8.decode(d).contains('@M_IP')) c.add(utf8.encode('%f0:24:f9:cb:2f:f9+$ip+aramdaftar\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000%'));
      });
    });
    var r = await HomeNet.askIp('127.0.0.1', srv.port);
    expect(r?.$1, 'f0:24:f9:cb:2f:f9');
    expect(r?.$2, '');                    // not on the modem yet
    expect(r?.$3, 'aramdaftar');
    ip = '192.168.1.37    ';
    r = await HomeNet.askIp('127.0.0.1', srv.port);
    expect(r?.$2, '192.168.1.37');
    final w = await HomeNet.askIpWhy('127.0.0.1', srv.port);
    expect(w.$1, 'ok');
    expect(w.$2?.$2, '192.168.1.37');
    expect((await HomeNet.askIpWhy('127.0.0.1', 1)).$1, 'no-connect');
    await srv.close();
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('the panel black box (@M_DBG / @M_DBS)', () async {
    final srv = await ServerSocket.bind('127.0.0.1', 0);
    srv.listen((c) {
      c.listen((d) {
        final q = utf8.decode(d);
        if (q.contains('@M_DBG')) c.add(utf8.encode(r'$DBG#R1B0E1J1W3P1F0Q0C1S0A1I0$$DBL#+CWJAP:3|FAIL$'));
        if (q.contains('@M_DBS')) c.add(utf8.encode(r'$DBS#-$$DBT#$'));
      });
    });
    final live = await HomeNet.askDbg('127.0.0.1', srv.port, '@M_DBG');
    expect(live, ['DBG: R1B0E1J1W3P1F0Q0C1S0A1I0', 'DBL: +CWJAP:3|FAIL']);
    final saved = await HomeNet.askDbg('127.0.0.1', srv.port, '@M_DBS');
    expect(saved, ['DBS: -', 'DBT: ']);
    expect(await HomeNet.askDbg('127.0.0.1', 1, '@M_DBG'), isNull);
    await srv.close();
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('UPnP: external address and port mapping (718 conflict -> delete, add again)', () async {
    final calls = <String>[];
    bool mapped = false;
    final http = await HttpServer.bind('127.0.0.1', 0);
    http.listen((rq) async {
      final body = await utf8.decoder.bind(rq).join();
      final act = (rq.headers.value('SOAPAction') ?? '').split('#').last.replaceAll('"', '');
      calls.add(act);
      String out;
      int code = 200;
      if (act == 'GetExternalIPAddress') {
        out = '<NewExternalIPAddress>5.160.20.11</NewExternalIPAddress>';
      } else if (act == 'AddPortMapping' && !mapped && calls.where((c) => c == 'DeletePortMapping').isEmpty) {
        code = 500;
        out = '<UPnPError><errorCode>718</errorCode></UPnPError>';
      } else if (act == 'AddPortMapping') {
        mapped = body.contains('<NewInternalClient>192.168.1.50</NewInternalClient>') && body.contains('<NewExternalPort>6269</NewExternalPort>');
        out = '<u:AddPortMappingResponse/>';
      } else {
        out = '<ok/>';
      }
      rq.response.statusCode = code;
      rq.response.write('<s:Envelope><s:Body>$out</s:Body></s:Envelope>');
      await rq.response.close();
    });
    final gw = Upnp(Uri.parse('http://127.0.0.1:${http.port}/ctl'), 'urn:schemas-upnp-org:service:WANIPConnection:1');
    expect(await gw.externalIp(), '5.160.20.11');
    expect(await gw.map(6269, '192.168.1.50'), isTrue);
    expect(mapped, isTrue);
    expect(calls, ['GetExternalIPAddress', 'AddPortMapping', 'DeletePortMapping', 'AddPortMapping']);
    await http.close(force: true);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
