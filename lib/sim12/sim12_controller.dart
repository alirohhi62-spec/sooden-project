import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/data_sources/remote_data_sources/socket/connection_keeper.dart';
import '../data/data_sources/remote_data_sources/socket/socket.dart';
import '../panel12/panel12_controller.dart';
import '../sd23/sd23_controller.dart';
import 'sim12_simulator.dart';
import 'sim12_sms.dart';

/// پنل ۱۲ پل سیمکارتی (دزدگیر + سیمکارت + وای‌فای).
///
/// شماره‌ی کلیدها (مثل پروگرامر):
///   ۰..۱۱ پل ۱ تا ۱۲، ۱۲..۱۴ کلید ۱۳ تا ۱۵ (K1..K3)، ۱۵..۲۰ سناریو S1..S6 (S5 خروج، S6 قفل کودک)،
///   ۲۱ مستر، ۲۲ آسانسور، ۲۳..۲۶ پرده ۱ باز / بسته، پرده ۲ باز / بسته.
///
/// وای‌فای (پیام‌های پنل بین دو $):
///   $MDL=SIM12-1.0$   $LAY#<۲۷ حرف>$   $K#<hex>$   $A#nn#1|0$   $Lnn#ii~متن$
///   $AL#s#z#o$  s: ۰ خاموش، ۱ مهلت خروج، ۲ فعال، ۳ مهلت ورود، ۴ آژیر؛ z زون‌های فعال، o زون‌های باز (بیت ۰ = زون ۱)
///   $ARM#ok|no|busy$   $SIM#g#b#op#credit$  (g ماژول، b آنتن ۰..۵، op اپراتور ۱ همراه اول ۲ ایرانسل ۳ رایتل، credit ریال یا - یا ?)
///   $EV#a;b;c$ (آخرین رویدادها، تازه‌ترین اول)، $EV1#a$ رویداد تازه؛ هر رویداد: روز.دقیقه.نوع.زون.منبع
/// فرمان‌ها: @M_MDL @M_LAY @K @M_LBL#nn @X1Z @M_SIM @M_EV &K#nn &X1A#m#f#dddd &X1D#dddd &CRD Lbl#nn#ii~متن#
///
/// پیامک (وقتی وای‌فای در دسترس نیست): به شماره‌ی سیمکارت پنل، از گوشی‌ای که شماره‌اش روی پنل ثبت است.
///   #L5ON #L5OFF #K1ON #S2ON #P1OPEN #P1CLOSE #P1STOP #ON #12ON #FAST #OFF #CREDIT #STATUS
///   جواب پنل:  #SD,s,z,o,pppp,b,c#   (pppp = hex پل‌های ۱ تا ۱۵ روشن)
class Sim12Controller extends GetxController {
  static Sim12Controller get instance {
    if (!Get.isRegistered<Sim12Controller>()) {
      Get.put(Sim12Controller(), permanent: true);
    }
    return Get.find<Sim12Controller>();
  }

  static const int keyCount = 27;
  static const int protocolMajor = 1;
  static const String defaultLay = 'LLLLLLLLLLLLLLLSSSSXHMEUWUW';

  /// آیا الان صفحه‌ی این پنل نشان داده می‌شود (پنل وصل یا آخرین پنل همین بوده)
  final RxBool active = false.obs;
  final RxBool demo = false.obs;
  final RxString version = ''.obs;

  // ---------- وضعیت ----------
  final RxString lay = defaultLay.obs;
  final RxInt bits = 0.obs;
  final RxList<String> labels = List<String>.filled(keyCount, '').obs;

  /// دزدگیر
  final RxInt alarm = 0.obs;
  final RxInt armedZones = 0.obs;
  final RxInt openZones = 0.obs;
  final RxBool alarmKnown = false.obs;

  /// سیمکارت
  final RxBool gsmOk = false.obs;
  final RxInt bars = 0.obs;
  final RxInt operator = 0.obs;
  final RxString credit = '-'.obs;
  final RxBool simKnown = false.obs;
  final RxBool creditBusy = false.obs;

  final RxList<Sim12Event> events = <Sim12Event>[].obs;

