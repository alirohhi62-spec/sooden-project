import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';

import '../../data/data_sources/local_data_sources/database/model/location.dart';
import '../../data/repositories/location_repository.dart';
import 'globals.dart';
import 'loc_store.dart';

/// شبکه‌ی منزل (گوشی به وای‌فای مودم همان مکان وصل است):
/// - آی‌پی پنل روی مودم: اگر عوض شده، پنل در شبکه پیدا می‌شود (از روی مک آدرس پنل)
/// - آی‌پی اینترنت مودم: خوانده و به‌جای آی‌پی استاتیک ذخیره می‌شود (اتصال از بیرون منزل)
/// - پورت پنل روی مودم با UPnP خودکار باز می‌شود (بدون رمز و صفحه‌ی تنظیمات مودم)
class HomeNet {
  HomeNet._();

  // وضعیت هر مکان (روی گوشی): upnp 'ok' | 'off' | 'fail'، cgnat true (آی‌پی مشترک)، pubIp، checkedAt
  static String? upnpOf(int? id) => LocStore.readFor<String>(id, 'net_upnp');
  static bool cgnatOf(int? id) => LocStore.readFor<bool>(id, 'net_cgnat') ?? false;
  static String? pubOf(int? id) => LocStore.readFor<String>(id, 'net_pub');

  static String _tail(String? m) {
    final h = (m ?? '').toLowerCase().replaceAll(RegExp('[^0-9a-f]'), '');
    return h.length >= 12 ? h.substring(h.length - 10) : '';
  }

  /// پنل در ip:port هست؟ مک آدرسی که پنل در جواب @M_IP می‌دهد (یا null)
  static Future<String?> probe(String ip, int port, {int ms = 700}) async {
    Socket? s;
    try {
      s = await Socket.connect(ip, port, timeout: Duration(milliseconds: ms));
      final done = Completer<String?>();
      final buf = <int>[];
      final sub = s.listen((d) {
        buf.addAll(d);
        final t = latin1.decode(buf, allowInvalid: true);
        final i = t.indexOf('%');
        if (i >= 0 && t.length >= i + 18 && !done.isCompleted) done.complete(t.substring(i + 1, i + 18));
      }, onError: (_) {
        if (!done.isCompleted) done.complete(null);
      }, onDone: () {
        if (!done.isCompleted) done.complete(null);
      });
      s.add(utf8.encode('@M_IP'));
      final r = await done.future.timeout(const Duration(milliseconds: 1500), onTimeout: () => null);
      await sub.cancel();
      return r;
    } catch (_) {
      return null;
    } finally {
      s?.destroy();
    }
  }

