import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../core/eventbus/event_bus_const.dart';
import '../core/eventbus/event_bus_model.dart';
import '../core/utils/globals.dart';
import '../data/data_sources/remote_data_sources/socket/socket.dart';
import '../data/data_sources/remote_data_sources/socket/connection_keeper.dart';
import '../sd23/sd23_controller.dart';
import '../sim12/sim12_controller.dart';
import 'panel12_icons.dart';
import '../core/utils/loc_store.dart';
import 'panel12_simulator.dart';

/// یک سناریوی ذخیره‌شده روی پنل
class Panel12Scenario {
  /// وضعیت ۱۰ چراغ: '1' روشن، '0' خاموش، '2' بدون تغییر
  String st;

  /// پرده: 'O' باز، 'C' بسته، '-' بدون تغییر
  String c;

  /// تایمر: 'N' بدون تایمر، 'F' خاموشی خودکار بعد از [mins]، 'D' اجرا بعد از [mins]
  String tm;
  int mins;
  String name;

  Panel12Scenario({required this.st, this.c = '-', this.tm = 'N', this.mins = 0, required this.name});

  Panel12Scenario copy() => Panel12Scenario(st: st, c: c, tm: tm, mins: mins, name: name);

  int get onCount => st.split('').where((e) => e == '1').length;
  int get offCount => st.split('').where((e) => e == '0').length;
}

/// یک مرحله‌ی برنامه‌ی مسافرت
class Panel12VacStep {
  /// ساعت مرحله، دقیقه از نیمه‌شب (۰ تا ۱۴۳۹)
  int t;

  /// چراغ‌هایی که در این مرحله روشن‌اند (بقیه خاموش می‌شوند)
  List<bool> k;

  /// پرده: 'O' باز، 'C' بسته، '-' بدون تغییر
  String c;

  Panel12VacStep({required this.t, List<bool>? k, this.c = '-'})
      : k = k ?? List<bool>.filled(Panel12Controller.lightCount, false);

  Panel12VacStep copy() => Panel12VacStep(t: t, k: List<bool>.from(k), c: c);
}

/// برنامه‌ی مسافرت (روی خود پنل ذخیره و اجرا می‌شود)
class Panel12Vacation {
  bool on;

  /// شب اول و شب آخر (شماره‌ی روز از ۱ ژانویه‌ی ۲۰۰۰)
  int d0, d1;
  List<Panel12VacStep> steps;

  /// پایان: خاموشی کامل، ساعت و پرده
  int te;
  String ce;

  Panel12Vacation({this.on = true, required this.d0, required this.d1, required this.steps, this.te = 60, this.ce = '-'});

  bool get repeat => d1 > d0;

  Panel12Vacation copy() =>
      Panel12Vacation(on: on, d0: d0, d1: d1, steps: steps.map((e) => e.copy()).toList(), te: te, ce: ce);

  /// برنامه‌ی پیش‌فرض: از امروز تا یک هفته
  static Panel12Vacation defaults() {
    final today = Panel12Controller.dayNumber(DateTime.now());
    return Panel12Vacation(on: true, d0: today, d1: today + 7, steps: [
      Panel12VacStep(t: 18 * 60),
      Panel12VacStep(t: 21 * 60),
      Panel12VacStep(t: 23 * 60 + 30),
    ], te: 60, ce: '-');
  }

  /// زمان هر مرحله نسبت به نیمه‌شبِ شب شروع (بعد از نیمه‌شب = بیشتر از ۱۴۴۰)؛ null اگر نامعتبر
  List<int>? relTimes() {
    final out = <int>[];
    int day = 0, prev = -1;
    for (final t in [...steps.map((e) => e.t), te]) {
      if (prev >= 0 && t < prev) day++;
      if (prev >= 0 && t == prev) return null;
      final r = day * 1440 + t;
      if (r > 2879) return null;
      out.add(r);
      prev = t;
    }
    return out;
  }

  /// آیا این مرحله (یا پایان، با index = steps.length) روز بعد اجرا می‌شود؟
  bool nextDay(int index) {
    final r = relTimes();
    if (r == null) {
      // نامعتبر: فقط مقایسه با قبلی
      if (index == 0) return false;
      final prev = index - 1 < steps.length ? steps[index - 1].t : te;
      final cur = index < steps.length ? steps[index].t : te;
      return cur < prev;
    }
    return r[index] >= 1440;
  }
}

/// آینه‌ی پنل ۱۲ کلید (۱۰ روشنایی + پرده + دزدگیر + آسانسور).
/// همه‌ی وضعیت‌ها از خود پنل می‌آید؛ اپ فقط فرمان می‌فرستد و آنچه پنل گزارش می‌دهد را نشان می‌دهد.
class Panel12Controller extends GetxController {
  static Panel12Controller get instance {
    if (!Get.isRegistered<Panel12Controller>()) {
      Get.put(Panel12Controller(), permanent: true);
    }
    return Get.find<Panel12Controller>();
  }

  static const int lightCount = 10;
  static const int labelCount = 12; // ۱۰ روشنایی + پرده باز + پرده بسته
  static const int scenarioCount = 12;
  static const int labelBytes = 48; // ۲۴ حرف فارسی

  /// زمان هر پله‌ی پرده در پنل: ۲۷۰ تیک × ۲۵ میلی‌ثانیه
  static const Duration curtainStep = Duration(milliseconds: 6750);

  // ---------- وضعیت ----------
  final RxBool isRf12 = false.obs;

  /// نوع پنل معلوم شده؟ (تا آن موقع صفحه‌ی قدیمی نشان داده نمی‌شود)
  final RxBool modelKnown = false.obs;