  // ---------- ارتباط ----------
  /// 'wifi' یا 'sms'
  final RxString link = 'wifi'.obs;
  /// کاربر دستی پیامک را انتخاب کرده
  final RxBool forceSms = false.obs;
  final RxString panelNumber = ''.obs;
  final RxBool smsWaiting = false.obs;
  final RxString lastSmsAt = ''.obs;

  // ---------- نمایش ----------
  final RxString tab = 'keys'.obs;
  final RxString message = ''.obs;
  final RxString messageType = ''.obs;
  final RxSet<int> pendingKeys = <int>{}.obs;
  final RxString savedCode = ''.obs;

  // ---------- نصاب ----------
  final RxBool installer = false.obs;
  final RxMap<int, Sim12Cf> cf = <int, Sim12Cf>{}.obs;
  final RxInt darkSec = (-1).obs; // خاموش شدن پنل بعد از بی‌کاری (۰ = هرگز)، -۱ = هنوز خوانده نشده
  List<int> _alRaw = const [];
  final Map<String, Timer> _writeTimers = {};

  Sim12Simulator? _sim;
  final List<int> _demoRx = [];
  Timer? _loadTimer, _msgTimer, _armTimer, _smsTimer;
  final List<String> _queue = [];
  final Map<int, Timer> _keyTimers = {};
  StreamSubscription? _smsSub;
  Worker? _linkWorker;

  static const _kNumber = 'sim12_panel_number';
  static const _kCode = 'sim12_code';
  static const _kForce = 'sim12_force_sms';

  @override
  void onInit() {
    super.onInit();
    try {
      panelNumber.value = (GetStorage().read(_kNumber) as String?) ?? '';
      savedCode.value = (GetStorage().read(_kCode) as String?) ?? '';
      forceSms.value = (GetStorage().read(_kForce) as bool?) ?? false;
    } catch (_) {}
    _smsSub = Sim12Sms.incoming.listen(_onSms, onError: (_) {});
    _linkWorker = ever(ConnectionKeeper.instance.state, (_) => updateLink());
    updateLink();
  }

  @override
  void onClose() {
    _smsSub?.cancel();
    _linkWorker?.dispose();
    super.onClose();
  }

  // ---------- کلیدها ----------

  String kindOf(int k) => k >= 0 && k < lay.value.length ? lay.value[k] : '-';
  bool isOn(int k) => ((bits.value >> k) & 1) == 1;

  static String defaultName(int k) {
    if (k < 12) return 'پل ${faNum(k + 1)}';
    if (k < 15) return ['بخاری', 'پریز', 'کولر'][k - 12];
    if (k < 21) return ['سناریو ۱', 'سناریو ۲', 'سناریو ۳', 'سناریو ۴', 'خروج', 'قفل کودک'][k - 15];
    if (k == 21) return 'مستر';
    if (k == 22) return 'آسانسور';
    return ['پرده ۱ باز', 'پرده ۱ بسته', 'پرده ۲ باز', 'پرده ۲ بسته'][k - 23];
  }

  String nameOf(int k) {
    final l = k < labels.length ? labels[k] : '';
    return l.isNotEmpty ? l : defaultName(k);
  }

  String kindText(int k) {
    switch (kindOf(k)) {
      case 'D':
        return 'خاموشی تأخیری';
      case 'P':
        return 'شاسی';
      case 'Y':
        return 'شاسی تأخیری';
      case 'T':
        return 'سرویسی';
      case 'O':
        return 'تایمر خاموشی';
      case 'U':
      case 'W':
        return 'پرده';
      case 'X':
        return 'خروج';
      case 'H':
        return 'قفل کودک';
      case 'Z':
        return 'خواب';
      case 'E':
        return 'آسانسور';
      case 'M':
        return 'مستر';
      case 'Q':
        return 'گروه';
      case 'K':
        return 'پمپ کولر';
      case 'F':
        return 'کولر کند';
      case 'G':
        return 'کولر تند';
      case 'S':
        return 'سناریو';
      case '-':
        return 'بدون کار';
    }
    return 'معمولی';
  }

  int get polesOn {
    int n = 0;
    for (int k = 0; k < 15; k++) {
      if (isOn(k)) n++;
    }
    return n;
  }

  // ---------- ورود و خروج ----------

