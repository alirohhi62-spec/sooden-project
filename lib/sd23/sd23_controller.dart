import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/data_sources/remote_data_sources/socket/socket.dart';
import '../panel12/panel12_controller.dart';
import '../core/utils/loc_store.dart';
import 'sd23_simulator.dart';

/// تنظیمات یک کلید که پنل گزارش می‌دهد: $CF#nn#نوع#sec1#sec2#دقیقه#روشن‌ها#خاموش‌ها#ثانیه‌ی باقی‌مانده$
class Sd23Cf {
  final int type, sec1, sec2, minutes, on, off, left;

  const Sd23Cf(this.type, this.sec1, this.sec2, this.minutes, this.on, this.off, this.left);

  /// زمان EXIT و SLEEP (ثانیه)
  int get secs16 => sec1 | (sec2 << 8);
}

/// یک سناریوی گوشی (روی پنل ذخیره می‌شود)
class Sd23PhoneScn {
  /// ۲۰ حرف برای جای ۱ تا ۲۰: '1' روشن، '0' خاموش، '2' بدون تغییر
  String st;

  /// 'N' بدون تایمر، 'F' خاموشی بعد از [mins] دقیقه، 'D' اجرا بعد از [mins] دقیقه
  String tm;
  int mins;
  String name;

  Sd23PhoneScn({required this.st, this.tm = 'N', this.mins = 0, required this.name});

  Sd23PhoneScn copy() => Sd23PhoneScn(st: st, tm: tm, mins: mins, name: name);

  int get onCount => st.split('').where((e) => e == '1').length;
  int get offCount => st.split('').where((e) => e == '0').length;
}

/// یک مرحله‌ی برنامه‌ی مسافرت
class Sd23VacStep {
  /// ساعت مرحله، دقیقه از نیمه‌شب (۰ تا ۱۴۳۹)
  int t;

  /// پل‌های روشن در این مرحله (بیت k = جای k+1)؛ بقیه‌ی چراغ‌ها خاموش می‌شوند
  int lights;

  /// پرده: 'O' باز، 'C' بسته، '-' بدون تغییر
  String c;

  Sd23VacStep({required this.t, this.lights = 0, this.c = '-'});

  Sd23VacStep copy() => Sd23VacStep(t: t, lights: lights, c: c);

  bool has(int k) => ((lights >> k) & 1) == 1;

  int get count {
    int n = 0;
    for (int k = 0; k < 20; k++) {
      if (has(k)) n++;
    }
    return n;
  }
}

/// برنامه‌ی مسافرت پنل ۲۳ کلید (روی خود پنل ذخیره و با ساعت پنل اجرا می‌شود)
class Sd23Vacation {
  bool on;

  /// شب اول و شب آخر (شماره‌ی روز از ۱ ژانویه‌ی ۲۰۰۰، به وقت ایران)
  int d0, d1;
  List<Sd23VacStep> steps;

  /// پایان: همه‌ی چراغ‌ها خاموش، ساعت و پرده
  int te;
  String ce;

  Sd23Vacation({this.on = true, required this.d0, required this.d1, required this.steps, this.te = 60, this.ce = '-'});

  bool get repeat => d1 > d0;

  Sd23Vacation copy() => Sd23Vacation(on: on, d0: d0, d1: d1, steps: steps.map((e) => e.copy()).toList(), te: te, ce: ce);

  /// برنامه‌ی پیش‌فرض: از امشب تا یک هفته
  static Sd23Vacation defaults() {
    final today = Sd23Controller.iranDay();
    return Sd23Vacation(on: true, d0: today, d1: today + 7, steps: [
      Sd23VacStep(t: 18 * 60),
      Sd23VacStep(t: 21 * 60),
      Sd23VacStep(t: 23 * 60 + 30),
    ], te: 60, ce: '-');
  }

  /// زمان هر مرحله (و پایان) نسبت به نیمه‌شبِ شروع آن شب (بعد از نیمه‌شب = ۱۴۴۰ به بالا)؛ null اگر نامعتبر
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
    if (r == null || index >= r.length) return false;
    return r[index] >= 1440;
  }
}

/// پنل‌های ۲۳ کلید سودن (دزدگیردار و ۲۰ پل) با وای‌فای.
///
/// هر پنل وقتی وصل می‌شود خودش را معرفی می‌کند و برنامه از روی همان، صفحه‌ی مخصوص آن پنل را می‌سازد:
///   $MDL=SD23-a14-1.0$        مدل (همان شناسه‌ی پروگرامر) و نسخه‌ی پروتکل
///   $LAY#LLLLLLLLLLLLnc1234UWXEZ$   نقش ۲۳ کلید (جای ۱ تا ۲۰، سناریو ۱ تا ۳)
///   $CAP#A1R1W1S1$            دزدگیر / ریموت / وای‌فای / تنظیمات و سناریوهای گوشی
///   $K#00000F$                روشن/خاموش ۲۳ کلید (بیت ۰ = جای ۱)
///   $AL#n$                    دزدگیر: ۰ خاموش، ۱ در حال فعال شدن، ۲ فعال، ۳ مهلت ورود، ۴ آژیر
///   $Lnn#ii~متن$               متن و آیکون هر کلید
///   $CF#nn#...$               زمان‌ها و پل‌های یک کلید (سناریوها)، $CF#AL#...$ زمان‌های دزدگیر
///   $Snn#...$ ، $RUN=nnR$ ، $PND#...$   سناریوهای گوشی
///   $CLK#1#روز#دقیقه#P|N$ ، $CLK#0$   ساعت پنل (P از گوشی، N از اینترنت؛ ۰ = برق رفته و ساعت معلوم نیست)
///   $V#...$                   برنامه‌ی مسافرت
/// فرمان‌ها: &K#nn ، &X1Z1#dddd ، &X1P#dddd ، Lbl#nn#ii~متن# ، Set#nn#f#hex# ، Set#AL#.. ، Set#RS# ،
///           Scn#nn#.. ، Scd#nn ، &RUN#nn ، &CAN#nn ، @M_PND ، &CLK#.. ، @M_CLK ، Vac#.. ، @M_VAC
///
/// حرف‌های نقش کلید (پروگرامر می‌نویسد):
///   L پل معمولی، D خاموشی تأخیری، P شاسی، Y شاسی تأخیری، K پمپ کولر، F کولر کند، G کولر تند،
///   U پرده باز، W پرده بسته، M مستر، T سرویسی، O تایمر خاموشی، X خروج (EXIT)، Z خواب (SLEEP)،
///   E آسانسور، S سناریو سفارشی، Q گروه، ۱ تا ۹ رقم صفحه‌کلید دزدگیر، n کلید ON/OFF، c تغییر رمز، - خالی.
/// حرف ناشناخته (پنل‌های آینده) مثل یک پل نشان داده می‌شود و لمسش به پنل فرستاده می‌شود.
class Sd23Controller extends GetxController {
  static Sd23Controller get instance {
    if (!Get.isRegistered<Sd23Controller>()) {
      Get.put(Sd23Controller(), permanent: true);
    }
    return Get.find<Sd23Controller>();
  }

  static const int keyCount = 23;
  static const int labelBytes = 40; // ۲۰ حرف فارسی
  static const int phoneCount = 12;
  static const int phoneNameBytes = 18; // ۹ حرف فارسی
  static const int protocolMajor = 1;