  /// آخرین بار به پنل RF-12 وصل بودیم؟ (برای نمایش فوری صفحه‌ی پنل از همان ابتدا)
  final RxBool lastRf12 = false.obs;

  /// پنل ۲۳ کلید (دزدگیردار / ۲۰ پل): صفحه‌اش را Sd23Controller می‌سازد
  final RxBool isSd23 = false.obs;

  /// آخرین بار به پنل ۲۳ کلید وصل بودیم؟
  final RxBool lastSd23 = false.obs;

  /// پنل ۱۲ پل سیمکارتی: صفحه‌اش را Sim12Controller می‌سازد
  final RxBool isSim12 = false.obs;
  final RxBool lastSim12 = false.obs;

  final RxList<bool> lights = List<bool>.filled(lightCount, false).obs;
  final RxInt curtainPos = 0.obs; // ۰ کاملاً باز … ۹ کاملاً بسته
  final RxString curtainState = 'S'.obs; // O در حال باز شدن، C در حال بسته شدن، S ایستاده
  final RxDouble curtainClosed = 0.0.obs; // ۰ تا ۱، برای نمایش پیوسته‌ی حرکت پرده
  final RxBool armed = false.obs;
  final RxList<String> types = List<String>.filled(lightCount, 'a').obs;
  final RxList<String> labels = List<String>.filled(labelCount, '').obs;
  final RxList<String> iconIds = List<String>.filled(labelCount, '').obs;
  final RxSet<String> flashing = <String>{}.obs;

  // سناریوها (روی خود پنل ذخیره می‌شوند)
  final RxList<Panel12Scenario?> scenarios = List<Panel12Scenario?>.filled(scenarioCount, null).obs;

  /// سناریوهایی که تایمرشان در حال شمارش است: شماره (۰ تا ۱۱) ← دقیقه‌ی باقی‌مانده
  final RxMap<int, int> pending = <int, int>{}.obs;

  // برنامه‌ی مسافرت
  final Rxn<Panel12Vacation> vacation = Rxn<Panel12Vacation>();
  final RxBool vacLoaded = false.obs;

  /// ساعت پنل تنظیم است؟ (بعد از قطع برق تا اتصال دوباره‌ی گوشی تنظیم نیست)
  final RxBool panelClockOk = true.obs;

  /// آخرین مرحله‌ای که پنل اجرا کرد: '1' تا '6' یا 'E'
  final RxString vacLast = ''.obs;

  /// نتیجه‌ی ذخیره‌ی برنامه‌ی مسافرت: بعد از هر ذخیره‌ی تأییدشده توسط پنل یکی زیاد می‌شود
  final RxInt vacSaveOk = 0.obs;
  final RxBool vacSaving = false.obs;
  String? _vacExpect;

  /// پیام کوتاه برای همه‌ی صفحه‌ها (نتیجه‌ی فرمان‌ها، فقط بر اساس جواب پنل)
  final RxString notice = ''.obs;
  final RxString noticeType = ''.obs; // ok / err / wait
  Timer? _noticeTimer;

  /// سناریوهایی که پنل همین الان اجرا کرد (برای روشن شدن لحظه‌ای ردیف)
  final RxSet<int> scenarioRan = <int>{}.obs;

  /// فرمان‌هایی که منتظر تأیید پنل‌اند: کلید ← زمان‌سنج ۳ ثانیه‌ای
  final Map<String, Timer> _expects = {};

  /// ذخیره‌هایی که منتظر خواندن دوباره از پنل‌اند: کلید (مثلاً S03) ← مقدار مورد انتظار
  final Map<String, String> _writes = {};
  final Map<String, Timer> _writeTimers = {};

  /// تایمرهایی که در آخرین @M_PND گزارش شدند
  Set<int>? _pndSeen;

  /// پیش‌نمایش روی تصویر پنل (فقط در گوشی)
  final Rxn<List<bool>> previewLights = Rxn<List<bool>>();
  final RxString previewCurtain = ''.obs;

  // صفحه‌کلید دزدگیر
  final RxString entry = ''.obs; // '' ، 'arm' ، 'new'
  final RxString buf = ''.obs;
  final RxString message = ''.obs;
  final RxString messageType = ''.obs; // '' ، 'ok' ، 'err'

  // نمایش
  final RxInt zone = 0.obs;
  final RxInt touchedZone = (-1).obs;
  final RxBool installer = false.obs;

  /// حالت نمایشی: پنل مجازی داخل گوشی، بدون پنل واقعی
  final RxBool demo = false.obs;
  Panel12Simulator? _sim;

  final List<int> _rx = [];
  Timer? _msgTimer, _zoneTimer, _passHold, _armCheck, _modelTimer, _curtainTimer, _pendTimer;
  final List<Timer> _seq = [];
  List<bool>? _seqTarget;
  StreamSubscription? _busSub;

  static const String _kLastRf12 = 'panel12_last_rf12';
  static const String _kLastSd23 = 'panel12_last_sd23';
  static const String _kLastSim12 = 'panel12_last_sim12';

  void _loadLast() {
    lastRf12.value = LocStore.read<bool>(_kLastRf12) ?? false;
    lastSd23.value = LocStore.read<bool>(_kLastSd23) ?? false;
    lastSim12.value = LocStore.read<bool>(_kLastSim12) ?? false;
  }

