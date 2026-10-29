import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import '../data/data_sources/remote_data_sources/socket/socket.dart';
import '../panel12/panel12_controller.dart';
import '../sd23/sd23_controller.dart';

/// ماژول وای‌فای شبکه‌ی CPU (چند پنل یک خانه، همه زیر فرمان CPU)
///
/// پروتکل (همان wifi64.c با SW_WMOD):
///   @M_MDL           -> $MDL=SDNET-nn-1.0$      (در فهرست خانه؛ nn = تعداد پنل‌ها)
///   @M_NET           -> $NET#nn$
///   @M_NP#nn         -> $NP#nn#o#مدل#اسم$       (o: ۱ = جواب می‌دهد)
///   @P#nn            -> $P#nn$                  (نگاه به پنل nn؛ ۰۰ = فهرست خانه)
///                       بعد از آن $MDL=SD23-<مدل>-1.0$ و همان صفحه‌ی پنل تنها
///   @M_HL#nn         -> $HL#nn#<۱۴ قلم هگز>$    (گزارش سلامت پنل از CPU)
///   خودبه‌خود: $NO#<۸ هگز>$  بیت n-1 = پنل n جواب می‌دهد
class NetPanel {
  final int n;
  bool online;
  String model;
  String name;

  NetPanel(this.n, {this.online = false, this.model = '', this.name = ''});
}

/// گزارش سلامت یک پنل (همان اقلام health() در cpu.c)
class NetHealth {
  final List<int> it;

  NetHealth(this.it);

  bool get online => (it[0] & 1) == 1;
  int get misses => it[0] >> 1;
  int get seenSecs => it[1] | (it[2] << 8);
  int get modelCode => it[3];
  int get version => it[4];
  int get lost => it[6] | (it[7] << 8);
  int get bad => it[8] | (it[9] << 8);
  int get repeats => it[10];
  int get powerUps => it[12];
  int get rttMs => it[13];

  static const Map<int, String> modelNames = {
    1: 'دو پل',
    2: 'چهار پل',
    3: 'پنل ۲۳ کلید',
    4: '۱۲ اقتصادی',
    5: 'دزدگیر سیمکارتی',
    6: 'شش پل',
  };

  String get modelName => modelNames[modelCode] ?? (modelCode == 0 ? '—' : 'مدل $modelCode');

  /// کار شبکه‌ی این پنل درست است؟ (جواب می‌دهد و فریم خراب یا بی‌جواب زیاد ندارد)
  bool get healthy => online && lost < 20 && bad < 20;
}

class NetController extends GetxController {
  static NetController get instance {
    if (!Get.isRegistered<NetController>()) {
      Get.put(NetController(), permanent: true);
    }
    return Get.find<NetController>();
  }

  static const int maxPanels = 25;

  final RxInt count = 0.obs;
  final RxList<NetPanel> panels = <NetPanel>[].obs;

  /// پنلی که الان دیده می‌شود (۰ = فهرست خانه)
  final RxInt viewing = 0.obs;

  /// پنلی که خواسته شد و هنوز جوابش نیامده
  final RxInt opening = 0.obs;
  final RxMap<int, NetHealth> health = <int, NetHealth>{}.obs;
  final RxSet<int> healthAsked = <int>{}.obs;
  final RxBool installer = false.obs;

  /// برای تست: آخرین فرمان‌های فرستاده‌شده
  final List<String> sentLog = [];

  Timer? _openTimer;
  final List<Timer> _askTimers = [];

  NetPanel? panel(int n) => n >= 1 && n <= panels.length ? panels[n - 1] : null;

  String panelTitle(int n) {
    final p = panel(n);
    if (p == null) return '';
    return p.name.isNotEmpty ? p.name : 'پنل ${Panel12Controller.faNum(n)}';
  }

  static String modelTitle(String m) => Sd23Controller.modelNames[m] ?? (m.isEmpty ? 'پنل' : m);

  int get onlineCount => panels.where((p) => p.online).length;

