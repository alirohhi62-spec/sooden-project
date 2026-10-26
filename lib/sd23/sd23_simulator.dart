import 'dart:async';
import 'dart:convert';

/// پنل ۲۳ کلید مجازی برای «حالت نمایشی»: به همان فرمان‌ها و با همان پیام‌های فریمور پنل (SD23 نسخه‌ی ۱) جواب می‌دهد.
class Sd23Simulator {
  Sd23Simulator(this.model, this.reply) {
    lay = layouts[model] ?? layouts['a14']!;
    for (int k = 0; k < 23; k++) {
      final t = lay[k];
      _type[k] = _typeOf(t);
      if (t == 'X') _s1[k] = 20;
      if (t == 'Z') _s1[k] = 30;
      if (t == 'T' || t == 'O') _min[k] = 10;
      if (t == 'U' || t == 'W') _s1[k] = 6;
    }
    // مستر: پیش‌فرض همه‌ی پل‌های معمولی
    for (int k = 0; k < 23; k++) {
      if (lay[k] == 'M') {
        for (final i in _kind('L')) {
          _onm[k] |= 1 << i;
        }
      }
    }
  }

  final String model;
  final void Function(List<int>) reply;

  static const Map<String, String> layouts = {
    'a14': 'LLLLLLLLLLLLnc1234UWXEZ',
    'a12': 'LLLLLLLLLLLLnc123456XEZ',
    'p20': 'LLLLLLLLLLLLLLLLLLLLMTX',
    'pc': 'LLLLLLLLKFGLUWSSQLLLMXZ',
  };

  late final String lay;
  int _on = 0;
  int _al = 0;
  String _code = '1234';
  final Map<int, String> _lbl = {};
  final Map<int, Timer> _timers = {};
  final List<int> _type = List<int>.filled(23, 1);
  final List<int> _s1 = List<int>.filled(23, 0);
  final List<int> _s2 = List<int>.filled(23, 0);
  final List<int> _min = List<int>.filled(23, 0);
  final List<int> _onm = List<int>.filled(23, 0);
  final List<int> _offm = List<int>.filled(23, 0);
  final Map<int, String> _phone = {};
  String? _vac;
  int _p2 = 0;
  bool get _peer => model == 'pc';
  int _alArm = 20, _alEntry = 30, _alSiren = 60, _dark = 60;
  Timer? _alTimer;
  bool _locked = false;

  bool get _alarm => lay.contains('n');