  /// پنل با $MDL=SIM12-...$ خودش را معرفی کرد
  void activate(String mdl) {
    final p = mdl.split('-');
    version.value = p.length > 1 ? p.sublist(1).join('-') : '';
    active.value = true;
    reload();
  }

  void deactivate() {
    active.value = false;
  }

  void reload() {
    _queue
      ..clear()
      ..addAll([Sd23Controller.clockCommand(), '@M_LAY', '@K', '@X1Z', '@M_SIM', '@M_EV'])
      ..addAll([for (int i = 1; i <= keyCount; i++) '@M_LBL#${_two(i)}']);
    _pump();
  }

  void _pump() {
    if (_loadTimer != null) return;
    _loadTimer = Timer.periodic(const Duration(milliseconds: 260), (t) {
      if (_queue.isEmpty) {
        t.cancel();
        _loadTimer = null;
        return;
      }
      _sendWifi(_queue.removeAt(0));
    });
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String faNum(int n) {
    const d = '۰۱۲۳۴۵۶۷۸۹';
    return n.toString().split('').map((c) {
      final i = c.codeUnitAt(0) - 48;
      return i >= 0 && i <= 9 ? d[i] : c;
    }).join();
  }

  static String faMoney(String digits) {
    final s = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (s.isEmpty) return '';
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('٬');
      b.write(s[i]);
    }
    return b.toString().split('').map((c) => c == '٬' ? c : faNum(int.parse(c))).join();
  }

  // ---------- راه ارتباط ----------

  bool get wifiUp => demo.value || ConnectionKeeper.instance.state.value == LinkState.connected;

  void updateLink() {
    final was = link.value;
    link.value = (!forceSms.value && wifiUp) ? 'wifi' : 'sms';
    if (was == 'wifi' && link.value == 'sms' && !forceSms.value && panelNumber.value.isNotEmpty) {
      _say('وای‌فای پنل قطع شد؛ فرمان‌ها با پیامک می‌رود', 'err');
    } else if (was == 'sms' && link.value == 'wifi' && panelNumber.value.isNotEmpty) {
      _say('وای‌فای پنل وصل شد', 'ok');
    }
  }

  void toggleLink() {
    if (link.value == 'wifi') {
      if (panelNumber.value.isEmpty) {
        _say('اول شماره سیمکارت پنل را در بخش سیمکارت وارد کن', 'err');
        tab.value = 'sim';
        return;
      }
      forceSms.value = true;
    } else {
      forceSms.value = false;
      if (!wifiUp) _say('وای‌فای پنل در دسترس نیست؛ فرمان‌ها با پیامک می‌رود', 'err');
    }
    try {
      GetStorage().write(_kForce, forceSms.value);
    } catch (_) {}
    updateLink();
  }

  void setPanelNumber(String n) {
    panelNumber.value = n.replaceAll(RegExp(r'[^0-9+]'), '');
    try {
      GetStorage().write(_kNumber, panelNumber.value);
    } catch (_) {}
  }

  void setSavedCode(String c) {
    savedCode.value = c;
    try {
      GetStorage().write(_kCode, c);
    } catch (_) {}
  }

  bool get smsMode => link.value == 'sms';

  void _sendWifi(String s) {
    final b = utf8.encode(s);
    if (demo.value) {
      _sim?.receive(b);
    } else {
      Socket.instance.send(b);
    }
  }

  /// فرمان پیامکی: جواب پنل (#SD,...) صفحه را به‌روز می‌کند
  Future<void> _sendSms(String cmd) async {
    if (panelNumber.value.isEmpty) {
      _say('شماره سیمکارت پنل وارد نشده است', 'err');
      tab.value = 'sim';
      return;
    }
    if (demo.value) {
      smsWaiting.value = true;
      _sim?.sms(cmd);
      return;
    }
    final ok = await Sim12Sms.send(panelNumber.value, cmd);
    if (!ok) {
      _say('پیامک فرستاده نشد (اجازه پیامک یا شارژ گوشی را بررسی کن)', 'err');
      return;
    }
    smsWaiting.value = true;
    _say('پیامک فرستاده شد؛ منتظر جواب پنل...', 'sticky');
    _smsTimer?.cancel();
    _smsTimer = Timer(const Duration(seconds: 90), () {
      smsWaiting.value = false;
      _say('جوابی از پنل نیامد', 'err');
    });
  }