  @override
  void onInit() {
    super.onInit();
    Socket.rawListener = onRaw;
    try {
      _loadLast();
    } catch (_) {}
    LocStore.listen(_loadLast);                        // آخرین نوع پنل هر مکان
    _busSub = eventBus.on<EventBusModel>().listen((e) {
      if (e.event == EventBusConst.eventSocketReconnect) reloadPanel();
    });    // پنل سیمکارتی با شماره‌ی پنل: قطع وای‌فای = حالت پیامکی در همان صفحه، نه صفحه‌ی «دستگاه پیدا نشد»
    ConnectionKeeper.holdOnLoss = () {
      final sim = isSim12.value || (!modelKnown.value && lastSim12.value);
      if (!sim) return false;
      try {
        return (LocStore.read<String>('sim12_panel_number') ?? '').isNotEmpty;
      } catch (_) {
        return false;
      }
    };
  }

  @override
  void onClose() {
    _busSub?.cancel();
    _pendTimer?.cancel();
    super.onClose();
  }

  // ---------- شروع ارتباط ----------

  /// بعد از اتصال به پنل: پرسیدن مدل. اگر پنل جواب نداد (فریمور قدیمی)، بعد از ۲٫۵ ثانیه صفحه‌ی قدیمی.
  void onSession() {
    _send('@M_MDL');
    if (isRf12.value) reloadPanel();
    _modelTimer?.cancel();
    _modelTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!isRf12.value && !isSd23.value && !isSim12.value) {
        modelKnown.value = true;
        _setLastRf12(false);
        _setLastSd23(false);
        _setLastSim12(false);
        Sim12Controller.instance.deactivate();
      }
    });
  }

  /// خواندن دوباره‌ی همه‌ی وضعیت‌ها از پنل
  void reloadPanel() {
    if (!isRf12.value) {
      _send('@M_MDL');
      return;
    }
    syncClock();
    _send('@M_F_T');
    _send('@TA1U');
    _send('@TA1V');
    _send('@X1Z');
    for (int i = 1; i <= labelCount; i++) {
      _send('@M_LBL#${_two(i)}');
    }
    askPending();
    for (int i = 1; i <= scenarioCount; i++) {
      _send('@M_SCN#${_two(i)}');
    }
    _send('@M_VAC');
  }

  // ---------- ساعت پنل ----------

  static final DateTime _epoch = DateTime.utc(2000, 1, 1);

  /// شماره‌ی روز از ۱ ژانویه‌ی ۲۰۰۰ (همان شمارش پنل)
  static int dayNumber(DateTime d) => DateTime.utc(d.year, d.month, d.day).difference(_epoch).inDays;

  static DateTime dateOf(int day) {
    final u = _epoch.add(Duration(days: day));
    return DateTime(u.year, u.month, u.day);
  }

  /// ساعت گوشی را روی پنل تنظیم می‌کند: &CLK#روز#دقیقه‌ی روز#ثانیه
  void syncClock() {
    final n = DateTime.now();
    final d = dayNumber(n).toString().padLeft(5, '0');
    final m = (n.hour * 60 + n.minute).toString().padLeft(4, '0');
    final sec = n.second.toString().padLeft(2, '0');
    _send('&CLK#$d#$m#$sec');
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  void _send(String s) => _sendBytes(utf8.encode(s));

  void _sendBytes(List<int> b) {
    if (demo.value) {
      _sim?.receive(b);
    } else {
      Socket.instance.send(b);
    }
  }

  void _setLastSim12(bool v) {
    lastSim12.value = v;
    try {
      LocStore.write(_kLastSim12, v);
    } catch (_) {}
  }

  void _setLastSd23(bool v) {
    lastSd23.value = v;
    try {
      LocStore.write(_kLastSd23, v);
    } catch (_) {}
  }

  void _setLastRf12(bool v) {
    lastRf12.value = v;
    try {
      LocStore.write(_kLastRf12, v);
    } catch (_) {}
  }

  // ---------- حالت نمایشی ----------

  void startDemo() {
    _resetState();
    _sim?.dispose();
    _sim = Panel12Simulator(onRaw);
    demo.value = true;
    zone.value = 0;
    _send('@M_MDL');
  }

  void stopDemo() {
    _sim?.dispose();
    _sim = null;
    demo.value = false;
    installer.value = false;
    _resetState();
  }

  void _resetState() {
    _rx.clear();
    _cancelSeq();
    _curtainTimer?.cancel();
    isRf12.value = false;
    isSd23.value = false;
    isSim12.value = false;
    modelKnown.value = false;
    lights.assignAll(List<bool>.filled(lightCount, false));
    curtainPos.value = 0;
    curtainState.value = 'S';
    curtainClosed.value = 0;
    armed.value = false;
    types.assignAll(List<String>.filled(lightCount, 'a'));
    labels.assignAll(List<String>.filled(labelCount, ''));
    iconIds.assignAll(List<String>.filled(labelCount, ''));
    scenarios.assignAll(List<Panel12Scenario?>.filled(scenarioCount, null));
    pending.clear();
    vacation.value = null;
    vacLoaded.value = false;
    vacSaving.value = false;
    _vacExpect = null;
    for (final t in _expects.values) {
      t.cancel();
    }
    _expects.clear();
    for (final t in _writeTimers.values) {
      t.cancel();
    }
    _writeTimers.clear();
    _writes.clear();
    _pndSeen = null;
    notice.value = '';
    scenarioRan.clear();
    panelClockOk.value = true;
    vacLast.value = '';
    previewLights.value = null;
    previewCurtain.value = '';
    entry.value = '';
    buf.value = '';
    message.value = '';
  }

  // ---------- دریافت و تجزیه‌ی پیام‌های پنل ----------

  void onRaw(List<int> data) {
    _rx.addAll(data);
    _parse();
  }

  bool _match(int i, String s) {
    if (i + s.length > _rx.length) return false;
    for (int k = 0; k < s.length; k++) {
      if (_rx[i + k] != s.codeUnitAt(k)) return false;
    }
    return true;
  }

  /// آیا بایت‌های باقی‌مانده می‌توانند ابتدای یک پیام ناقص باشند؟
  bool _partialPrefix(int i) {
    const prefixes = ['@TA1U', '@TA1Vp1-', '@X1Z1o', '#T*A1/U'];
    for (final p in prefixes) {
      final n = _rx.length - i;
      if (n >= p.length) continue;
      bool ok = true;
      for (int k = 0; k < n; k++) {
        if (_rx[i + k] != p.codeUnitAt(k)) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  void _parse() {
    int i = 0;
    while (i < _rx.length) {
      final c = _rx[i];

      if (c == 0x40) {
        // @
        if (_match(i, '@TA1U')) {
          if (_rx.length < i + 7) break;
          _confirm('lights');
          _applyLights(_rx[i + 5], _rx[i + 6]);
          i += 7;
          continue;
        }
        if (_match(i, '@TA1Vp1-')) {
          if (_rx.length < i + 10) break;
          _confirm('curtain');
          final p = _rx[i + 8] - 0x30;
          _applyCurtain(p >= 0 && p <= 9 ? p : curtainPos.value, String.fromCharCode(_rx[i + 9]));
          i += 10;
          continue;
        }
        if (_match(i, '@X1Z1o')) {
          if (_rx.length < i + 7) break;
          _applyAlarm(_rx[i + 6] == 0x6E); // 'n' = روشن
          i += 7;
          continue;
        }
        if (_partialPrefix(i)) break;
        i++;
        continue;
      }

      if (c == 0x24) {
        // $ ... $
        final end = _rx.indexOf(0x24, i + 1);
        if (end < 0) {
          if (_rx.length - i > 160) {
            i++;
            continue;
          }
          break;
        }
        _handleDollar(utf8.decode(_rx.sublist(i + 1, end), allowMalformed: true));
        i = end + 1;
        continue;
      }

      if (c == 0x23 && _match(i, '#T*A1/U')) {
        // پیکربندی: نوع ۱۰ پل روشنایی
        final start = i + 7;
        if (_rx.length < start + lightCount) break;
        final t = <String>[];
        for (int k = 0; k < lightCount; k++) {
          final ch = _rx[start + k];
          t.add((ch >= 0x61 && ch <= 0x7A) ? String.fromCharCode(ch) : 'a');
        }
        types.assignAll(t);
        _checkWrite('T', t.join());
        i = start + lightCount;
        continue;
      }
      if (c == 0x23 && _partialPrefix(i)) break;

      i++;
    }
    if (i > 0) _rx.removeRange(0, i > _rx.length ? _rx.length : i);
    if (_rx.length > 800) _rx.clear();
  }

  // ---------- چراغ‌ها: هم‌ترتیب با پنل ----------

  void _cancelSeq() {
    for (final t in _seq) {
      t.cancel();
    }
    _seq.clear();
    if (_seqTarget != null) {
      lights.assignAll(_seqTarget!);
      _seqTarget = null;
    }
  }

  void _applyLights(int b0, int b1) {
    final target = <bool>[];
    for (int k = 0; k < lightCount; k++) {
      final b = k < 8 ? b0 : b1;
      target.add(((b >> (7 - (k % 8))) & 1) == 1);
    }
    _cancelSeq();
    final changed = <int>[for (int k = 0; k < lightCount; k++) if (lights[k] != target[k]) k];
    if (changed.length <= 1) {
      lights.assignAll(target);
      return;
    }
    // پنل چند چراغ را با فاصله‌ی ۱۰۰ میلی‌ثانیه یکی‌یکی عوض می‌کند؛ Master در خاموشی از آخر به اول می‌رود
    final allOff = target.every((e) => !e) && lights.every((e) => e);
    final order = allOff ? changed.reversed.toList() : changed;
    _seqTarget = target;
    for (int n = 0; n < order.length; n++) {
      final k = order[n];
      _seq.add(Timer(Duration(milliseconds: 100 * n), () {
        final l = List<bool>.from(lights);
        l[k] = target[k];
        lights.assignAll(l);
        if (n == order.length - 1) {
          _seq.clear();
          _seqTarget = null;
        }
      }));
    }
  }

  // ---------- پرده: همان زمان‌بندی پنل ----------

  void _applyCurtain(int pos, String st) {
    curtainPos.value = pos;
    curtainState.value = st;
    _curtainTimer?.cancel();
    if (st != 'O' && st != 'C') {
      curtainClosed.value = pos / 9.0;
      return;
    }
    // پنل فقط شروع و پایان حرکت را گزارش می‌دهد؛ بین آن‌ها همان سرعت پنل محاسبه می‌شود
    final current = curtainClosed.value;
    if ((current - pos / 9.0).abs() > 1 / 9.0) curtainClosed.value = pos / 9.0;
    const tick = Duration(milliseconds: 200);
    final perTick = (1 / 9.0) * tick.inMilliseconds / curtainStep.inMilliseconds;
    _curtainTimer = Timer.periodic(tick, (t) {
      var v = curtainClosed.value + (st == 'C' ? perTick : -perTick);
      if (v <= 0 || v >= 1) {
        v = v.clamp(0.0, 1.0).toDouble();
        t.cancel();
      }
      curtainClosed.value = v;
    });
  }

  void _applyAlarm(bool on) {
    final changed = armed.value != on;
    armed.value = on;
    if (_armCheck != null) {
      _armCheck!.cancel();
      _armCheck = null;
      if (changed) {
        _say(on ? 'دزدگیر روشن شد' : 'دزدگیر خاموش شد', 'ok');
      } else {
        _say('کد اشتباه است', 'err');
      }
    }
  }

  void _handleDollar(String m) {
    if (m.startsWith('MDL=SIM12')) {
      // پنل ۱۲ پل سیمکارتی: صفحه‌ی مخصوص (کلیدها، دزدگیر، پرده، سناریو، سیمکارت)
      isRf12.value = false;
      isSd23.value = false;
      isSim12.value = true;
      modelKnown.value = true;
      _setLastRf12(false);
      _setLastSd23(false);
      _setLastSim12(true);
      Sim12Controller.instance.activate(m.substring(4));
      return;
    }
    if (isSim12.value && !m.startsWith('MDL=')) {
      Sim12Controller.instance.handle(m);
      return;
    }
    if (m.startsWith('MDL=SD23')) {
      // پنل ۲۳ کلید: صفحه‌ی مخصوص همین پنل (چیدمان، دزدگیر و متن کلیدها را خود پنل می‌فرستد)
      isRf12.value = false;
      isSd23.value = true;
      isSim12.value = false;
      _setLastSim12(false);
      Sim12Controller.instance.deactivate();
      modelKnown.value = true;
      _setLastRf12(false);
      _setLastSd23(true);
      Sd23Controller.instance.activate(m.substring(4));
      return;
    }
    if (isSd23.value && !m.startsWith('MDL=')) {
      Sd23Controller.instance.handle(m);
      return;
    }
    if (m.startsWith('MDL=')) {
      isSd23.value = false;
      _setLastSd23(false);
      isSim12.value = false;
      _setLastSim12(false);
      Sim12Controller.instance.deactivate();
      final rf = m.startsWith('MDL=RF12');
      final first = rf && !isRf12.value;
      isRf12.value = rf;
      modelKnown.value = true;
      _setLastRf12(rf);
      if (first) reloadPanel();
    } else if (m.startsWith('PASS=')) {
      _confirm('pass');
      _say(m == 'PASS=ok' ? 'رمز جدید ثبت شد' : 'رمز ثبت نشد (دزدگیر باید خاموش باشد)', m == 'PASS=ok' ? 'ok' : 'err');
    } else if (m.startsWith('EV=')) {
      // Exit یا Elevator روی پنل یا گوشی دیگر زده شد
      if (m == 'EV=E') {
        _confirm('exit');
        _flash('exit', 15000);
      }
      if (m == 'EV=L') {
        _confirm('elevator');
        _flash('elevator', 1000);
      }
      if (m == 'EV=M') {
        _confirm('master');
        _flash('master', 1200);
      }
    } else if (m.startsWith('RUN=') && m.length >= 7) {
      // پنل سناریو را اجرا کرد: RUN=03R   (یا RUN=03- یعنی چنین سناریویی روی پنل نیست)
      final n = int.tryParse(m.substring(4, 6));
      if (n == null || n < 1 || n > scenarioCount) return;
      _confirm('run$n');
      if (m[6] == 'R') {
        scenarioRan.add(n - 1);
        Timer(const Duration(milliseconds: 1500), () => scenarioRan.remove(n - 1));
      } else {
        _notify('این سناریو روی پنل ثبت نیست', 'err');
      }
    } else if (m == 'PE') {
      // پایان فهرست تایمرها: هر تایمری که گزارش نشد، روی پنل تمام شده است
      final seen = _pndSeen;
      _pndSeen = null;
      if (seen != null) {
        final p = Map<int, int>.from(pending)..removeWhere((k, v) => !seen.contains(k));
        pending.assignAll(p);
        _ensurePendTimer();
      }
    } else if (m.startsWith('VS#') && m.length >= 4) {
      vacLast.value = m.substring(3, 4);
    } else if (m.startsWith('V#')) {
      _parseVacation(m);
    } else if (m.length >= 4 && m[3] == '#' && (m[0] == 'L' || m[0] == 'S' || m[0] == 'P')) {
      final n = int.tryParse(m.substring(1, 3));
      if (n == null || n < 1) return;
      final body = m.substring(4);
      if (m[0] == 'L' && n <= labelCount) {
        // متن کلید به شکل «شماره‌ی آیکون~متن»
        final mm = RegExp(r'^(\d\d)~').firstMatch(body);
        iconIds[n - 1] = mm != null ? mm.group(1)! : '';
        labels[n - 1] = mm != null ? body.substring(3) : body;
        _checkWrite('L${_two(n)}', body);
      } else if (m[0] == 'S' && n <= scenarioCount) {
        scenarios[n - 1] = _parseScenario(body);
        _checkWrite('S${_two(n)}', body);
      } else if (m[0] == 'P' && n <= scenarioCount) {
        final left = int.tryParse(body) ?? 0;
        if (left > 0) _pndSeen?.add(n - 1);
        final p = Map<int, int>.from(pending);
        if (left > 0) {
          p[n - 1] = left;
        } else {
          p.remove(n - 1);
        }
        pending.assignAll(p);
        _ensurePendTimer();
      }
    }
  }

  /// زمان باقی‌مانده فقط از خود پنل: تا وقتی تایمری در حال شمارش است، هر دقیقه از پنل پرسیده می‌شود
  void _ensurePendTimer() {
    if (pending.isEmpty) {
      _pendTimer?.cancel();
      _pendTimer = null;
      return;
    }
    _pendTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
      if (pending.isEmpty) {
        _pendTimer?.cancel();
        _pendTimer = null;
        return;
      }
      askPending();
    });
  }

  /// @M_PND: پنل همه‌ی تایمرهای در حال شمارش را گزارش می‌دهد و با $PE$ تمام می‌کند
  void askPending() {
    _pndSeen = <int>{};
    _send('@M_PND');
  }

  // V#1#09410#09411#3#1080000-1260000-1410000-#0060C#1   یا   V#0#-#1
  void _parseVacation(String m) {
    final p = m.split('#');
    vacLoaded.value = true;
    if (p.length >= 4 && p[2] == '-') {
      vacation.value = null;
      panelClockOk.value = p[3] == '1';
      _checkVacation();
      return;
    }
    if (p.length < 8) return;
    final n = int.tryParse(p[4]) ?? 0;
    final d0 = int.tryParse(p[2]), d1 = int.tryParse(p[3]);
    if (d0 == null || d1 == null || n < 1 || n > vacSteps || p[5].length != n * 8 || p[6].length != 5) return;
    final steps = <Panel12VacStep>[];
    for (int k = 0; k < n; k++) {
      final x = p[5].substring(k * 8, k * 8 + 8);
      final t = int.tryParse(x.substring(0, 4)) ?? 0;
      final mask = int.tryParse(x.substring(4, 7), radix: 16) ?? 0;
      steps.add(Panel12VacStep(
        t: t % 1440,
        k: [for (int b = 0; b < lightCount; b++) ((mask >> b) & 1) == 1],
        c: 'OC-'.contains(x[7]) ? x[7] : '-',
      ));
    }
    vacation.value = Panel12Vacation(
      on: p[1] == '1',
      d0: d0,
      d1: d1,
      steps: steps,
      te: (int.tryParse(p[6].substring(0, 4)) ?? 0) % 1440,
      ce: 'OC-'.contains(p[6][4]) ? p[6][4] : '-',
    );
    panelClockOk.value = p[7] == '1';
    _checkVacation();
  }

  void _checkVacation() {
    final exp = _vacExpect;
    if (exp == null) return;
    final v = vacation.value;
    final got = v == null ? null : vacationCommand(v);
    _vacExpect = null;
    vacSaving.value = false;
    _writeTimers.remove('V')?.cancel();
    if (got == exp) {
      vacSaveOk.value++;
      _notify('برنامه‌ی مسافرت روی پنل ثبت شد', 'ok');
    } else {
      _notify('پنل برنامه را ثبت نکرد؛ دوباره ذخیره کنید', 'err');
    }
  }

  static Panel12Scenario? _parseScenario(String body) {
    // 1102222220OF0090#نام   یا   -
    if (body.length < 17 || body[16] != '#') return null;
    final st = body.substring(0, 10);
    if (!RegExp(r'^[012]{10}$').hasMatch(st)) return null;
    return Panel12Scenario(
      st: st,
      c: 'OC-'.contains(body[10]) ? body[10] : '-',
      tm: 'NFD'.contains(body[11]) ? body[11] : 'N',
      mins: int.tryParse(body.substring(12, 16)) ?? 0,
      name: body.substring(17),
    );
  }

  // ---------- فرمان‌ها ----------

  void toggleLight(int index) {
    // فقط یک بیت در هر فرمان: بایت‌هایی مثل «!» در پیام پنل را به اشتباه نمی‌اندازند
    final b = [0, 0];
    b[index ~/ 8] = 0x80 >> (index % 8);
    _expect('lights');
    _sendBytes([...utf8.encode('&TA1U'), ...b]);
  }

  // Master و Exit و Elevator فقط بعد از پیام اجرای پنل روشن می‌شوند
  void master() {
    _expect('master', seconds: 5);
    _send('&SCM');
  }

  void exitScenario() {
    _expect('exit');
    _send('&SCE');
  }

  void elevator() {
    _expect('elevator');
    _send('&TL');
  }

  /// پرده: هر کلید روشن می‌کند؛ لمس خودش یا کلید روبه‌رو متوقف می‌کند
  void curtain(bool open) {
    if (curtainState.value == 'O' || curtainState.value == 'C') {
      _expect('curtain');
      _send('&TA1Vp1S');
    } else {
      _expect('curtain');
      _send(open ? '&TA1Vp1O' : '&TA1Vp1C');
    }
  }

  // دزدگیر
  void onOff() {
    if (entry.value == 'arm') {
      entry.value = '';
      buf.value = '';
      _say('');
      return;
    }
    entry.value = 'arm';
    buf.value = '';
    _say(armed.value ? 'برای خاموش کردن، کد ۴ رقمی را وارد کنید' : 'برای روشن کردن، کد ۴ رقمی را وارد کنید',
        'sticky');
  }

  void digit(int d) {
    _flash('d$d', 400);
    if (entry.value.isEmpty) return;
    final b = buf.value + d.toString();
    if (b.length < 4) {
      buf.value = b;
      return;
    }
    final mode = entry.value;
    entry.value = '';
    buf.value = '';
    if (mode == 'arm') {
      _say('در حال بررسی…', 'sticky');
      _send('&X1Z1#$b');
      _armCheck?.cancel();
      _armCheck = Timer(const Duration(seconds: 3), () {
        _armCheck = null;
        _say('پنل جواب نداد', 'err');
      });
    } else {
      _say('در حال ثبت رمز…', 'sticky');
      _expect('pass');
      _send('&X1P#$b');
    }
  }

  void passDown() {
    if (armed.value) {
      _say('اول دزدگیر را خاموش کنید', 'err');
      return;
    }
    _say('دو ثانیه نگه دارید…', 'sticky');
    _passHold?.cancel();
    _passHold = Timer(const Duration(seconds: 2), () {
      _passHold = null;
      entry.value = 'new';
      buf.value = '';
      _say('رمز جدید ۴ رقمی را وارد کنید (اعداد ۱ تا ۶)', 'sticky');
    });
  }

  void passUp() {
    if (_passHold != null) {
      _passHold!.cancel();
      _passHold = null;
      if (entry.value.isEmpty) _say('');
    }
  }

  // ---------- سناریوها ----------

  /// اولین جای خالی (۰ تا ۱۱)، یا -۱ اگر هر ۱۲ سناریو پر است
  int get freeScenarioSlot => scenarios.indexWhere((e) => e == null);

  String defaultScenarioName() {
    final used = scenarios.where((e) => e != null).length;
    return 'سناریو ${faNum(used + 1)}';
  }

  void saveScenario(int idx, Panel12Scenario sc) {
    final name = cleanLabel(sc.name).isEmpty ? defaultScenarioName() : cleanLabel(sc.name);
    // کلیدی که انتخاب نشده خاموش می‌شود (پنل هم همین کار را می‌کند)
    final st = sc.st.replaceAll('2', '0');
    final s = Panel12Scenario(st: st, c: sc.c, tm: sc.tm, mins: sc.mins.clamp(0, 9999).toInt(), name: name);
    final body = '${s.st}${s.c}${s.tm}${s.mins.toString().padLeft(4, '0')}#${s.name}';
    // فهرست فقط بعد از خواندن دوباره از پنل عوض می‌شود
    _write('S${_two(idx + 1)}', body, 'Scn#${_two(idx + 1)}#$body#', '@M_SCN#${_two(idx + 1)}',
        okText: 'سناریو روی پنل ثبت شد');
  }

  void deleteScenario(int idx) {
    _write('S${_two(idx + 1)}', '-', 'Scd#${_two(idx + 1)}', '@M_SCN#${_two(idx + 1)}', okText: 'سناریو از پنل حذف شد');
    Timer(const Duration(milliseconds: 900), askPending);
  }

  void runScenario(int idx) {
    _expect('run${idx + 1}');
    _send('&RUN#${_two(idx + 1)}');
  }

  void cancelScenario(int idx) => _send('&CAN#${_two(idx + 1)}');

  // ---------- مسافرت ----------

  static const int vacSteps = 6;

  /// فرمان ذخیره‌ی برنامه؛ null اگر زمان‌ها نامعتبر باشند
  static String? vacationCommand(Panel12Vacation v) {
    final r = v.relTimes();
    if (r == null || v.steps.isEmpty || v.steps.length > vacSteps) return null;
    final b = StringBuffer('Vac#${v.on ? 1 : 0}#${v.d0.toString().padLeft(5, '0')}#'
        '${(v.d1 < v.d0 ? v.d0 : v.d1).toString().padLeft(5, '0')}#${v.steps.length}#');
    for (int k = 0; k < v.steps.length; k++) {
      int mask = 0;
      for (int i = 0; i < lightCount; i++) {
        if (v.steps[k].k[i]) mask |= 1 << i;
      }
      b.write(r[k].toString().padLeft(4, '0'));
      b.write(mask.toRadixString(16).toUpperCase().padLeft(3, '0'));
      b.write(v.steps[k].c);
    }
    b.write('#${r.last.toString().padLeft(4, '0')}${v.ce}#');
    return b.toString();
  }

  /// ذخیره روی پنل؛ پیام خطا یا null
  String? saveVacation(Panel12Vacation v) {
    final cmd = vacationCommand(v);
    if (cmd == null) return 'زمان مرحله‌ها درست نیست: دو مرحله هم‌زمان‌اند یا برنامه بیشتر از یک شبانه‌روز طول می‌کشد';
    // برنامه فقط بعد از خواندن دوباره از پنل «ذخیره شده» حساب می‌شود
    _vacExpect = cmd;
    vacSaving.value = true;
    _notify('در حال ذخیره روی پنل…', 'wait');
    syncClock();
    _send(cmd);
    Timer(const Duration(milliseconds: 700), () => _send('@M_VAC'));
    _writeTimers.remove('V')?.cancel();
    _writeTimers['V'] = Timer(const Duration(seconds: 4), () {
      _writeTimers.remove('V');
      if (_vacExpect == null) return;
      _vacExpect = null;
      vacSaving.value = false;
      _notify('پنل جواب نداد؛ برنامه ذخیره نشد', 'err');
    });
    return null;
  }

  Timer? _previewTimer;

  /// پیش‌نمایش مرحله‌ها روی تصویر پنل (پنل واقعی تغییری نمی‌کند)
  void previewVacation(Panel12Vacation v, void Function(int active) onStep) {
    _previewTimer?.cancel();
    int i = 0;
    void next() {
      if (i < v.steps.length) {
        final s = v.steps[i];
        previewLights.value = List<bool>.from(s.k);
        if (s.c != '-') previewCurtain.value = s.c;
        onStep(i);
        i++;
        _previewTimer = Timer(const Duration(milliseconds: 1600), next);
      } else if (i == v.steps.length) {
        previewLights.value = List<bool>.filled(lightCount, false);
        if (v.ce != '-') previewCurtain.value = v.ce;
        onStep(i);
        i++;
        _previewTimer = Timer(const Duration(milliseconds: 1600), next);
      } else {
        stopPreview();
        onStep(-1);
      }
    }

    previewCurtain.value = 'S';
    next();
  }

  void stopPreview() {
    _previewTimer?.cancel();
    _previewTimer = null;
    previewLights.value = null;
    previewCurtain.value = '';
  }

  // ---------- نصاب ----------

  /// رمز نصاب = ساعت فعلی گوشی به‌صورت برعکس (۱۰:۳۵ ← 5301). دقیقه‌ی قبل هم پذیرفته می‌شود.
  static bool checkInstallerPin(String pin) {
    String rev(DateTime t) {
      final s = '${t.hour.toString().padLeft(2, '0')}${t.minute.toString().padLeft(2, '0')}';
      return s.split('').reversed.join();
    }

    final now = DateTime.now();
    return pin == rev(now) || pin == rev(now.subtract(const Duration(minutes: 1)));
  }

  /// پاک‌سازی متن برای پروتکل پنل (حداکثر ۴۸ بایت = ۲۴ حرف فارسی)
  static String cleanLabel(String s) {
    var t = s.replaceAll(RegExp(r'[#\$!&@~\r\n]'), '').trim();
    while (utf8.encode(t).length > labelBytes) {
      t = t.substring(0, t.length - 1);
    }
    return t;
  }

  /// ذخیره‌ی انتخاب نصاب روی پنل: آیکون و متن یک کلید
  void saveKey({required int labelIndex, required String iconId, required String label}) {
    // متن و آیکون فقط بعد از خواندن دوباره از پنل عوض می‌شوند
    if (labelIndex < lightCount) {
      final t = List<String>.from(types);
      t[labelIndex] = PanelIcons.typeOf(iconId);
      _write('T', t.join(), 'Line#${t.join()}', '@M_F_T', okText: '');
    }
    final clean = cleanLabel(label);
    final n = _two(labelIndex + 1);
    Timer(Duration(milliseconds: labelIndex < lightCount ? 400 : 0), () {
      _write('L$n', iconId.isEmpty ? clean : '$iconId~$clean', 'Lbl#$n#$iconId~$clean#', '@M_LBL#$n',
          okText: 'روی پنل ثبت شد');
    });
  }

  String iconOf(int i) {
    if (iconIds[i].isNotEmpty) return iconIds[i];
    return i < lightCount ? PanelIcons.forType(types[i]) : '07';
  }

  static String faNum(int n) => n.toString().split('').map((d) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(d)]).join();

  /// شناسایی: پل را یک لحظه تغییر می‌دهد تا نصاب ببیند روی شیشه کدام کلید است
  void identify(int index) {
    toggleLight(index);
    Timer(const Duration(milliseconds: 1500), () => toggleLight(index));
  }

  // ---------- کمکی ----------

  void selectZone(int z) {
    zone.value = z;
    touchedZone.value = z;
    _zoneTimer?.cancel();
    _zoneTimer = Timer(const Duration(milliseconds: 700), () => touchedZone.value = -1);
  }

  // ---------- تأیید پنل ----------

  /// منتظر تأیید پنل: اگر تا [seconds] ثانیه جوابی نیاید، پیام «اجرا نشد»
  void _expect(String key, {int seconds = 3}) {
    _expects.remove(key)?.cancel();
    _expects[key] = Timer(Duration(seconds: seconds), () {
      _expects.remove(key);
      _notify('پنل جواب نداد؛ فرمان اجرا نشد', 'err');
    });
  }

  void _confirm(String key) => _expects.remove(key)?.cancel();

  /// نوشتن روی پنل و خواندن دوباره: فقط اگر پنل همان مقدار را برگرداند «ثبت شد»
  void _write(String key, String expected, String cmd, String readBack, {required String okText}) {
    _writes[key] = expected;
    _writeTimers.remove(key)?.cancel();
    if (okText.isNotEmpty) _notify('در حال ذخیره روی پنل…', 'wait');
    _send(cmd);
    Timer(const Duration(milliseconds: 500), () => _send(readBack));
    _writeTimers[key] = Timer(const Duration(seconds: 4), () {
      _writeTimers.remove(key);
      if (_writes.remove(key) != null) _notify('پنل جواب نداد؛ ذخیره نشد', 'err');
    });
    _writeOk[key] = okText;
  }

  final Map<String, String> _writeOk = {};

  void _checkWrite(String key, String got) {
    final exp = _writes.remove(key);
    if (exp == null) return;
    _writeTimers.remove(key)?.cancel();
    final ok = _writeOk.remove(key) ?? '';
    if (got == exp) {
      if (ok.isNotEmpty) _notify(ok, 'ok');
    } else {
      _notify('پنل تغییر را ثبت نکرد؛ دوباره امتحان کنید', 'err');
    }
  }

  void notify(String text, String type) => _notify(text, type);

  void _notify(String text, String type) {
    notice.value = text;
    noticeType.value = type;
    _noticeTimer?.cancel();
    _noticeTimer = Timer(Duration(milliseconds: type == 'wait' ? 5000 : 3000), () {
      notice.value = '';
      noticeType.value = '';
    });
  }

  void _flash(String id, int ms) {
    flashing.add(id);
    Timer(Duration(milliseconds: ms), () => flashing.remove(id));
  }

  void _say(String text, [String type = '']) {
    message.value = text;
    messageType.value = type;
    _msgTimer?.cancel();
    if (text.isNotEmpty && type != 'sticky') {
      _msgTimer = Timer(const Duration(milliseconds: 2500), () {
        message.value = '';
        messageType.value = '';
      });
    }
  }

  int get lightsOn => lights.where((e) => e).length;

  /// متن پیش‌فرض: چراغ ۱ تا چراغ ۱۲ (نصاب تغییرش می‌دهد)
  String labelOf(int i) => labels[i].isNotEmpty ? labels[i] : 'چراغ ${faNum(i + 1)}';
}
