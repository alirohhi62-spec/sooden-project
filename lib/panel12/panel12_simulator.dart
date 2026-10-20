import 'dart:async';
import 'dart:convert';

import 'package:get_storage/get_storage.dart';

/// پنل مجازی برای «حالت نمایشی»: به همان فرمان‌ها، با همان قالب پیام فریمور RF-12 (نسخه‌ی ۲) جواب می‌دهد.
class Panel12Simulator {
  Panel12Simulator(this.reply);

  final void Function(List<int>) reply;

  GetStorage? _box;
  final Map<String, dynamic> _mem = {};
  static const _kTypes = 'demo_types', _kCode = 'demo_code', _kLbl = 'demo_lbl_', _kScn = 'demo_scn_', _kVac = 'demo_vac';

  int _w0 = 0x90, _w1 = 0x00;
  int _pos = 0; // ۰ باز … ۹ بسته (مثل پنل)
  String _cState = 'S';
  bool _armed = false;
  Timer? _curtainTimer, _exitTimer, _minuteTimer, _vacTimer;
  bool _clockOk = false;
  String _vacLastKey = '';
  final Map<int, int> _pend = {};

  /// زمان هر پله‌ی پرده (مثل پنل ۶٫۷۵ ثانیه)
  static const Duration step = Duration(milliseconds: 6750);

  dynamic _read(String k) {
    try {
      _box ??= GetStorage();
      return _box!.read(k);
    } catch (_) {
      return _mem[k];
    }
  }

  void _write(String k, dynamic v) {
    _mem[k] = v;
    try {
      _box ??= GetStorage();
      _box!.write(k, v);
    } catch (_) {}
  }

  String get _types => (_read(_kTypes) as String?) ?? 'aaaaaaaaaa';
  String get _code => (_read(_kCode) as String?) ?? '1234';

  void dispose() {
    _curtainTimer?.cancel();
    _exitTimer?.cancel();
    _minuteTimer?.cancel();
    _vacTimer?.cancel();
  }