  void _onSms(Map<String, String> m) {
    final from = m['from'] ?? '', body = m['body'] ?? '';
    if (!_sameNumber(from, panelNumber.value)) return;
    handleSmsText(body);
  }

  /// متن پیامک پنل
  void handleSmsText(String body) {
    final i = body.indexOf('#SD,');
    if (i < 0) return;
    final e = body.indexOf('#', i + 1);
    if (e < 0) return;
    final p = body.substring(i + 4, e).split(',');
    if (p.length < 6) return;
    _smsTimer?.cancel();
    smsWaiting.value = false;
    alarm.value = int.tryParse(p[0]) ?? alarm.value;
    armedZones.value = int.tryParse(p[1]) ?? armedZones.value;
    openZones.value = int.tryParse(p[2]) ?? openZones.value;
    alarmKnown.value = true;
    final pm = int.tryParse(p[3], radix: 16);
    if (pm != null) bits.value = (bits.value & ~0x7FFF) | (pm & 0x7FFF);
    bars.value = int.tryParse(p[4]) ?? bars.value;
    gsmOk.value = true;
    simKnown.value = true;
    if (p[5].isNotEmpty && p[5] != '-') credit.value = p[5];
    creditBusy.value = false;
    final now = DateTime.now();
    lastSmsAt.value = '${faNum(now.hour)}:${faNum(now.minute).padLeft(2, '۰')}';
    _say('جواب پنل با پیامک رسید', 'ok');
  }

  static bool _sameNumber(String a, String b) {
    String d(String s) {
      final x = s.replaceAll(RegExp(r'[^0-9]'), '');
      return x.length > 10 ? x.substring(x.length - 10) : x;
    }

    return d(a).isNotEmpty && d(a) == d(b);
  }

  // ---------- فرمان‌ها ----------

  /// لمس یک کلید
  void press(int k) {
    if (smsMode) {
      final cmd = _smsKey(k);
      if (cmd == null) {
        _say('این کلید با پیامک کار نمی‌کند', 'err');
        return;
      }
      _sendSms(cmd);
      return;
    }
    pendingKeys.add(k);
    _keyTimers[k]?.cancel();
    _keyTimers[k] = Timer(const Duration(seconds: 3), () {
      pendingKeys.remove(k);
      _say('پنل جواب نداد', 'err');
    });
    _sendWifi('&K#${_two(k + 1)}');
  }

  String? _smsKey(int k) {
    final on = isOn(k);
    if (k < 12) return '#L${k + 1}${on ? 'OFF' : 'ON'}';
    if (k < 15) return '#K${k - 11}${on ? 'OFF' : 'ON'}';
    if (k >= 15 && k <= 18) return '#S${k - 14}ON';
    if (k >= 23) {
      final c = (k - 23) ~/ 2 + 1;
      if (on) return '#P${c}STOP';
      return '#P$c${(k - 23) % 2 == 0 ? 'OPEN' : 'CLOSE'}';
    }
    return null;
  }

  /// پرده: 0 باز، 1 توقف، 2 بسته
  void curtain(int c, int op) {
    final ko = 23 + c * 2, kc = ko + 1;
    if (smsMode) {
      _sendSms('#P${c + 1}${['OPEN', 'STOP', 'CLOSE'][op]}');
      return;
    }
    if (op == 1) {
      if (isOn(ko)) press(ko);
      if (isOn(kc)) press(kc);
      return;
    }
    final want = op == 0 ? ko : kc;
    if (!isOn(want)) press(want);
  }

  void allOff() {
    if (smsMode) {
      _say('خاموش کردن همه با پیامک نیست؛ پل‌ها را یکی‌یکی خاموش کن', 'err');
      return;
    }
    press(21);
  }

  /// دزدگیر: zones بیت‌های زون (۷ = همه)، fast بدون مهلت خروج
  void arm(String code, {int zones = 7, bool fast = false}) {
    if (smsMode) {
      _sendSms(fast ? '#FAST' : zones == 7 ? '#ON' : '#${_zoneDigits(zones)}ON');
      return;
    }
    _armWait();
    _sendWifi('&X1A#$zones#${fast ? 1 : 0}#$code');
  }