  void _send(String s) {
    sentLog.add(s);
    if (sentLog.length > 60) sentLog.removeAt(0);
    final b = utf8.encode(s);
    if (Panel12Controller.instance.demo.value) return;
    Socket.instance.send(b);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// $MDL=SDNET-nn-1.0$ رسید: فهرست خانه
  void activate(String mdl) {
    final p = mdl.split('-');
    final n = p.length > 1 ? (int.tryParse(p[1]) ?? 0).clamp(0, maxPanels).toInt() : 0;
    _setCount(n);
    viewing.value = 0;
    opening.value = 0;
    _openTimer?.cancel();
    reload();
  }

  void _setCount(int n) {
    if (n == count.value && panels.length == n) return;
    count.value = n;
    final old = {for (final p in panels) p.n: p};
    panels.assignAll([for (int i = 1; i <= n; i++) old[i] ?? NetPanel(i)]);
    health.removeWhere((k, v) => k > n);
  }

  /// اسم و مدل و وضعیت همه‌ی پنل‌ها، با فاصله تا صف ماژول پر نشود
  void reload() {
    for (final t in _askTimers) {
      t.cancel();
    }
    _askTimers.clear();
    _send('@M_NET');
    for (int i = 1; i <= count.value; i++) {
      _askTimers.add(Timer(Duration(milliseconds: 200 * i), () => _send('@M_NP#${_two(i)}')));
    }
  }

  /// پیام‌های فهرست خانه؛ true یعنی مال همین‌جا بود
  bool handle(String m) {
    if (m.startsWith('NET#')) {
      final n = int.tryParse(m.substring(4));
      if (n != null && n != count.value) {
        _setCount(n.clamp(0, maxPanels).toInt());
        reload();
      }
      return true;
    }
    if (m.startsWith('NP#')) {
      final f = m.split('#');
      if (f.length < 4) return true;
      final n = int.tryParse(f[1]) ?? 0;
      final p = panel(n);
      if (p == null) return true;
      p.online = f[2] == '1';
      p.model = f[3];
      p.name = f.length > 4 ? f.sublist(4).join('#') : '';
      panels.refresh();
      return true;
    }
    if (m.startsWith('NO#')) {
      final bits = int.tryParse(m.substring(3), radix: 16);
      if (bits == null) return true;
      for (final p in panels) {
        p.online = ((bits >> (p.n - 1)) & 1) == 1;
      }
      panels.refresh();
      return true;
    }
    if (m.startsWith('HL#')) {
      final f = m.split('#');
      final n = f.length > 1 ? int.tryParse(f[1]) ?? 0 : 0;
      if (n < 1 || f.length < 16) return true;
      final it = [for (int i = 2; i < 16; i++) int.tryParse(f[i], radix: 16) ?? 0];
      health[n] = NetHealth(it);
      healthAsked.remove(n);
      final p = panel(n);
      if (p != null && p.online != health[n]!.online) {
        p.online = health[n]!.online;
        panels.refresh();
      }
      return true;
    }
    if (m.startsWith('P#')) {
      final n = int.tryParse(m.substring(2)) ?? -1;
      if (n < 0) return true;
      _openTimer?.cancel();
      opening.value = 0;
      viewing.value = n;
      _send('@M_MDL');                        // ماژول حالا خودش را همان پنل (یا خانه) معرفی می‌کند
      return true;
    }
    return false;
  }

  /// باز کردن یک پنل: از اینجا به بعد همان صفحه‌ی پنل تنها
  void open(int n) {
    if (panel(n) == null) return;
    opening.value = n;
    _send('@P#${_two(n)}');
    _openTimer?.cancel();
    _openTimer = Timer(const Duration(seconds: 4), () => opening.value = 0);
  }

  /// برگشت به فهرست خانه
  void back() {
    _send('@P#00');
  }

  /// گزارش سلامت (فقط با درخواست؛ CPU از همان لحظه جواب می‌دهد)
  void askHealth(int n) {
    if (panel(n) == null) return;
    healthAsked.add(n);
    _send('@M_HL#${_two(n)}');
    Timer(const Duration(seconds: 8), () => healthAsked.remove(n));
  }

  void askAllHealth() {
    for (int i = 1; i <= count.value; i++) {
      _askTimers.add(Timer(Duration(milliseconds: 1500 * (i - 1)), () => askHealth(i)));
    }
  }

  /// ماژول دیگر شبکه‌ی خانه نیست (پنل دیگری وصل شد)
  void deactivate() {
    for (final t in _askTimers) {
      t.cancel();
    }
    _askTimers.clear();
    _openTimer?.cancel();
    viewing.value = 0;
    opening.value = 0;
    installer.value = false;
  }

  static String ago(int secs) {
    if (secs < 60) return '${Panel12Controller.faNum(secs)} ثانیه';
    if (secs < 3600) return '${Panel12Controller.faNum(secs ~/ 60)} دقیقه';
    if (secs < 86400) return '${Panel12Controller.faNum(secs ~/ 3600)} ساعت';
    return '${Panel12Controller.faNum(secs ~/ 86400)} روز';
  }
}
