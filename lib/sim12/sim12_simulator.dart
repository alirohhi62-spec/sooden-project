import 'dart:async';
import 'dart:convert';

/// پنل سیمکارتی مجازی برای «حالت نمایشی»: همان فرمان‌ها و همان جواب‌های فریمور (SIM12 نسخه‌ی ۱)
class Sim12Simulator {
  Sim12Simulator(this.reply);

  final void Function(List<int>) reply;

  static const String lay = 'LLLLLLLLLLLLLLLSSSSXHMEUWUW';
  int _on = 0x0009;
  int _al = 0, _zones = 0, _open = 0;
  String _code = '1234';
  int _bars = 4;
  String _credit = '1245000';
  final Map<int, String> _lbl = {
    1: 'لوستر سالن', 2: 'هالوژن سالن', 3: 'آشپزخانه', 4: 'هود', 5: 'راهرو', 6: 'سرویس', 7: 'اتاق ۱', 8: 'اتاق ۲',
    9: 'حیاط', 10: 'نور مخفی', 11: 'تراس', 12: 'پارکینگ', 24: 'پرده سالن', 26: 'پرده خواب',
  };
  final List<String> _ev = ['0.495.2.0.1', '0.100.1.0.2', '0.1325.3.2.0'];
  final Map<int, Timer> _cur = {};
  Timer? _alT;

  int _dark = 60, _exitSec = 35, _fanMin = 15;
  final List<String> _acf = ['40', '30', '180', '1234', '09121111111', '09352222222', '', '09121111111', '', ''];
  static String _hx(int v, int n) => v.toRadixString(16).toUpperCase().padLeft(n, '0');
  // کلید ۴ سرویسی (هود)، S5 خروج؛ بقیه معمولی
  int _type(int n) => n == 4 ? 3 : n == 20 ? 11 : n == 22 ? 2 : 1;
  String _cf(int n) {
    final t = _type(n);
    final s1 = t == 11 ? _exitSec & 255 : 0, s2 = t == 11 ? _exitSec >> 8 : 0, m = t == 3 ? _fanMin : 0;
    return 'CF#${n.toString().padLeft(2, '0')}#${_hx(t, 2)}#${_hx(s1, 2)}#${_hx(s2, 2)}#${_hx(m, 2)}#000000#000000#0000';
  }

  void dispose() {
    for (final t in _cur.values) {
      t.cancel();
    }
    _alT?.cancel();
  }

  void _out(String s) => Timer(const Duration(milliseconds: 40), () => reply(utf8.encode('\$$s\$')));

  String get _k => 'K#${_on.toRadixString(16).toUpperCase()}';
  String get _alMsg => 'AL#$_al#$_zones#$_open';
  String get _simMsg => 'SIM#1#$_bars#1#$_credit';

  void receive(List<int> data) {
    final s = utf8.decode(data, allowMalformed: true);
    if (s.startsWith('@M_MDL')) return _out('MDL=SIM12-1.0');
    if (s.startsWith('@M_LAY')) return _out('LAY#$lay');
    if (s == '@K') return _out(_k);
    if (s.startsWith('@X1Z')) return _out(_alMsg);
    if (s.startsWith('@M_SIM')) return _out(_simMsg);
    if (s.startsWith('@M_EV')) return _out('EV#${_ev.join(';')}');
    if (s.startsWith('@M_LBL#')) {
      final n = int.tryParse(s.substring(7)) ?? 0;
      return _out('L${n.toString().padLeft(2, '0')}#FF~${_lbl[n] ?? ''}');
    }
    if (s.startsWith('Lbl#')) {
      final p = s.split('#');
      final n = int.tryParse(p[1]) ?? 0;
      final t = s.indexOf('~');
      _lbl[n] = t >= 0 ? s.substring(t + 1, s.length - 1) : '';
      return;
    }
    if (s == '@M_POS') return _out('POS#00#00');
    if (s == '&ACR') return _out('ACF#${_acf.join(',')}');
    if (s.startsWith('&ACS#')) {
      final p = s.split('#');
      const codes = ['E', 'N', 'S', 'P', '1', '2', '3', '4', '5', '6'];
      final i = codes.indexOf(p[1]);
      final v = p.length > 2 ? p[2] : '';
      if (i < 0 || (i == 1 && (int.tryParse(v) ?? 0) < 1) || (i == 3 && v.length != 4)) return _out('ACS#no');
      _acf[i] = v;
      return _out('ACS#ok');
    }
    if (s == '&SOFF') {
      _on &= ~0x0F3F;
      _out('SOFF#1');
      return _out(_k);
    }
    if (s == '@M_CF#AL') return _out('CF#AL#00#00#00#${_hx(_dark, 2)}');
    if (s.startsWith('@M_CF#')) {
      final n = int.tryParse(s.substring(6)) ?? 0;
      if (n >= 1 && n <= 27) _out(_cf(n));
      return;
    }
    if (s.startsWith('Set#AL#')) {
      final p = s.split('#');
      if (p.length > 5) _dark = int.tryParse(p[5], radix: 16) ?? _dark;
      return _out('CF#AL#00#00#00#${_hx(_dark, 2)}');
    }
    if (s.startsWith('Set#RS#')) return _out('SET#RS#ok');
    if (s.startsWith('Set#')) {
      final p = s.split('#');
      final n = int.tryParse(p[1]) ?? 0;
      final v = int.tryParse(p.length > 3 ? p[3] : '', radix: 16);
      final t = _type(n);
      final ok = v != null && ((p[2] == 'T' && t == 11) || (p[2] == 'M' && t == 3 && v >= 1));
      if (!ok) return _out('SET#${p[1]}#no');
      if (p[2] == 'T') _exitSec = v; else _fanMin = v;
      return _out(_cf(n));
    }
    if (s.startsWith('&K#')) {
      final k = (int.tryParse(s.substring(3)) ?? 0) - 1;
      if (k < 0 || k > 26) return;
      _press(k);
      _out('A#${(k + 1).toString().padLeft(2, '0')}#1');
      _out(_k);
      return;
    }
    if (s.startsWith('&X1A#')) {
      final p = s.split('#');
      if (p.length < 4 || p[3] != _code) return _out('ARM#no');
      final z = int.tryParse(p[1]) ?? 7, fast = p[2] == '1';
      _arm(z, fast, 3);
      return _out('ARM#ok');
    }
    if (s.startsWith('&X1D#')) {
      if (s.substring(5) != _code) return _out('ARM#no');
      _disarm(3);
      return _out('ARM#ok');
    }
    if (s.startsWith('&CRD')) {
      _out('SIM#1#$_bars#1#?');
      Timer(const Duration(seconds: 4), () => _out(_simMsg));
    }
  }