  void disarm(String code) {
    if (smsMode) {
      _sendSms('#OFF');
      return;
    }
    _armWait();
    _sendWifi('&X1D#$code');
  }

  static String _zoneDigits(int m) => [for (int i = 0; i < 3; i++) if ((m >> i) & 1 == 1) '${i + 1}'].join();

  void _armWait() {
    _armTimer?.cancel();
    _say('در حال فرستادن...', 'sticky');
    _armTimer = Timer(const Duration(seconds: 5), () => _say('دزدگیر جواب نداد', 'err'));
  }

  void checkCredit() {
    creditBusy.value = true;
    credit.value = '?';
    if (smsMode) {
      _sendSms('#CREDIT');
      return;
    }
    _sendWifi('&CRD');
    Timer(const Duration(seconds: 40), () {
      if (creditBusy.value) {
        creditBusy.value = false;
        if (credit.value == '?') credit.value = '-';
        _say('استعلام شارژ جواب نداد', 'err');
      }
    });
  }

  void refresh() {
    if (smsMode) {
      _sendSms('#STATUS');
    } else {
      reload();
    }
  }

  void setLabel(int k, String text) {
    if (smsMode) {
      _say('تغییر اسم فقط با وای‌فای', 'err');
      return;
    }
    final clean = text.replaceAll(RegExp(r'[#\$!&@~\r\n%]'), '').trim();
    final n = _two(k + 1);
    _expect('L$n');
    _sendWifi('Lbl#$n#FF~$clean#');
    Timer(const Duration(milliseconds: 600), () => _sendWifi('@M_LBL#$n'));
  }

  // ---------- نصاب ----------

  void setInstaller(bool on) {
    installer.value = on;
    if (on && !smsMode) {
      for (int k = 1; k <= keyCount; k++) {
        if (!_queue.contains('@M_CF#${_two(k)}')) _queue.add('@M_CF#${_two(k)}');
      }
      _queue.add('@M_CF#AL');
      _pump();
    }
  }

  /// یک زمان کلید: M دقیقه، T ثانیه (خروج / خواب)، 1 و 2 ثانیه
  void saveTime(int k, String f, int v) {
    if (smsMode) {
      _say('تنظیمات فقط با وای‌فای', 'err');
      return;
    }
    _expect('C${_two(k + 1)}');
    _sendWifi('Set#${_two(k + 1)}#$f#${v.toRadixString(16).toUpperCase().padLeft(f == 'T' ? 4 : 2, '0')}#');
  }

  /// خاموش شدن پنل بعد از بی‌کاری (ثانیه، ۰ = هرگز)
  void saveDark(int sec) {
    if (smsMode) {
      _say('تنظیمات فقط با وای‌فای', 'err');
      return;
    }
    String h(int v) => v.clamp(0, 255).toRadixString(16).toUpperCase().padLeft(2, '0');
    final a = _alRaw.length >= 3 ? _alRaw : const [20, 30, 60];
    _expect('AL');
    // سه عدد اول (زمان‌های دزدگیر قدیم پنل) همان که هست می‌ماند؛ دزدگیر این پنل میکروی خودش را دارد
    _sendWifi('Set#AL#${h(a[0])}#${h(a[1] < 1 ? 1 : a[1])}#${h(a[2] < 1 ? 1 : a[2])}#${h(sec)}#');
  }

  void resetSettings() {
    if (smsMode) return;
    _sendWifi('Set#RS#');
  }

  void _expect(String key) {
    _writeTimers.remove(key)?.cancel();
    _say('در حال ذخیره روی پنل…', 'sticky');
    _writeTimers[key] = Timer(const Duration(seconds: 4), () {
      if (_writeTimers.remove(key) != null) _say('پنل جواب نداد؛ ذخیره نشد', 'err');
    });
  }

  void _got(String key, bool ok) {
    final t = _writeTimers.remove(key);
    if (t == null) return;
    t.cancel();
    _say(ok ? 'روی پنل ثبت شد' : 'پنل این مقدار را قبول نکرد', ok ? 'ok' : 'err');
  }

  // ---------- پیام‌های پنل ----------