  /// جای کلیدها روی شیشه: ستون چپ، ستون راست، وسط (ردیف به ردیف) و سه کلید پایین
  static const List<int> leftKeys = [0, 2, 4, 6, 8, 10];
  static const List<int> rightKeys = [1, 3, 5, 7, 9, 11];
  static const List<List<int>> middleRows = [
    [12, 13],
    [14, 15],
    [16, 17],
    [18, 19],
  ];
  static const List<int> bottomKeys = [20, 21, 22];

  /// گروه‌های صفحه (زبانه‌ها)
  static const String gPoles = 'poles', gCooler = 'cooler', gCurtain = 'curtain', gScn = 'scn', gAlarm = 'alarm';

  static const Map<String, String> modelNames = {
    'a14': 'دزدگیردار ۱۴ پل',
    'a12': 'دزدگیردار ۱۲ پل',
    'a10': 'دزدگیردار ۱۰ پل',
    'a8': 'دزدگیردار ۸ پل',
    'a6': 'دزدگیردار ۶ پل',
    'ac': 'دزدگیردار سفارشی',
    'ac6': 'دزدگیردار سفارشی',
    'p20': 'پنل ۲۰ پل',
    'p6': 'شش پل',
    'e12': '۱۲ اقتصادی',
    'p14': 'پنل پل + سناریو',
    'pc': 'پنل ۲۰ پل سفارشی',
    // پنل‌های ۱ تا ۴ پل (پنل دوم شبکه)
    'p1': 'تک پل',
    'p2': 'دو پل',
    'p3m': 'سه پل + مستر',
    'p4': 'چهار پل',
  };

  // ---------- وضعیت (همه از خود پنل) ----------
  final RxString model = ''.obs;
  final RxString version = ''.obs;
  final RxBool tooNew = false.obs;
  final RxString lay = ('-' * keyCount).obs;
  final RxBool layKnown = false.obs;
  final RxBool hasAlarm = false.obs;
  final RxBool hasRemote = false.obs;
  final RxBool hasSettings = false.obs;

  /// پنل تنظیمات کلیدها را می‌دهد (S1، یا C1 برای پنل بدون سناریوی گوشی مثل شش پل)
  final RxBool hasCf = false.obs;

  /// پنل برنامه‌ی مسافرت دارد (V0 = ندارد)
  final RxBool hasVac = true.obs;
  final RxInt bits = 0.obs;
  final RxInt alarm = 0.obs;
  final RxList<String> labels = List<String>.filled(keyCount, '').obs;
  final RxList<String> iconIds = List<String>.filled(keyCount, '').obs;
  final RxSet<String> flashing = <String>{}.obs;

  /// تنظیمات کلیدها (فقط کلیدهایی که پرسیده شده‌اند)
  final RxMap<int, Sd23Cf> cf = <int, Sd23Cf>{}.obs;

  /// زمان‌های دزدگیر و خاموش شدن پنل: فعال شدن، مهلت ورود، آژیر، خاموش شدن پنل (ثانیه)
  final RxList<int> alTimes = <int>[].obs;

  /// سناریوهای گوشی (۱۲ جا، روی پنل)
  final RxList<Sd23PhoneScn?> phone = List<Sd23PhoneScn?>.filled(phoneCount, null).obs;
  final RxBool phoneLoaded = false.obs;

  /// سناریوهای گوشی که تایمرشان در حال شمارش است: شماره ← (نوع، دقیقه‌ی باقی‌مانده)
  final RxMap<int, String> pending = <int, String>{}.obs;
  final RxSet<int> phoneRan = <int>{}.obs;

  /// برنامه‌ی مسافرت روی پنل (null = ندارد)
  final Rxn<Sd23Vacation> vacation = Rxn<Sd23Vacation>();
  final RxBool vacLoaded = false.obs;
  final RxString vacLast = '-'.obs; // آخرین کار انجام‌شده: '1'..'6' مرحله، 'E' پایان، '-' هنوز هیچ
  final RxInt vacSaveOk = 0.obs;
  final RxBool vacSaving = false.obs;
  String? _vacExpect;

  /// ساعت پنل: معلوم است؟ و از کجا (P گوشی، N اینترنت)
  final RxBool clockOk = true.obs;
  final RxBool clockKnown = false.obs;
  final RxString clockSrc = ''.obs;
  final RxInt clockDay = 0.obs, clockMin = 0.obs;

  // صفحه‌کلید دزدگیر
  final RxString entry = ''.obs; // '' ، 'arm' ، 'new'
  final RxString buf = ''.obs;
  final RxString message = ''.obs;
  final RxString messageType = ''.obs; // '' ، 'ok' ، 'err' ، 'sticky'

  // نمایش
  final RxString tab = gPoles.obs;
  final RxInt highlight = (-1).obs;
  final RxBool installer = false.obs;
  final RxBool demo = false.obs;

  // ---------- دو پنل شبکه‌ای: پنل دوم از راه همین پنل ----------
  /// پنل وای‌فای‌دار، پنل دیگرِ شبکه را هم نشان می‌دهد ($CAP#..P1$)
  final RxBool hasPeer = false.obs;
  /// پنلی که صفحه نشان می‌دهد: ۰ خود این پنل، ۱ پنل دوم
  final RxInt panel = 0.obs;
  final RxBool peerOnline = false.obs;
  final RxString peerModel = ''.obs;
  String _peerLay = '-' * keyCount;
  int _peerBits = 0;
  /// داده‌های خود پنل وقتی صفحه پنل دوم را نشان می‌دهد
  String _oLay = '-' * keyCount, _oModel = '';
  int _oBits = 0;
  List<String> _oLabels = List<String>.filled(keyCount, ''), _oIcons = List<String>.filled(keyCount, '');
  bool _oAlarm = false, _oSettings = false, _oCf = false, _oVac = true;
  final RxMap<int, String> panelNames = <int, String>{}.obs;
  bool get peerView => panel.value == 1;

  Sd23Simulator? _sim;
  final List<int> _demoRx = [];
  final Map<String, Timer> _expects = {};
  final Map<String, String> _writes = {};
  final Map<String, Timer> _writeTimers = {};
  final List<String> _loadQueue = [];
  Timer? _loadTimer, _msgTimer, _hlTimer, _passHold, _armCheck, _pendTimer;

  // ---------- نقش کلیدها ----------

  String kindOf(int k) => k >= 0 && k < lay.value.length ? lay.value[k] : '-';

  bool isOn(int k) => ((bits.value >> k) & 1) == 1;

  static bool isDigitKind(String t) => t.length == 1 && '123456789'.contains(t);

  bool isEmpty(int k) => kindOf(k) == '-';

  /// گروه هر کلید در صفحه
  String groupOf(int k) {
    final t = kindOf(k);
    if (t == '-') return '';
    if ('KFG'.contains(t)) return gCooler;
    if ('UW'.contains(t)) return gCurtain;
    if ('MTOXZESQ'.contains(t)) return gScn;
    if (t == 'n' || t == 'c' || isDigitKind(t)) return gAlarm;
    return gPoles;
  }

  List<int> keysOf(String g) => [for (int k = 0; k < keyCount; k++) if (groupOf(k) == g) k];

  /// زبانه‌هایی که این پنل دارد
  List<String> get tabs =>
      [gPoles, gCooler, gCurtain, gScn, if (!peerView) gAlarm].where((g) => keysOf(g).isNotEmpty).toList();

  /// پل‌هایی که سناریو می‌تواند روشن یا خاموش کند (جای ۱ تا ۲۰)
  List<int> get scnPoles => [for (int k = 0; k < 20; k++) if ('LDK'.contains(kindOf(k)) || 'FGUW'.contains(kindOf(k))) k];