  static int _typeOf(String t) {
    const m = {'L': 1, 'M': 2, 'T': 3, 'O': 4, 'D': 5, 'P': 6, 'Y': 6, 'U': 7, 'W': 7, 'F': 7, 'G': 7, 'K': 1, 'X': 11, 'Z': 12, 'E': 13, 'S': 14, 'Q': 15, 'n': 9, 'c': 10, '-': 0};
    if ('123456789'.contains(t)) return 8;
    return m[t] ?? 1;
  }

  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    _alTimer?.cancel();
  }

  void receive(List<int> bytes) {
    final s = utf8.decode(bytes, allowMalformed: true);
    Future.delayed(const Duration(milliseconds: 120), () => _handle(s));
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _hx(int v, int n) => v.toRadixString(16).toUpperCase().padLeft(n, '0');

  void _out(String m) => reply(utf8.encode('\$$m\$'));

  void _state() => _out('K#${_hx(_on, 6)}');

  void _cf(int k) => _out('CF#${_two(k + 1)}#${_hx(_type[k], 2)}#${_hx(_s1[k], 2)}#${_hx(_s2[k], 2)}#${_hx(_min[k], 2)}#'
      '${_hx(_onm[k], 6)}#${_hx(_offm[k], 6)}#0000');

  int get _poles {
    int m = 0;
    for (int k = 0; k < 20; k++) {
      if ('LDKFGUW'.contains(lay[k])) m |= 1 << k;
    }
    return m;
  }

  void _handle(String s) {
    if (s.startsWith('@M_MDL')) return _out('MDL=SD23-$model-1.0');
    if (s.startsWith('@M_LAY')) return _out('LAY#$lay');
    if (s.startsWith('@M_CAP')) return _out('CAP#A${_alarm ? 1 : 0}R1W1S1${_peer ? 'P1' : ''}');
    // پنل دوم (نمایشی: مدل سفارشی با یک پنل چهار پل شبکه شده)
    if (s.startsWith('@M_P2')) {
      if (!_peer) return _out('P2#-');
      _out('P2#p4#${'LLML'.padRight(23, '-')}#1');
      return _out('P2K#${_hx(_p2, 6)}#1');
    }
    if (s.startsWith('&P2K#') && s.length >= 7) {
      final n = int.tryParse(s.substring(5, 7)) ?? 0;
      if (!_peer || n < 1 || n > 4) return _out('P2A#${_two(n)}#0');
      final k = n - 1;
      if (k == 2) {
        final any = (_p2 & 3) != 0;
        _p2 = any ? _p2 & ~3 : _p2 | 3;
      } else {
        _p2 ^= 1 << k;
      }
      _out('P2A#${_two(n)}#1');
      return _out('P2K#${_hx(_p2, 6)}#1');
    }
    if (s.startsWith('@K')) return _state();
    if (s.startsWith('@X1Z')) return _out('AL#$_al');
    if (s.startsWith('@M_CF#AL')) return _out('CF#AL#${_hx(_alArm, 2)}#${_hx(_alEntry, 2)}#${_hx(_alSiren, 2)}#${_hx(_dark, 2)}');
    if (s.startsWith('@M_CF#') && s.length >= 8) {
      final n = int.tryParse(s.substring(6, 8)) ?? 0;
      if (n >= 1 && n <= 23) _cf(n - 1);
      return;
    }
    if (s.startsWith('Set#AL#')) {
      final p = s.substring(7).split('#');
      if (p.length >= 4) {
        _alArm = int.tryParse(p[0], radix: 16) ?? _alArm;
        _alEntry = int.tryParse(p[1], radix: 16) ?? _alEntry;
        _alSiren = int.tryParse(p[2], radix: 16) ?? _alSiren;
        _dark = int.tryParse(p[3], radix: 16) ?? _dark;
      }
      return _out('CF#AL#${_hx(_alArm, 2)}#${_hx(_alEntry, 2)}#${_hx(_alSiren, 2)}#${_hx(_dark, 2)}');
    }
    if (s.startsWith('Set#RS#')) return _out('SET#RS#ok');
    if (s.startsWith('Set#') && s.length >= 10) {
      final n = int.tryParse(s.substring(4, 6)) ?? 0;
      final f = s[7];
      final v = int.tryParse(s.substring(9).split('#').first, radix: 16) ?? 0;
      if (n < 1 || n > 23) return;
      final k = n - 1;
      if (f == 'M') _min[k] = v;
      if (f == '1') _s1[k] = v;
      if (f == '2') _s2[k] = v;
      if (f == 'T') {
        _s1[k] = v & 255;
        _s2[k] = v >> 8;
      }
      if (f == 'O') _onm[k] = v & _poles & ~(1 << k);
      if (f == 'F') _offm[k] = v & _poles & ~_onm[k];
      return _cf(k);
    }
    if (s.startsWith('@M_LBL#') && s.length >= 9) {
      final n = int.tryParse(s.substring(7, 9)) ?? 0;
      return _out('L${_two(n)}#${_lbl[n] ?? ''}');
    }
    if (s.startsWith('Lbl#') && s.length >= 7) {
      final n = int.tryParse(s.substring(4, 6)) ?? 0;
      var body = s.substring(7);
      if (body.endsWith('#')) body = body.substring(0, body.length - 1);
      if (n >= 1 && n <= 23) _lbl[n] = body;
      return;
    }
    if (s.startsWith('Scn#') && s.length >= 33) {
      final n = int.tryParse(s.substring(4, 6)) ?? 0;
      var body = s.substring(7);
      if (body.endsWith('#')) body = body.substring(0, body.length - 1);
      if (n >= 1 && n <= 12) _phone[n] = body;
      return;
    }
    if (s.startsWith('@M_SCN#') && s.length >= 9) {
      final n = int.tryParse(s.substring(7, 9)) ?? 0;
      return _out('S${_two(n)}#${_phone[n] ?? '-'}');
    }
    if (s.startsWith('Scd#') && s.length >= 6) {
      _phone.remove(int.tryParse(s.substring(4, 6)) ?? 0);
      return;
    }
    if (s.startsWith('&RUN#') && s.length >= 7) {
      final n = int.tryParse(s.substring(5, 7)) ?? 0;
      final b = _phone[n];
      if (b == null) return _out('RUN=${_two(n)}-');
      for (int p = 0; p < 20; p++) {
        if (b[p] == '1' && ((_poles >> p) & 1) == 1) _on |= 1 << p;
        if (b[p] == '0' && ((_poles >> p) & 1) == 1) _on &= ~(1 << p);
      }
      _out('RUN=${_two(n)}R');
      return _state();
    }
    if (s.startsWith('&CAN#') || s.startsWith('@M_PND')) return _out('PND#');
    // ساعت: پنل نمایشی وانمود می‌کند که ساعت را از اینترنت دارد
    if (s.startsWith('&CLK#') || s.startsWith('@M_CLK')) {
      final n = DateTime.now().toUtc().add(const Duration(hours: 3, minutes: 30));
      final day = DateTime.utc(n.year, n.month, n.day).difference(DateTime.utc(2000, 1, 1)).inDays;
      return _out('CLK#1#${day.toString().padLeft(5, '0')}#${(n.hour * 60 + n.minute).toString().padLeft(4, '0')}#N');
    }
    if (s.startsWith('Vac#')) {
      var body = s.substring(4);
      if (body.endsWith('#')) body = body.substring(0, body.length - 1);
      if (body.split('#').length == 6) _vac = body;
      return;
    }
    if (s.startsWith('@M_VAC')) return _out('V#${_vac ?? '-'}#1#-');
    if (s.startsWith('&K#') && s.length >= 5) {
      final n = int.tryParse(s.substring(3, 5)) ?? 0;
      final ok = n >= 1 && n <= 23 && _press(n - 1);
      _out('A#${_two(n)}#${ok ? 1 : 0}');
      _state();
      return;
    }
    if (s.startsWith('&X1Z1#') && s.length >= 10) {
      final ok = _alarm && s.substring(6, 10) == _code;
      _out(ok ? 'ARM#ok' : 'ARM#no');
      if (ok) _toggleAlarm();
      return;
    }
    if (s.startsWith('&X1P#') && s.length >= 9) {
      final c = s.substring(5, 9);
      final ok = _alarm && _al == 0 && RegExp(r'^[1-6]{4}$').hasMatch(c);
      if (ok) _code = c;
      return _out(ok ? 'PASS=ok' : 'PASS=no');
    }
  }

  void _set(int k, bool v) {
    if (v) {
      _on |= 1 << k;
    } else {
      _on &= ~(1 << k);
    }
  }

  bool _isOn(int k) => ((_on >> k) & 1) == 1;

  Iterable<int> _kind(String t) sync* {
    for (int k = 0; k < 23; k++) {
      if (lay[k] == t) yield k;
    }
  }

  bool _press(int k) {
    final t = lay[k];
    if (t == '-' || t == 'n' || t == 'c' || '123456789'.contains(t)) return false;
    if (_locked) return false;
    switch (t) {
      case 'M':
        {
          final ps = [for (int i = 0; i < 20; i++) if (((_onm[k] >> i) & 1) == 1) i];
          final anyOn = ps.any(_isOn);
          for (final i in ps) {
            _set(i, !anyOn);
          }
          return true;
        }
      case 'S':
        {
          for (int i = 0; i < 20; i++) {
            if (((_onm[k] >> i) & 1) == 1) _set(i, true);
            if (((_offm[k] >> i) & 1) == 1) _set(i, false);
          }
          return true;
        }
      case 'Q':
        {
          bool anyOn = false;
          for (int i = 0; i < 20; i++) {
            if (((_onm[k] >> i) & 1) == 1 && _isOn(i)) anyOn = true;
          }
          for (int i = 0; i < 20; i++) {
            if (((_onm[k] >> i) & 1) == 1) _set(i, !anyOn);
          }
          return true;
        }
      case 'T':
        for (final i in _kind('L').take(3)) {
          _set(i, true);
        }
        return true;
      case 'U':
      case 'W':
      case 'F':
      case 'G':
        {
          const pair = {'U': 'W', 'W': 'U', 'F': 'G', 'G': 'F'};
          final other = lay.indexOf(pair[t]!);
          final curtain = t == 'U' || t == 'W';
          if (_isOn(k)) {
            _set(k, false);
            return true;
          }
          if (other >= 0 && _isOn(other)) {
            _set(other, false);
            if (curtain) return true;
          }
          _set(k, true);
          if (curtain) {
            _timers[k]?.cancel();
            _timers[k] = Timer(Duration(seconds: _s1[k] == 0 ? 6 : _s1[k]), () {
              _set(k, false);
              _state();
            });
          }
          return true;
        }
      case 'E':
        _set(k, true);
        _timers[k]?.cancel();
        _timers[k] = Timer(const Duration(seconds: 1), () {
          _set(k, false);
          _state();
        });
        return true;
      case 'X':
      case 'Z':
        {
          if (_isOn(k)) return true;
          _set(k, true);
          final secs = _s1[k] | (_s2[k] << 8);
          _locked = secs < 60;
          _timers[k]?.cancel();
          _timers[k] = Timer(Duration(seconds: secs), () {
            _locked = false;
            for (final i in _kind('L')) {
              _set(i, false);
            }
            _set(k, false);
            _state();
          });
          return true;
        }
    }
    _set(k, !_isOn(k));
    return true;
  }

  void _toggleAlarm() {
    _alTimer?.cancel();
    if (_al == 0) {
      _al = 1;
      _out('AL#1');
      _alTimer = Timer(Duration(seconds: _alArm), () {
        _al = 2;
        _out('AL#2');
      });
    } else {
      _al = 0;
      _out('AL#0');
    }
  }
}