  void handle(String m) {
    if (m.startsWith('LAY#')) {
      var l = m.substring(4);
      if (l.length < keyCount) l = l.padRight(keyCount, '-');
      // پنلی که پروگرامر هنوز نقش کلیدها را ننوشته: همان چیدمان پیش‌فرض
      lay.value = l.replaceAll('-', '').isEmpty ? defaultLay : l.substring(0, keyCount);
    } else if (m.startsWith('K#')) {
      final v = int.tryParse(m.substring(2), radix: 16);
      if (v != null) {
        final changed = v ^ bits.value;
        bits.value = v;
        for (int k = 0; k < keyCount; k++) {
          if ((changed >> k) & 1 == 1) _done(k);
        }
      }
    } else if (m.startsWith('A#') && m.length >= 6) {
      final k = (int.tryParse(m.substring(2, 4)) ?? 0) - 1;
      _done(k);
      if (m.endsWith('#0')) _say('پنل این فرمان را الان قبول نکرد (قفل یا سناریو در حال اجرا)', 'err');
    } else if (m.startsWith('L') && m.length > 3 && m[3] == '#') {
      final k = (int.tryParse(m.substring(1, 3)) ?? 0) - 1;
      final t = m.indexOf('~');
      if (k >= 0 && k < keyCount) {
        labels[k] = t >= 0 ? m.substring(t + 1) : '';
        _got('L${_two(k + 1)}', true);
      }
    } else if (m.startsWith('CF#AL#')) {
      final p = m.substring(6).split('#');
      if (p.length >= 4) {
        _alRaw = [for (final x in p.take(4)) int.tryParse(x, radix: 16) ?? 0];
        darkSec.value = _alRaw[3];
        _got('AL', true);
      }
    } else if (m.startsWith('CF#')) {
      final p = m.substring(3).split('#');
      if (p.length >= 8) {
        final n = int.tryParse(p[0]) ?? 0;
        int h(String x) => int.tryParse(x, radix: 16) ?? 0;
        if (n >= 1 && n <= keyCount) {
          cf[n - 1] = Sim12Cf(h(p[1]), h(p[2]), h(p[3]), h(p[4]));
          _got('C${p[0]}', true);
        }
      }
    } else if (m.startsWith('SET#')) {
      if (m == 'SET#RS#ok') {
        _say('تنظیمات پروگرم برگشت؛ پنل دوباره روشن می‌شود', 'ok');
      } else {
        _got(m.startsWith('SET#AL') ? 'AL' : 'C${m.length >= 6 ? m.substring(4, 6) : ''}', false);
      }
    } else if (m.startsWith('AL#')) {
      final p = m.substring(3).split('#');
      alarm.value = int.tryParse(p[0]) ?? 0;
      if (p.length > 1) armedZones.value = int.tryParse(p[1]) ?? 0;
      if (p.length > 2) openZones.value = int.tryParse(p[2]) ?? 0;
      alarmKnown.value = true;
    } else if (m.startsWith('ARM#')) {
      _armTimer?.cancel();
      final r = m.substring(4);
      _say(r == 'ok' ? 'انجام شد' : r == 'busy' ? 'دزدگیر مشغول است؛ چند ثانیه بعد دوباره بزن' : 'رمز اشتباه است',
          r == 'ok' ? 'ok' : 'err');
    } else if (m.startsWith('SIM#')) {
      final p = m.substring(4).split('#');
      gsmOk.value = p.isNotEmpty && p[0] == '1';
      if (p.length > 1) bars.value = int.tryParse(p[1]) ?? 0;
      if (p.length > 2) operator.value = int.tryParse(p[2]) ?? 0;
      if (p.length > 3) {
        if (p[3] == '?') {
          creditBusy.value = true;
        } else {
          if (creditBusy.value && p[3] == '-') _say('استعلام شارژ انجام نشد', 'err');
          creditBusy.value = false;
          credit.value = p[3];
        }
      }
      simKnown.value = true;
    } else if (m.startsWith('EV#')) {
      events.assignAll(m.substring(3).split(';').map(Sim12Event.parse).whereType<Sim12Event>());
    } else if (m.startsWith('EV1#')) {
      final e = Sim12Event.parse(m.substring(4));
      if (e != null) {
        events.insert(0, e);
        if (events.length > 20) events.removeRange(20, events.length);
      }
    }
  }