  /// جفت‌های پرده: (باز، بسته)
  List<List<int>> get curtainPairs {
    final u = [for (int k = 0; k < keyCount; k++) if (kindOf(k) == 'U') k];
    final w = [for (int k = 0; k < keyCount; k++) if (kindOf(k) == 'W') k];
    return [for (int i = 0; i < u.length && i < w.length; i++) [u[i], w[i]]];
  }

  /// جفت‌های کولر: (کند، تند)
  List<List<int>> get coolerPairs {
    final f = [for (int k = 0; k < keyCount; k++) if (kindOf(k) == 'F') k];
    final g = [for (int k = 0; k < keyCount; k++) if (kindOf(k) == 'G') k];
    return [for (int i = 0; i < f.length && i < g.length; i++) [f[i], g[i]]];
  }

  /// بزرگ‌ترین رقم صفحه‌کلید روی این پنل (رمز فقط با همین اعداد)
  int get maxDigit {
    int m = 0;
    for (int k = 0; k < keyCount; k++) {
      final t = kindOf(k);
      if (isDigitKind(t)) {
        final d = int.parse(t);
        if (d > m) m = d;
      }
    }
    return m == 0 ? 6 : m;
  }

  String get modelName => modelNames[model.value] ?? 'پنل ۲۳ کلید';

  static String faNum(int n) => Panel12Controller.faNum(n);

  /// نام پیش‌فرض کلید (تا وقتی نصاب متنی ننوشته)
  String defaultLabel(int k) {
    final t = kindOf(k);
    switch (t) {
      case 'L':
        return k < 20 ? 'چراغ ${faNum(k + 1)}' : 'کلید ${faNum(k + 1)}';
      case 'M':
        return 'مستر';
      case 'T':
        return 'سرویسی';
      case 'O':
        return 'تایمر خاموشی';
      case 'D':
        return 'خاموشی تأخیری';
      case 'P':
        return 'شاسی';
      case 'Y':
        return 'شاسی تأخیری';
      case 'K':
        return 'پمپ';
      case 'U':
        return 'پرده باز';
      case 'W':
        return 'پرده بسته';
      case 'F':
        return 'دور کند';
      case 'G':
        return 'دور تند';
      case 'X':
        return 'EXIT';
      case 'Z':
        return 'SLEEP';
      case 'E':
        return 'آسانسور';
      case 'S':
        return 'سناریو ${faNum(k + 1)}';
      case 'Q':
        return 'گروه ${faNum(k + 1)}';
      case 'n':
        return 'ON / OFF';
      case 'c':
        return 'change pass';
      case '-':
        return '';
    }
    if (isDigitKind(t)) return t;
    return 'کلید ${faNum(k + 1)}';
  }

  /// نوع کلید به زبان کاربر
  String kindName(int k) {
    switch (kindOf(k)) {
      case 'S':
        return 'سفارشی';
      case 'Q':
        return 'گروه';
      case 'M':
        return 'مستر';
      case 'T':
        return 'سرویسی';
      case 'O':
        return 'تایمر خاموشی';
      case 'X':
        return 'خروج';
      case 'Z':
        return 'خواب';
      case 'E':
        return 'آسانسور';
    }
    return '';
  }

  /// جای کلید روی پنل
  String placeName(int k) => k < 20 ? 'جای ${faNum(k + 1)}' : 'سناریو ${faNum(k - 19)}';

  String labelOf(int k) => labels[k].isNotEmpty ? labels[k] : defaultLabel(k);

  /// آیکون پیش‌فرض بر اساس نقش کلید
  static String defaultIcon(String t) {
    switch (t) {
      case 'M':
        return 'master';
      case 'T':
      case 'P':
      case 'Y':
      case 'S':
      case 'Q':
        return '10';
      case 'O':
      case 'D':
      case 'Z':
        return '21';
      case 'U':
      case 'W':
        return '07';
      case 'F':
      case 'G':
        return '01';
      case 'K':
        return '00';
      case 'X':
        return 'exit';
      case 'E':
        return 'elevator';
    }
    return '16';
  }

  String iconOf(int k) => iconIds[k].isNotEmpty ? iconIds[k] : defaultIcon(kindOf(k));

  /// کلیدهایی که با لمس به پنل فرستاده می‌شوند (نه صفحه‌کلید دزدگیر، نه خالی)
  bool isPressKey(int k) {
    final t = kindOf(k);
    return t != '-' && t != 'n' && t != 'c' && !isDigitKind(t);
  }

  /// پل‌های روشن (بخش پل‌ها)
  int get polesOn => keysOf(gPoles).where(isOn).length;

  int get onCount {
    int n = 0;
    for (int k = 0; k < keyCount; k++) {
      if (isPressKey(k) && isOn(k)) n++;
    }
    return n;
  }

  /// خط توضیح هر سناریو در زبانه‌ی سناریو
  String scnLine(int k) {
    if (peerView) return '';                                // تنظیمات پنل دوم از اینجا خوانده نمی‌شود
    final t = kindOf(k);
    final c = cf[k];
    final run = isOn(k);
    String time(int s) => s >= 60 && s % 60 == 0 ? '${faNum(s ~/ 60)} دقیقه' : '${faNum(s)} ثانیه';
    switch (t) {
      case 'S':
        if (c == null) return '';
        final on = _count(c.on), off = _count(c.off);
        if (on == 0 && off == 0) return 'هنوز ذخیره نشده (پل‌ها را روشن کنید و ۴ ثانیه نگه دارید)';
        return '${faNum(on)} پل روشن · ${faNum(off)} پل خاموش';
      case 'Q':
        if (c == null) return '';
        final on = _count(c.on);
        return on == 0 ? 'هنوز پلی ندارد' : '${faNum(on)} پل · با هر لمس همه با هم روشن یا خاموش';
      case 'M':
        return 'همه‌ی پل‌ها روشن / خاموش';
      case 'X':
      case 'Z':
        if (c == null) return '';
        if (run && c.left > 0) return 'در حال اجرا · ${time(c.left)} مانده';
        return t == 'X' ? 'خاموشی همه بعد از ${time(c.secs16)}' : 'خاموشی بعد از ${time(c.secs16)} · چراغ خواب روشن می‌ماند';
      case 'T':
        if (c == null) return '';
        return run ? 'هواکش روشن است' : 'هواکش ${faNum(c.minutes)} دقیقه روشن می‌ماند';
      case 'O':
        if (c == null) return '';
        return run ? 'در حال شمارش' : 'خاموشی بعد از ${faNum(c.minutes)} دقیقه';
      case 'E':
        return run ? 'احضار شد' : 'احضار آسانسور';
    }
    return '';
  }

  static int _count(int m) {
    int n = 0;
    for (int i = 0; i < 23; i++) {
      if (((m >> i) & 1) == 1) n++;
    }
    return n;
  }

  // ---------- شروع ارتباط ----------

  /// پیام $MDL=SD23-...$ رسید: صفحه‌ی همین پنل ساخته می‌شود و همه‌چیز از پنل خوانده می‌شود
  void activate(String mdl) {
    if (peerView) _showOwn();
    // mdl: SD23-a14-1.0
    final p = mdl.split('-');
    final m = p.length > 1 ? p[1] : '';
    final v = p.length > 2 ? p.sublist(2).join('-') : '';
    if (m != model.value) {
      labels.assignAll(List<String>.filled(keyCount, ''));
      iconIds.assignAll(List<String>.filled(keyCount, ''));
      cf.clear();
      phone.assignAll(List<Sd23PhoneScn?>.filled(phoneCount, null));
      phoneLoaded.value = false;
      layKnown.value = false;
    }
    model.value = m;
    version.value = v;
    final major = int.tryParse(v.split('.').first) ?? protocolMajor;
    tooNew.value = major > protocolMajor;
    reload();
  }