  void _event(int type, int zone, int src) {
    final n = DateTime.now();
    final e = '0.${n.hour * 60 + n.minute}.$type.$zone.$src';
    _ev.insert(0, e);
    _out('EV1#$e');
  }

  void _arm(int z, bool fast, int src) {
    _zones = z;
    _alT?.cancel();
    if (fast) {
      _al = 2;
    } else {
      _al = 1;
      _alT = Timer(const Duration(seconds: 8), () {
        _al = 2;
        _out(_alMsg);
      });
    }
    _event(1, 0, src);
    _out(_alMsg);
  }

  void _disarm(int src) {
    _alT?.cancel();
    _al = 0;
    _zones = 0;
    _event(2, 0, src);
    _out(_alMsg);
  }

  void _press(int k) {
    if (k == 21) {
      _on &= ~0x7FFF;
      return;
    }
    if (k >= 23) {
      final mate = (k - 23) % 2 == 0 ? k + 1 : k - 1;
      _cur[k]?.cancel();
      if ((_on >> k) & 1 == 1) {
        _on &= ~(1 << k);
        return;
      }
      _on &= ~(1 << mate);
      _cur[mate]?.cancel();
      _on |= 1 << k;
      _cur[k] = Timer(const Duration(seconds: 6), () {
        _on &= ~(1 << k);
        _out(_k);
      });
      return;
    }
    if (k >= 15 && k <= 18) {
      // سناریو: چند پل را روشن می‌کند
      _on |= [0x0003, 0x0030, 0x0F00, 0x000C][k - 15];
      return;
    }
    if (k == 19 || k == 20 || k == 22) return;
    _on ^= 1 << k;
  }

  /// فرمان پیامکی: جواب بعد از ۳ ثانیه
  void sms(String cmd) {
    var c = cmd.toUpperCase();
    if (c.startsWith('#')) c = c.substring(1);
    final m = RegExp(r'^([LK])(\d+)(ON|OFF)$').firstMatch(c);
    if (m != null) {
      final n = int.parse(m.group(2)!);
      final k = m.group(1) == 'L' ? n - 1 : 11 + n;
      if (k >= 0 && k < 15) {
        if (m.group(3) == 'ON') {
          _on |= 1 << k;
        } else {
          _on &= ~(1 << k);
        }
      }
    } else if (c == 'ON') {
      _arm(7, false, 2);
    } else if (c == 'FAST') {
      _arm(7, true, 2);
    } else if (RegExp(r'^[123]+ON$').hasMatch(c)) {
      int z = 0;
      for (final d in c.replaceAll('ON', '').split('')) {
        z |= 1 << (int.parse(d) - 1);
      }
      _arm(z, false, 2);
    } else if (c == 'OFF') {
      _disarm(2);
    } else if (c.startsWith('S') && c.endsWith('ON')) {
      final n = int.tryParse(c.substring(1, c.length - 2)) ?? 0;
      if (n >= 1 && n <= 4) _press(14 + n);
    } else if (c.startsWith('P')) {
      final n = int.tryParse(c.substring(1, 2)) ?? 0;
      if (n == 1 || n == 2) {
        final ko = 23 + (n - 1) * 2;
        if (c.endsWith('STOP')) {
          _on &= ~(3 << ko);
        } else {
          _press(c.endsWith('OPEN') ? ko : ko + 1);
        }
      }
    }
    final pm = (_on & 0x7FFF).toRadixString(16).toUpperCase();
    Timer(const Duration(seconds: 3), () {
      reply(utf8.encode('\$SMS:#SD,$_al,$_zones,$_open,$pm,$_bars,$_credit#\$'));
    });
  }
}