  /// جواب کامل @M_IP پنل: (مک، آی‌پی پنل روی مودم یا ''، اسم مودم) یا null
  /// %mac(17)+ip(16)+router name(20)%
  static Future<(String mac, String ip, String router)?> askIp(String ip, int port) async {
    Socket? s;
    try {
      s = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 1500));
      final done = Completer<String?>();
      final buf = <int>[];
      final sub = s.listen((d) {
        buf.addAll(d);
        final t = utf8.decode(buf, allowMalformed: true);
        final i = t.indexOf('%');
        final j = i >= 0 ? t.indexOf('%', i + 1) : -1;
        if (j > i && !done.isCompleted) done.complete(t.substring(i + 1, j));
      }, onError: (_) {
        if (!done.isCompleted) done.complete(null);
      }, onDone: () {
        if (!done.isCompleted) done.complete(null);
      });
      s.add(utf8.encode('@M_IP'));
      final r = await done.future.timeout(const Duration(seconds: 2), onTimeout: () => null);
      await sub.cancel();
      if (r == null) return null;
      final p = r.split('+');
      final mac = p.isNotEmpty ? p[0].trim() : '';
      final pip = p.length > 1 ? p[1].trim() : '';
      final rt = p.length > 2 ? p.sublist(2).join('+').replaceAll('\u0000', '').trim() : '';
      return (mac, RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(pip) && pip != '0.0.0.0' ? pip : '', rt);
    } catch (_) {
      return null;
    } finally {
      s?.destroy();
    }
  }

  static Future<bool> isPanel(String ip, Location l) async {
    final m = await probe(ip, l.port ?? 6269);
    return m != null && _tail(m) == _tail(l.mac);
  }

  /// پنل این مکان در شبکه‌ی منزل: همه‌ی آدرس‌های ۱ تا ۲۵۴ (گروه‌های ۶۴تایی، هم‌زمان)
  static Future<String?> findPanel(Location l) async {
    String? me;
    try {
      me = await NetworkInfo().getWifiIP();
    } catch (_) {}
    if (me == null || !RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(me)) return null;
    final pre = me.substring(0, me.lastIndexOf('.') + 1);
    final port = l.port ?? 6269;
    for (int a = 1; a < 255; a += 64) {
      final ips = [for (int i = a; i < a + 64 && i < 255; i++) '$pre$i']..remove(me);
      // اول فقط پورت باز (سریع)، بعد پرسیدن مک
      final open = <String>[];
      await Future.wait(ips.map((ip) async {
        try {
          final s = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 600));
          s.destroy();
          open.add(ip);
        } catch (_) {}
      }));
      for (final ip in open) {
        if (await isPanel(ip, l)) return ip;
      }
    }
    return null;
  }

  /// گوشی روی وای‌فای مودم این مکان است: آی‌پی پنل روی مودم درست است؟ اگر نه، پیدا و ذخیره شود
  static Future<void> checkLanIp(Location l, LocationRepository repo) async {
    final old = l.panelIpOnModem ?? '';
    if (old.isNotEmpty && await isPanel(old, l)) return;
    final ip = await findPanel(l);
    _log('checkLanIp', 'old $old -> ${ip ?? 'not found'}');
    if (ip != null && ip != old) {
      l.panelIpOnModem = ip;
      await repo.updateLocation(l);
    }
  }

  /// آی‌پی اینترنت مودم و باز کردن پورت (UPnP)؛ پشت صحنه، بعد از اتصال
  static Future<void> refreshOutside(Location l, LocationRepository repo) async {
    try {
      final port = l.port ?? 6269;
      final lan = l.panelIpOnModem ?? '';
      final pub = await publicIp();
      String? ext;
      String upnp = 'off';
      final gw = await Upnp.find();
      if (gw != null) {
        ext = await gw.externalIp();
        upnp = lan.isNotEmpty && await gw.map(port, lan) ? 'ok' : 'fail';
      }
      // آی‌پی واقعی ندارد: مودم آی‌پی خصوصی / مشترک گرفته یا با آی‌پی اینترنت فرق دارد
      final cgnat = ext != null && (isPrivate(ext) || (pub != null && ext != pub));
      LocStore.writeFor(l.id, 'net_upnp', upnp);
      LocStore.writeFor(l.id, 'net_cgnat', cgnat);
      if (pub != null) LocStore.writeFor(l.id, 'net_pub', pub);
      LocStore.writeFor(l.id, 'net_checked', DateTime.now().millisecondsSinceEpoch);
      final cur = (l.staticIp ?? '').trim();
      final isHost = cur.isNotEmpty && RegExp('[a-zA-Z]').hasMatch(cur);   // آدرس اسمی (DDNS): دست نمی‌خورد
      if (pub != null && !cgnat && !isHost && pub != cur && (upnp == 'ok' || cur.isNotEmpty)) {
        l.staticIp = pub;
        await repo.updateLocation(l);
        _log('refreshOutside', 'static ip $cur -> $pub');
      }
      _log('refreshOutside', 'pub $pub ext $ext upnp $upnp cgnat $cgnat');
    } catch (e) {
      _log('refreshOutside', 'error $e');
    }
  }

  static bool isPrivate(String ip) {
    final p = ip.split('.').map((e) => int.tryParse(e) ?? -1).toList();
    if (p.length != 4) return true;
    return p[0] == 10 ||
        p[0] == 127 ||
        p[0] == 0 ||
        (p[0] == 172 && p[1] >= 16 && p[1] <= 31) ||
        (p[0] == 192 && p[1] == 168) ||
        (p[0] == 169 && p[1] == 254) ||
        (p[0] == 100 && p[1] >= 64 && p[1] <= 127);
  }

  /// آی‌پی اینترنت (گوشی پشت مودم منزل: همان آی‌پی مودم)
  static Future<String?> publicIp() async {
    for (final u in ['https://api.ipify.org', 'https://ipv4.icanhazip.com', 'https://checkip.amazonaws.com']) {
      final t = await _get(u, 5);
      final ip = t?.trim() ?? '';
      if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(ip)) return ip;
    }
    return null;
  }

  static Future<String?> _get(String url, int sec) async {
    final c = HttpClient()..connectionTimeout = Duration(seconds: sec);
    try {
      final rq = await c.getUrl(Uri.parse(url));
      final rs = await rq.close().timeout(Duration(seconds: sec));
      if (rs.statusCode != 200) return null;
      return await rs.transform(utf8.decoder).join().timeout(Duration(seconds: sec));
    } catch (_) {
      return null;
    } finally {
      c.close(force: true);
    }
  }

  static void _log(String k, String v) => doLogGlobal('home_net', k, v);
}