  /// خواندن همه‌چیز از پنل، با فاصله تا صف ارسال برنامه پر نشود
  void reload() {
    _loadQueue
      ..clear()
      ..addAll([clockCommand(), '@M_LAY', '@M_CAP', '@K', '@X1Z'])
      ..addAll([for (int i = 1; i <= keyCount; i++) '@M_LBL#${_two(i)}'])
      ..add('@M_VAC');
    _loadTimer?.cancel();
    _loadTimer = Timer.periodic(const Duration(milliseconds: 260), (t) {
      if (_loadQueue.isEmpty) {
        t.cancel();
        _loadTimer = null;
        return;
      }
      _send(_loadQueue.removeAt(0));
    });
  }

  /// بعد از رسیدن چیدمان: تنظیمات سناریوها (و در حالت نصاب بقیه) پرسیده می‌شود
  void _askSettings() {
    if (!hasCf.value) return;
    for (int k = 0; k < keyCount; k++) {
      if (groupOf(k) == gScn || (installer.value && 'UWDPY'.contains(kindOf(k)) && kindOf(k) != '-')) {
        _queue('@M_CF#${_two(k + 1)}');
      }
    }
    if (installer.value) _queue('@M_CF#AL');
    if (hasSettings.value && !phoneLoaded.value) loadPhone();
  }

  void _queue(String cmd) {
    if (!_loadQueue.contains(cmd)) _loadQueue.add(cmd);
    if (_loadTimer == null) {
      _loadTimer = Timer.periodic(const Duration(milliseconds: 260), (t) {
        if (_loadQueue.isEmpty) {
          t.cancel();
          _loadTimer = null;
          return;
        }
        _send(_loadQueue.removeAt(0));
      });
    }
  }

  /// سناریوهای گوشی از پنل (وقتی زبانه‌ی سناریو باز می‌شود)
  void loadPhone() {
    if (!hasSettings.value) return;
    for (int i = 1; i <= phoneCount; i++) {
      _queue('@M_SCN#${_two(i)}');
    }
    _queue('@M_PND');
  }