  void receive(List<int> bytes) {
    final s = latin1.decode(bytes, allowInvalid: true);
    Future.delayed(const Duration(milliseconds: 120), () => _handle(s, bytes));
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  void _handle(String s, List<int> bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    if (s.startsWith('@M_MDL')) return _str(r'$MDL=RF12-L10P1A1E1$');
    if (s.startsWith('@M_F_T')) return _str('#T*A1/U$_types/Vp1*L+#X1*Z1++');
    if (s.startsWith('@TA1U')) return _lights();
    if (s.startsWith('&TA1U') && bytes.length >= 7) {
      _w0 ^= bytes[5];
      _w1 ^= bytes[6] & 0xC0;
      return _lights();
    }
    if (s.startsWith('@TA1V')) return _curtainFrame();
    if (s.startsWith('&TA1Vp1O')) return _curtainKey('O');
    if (s.startsWith('&TA1Vp1C')) return _curtainKey('C');
    if (s.startsWith('&TA1Vp1S')) return _stopCurtain();
    if (s.startsWith('@X1Z')) return _alarm();
    if (s.startsWith('&X1Z1')) {
      if (s.length >= 10 && s[5] == '#' && s.substring(6, 10) == _code) _armed = !_armed;
      return _alarm();
    }
    if (s.startsWith('&X1P#') && s.length >= 9) {
      final c = s.substring(5, 9);
      final ok = !_armed && RegExp(r'^[1-6]{4}$').hasMatch(c);
      if (ok) _write(_kCode, c);
      return _str(ok ? r'$PASS=ok$' : r'$PASS=no$');
    }
    if (s.startsWith('&SCM')) {
      final allOn = _w0 == 0xFF && (_w1 & 0xC0) == 0xC0;
      _w0 = allOn ? 0 : 0xFF;
      _w1 = allOn ? 0 : 0xC0;
      _lights();
      return _str(r'$EV=M$');
    }
    if (s.startsWith('&SCE')) {
      _str(r'$EV=E$');
      _exitTimer?.cancel();
      _exitTimer = Timer(const Duration(seconds: 15), () {
        _w0 = 0;
        _w1 = 0;
        _lights();
        if (_cState == 'S' && _pos < 9) _curtainKey('C');
      });
      return;
    }
    if (s.startsWith('&TL')) return _str(r'$EV=L$');
    if (s.startsWith('Line#') && s.length >= 15) {
      _write(_kTypes, s.substring(5, 15));
      return _str('ok\n');
    }
    if (s.startsWith('Lbl#')) {
      final m = RegExp(r'^Lbl#(\d\d)#([^#]*)#').firstMatch(text);
      if (m != null) _write('$_kLbl${m.group(1)}', m.group(2));
      return _str('ok\n');
    }
    if (s.startsWith('@M_LBL#') && s.length >= 9) {
      final n = s.substring(7, 9);
      final t = (_read('$_kLbl$n') as String?) ?? '';
      return reply([...utf8.encode('\$L$n#'), ...utf8.encode(t), 0x24]);
    }
    if (s.startsWith('Scn#')) {
      final m = RegExp(r'^Scn#(\d\d)#([012]{10}[OC-][NFD]\d{4})#([^#]*)#').firstMatch(text);
      if (m != null) _write('$_kScn${m.group(1)}', '${m.group(2)}#${m.group(3)}');
      return _str('ok\n');
    }
    if (s.startsWith('Scd#') && s.length >= 6) {
      _write('$_kScn${s.substring(4, 6)}', null);
      _pend.remove(int.parse(s.substring(4, 6)) - 1);
      return _str('ok\n');
    }
    if (s.startsWith('@M_SCN#') && s.length >= 9) {
      final n = s.substring(7, 9);
      final v = _read('$_kScn$n') as String?;
      return reply([...utf8.encode('\$S$n#'), ...utf8.encode(v ?? '-'), 0x24]);
    }
    if (s.startsWith('&RUN#') && s.length >= 7) return _run(int.parse(s.substring(5, 7)) - 1);
    if (s.startsWith('&CAN#') && s.length >= 7) {
      final n = int.parse(s.substring(5, 7)) - 1;
      _pend.remove(n);
      return _report(n, 0);
    }
    // برنامه‌ی مسافرت و ساعت (مثل فریمور نسخه‌ی ۳)
    if (s.startsWith('&CLK#')) {
      _clockOk = true;
      _vacTimer ??= Timer.periodic(const Duration(seconds: 20), (_) => _vacCheck());
      return;
    }
    if (s.startsWith('Vac#')) {
      final ok = RegExp(r'^Vac#[01]#\d{5}#\d{5}#([1-6])#((?:\d{4}[0-9A-F]{3}[OC-])+)#\d{4}[OC-]#').firstMatch(s);
      final good = ok != null && ok.group(2)!.length == int.parse(ok.group(1)!) * 8;
      if (good) _write(_kVac, s.substring(4, ok.end - 1));
      return _str(good ? 'ok\n' : 'no\n');
    }
    if (s.startsWith('@M_VAC')) {
      final v = _read(_kVac) as String?;
      return _str('\$V#${v ?? '0#-'}#${_clockOk ? 1 : 0}\$');
    }
    if (s.startsWith('@M_PND')) {
      _pend.forEach((k, v) => _report(k, v));
      return _str(r'$PE$');
    }
  }

  // ---------- سناریو ----------

  void _run(int n) {
    final v = _read('$_kScn${_two(n + 1)}') as String?;
    if (v == null) return _str('\$RUN=${_two(n + 1)}-\$');
    final tm = v[11];
    final mins = int.parse(v.substring(12, 16));
    if (tm != 'D') _apply(v, false);
    if ((tm == 'F' || tm == 'D') && mins > 0) {
      _pend[n] = mins;
      _report(n, mins);
      _minuteTimer ??= Timer.periodic(const Duration(minutes: 1), (_) => _minute());
    }
    _str('\$RUN=${_two(n + 1)}R\$');
  }

  void _minute() {
    for (final n in _pend.keys.toList()) {
      final left = _pend[n]! - 1;
      if (left > 0) {
        _pend[n] = left;
        continue;
      }
      _pend.remove(n);
      final v = _read('$_kScn${_two(n + 1)}') as String?;
      if (v != null) _apply(v, v[11] == 'F');
      _report(n, 0);
    }
  }

  void _apply(String v, bool onlyOff) {
    for (int k = 0; k < 10; k++) {
      final st = v[k];
      final bit = k < 8 ? (0x80 >> k) : (0x80 >> (k - 8));
      final on = k < 8 ? (_w0 & bit) != 0 : (_w1 & bit) != 0;
      final want = onlyOff ? (st == '1' ? false : on) : st == '1'; // کلید انتخاب‌نشده خاموش
      if (want == on) continue;
      if (k < 8) {
        _w0 ^= bit;
      } else {
        _w1 ^= bit;
      }
    }
    _lights();
    if (onlyOff) return;
    final c = v[10];
    if (c == 'O' && _cState != 'O') {
      if (_cState == 'C') _stopCurtain();
      _curtainKey('O');
    }
    if (c == 'C' && _cState != 'C') {
      if (_cState == 'O') _stopCurtain();
      _curtainKey('C');
    }
  }

  /// هر ۲۰ ثانیه: آیا مرحله‌ای از برنامه‌ی مسافرت همین دقیقه است؟
  void _vacCheck() {
    final v = _read(_kVac) as String?;
    if (v == null || !v.startsWith('1#')) return;
    final p = v.split('#'); // 1, d0, d1, n, steps, end
    if (p.length < 6) return;
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day).difference(DateTime.utc(2000, 1, 1)).inDays;
    final d0 = int.parse(p[1]), d1 = int.parse(p[2]), n = int.parse(p[3]);
    for (int d = 0; d < 2; d++) {
      final night = today - d;
      if (night < d0 || night > d1) continue;
      final rel = d * 1440 + now.hour * 60 + now.minute;
      final key = '$night/$rel';
      if (key == _vacLastKey) return;
      if (int.parse(p[5].substring(0, 4)) == rel) {
        _vacLastKey = key;
        _setMask(0);
        _curtainTo(p[5][4]);
        return _str(r'$VS#E$');
      }
      for (int k = n - 1; k >= 0; k--) {
        final x = p[4].substring(k * 8, k * 8 + 8);
        if (int.parse(x.substring(0, 4)) != rel) continue;
        _vacLastKey = key;
        _setMask(int.parse(x.substring(4, 7), radix: 16));
        _curtainTo(x[7]);
        return _str('\$VS#${k + 1}\$');
      }
    }
  }

  void _setMask(int mask) {
    _w0 = 0;
    _w1 = 0;
    for (int k = 0; k < 10; k++) {
      if ((mask >> k) & 1 == 0) continue;
      if (k < 8) {
        _w0 |= 0x80 >> k;
      } else {
        _w1 |= 0x80 >> (k - 8);
      }
    }
    _lights();
  }

  void _curtainTo(String c) {
    if (c == 'O' && _cState != 'O') {
      if (_cState == 'C') _stopCurtain();
      _curtainKey('O');
    }
    if (c == 'C' && _cState != 'C') {
      if (_cState == 'O') _stopCurtain();
      _curtainKey('C');
    }
  }

  void _report(int n, int mins) => _str('\$P${_two(n + 1)}#${mins.toString().padLeft(4, '0')}\$');

  // ---------- پاسخ‌ها ----------

  void _str(String s) => reply(utf8.encode(s));

  void _lights() => reply([...utf8.encode('@TA1U'), _w0, _w1, 0, 0, 0]);

  void _curtainFrame() => reply(utf8.encode('@TA1Vp1-$_pos$_cState'));

  void _alarm() => _str(_armed ? '@X1Z1on' : '@X1Z1of');

  /// مثل پنل: کلید پرده حرکت را شروع می‌کند؛ لمس دوباره یا کلید روبه‌رو متوقف می‌کند.
  /// باز شدن موقعیت را کم می‌کند (۰ = کاملاً باز)، بسته شدن زیاد (۹ = کاملاً بسته). فقط شروع و پایان گزارش می‌شود.
  void _curtainKey(String dir) {
    if (_cState != 'S') return _stopCurtain();
    if ((dir == 'O' && _pos <= 0) || (dir == 'C' && _pos >= 9)) return _curtainFrame();
    _cState = dir;
    _curtainFrame();
    _curtainTimer?.cancel();
    _curtainTimer = Timer.periodic(step, (t) {
      _pos += dir == 'O' ? -1 : 1;
      if (_pos <= 0 || _pos >= 9) {
        _pos = _pos.clamp(0, 9).toInt();
        _cState = 'S';
        t.cancel();
      }
      _curtainFrame(); // مثل فریمور ۳٫۱: هر پله گزارش می‌شود
    });
  }

  void _stopCurtain() {
    _curtainTimer?.cancel();
    _cState = 'S';
    _curtainFrame();
  }
}