  void _done(int k) {
    _keyTimers.remove(k)?.cancel();
    pendingKeys.remove(k);
  }

  void _say(String text, String type) {
    message.value = text;
    messageType.value = type;
    _msgTimer?.cancel();
    if (type != 'sticky') _msgTimer = Timer(const Duration(seconds: 3), () => message.value = '');
  }

  // ---------- حالت نمایشی ----------

  void startDemo() {
    _sim?.dispose();
    _sim = Sim12Simulator(_onDemoRaw);
    demo.value = true;
    Panel12Controller.instance.demo.value = true;
    updateLink();
    _sendWifi('@M_MDL');
  }

  void stopDemo() {
    _sim?.dispose();
    _sim = null;
    demo.value = false;
    Panel12Controller.instance.demo.value = false;
    active.value = Panel12Controller.instance.isSim12.value;
    updateLink();
    if (active.value) _sendWifi('@M_MDL');
  }

  void _onDemoRaw(List<int> data) {
    _demoRx.addAll(data);
    while (true) {
      final s = _demoRx.indexOf(0x24);
      if (s < 0) {
        _demoRx.clear();
        return;
      }
      final e = _demoRx.indexOf(0x24, s + 1);
      if (e < 0) {
        if (s > 0) _demoRx.removeRange(0, s);
        return;
      }
      final m = utf8.decode(_demoRx.sublist(s + 1, e), allowMalformed: true);
      _demoRx.removeRange(0, e + 1);
      if (m.startsWith('MDL=SIM12')) {
        activate(m.substring(4));
      } else if (m.startsWith('SMS:')) {
        handleSmsText(m.substring(4));
      } else {
        handle(m);
      }
    }
  }
}

/// تنظیمات یک کلید که پنل گزارش می‌دهد ($CF#nn#نوع#sec1#sec2#دقیقه#...$)
class Sim12Cf {
  const Sim12Cf(this.type, this.sec1, this.sec2, this.minutes);
  final int type, sec1, sec2, minutes;

  /// نوع‌های فریمور: ۳ سرویسی، ۴ تایمر خاموشی، ۵ خاموشی تأخیری، ۶ شاسی، ۷ پرده / کولر، ۱۱ خروج، ۱۲ خواب
  int get seconds => sec1 | (sec2 << 8);
}

/// یک رویداد دزدگیر
class Sim12Event {
  final int day, minute, type, zone, src;

  const Sim12Event(this.day, this.minute, this.type, this.zone, this.src);

  /// روز.دقیقه.نوع.زون.منبع
  static Sim12Event? parse(String s) {
    final p = s.split('.');
    if (p.length < 5) return null;
    final v = p.map((e) => int.tryParse(e) ?? -1).toList();
    if (v.any((e) => e < 0)) return null;
    return Sim12Event(v[0], v[1], v[2], v[3], v[4]);
  }

  static const _src = ['کی‌پد', 'ریموت', 'پیامک', 'اپ'];

  String get text {
    final by = src < _src.length ? ' با ${_src[src]}' : '';
    final z = zone > 0 ? '، زون ${Sim12Controller.faNum(zone)}' : '';
    switch (type) {
      case 1:
        return 'فعال شد$by';
      case 2:
        return 'غیرفعال شد$by';
      case 3:
        return 'آژیر$z';
      case 4:
        return 'برق رفت';
      case 5:
        return 'برق آمد';
      case 6:
        return 'مگنت باز شد$z';
    }
    return 'رویداد $type';
  }

  bool get isAlarm => type == 3 || type == 6;

  /// ساعت رویداد؛ روز دیگر: «دیروز» یا چند روز پیش. ساعت پنل معلوم نبوده: —
  String get when {
    if (day == 0 && minute == 0) return '-';
    final h = minute ~/ 60, m = minute % 60;
    final t = '${Sim12Controller.faNum(h)}:${Sim12Controller.faNum(m).padLeft(2, '۰')}';
    final ago = Sd23Controller.iranDay() - day;
    if (ago <= 0) return t;
    if (ago == 1) return 'دیروز $t';
    return '${Sim12Controller.faNum(ago)} روز پیش';
  }
}