  /// در حالت نصاب تنظیمات بیشتری خوانده می‌شود
  void setInstaller(bool on) {
    installer.value = on;
    if (on) _askSettings();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  void _send(String s) {
    final b = utf8.encode(s);
    if (demo.value) {
      _sim?.receive(b);
    } else {
      Socket.instance.send(b);
    }
  }

  // ---------- حالت نمایشی ----------

  void startDemo(String demoModel) {
    _reset();
    _sim?.dispose();
    _sim = Sd23Simulator(demoModel, _onDemoRaw);
    demo.value = true;
    Panel12Controller.instance.demo.value = true;
    _send('@M_MDL');
  }

  void stopDemo() {
    _sim?.dispose();
    _sim = null;
    demo.value = false;
    Panel12Controller.instance.demo.value = false;
    installer.value = false;
    _reset();
    // اگر در همین حال به یک پنل ۲۳ کلید واقعی وصل هستیم، صفحه‌اش دوباره از پنل خوانده می‌شود
    if (Panel12Controller.instance.isSd23.value) _send('@M_MDL');
  }

  /// پیام‌های پنل مجازی ($...$)
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
      if (m.startsWith('MDL=SD23')) {
        activate(m.substring(4));
      } else {
        handle(m);
      }
    }
  }

  void _reset() {
    panel.value = 0;
    hasPeer.value = false;
    peerOnline.value = false;
    peerModel.value = '';
    _peerLay = '-' * keyCount;
    _peerBits = 0;
    _loadTimer?.cancel();
    _loadTimer = null;
    _loadQueue.clear();
    _demoRx.clear();
    for (final t in _expects.values) {
      t.cancel();
    }
    _expects.clear();
    for (final t in _writeTimers.values) {
      t.cancel();
    }
    _writeTimers.clear();
    _writes.clear();
    _armCheck?.cancel();
    _armCheck = null;
    _pendTimer?.cancel();
    _pendTimer = null;
    model.value = '';
    version.value = '';
    tooNew.value = false;
    lay.value = '-' * keyCount;
    layKnown.value = false;
    hasAlarm.value = false;
    hasRemote.value = false;
    hasSettings.value = false;
    hasCf.value = false;
    hasVac.value = true;
    bits.value = 0;
    alarm.value = 0;
    labels.assignAll(List<String>.filled(keyCount, ''));
    iconIds.assignAll(List<String>.filled(keyCount, ''));
    cf.clear();
    alTimes.clear();
    phone.assignAll(List<Sd23PhoneScn?>.filled(phoneCount, null));
    phoneLoaded.value = false;
    pending.clear();
    vacation.value = null;
    vacLoaded.value = false;
    vacLast.value = '-';
    vacSaving.value = false;
    _vacExpect = null;
    clockOk.value = true;
    clockKnown.value = false;
    clockSrc.value = '';
    entry.value = '';
    buf.value = '';
    message.value = '';
    tab.value = gPoles;
  }

  // ---------- پیام‌های پنل ----------

  /// متن بین دو $ (Panel12Controller پیام‌های این پنل را به اینجا می‌فرستد)
  void handle(String m) {
    if (m.startsWith('P2')) return _handlePeer(m);
    if (peerView && _shadow(m)) return;
    if (m.startsWith('LAY#')) {
      var l = m.substring(4);
      if (l.length < keyCount) l = l.padRight(keyCount, '-');
      lay.value = l.substring(0, keyCount);
      layKnown.value = true;
      if (!tabs.contains(tab.value) && tabs.isNotEmpty) tab.value = tabs.first;
      _askSettings();
    } else if (m.startsWith('CAP#')) {
      hasAlarm.value = m.contains('A1');
      hasRemote.value = m.contains('R1');
      final had = hasSettings.value;
      final hadCf = hasCf.value;
      hasSettings.value = m.contains('S1');
      hasCf.value = hasSettings.value || m.contains('C1');
      hasVac.value = !m.contains('V0');
      if (((!had && hasSettings.value) || (!hadCf && hasCf.value)) && layKnown.value) _askSettings();
      final peer = m.contains('P1');
      if (peer && !hasPeer.value) _queue('@M_P2');
      hasPeer.value = peer;
    } else if (m.startsWith('K#')) {
      final v = int.tryParse(m.substring(2), radix: 16);
      if (v != null) {
        final was = bits.value;
        bits.value = v;
        // زمان باقی‌مانده‌ی سناریوهای در حال اجرا از پنل
        for (int k = 0; k < keyCount; k++) {
          final changed = ((was ^ v) >> k) & 1;
          if (changed == 1 && 'XZTO'.contains(kindOf(k)) && kindOf(k) != '-' && hasCf.value) {
            _queue('@M_CF#${_two(k + 1)}');
          }
        }
      }
    } else if (m.startsWith('A#') && m.length >= 6) {
      final n = int.tryParse(m.substring(2, 4));
      if (n == null) return;
      _confirm('k$n');
      if (m[5] != '1') {
        _notify(_refusedText(n - 1), 'err');
      }
    } else if (m.startsWith('AL#') && m.length >= 4) {
      final a = int.tryParse(m.substring(3, 4)) ?? 0;
      final was = alarm.value;
      alarm.value = a;
      if (a == 4 && was != 4) _say('آژیر! برای خاموش کردن رمز را وارد کنید', 'err');
      if (a == 3 && was != 3) _say('مهلت ورود: رمز را وارد کنید', 'sticky');
      if (a == 0 && (was == 3 || was == 4)) _say('');
    } else if (m.startsWith('ARM#')) {
      _armCheck?.cancel();
      _armCheck = null;
      if (m == 'ARM#ok') {
        _say(alarm.value == 0 ? 'رمز درست است' : 'دزدگیر خاموش شد', 'ok');
      } else {
        _say('رمز اشتباه است', 'err');
      }
    } else if (m.startsWith('PASS=')) {
      _confirm('pass');
      _say(m == 'PASS=ok' ? 'رمز جدید ثبت شد' : 'رمز ثبت نشد (دزدگیر باید خاموش باشد)', m == 'PASS=ok' ? 'ok' : 'err');
    } else if (m.startsWith('CF#AL#')) {
      final p = m.substring(6).split('#');
      if (p.length >= 4) {
        alTimes.assignAll([for (final x in p.take(4)) int.tryParse(x, radix: 16) ?? 0]);
        _checkWrite('AL', m.substring(6));
      }
    } else if (m.startsWith('CF#')) {
      final p = m.substring(3).split('#');
      if (p.length < 8) return;
      final n = int.tryParse(p[0]);
      if (n == null || n < 1 || n > keyCount) return;
      int h(String x) => int.tryParse(x, radix: 16) ?? 0;
      final c = Sd23Cf(h(p[1]), h(p[2]), h(p[3]), h(p[4]), h(p[5]), h(p[6]), h(p[7]));
      final k = n - 1;
      final m2 = Map<int, Sd23Cf>.from(cf);
      m2[k] = c;
      cf.assignAll(m2);
      _checkWrite('C${_two(n)}', '${p[1]}#${p[2]}#${p[3]}#${p[4]}#${p[5]}#${p[6]}');
      if (c.left > 0) _ensureCountdown();
    } else if (m.startsWith('SET#')) {
      // تغییری که پنل قبول نکرد
      final key = m.startsWith('SET#AL') ? 'AL' : 'C${m.length >= 6 ? m.substring(4, 6) : ''}';
      if (_writes.remove(key) != null) {
        _writeTimers.remove(key)?.cancel();
        _notify('پنل این مقدار را قبول نکرد', 'err');
      }
      if (m == 'SET#RS#ok') _notify('تنظیمات پروگرم برگشت؛ پنل دوباره روشن می‌شود', 'ok');
    } else if (m.startsWith('RUN=') && m.length >= 7) {
      final n = int.tryParse(m.substring(4, 6));
      if (n == null || n < 1 || n > phoneCount) return;
      _confirm('run$n');
      if (m[6] == 'R') {
        phoneRan.add(n - 1);
        Timer(const Duration(milliseconds: 1500), () => phoneRan.remove(n - 1));
        Timer(const Duration(milliseconds: 600), () => _send('@M_PND'));
      } else if (m[6] == 'L') {
        _notify('پنل الان فرمان نمی‌گیرد (سناریوی کوتاه در حال اجراست)', 'err');
      } else {
        _notify('این سناریو روی پنل ثبت نیست', 'err');
      }
    } else if (m.startsWith('PND#')) {
      final p = <int, String>{};
      for (final e in m.substring(4).split('#')) {
        // 03F=0012
        if (e.length < 8 || e[3] != '=') continue;
        final n = int.tryParse(e.substring(0, 2));
        final left = int.tryParse(e.substring(4));
        if (n == null || left == null || n < 1 || n > phoneCount) continue;
        p[n - 1] = '${e[2]}$left';
      }
      pending.assignAll(p);
      _ensurePendTimer();
    } else if (m.startsWith('CLK#')) {
      // CLK#1#09783#1170#N   یا   CLK#0
      final p = m.split('#');
      clockKnown.value = true;
      clockOk.value = p.length >= 2 && p[1] == '1';
      if (clockOk.value && p.length >= 5) {
        clockDay.value = int.tryParse(p[2]) ?? 0;
        clockMin.value = int.tryParse(p[3]) ?? 0;
        clockSrc.value = p[4];
      } else {
        clockSrc.value = '';
      }
    } else if (m.startsWith('V#')) {
      _parseVacation(m);
    } else if (m.length >= 4 && m[0] == 'S' && m[3] == '#' && int.tryParse(m.substring(1, 3)) != null) {
      final n = int.parse(m.substring(1, 3));
      if (n < 1 || n > phoneCount) return;
      final body = m.substring(4);
      phone[n - 1] = _parsePhone(body);
      phoneLoaded.value = true;
      _checkWrite('P${_two(n)}', body);
    } else if (m.length >= 4 && m[0] == 'L' && m[3] == '#') {
      final n = int.tryParse(m.substring(1, 3));
      if (n == null || n < 1 || n > keyCount) return;
      final body = m.substring(4);
      final mm = RegExp(r'^(\d\d)~').firstMatch(body);
      iconIds[n - 1] = mm != null ? mm.group(1)! : '';
      labels[n - 1] = mm != null ? body.substring(3) : body;
      _checkWrite('L${_two(n)}', body);
    }
  }

  // ---------- مسافرت و ساعت ----------

  static const int vacSteps = 6;

  /// ساعت ایران (بدون ساعت تابستانی)، هر جای دنیا که گوشی باشد
  static DateTime iranNow() => DateTime.now().toUtc().add(const Duration(hours: 3, minutes: 30));

  /// شماره‌ی امروز (به وقت ایران) از ۱ ژانویه‌ی ۲۰۰۰؛ همان شمارش پنل
  static int iranDay() {
    final n = iranNow();
    return DateTime.utc(n.year, n.month, n.day).difference(DateTime.utc(2000, 1, 1)).inDays;
  }

  static int iranMinute() {
    final n = iranNow();
    return n.hour * 60 + n.minute;
  }

  /// &CLK#روز#دقیقه#ثانیه به وقت ایران (پنل اگر ساعت را از اینترنت دارد، این را نمی‌گیرد)
  static String clockCommand() {
    final n = iranNow();
    return '&CLK#${iranDay().toString().padLeft(5, '0')}#${(n.hour * 60 + n.minute).toString().padLeft(4, '0')}#'
        '${n.second.toString().padLeft(2, '0')}';
  }

  void syncClock() => _send(clockCommand());

  /// چراغ‌هایی که برنامه‌ی مسافرت روشن و خاموش می‌کند (پل معمولی و خاموشی تأخیری، جای ۱ تا ۲۰)
  List<int> get vacLights => [for (int k = 0; k < 20; k++) if (kindOf(k) == 'L' || kindOf(k) == 'D') k];

  int get _vacLightMask {
    int m = 0;
    for (final k in vacLights) {
      m |= 1 << k;
    }
    return m;
  }

  int _kindMask(String t) {
    int m = 0;
    for (int k = 0; k < 20; k++) {
      if (kindOf(k) == t) m |= 1 << k;
    }
    return m;
  }

  bool get hasCurtain => _kindMask('U') != 0 && _kindMask('W') != 0;

  int _vacMask(int lights, String c) =>
      (lights & _vacLightMask) | (c == 'O' ? _kindMask('U') : 0) | (c == 'C' ? _kindMask('W') : 0);

  String _curtOf(int mask) {
    if (mask & _kindMask('U') != 0) return 'O';
    if (mask & _kindMask('W') != 0) return 'C';
    return '-';
  }

  /// فرمان ذخیره؛ null اگر زمان‌ها نامعتبر باشند
  String? vacationCommand(Sd23Vacation v) {
    final r = v.relTimes();
    if (r == null || v.steps.isEmpty || v.steps.length > vacSteps) return null;
    final d1 = v.d1 < v.d0 ? v.d0 : v.d1;
    final b = StringBuffer('Vac#${v.on ? 1 : 0}#${v.d0.toString().padLeft(5, '0')}#${d1.toString().padLeft(5, '0')}#'
        '${v.steps.length}#');
    for (int k = 0; k < v.steps.length; k++) {
      b.write(r[k].toString().padLeft(4, '0'));
      b.write(_hx(_vacMask(v.steps[k].lights, v.steps[k].c), 5));
    }
    b.write('#${r.last.toString().padLeft(4, '0')}${_hx(_vacMask(0, v.ce), 5)}#');
    return b.toString();
  }

  // V#1#09783#09784#3#118501003126000404153002008#159000000#1#-   یا   V#-#1#-
  void _parseVacation(String m) {
    final p = m.split('#');
    vacLoaded.value = true;
    if (p.length >= 4 && p[1] == '-') {
      vacation.value = null;
      clockOk.value = p[2] == '1';
      vacLast.value = p[3];
      _checkVacation();
      return;
    }
    if (p.length < 9) return;
    final n = int.tryParse(p[4]) ?? 0;
    final d0 = int.tryParse(p[2]), d1 = int.tryParse(p[3]);
    if (d0 == null || d1 == null || n < 1 || n > vacSteps || p[5].length != n * 9 || p[6].length != 9) return;
    final steps = <Sd23VacStep>[];
    for (int k = 0; k < n; k++) {
      final x = p[5].substring(k * 9, k * 9 + 9);
      final mask = int.tryParse(x.substring(4), radix: 16) ?? 0;
      steps.add(Sd23VacStep(t: (int.tryParse(x.substring(0, 4)) ?? 0) % 1440, lights: mask & _vacLightMask, c: _curtOf(mask)));
    }
    vacation.value = Sd23Vacation(
      on: p[1] == '1',
      d0: d0,
      d1: d1,
      steps: steps,
      te: (int.tryParse(p[6].substring(0, 4)) ?? 0) % 1440,
      ce: _curtOf(int.tryParse(p[6].substring(4), radix: 16) ?? 0),
    );
    clockOk.value = p[7] == '1';
    vacLast.value = p[8];
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

  /// ذخیره روی پنل؛ پیام خطا یا null. «ثبت شد» فقط وقتی پنل همان برنامه را برگرداند
  String? saveVacation(Sd23Vacation v) {
    final cmd = vacationCommand(v);
    if (cmd == null) return 'زمان مرحله‌ها درست نیست: دو مرحله هم‌زمان‌اند یا برنامه بیشتر از یک شبانه‌روز طول می‌کشد';
    _vacExpect = cmd;
    vacSaving.value = true;
    _notify('در حال ذخیره روی پنل…', 'wait');
    syncClock();
    Timer(const Duration(milliseconds: 300), () => _send(cmd));
    Timer(const Duration(milliseconds: 1000), () => _send('@M_VAC'));
    _writeTimers.remove('V')?.cancel();
    _writeTimers['V'] = Timer(const Duration(seconds: 5), () {
      _writeTimers.remove('V');
      if (_vacExpect == null) return;
      _vacExpect = null;
      vacSaving.value = false;
      _notify('پنل جواب نداد؛ برنامه ذخیره نشد', 'err');
    });
    return null;
  }

  /// وقتی زبانه‌ی مسافرت باز می‌شود: ساعت و برنامه دوباره از پنل
  void loadVacation() {
    _queue(clockCommand());
    _queue('@M_VAC');
  }

  // ---------- پنل دوم ----------

  /// پیام‌های پنل دوم: P2#مدل#حروف#وصل ، P2K#xxxxxx#وصل ، P2A#nn#1|0
  void _handlePeer(String m) {
    if (m.startsWith('P2#')) {
      final p = m.split('#');
      if (p.length < 4 || p[1] == '-') {
        hasPeer.value = false;
        if (peerView) _showOwn();
        return;
      }
      hasPeer.value = true;
      peerModel.value = p[1];
      _peerLay = p[2].padRight(keyCount, '-').substring(0, keyCount);
      peerOnline.value = p[3] == '1';
      _loadNames();
      if (peerView) lay.value = _peerLay;
    } else if (m.startsWith('P2K#') && m.length >= 10) {
      final v = int.tryParse(m.substring(4, 10), radix: 16);
      if (v == null) return;
      _peerBits = v;
      if (m.length >= 12) peerOnline.value = m[11] == '1';
      if (peerView) bits.value = v;
    } else if (m.startsWith('P2A#') && m.length >= 8) {
      final n = int.tryParse(m.substring(4, 6));
      if (n == null) return;
      _confirm('p$n');
      if (m[7] != '1') _notify('پنل دوم الان با این پنل ارتباط ندارد (کابل شبکه را بررسی کنید)', 'err');
    }
  }

  /// پیام‌های خود پنل وقتی صفحه پنل دوم را نشان می‌دهد: کنار گذاشته می‌شوند تا برگشت
  bool _shadow(String m) {
    if (m.startsWith('K#')) {
      final v = int.tryParse(m.substring(2), radix: 16);
      if (v != null) _oBits = v;
      return true;
    }
    if (m.startsWith('LAY#')) {
      var l = m.substring(4);
      if (l.length < keyCount) l = l.padRight(keyCount, '-');
      _oLay = l.substring(0, keyCount);
      return true;
    }
    if (m.startsWith('CAP#')) {
      _oAlarm = m.contains('A1');
      _oSettings = m.contains('S1');
      _oCf = _oSettings || m.contains('C1');
      _oVac = !m.contains('V0');
      hasPeer.value = m.contains('P1');
      return true;
    }
    if (m.length >= 4 && m[0] == 'L' && m[3] == '#') {
      final n = int.tryParse(m.substring(1, 3));
      if (n == null || n < 1 || n > keyCount) return true;
      final body = m.substring(4);
      final mm = RegExp(r'^(\d\d)~').firstMatch(body);
      _oIcons[n - 1] = mm != null ? mm.group(1)! : '';
      _oLabels[n - 1] = mm != null ? body.substring(3) : body;
      return true;
    }
    return false;
  }

  /// نشان دادن پنل ۱ (خود این پنل) یا پنل ۲
  void selectPanel(int i) {
    if (i == panel.value || (i == 1 && !hasPeer.value)) return;
    if (i == 1) {
      _oLay = lay.value;
      _oBits = bits.value;
      _oModel = model.value;
      _oLabels = labels.toList();
      _oIcons = iconIds.toList();
      _oAlarm = hasAlarm.value;
      _oSettings = hasSettings.value;
      _oCf = hasCf.value;
      _oVac = hasVac.value;
      panel.value = 1;
      lay.value = _peerLay;
      bits.value = _peerBits;
      model.value = peerModel.value;
      final saved = _load('lbl');
      final lb = List<String>.filled(keyCount, ''), ic = List<String>.filled(keyCount, '');
      if (saved is Map) {
        saved.forEach((k, v) {
          final n = int.tryParse('$k');
          final t = '$v';
          final j = t.indexOf('~');
          if (n == null || n < 0 || n >= keyCount || j < 0) return;
          ic[n] = t.substring(0, j);
          lb[n] = t.substring(j + 1);
        });
      }
      labels.assignAll(lb);
      iconIds.assignAll(ic);
      hasAlarm.value = false;
      hasSettings.value = false;
      hasCf.value = false;
      hasVac.value = true;
      entry.value = '';
      buf.value = '';
      _send('@M_P2');
    } else {
      _showOwn();
      _send('@K');
    }
    if (!tabs.contains(tab.value) && tabs.isNotEmpty) tab.value = tabs.first;
  }

  void _showOwn() {
    panel.value = 0;
    lay.value = _oLay;
    bits.value = _oBits;
    model.value = _oModel;
    labels.assignAll(_oLabels);
    iconIds.assignAll(_oIcons);
    hasAlarm.value = _oAlarm;
    hasSettings.value = _oSettings;
    hasCf.value = _oCf;
    hasVac.value = _oVac;
    if (!tabs.contains(tab.value) && tabs.isNotEmpty) tab.value = tabs.first;
  }

  /// اسم سربرگ هر پنل (روی همین گوشی)
  String panelName(int i) => panelNames[i] ?? 'پنل ${faNum(i + 1)}';

  void renamePanel(int i, String name) {
    var t = name.replaceAll(RegExp(r'[#\$!&@~\r\n%]'), '').trim();
    if (t.length > 20) t = t.substring(0, 20);
    if (t.isEmpty) {
      panelNames.remove(i);
    } else {
      panelNames[i] = t;
    }
    _store('names', {for (final e in panelNames.entries) '${e.key}': e.value});
  }

  void _loadNames() {
    final v = _load('names');
    final m = <int, String>{};
    if (v is Map) {
      v.forEach((k, x) {
        final n = int.tryParse('$k');
        if (n != null && '$x'.isNotEmpty) m[n] = '$x';
      });
    }
    panelNames.assignAll(m);
  }

  /// این دو پنل (هر جفت پنل اسم‌ها و متن‌های خودش را دارد)
  String get _pairKey => 'sd23pair_${panel.value == 1 ? _oModel : model.value}_${panel.value == 1 ? _oLay : lay.value}_${peerModel.value}_$_peerLay';

  static final Map<String, dynamic> _mem = {};

  dynamic _load(String what) {
    final k = '${_pairKey}_$what';
    try {
      return LocStore.read(k) ?? _mem[LocStore.key(k)];
    } catch (_) {
      return _mem[LocStore.key(k)];
    }
  }

  void _store(String what, dynamic v) {
    final k = '${_pairKey}_$what';
    _mem[LocStore.key(k)] = v;
    try {
      LocStore.write(k, v);
    } catch (_) {}
  }

  static Sd23PhoneScn? _parsePhone(String body) {
    // 11222222222222222222F0010#شب بخیر   یا   -
    if (body.length < 26 || body[25] != '#') return null;
    final st = body.substring(0, 20);
    if (!RegExp(r'^[012]{20}$').hasMatch(st)) return null;
    return Sd23PhoneScn(
      st: st,
      tm: 'NFD'.contains(body[20]) ? body[20] : 'N',
      mins: int.tryParse(body.substring(21, 25)) ?? 0,
      name: body.substring(26),
    );
  }

  /// شمارش معکوس سناریوهای در حال اجرا (زمان دقیق هر بار از پنل)
  Timer? _countTimer;

  void _ensureCountdown() {
    if (_countTimer != null) return;
    _countTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      bool any = false;
      final m2 = <int, Sd23Cf>{};
      cf.forEach((k, c) {
        if (c.left > 0 && isOn(k)) {
          any = true;
          m2[k] = Sd23Cf(c.type, c.sec1, c.sec2, c.minutes, c.on, c.off, c.left - 1);
        } else {
          m2[k] = c;
        }
      });
      cf.assignAll(m2);
      if (!any) {
        t.cancel();
        _countTimer = null;
      }
    });
  }

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
      _send('@M_PND');
    });
  }

  String _refusedText(int k) {
    final t = kindOf(k);
    if (t == '-' || t == 'n' || t == 'c' || isDigitKind(t)) return 'این کلید از گوشی کار نمی‌کند';
    return 'پنل الان فرمان نمی‌گیرد (سناریوی کوتاه در حال اجراست)';
  }

  // ---------- فرمان‌ها ----------

  /// لمس یک کلید از گوشی؛ وضعیت فقط با پیام پنل عوض می‌شود
  void press(int k) {
    if (!isPressKey(k)) return;
    if (peerView) {
      if (!peerOnline.value) return _notify('پنل دوم الان با این پنل ارتباط ندارد (کابل شبکه را بررسی کنید)', 'err');
      _expect('p${k + 1}');
      _send('&P2K#${_two(k + 1)}');
      return;
    }
    _expect('k${k + 1}');
    _send('&K#${_two(k + 1)}');
  }

  /// همه‌ی پل‌های روشن بخش پل‌ها خاموش (هر کدام جدا، با فاصله‌ی صف ارسال)
  void allPolesOff() {
    for (final k in keysOf(gPoles)) {
      if (isOn(k)) press(k);
    }
  }

  /// کولر: هر دو دور و پمپ خاموش
  void coolerOff() {
    for (final k in keysOf(gCooler)) {
      if (isOn(k)) press(k);
    }
  }

  /// شناسایی: کلید را یک لحظه عوض می‌کند تا نصاب ببیند روی شیشه کدام است
  void identify(int k) {
    press(k);
    Timer(const Duration(milliseconds: 1500), () => press(k));
  }

  // ---------- تنظیمات از گوشی ----------

  /// یک تنظیم کلید: f = M دقیقه، T ثانیه (EXIT/SLEEP)، 1 و 2 ثانیه، O و F پل‌ها
  void setValue(int k, String f, int v, {int digits = 2}) {
    final n = _two(k + 1);
    _send('Set#$n#$f#${v.toRadixString(16).toUpperCase().padLeft(digits, '0')}#');
  }

  String _hx(int v, int n) => v.toRadixString(16).toUpperCase().padLeft(n, '0');

  /// زمان یک کلید؛ فقط بعد از خواندن از پنل «ثبت شد»
  void saveTime(int k, String f, int v) {
    final c = cf[k];
    if (c == null) return;
    int s1 = c.sec1, s2 = c.sec2, mm = c.minutes;
    if (f == 'M') mm = v;
    if (f == '1') s1 = v;
    if (f == '2') s2 = v;
    if (f == 'T') {
      s1 = v & 255;
      s2 = v >> 8;
    }
    final exp = '${_hx(c.type, 2)}#${_hx(s1, 2)}#${_hx(s2, 2)}#${_hx(mm, 2)}#${_hx(c.on, 6)}#${_hx(c.off, 6)}';
    _write('C${_two(k + 1)}', exp, () => setValue(k, f, v, digits: f == 'T' ? 4 : 2));
  }

  /// پل‌های سناریوی سفارشی یا گروه یا مستر
  void saveMasks(int k, int on, int off) {
    final c = cf[k];
    if (c == null) return;
    final isGroup = kindOf(k) == 'Q' || kindOf(k) == 'M';
    final exp = '${_hx(c.type, 2)}#${_hx(c.sec1, 2)}#${_hx(c.sec2, 2)}#${_hx(c.minutes, 2)}#${_hx(on, 6)}#${_hx(isGroup ? 0 : off, 6)}';
    _write('C${_two(k + 1)}', exp, () {
      setValue(k, 'O', on, digits: 6);
      if (!isGroup) Timer(const Duration(milliseconds: 300), () => setValue(k, 'F', off, digits: 6));
    });
  }

  /// زمان‌های دزدگیر و خاموش شدن پنل (نصاب)
  void saveAlarmTimes(int arm, int entryT, int siren, int dark) {
    final exp = '${_hx(arm, 2)}#${_hx(entryT, 2)}#${_hx(siren, 2)}#${_hx(dark, 2)}';
    _write('AL', exp, () => _send('Set#AL#$exp#'));
  }

  /// برگشت به تنظیمات پروگرم (نصاب): سناریوهای ذخیره‌شده و زمان‌های تغییرکرده پاک می‌شوند
  void resetSettings() => _send('Set#RS#');

  // ---------- سناریوهای گوشی ----------

  int get freePhoneSlot => phone.indexWhere((e) => e == null);

  String defaultPhoneName() => 'سناریو ${faNum(phone.where((e) => e != null).length + 1)}';

  /// پاک‌سازی نام سناریو (حداکثر ۱۸ بایت)
  static String cleanPhoneName(String s) {
    var t = s.replaceAll(RegExp(r'[#\$!&@~\r\n%]'), '').trim();
    while (utf8.encode(t).length > phoneNameBytes) {
      t = t.substring(0, t.length - 1);
    }
    return t;
  }

  void savePhone(int i, Sd23PhoneScn sc) {
    final name = cleanPhoneName(sc.name).isEmpty ? defaultPhoneName() : cleanPhoneName(sc.name);
    final body = '${sc.st}${sc.tm}${sc.mins.clamp(0, 9999).toString().padLeft(4, '0')}#$name';
    final n = _two(i + 1);
    _write('P$n', body, () {
      _send('Scn#$n#$body#');
      Timer(const Duration(milliseconds: 500), () => _send('@M_SCN#$n'));
    }, readBack: false);
  }

  void deletePhone(int i) {
    final n = _two(i + 1);
    _write('P$n', '-', () {
      _send('Scd#$n');
      Timer(const Duration(milliseconds: 500), () => _send('@M_SCN#$n'));
    }, readBack: false);
  }

  void runPhone(int i) {
    _expect('run${i + 1}');
    _send('&RUN#${_two(i + 1)}');
  }

  void cancelPhone(int i) {
    _send('&CAN#${_two(i + 1)}');
    Timer(const Duration(milliseconds: 500), () => _send('@M_PND'));
  }

  // ---------- دزدگیر ----------

  void onOff() {
    if (entry.value == 'arm') {
      entry.value = '';
      buf.value = '';
      _say('');
      return;
    }
    entry.value = 'arm';
    buf.value = '';
    _say(alarm.value == 0 ? 'برای روشن کردن، رمز ۴ رقمی را وارد کنید' : 'برای خاموش کردن، رمز ۴ رقمی را وارد کنید',
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
    if (alarm.value != 0) {
      _say('اول دزدگیر را خاموش کنید', 'err');
      return;
    }
    _say('دو ثانیه نگه دارید…', 'sticky');
    _passHold?.cancel();
    _passHold = Timer(const Duration(seconds: 2), () {
      _passHold = null;
      entry.value = 'new';
      buf.value = '';
      _say('رمز جدید ۴ رقمی را وارد کنید (اعداد ۱ تا ${faNum(maxDigit)})', 'sticky');
    });
  }

  void passUp() {
    if (_passHold != null) {
      _passHold!.cancel();
      _passHold = null;
      if (entry.value.isEmpty) _say('');
    }
  }

  String get alarmText {
    switch (alarm.value) {
      case 1:
        return 'دزدگیر در حال فعال شدن…';
      case 2:
        return 'دزدگیر فعال است';
      case 3:
        return 'مهلت ورود: رمز را وارد کنید';
      case 4:
        return 'آژیر!';
    }
    return 'دزدگیر خاموش است';
  }

  // ---------- نصاب ----------

  /// پاک‌سازی متن برای پنل (حداکثر ۴۰ بایت = ۲۰ حرف فارسی)
  static String cleanLabel(String s) {
    var t = s.replaceAll(RegExp(r'[#\$!&@~\r\n%]'), '').trim();
    while (utf8.encode(t).length > labelBytes) {
      t = t.substring(0, t.length - 1);
    }
    return t;
  }

  /// ذخیره‌ی متن و آیکون یک کلید روی پنل؛ فقط بعد از خواندن دوباره از پنل «ثبت شد»
  void saveKey({required int index, required String iconId, required String label}) {
    final clean = cleanLabel(label);
    final ic = RegExp(r'^\d\d$').hasMatch(iconId) ? iconId : '';
    if (peerView) {
      // پنل دوم: متن کلیدها روی همین گوشی
      labels[index] = clean;
      iconIds[index] = ic;
      _store('lbl', {for (int k = 0; k < keyCount; k++) '$k': '${iconIds[k]}~${labels[k]}'});
      _notify('روی این گوشی ثبت شد', 'ok');
      return;
    }
    final n = _two(index + 1);
    final body = ic.isEmpty ? clean : '$ic~$clean';
    _write('L$n', body, () {
      _send(ic.isEmpty ? 'Lbl#$n#$clean#' : 'Lbl#$n#$ic~$clean#');
      Timer(const Duration(milliseconds: 600), () => _send('@M_LBL#$n'));
    }, readBack: false);
  }

  /// نوشتن روی پنل؛ «ثبت شد» فقط وقتی پنل همان مقدار را برگرداند
  void _write(String key, String expected, void Function() send, {bool readBack = true}) {
    _writes[key] = expected;
    _writeTimers.remove(key)?.cancel();
    _notify('در حال ذخیره روی پنل…', 'wait');
    send();
    _writeTimers[key] = Timer(const Duration(seconds: 4), () {
      _writeTimers.remove(key);
      if (_writes.remove(key) != null) _notify('پنل جواب نداد؛ ذخیره نشد', 'err');
    });
  }

  void _checkWrite(String key, String got) {
    final exp = _writes[key];
    if (exp == null) return;
    // پل‌ها با دو فرمان نوشته می‌شوند: تا جواب آخر صبر می‌شود
    if (got != exp && key.startsWith('C') && _writeTimers.containsKey(key)) {
      final parts = got.split('#');
      final ep = exp.split('#');
      if (parts.length == 6 && ep.length == 6 && parts[4] == ep[4] && parts[5] != ep[5]) return;
    }
    _writes.remove(key);
    _writeTimers.remove(key)?.cancel();
    if (got == exp) {
      _notify('روی پنل ثبت شد', 'ok');
    } else {
      _notify('پنل تغییر را ثبت نکرد؛ دوباره امتحان کنید', 'err');
    }
  }

  // ---------- کمکی ----------

  /// لمس یک کلید روی تصویر پنل: زبانه‌ی همان کلید باز و کلید پررنگ می‌شود
  void selectKey(int k) {
    final g = groupOf(k);
    if (g.isEmpty) return;
    tab.value = g;
    highlight.value = k;
    _hlTimer?.cancel();
    _hlTimer = Timer(const Duration(milliseconds: 1500), () => highlight.value = -1);
  }

  void _expect(String key, {int seconds = 3}) {
    _expects.remove(key)?.cancel();
    _expects[key] = Timer(Duration(seconds: seconds), () {
      _expects.remove(key);
      _notify('پنل جواب نداد؛ فرمان اجرا نشد', 'err');
    });
  }

  void _confirm(String key) => _expects.remove(key)?.cancel();

  void _notify(String text, String type) => Panel12Controller.instance.notify(text, type);

  void notifyError(String text) => _notify(text, 'err');

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
}