/// مودم با UPnP (Internet Gateway Device): آی‌پی اینترنت مودم و باز کردن پورت
class Upnp {
  final Uri control;
  final String service;
  Upnp(this.control, this.service);

  static Future<Upnp?> find() async {
    final loc = await _ssdp();
    if (loc == null) return null;
    final xml = await HomeNet._get(loc, 4);
    if (xml == null) return null;
    for (final m in RegExp(r'<service>(.*?)</service>', dotAll: true).allMatches(xml)) {
      final b = m.group(1)!;
      final t = RegExp(r'<serviceType>\s*(.*?)\s*</serviceType>').firstMatch(b)?.group(1) ?? '';
      if (!t.contains('WANIPConnection') && !t.contains('WANPPPConnection')) continue;
      final c = RegExp(r'<controlURL>\s*(.*?)\s*</controlURL>').firstMatch(b)?.group(1);
      if (c == null) continue;
      return Upnp(Uri.parse(loc).resolve(c), t);
    }
    return null;
  }

  static Future<String?> _ssdp() async {
    RawDatagramSocket? s;
    try {
      s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final done = Completer<String?>();
      s.listen((e) {
        if (e != RawSocketEvent.read) return;
        final d = s!.receive();
        if (d == null) return;
        final t = latin1.decode(d.data, allowInvalid: true);
        final m = RegExp(r'^location:\s*(\S+)', caseSensitive: false, multiLine: true).firstMatch(t);
        if (m != null && !done.isCompleted) done.complete(m.group(1));
      });
      for (final st in [
        'urn:schemas-upnp-org:device:InternetGatewayDevice:1',
        'urn:schemas-upnp-org:device:InternetGatewayDevice:2',
        'urn:schemas-upnp-org:service:WANIPConnection:1',
      ]) {
        final msg = 'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: "ssdp:discover"\r\nMX: 2\r\nST: $st\r\n\r\n';
        s.send(utf8.encode(msg), InternetAddress('239.255.255.250'), 1900);
      }
      return await done.future.timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (_) {
      return null;
    } finally {
      s?.close();
    }
  }

  Future<String?> _soap(String action, Map<String, String> args) async {
    final c = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final body = '<?xml version="1.0"?>'
          '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
          '<s:Body><u:$action xmlns:u="$service">'
          '${args.entries.map((e) => '<${e.key}>${e.value}</${e.key}>').join()}'
          '</u:$action></s:Body></s:Envelope>';
      final rq = await c.postUrl(control);
      rq.headers.set('Content-Type', 'text/xml; charset="utf-8"');
      rq.headers.set('SOAPAction', '"$service#$action"');
      rq.add(utf8.encode(body));
      final rs = await rq.close().timeout(const Duration(seconds: 5));
      final t = await rs.transform(utf8.decoder).join().timeout(const Duration(seconds: 5));
      return rs.statusCode == 200 ? t : 'ERR:${RegExp(r'<errorCode>(\d+)</errorCode>').firstMatch(t)?.group(1) ?? rs.statusCode}';
    } catch (_) {
      return null;
    } finally {
      c.close(force: true);
    }
  }

  Future<String?> externalIp() async {
    final r = await _soap('GetExternalIPAddress', {});
    return r == null ? null : RegExp(r'<NewExternalIPAddress>\s*([\d.]+)\s*</NewExternalIPAddress>').firstMatch(r)?.group(1);
  }

  /// پورت بیرونی port مودم -> lan:port پنل (همیشگی؛ اگر مودم نپذیرفت، یک هفته‌ای و هر بار در منزل تازه می‌شود)
  Future<bool> map(int port, String lan) async {
    Map<String, String> a(int lease) => {
          'NewRemoteHost': '',
          'NewExternalPort': '$port',
          'NewProtocol': 'TCP',
          'NewInternalPort': '$port',
          'NewInternalClient': lan,
          'NewEnabled': '1',
          'NewPortMappingDescription': 'Sooden panel',
          'NewLeaseDuration': '$lease',
        };
    var r = await _soap('AddPortMapping', a(0));
    if (r != null && r.startsWith('ERR:718')) {
      // همین پورت برای آدرس دیگری (آی‌پی قبلی پنل) باز است: پاک و دوباره
      await _soap('DeletePortMapping', {'NewRemoteHost': '', 'NewExternalPort': '$port', 'NewProtocol': 'TCP'});
      r = await _soap('AddPortMapping', a(0));
    }
    if (r != null && r.startsWith('ERR:') && !r.startsWith('ERR:725')) r = await _soap('AddPortMapping', a(604800));
    return r != null && !r.startsWith('ERR:');
  }
}
