import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../data/data_sources/remote_data_sources/socket/connection_keeper.dart';
import '../sim12/sim12_screen.dart' show Sim12Photo;
import '../net/net_controller.dart';
import '../panel12/panel12_controller.dart';
import '../panel12/panel12_icons.dart';
import '../panel12/panel12_screen.dart';
import 'sd23_controller.dart';
import 'sd23_editor.dart';

// ---------- رنگ‌ها (همان تم صفحه‌ی پنل RF-12) ----------
const Color _bg = Color(0xFF0B0C10);
const Color _text = Color(0xFFF2F4F7);
const Color _muted = Color(0xB8F2F4F7);
const Color _red = Color(0xFFFF3B4E);
const Color _amber = Color(0xFFFFB547);
const Color _ok = Color(0xFF7EE2AE);
const Color _off = Color(0xEBF6F7F9);
const Color _dim = Color(0x33F6F7F9);
const Color _cool = Color(0xFF7FD3FF);
const Color _curt = Color(0xFFC9A7FF);

/// رنگ نوشته‌ی هر گروه روی تصویر پنل
Color _groupColor(String g) {
  switch (g) {
    case Sd23Controller.gCooler:
      return _cool;
    case Sd23Controller.gCurtain:
      return _curt;
    case Sd23Controller.gScn:
      return _amber;
  }
  return _off;
}

BoxDecoration _glass({double radius = 28}) => BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x21FFFFFF), Color(0x0AFFFFFF), Color(0x05FFFFFF), Color(0x12FFFFFF)],
        stops: [0, .38, .62, 1],
      ),
      border: Border.all(color: const Color(0x29FFFFFF)),
      boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 20), spreadRadius: -20)],
    );

/// ظاهر یک کلید بر اساس رنگ فعلی (null = خاموش)
class _Look {
  final Color fg;
  final Color? lit;
  final bool ready;
  final bool mark;

  _Look(this.lit, {this.ready = false, this.mark = false, Color? base}) : fg = lit ?? base ?? _off;

  BoxDecoration box(double radius) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: lit != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [lit!.withValues(alpha: .20), lit!.withValues(alpha: .06)],
              )
            : null,
        color: lit == null ? (ready ? const Color(0x17FFFFFF) : const Color(0x09FFFFFF)) : null,
        border: Border.all(
            width: mark ? 1.6 : 1,
            color: mark
                ? _amber
                : lit != null
                    ? lit!.withValues(alpha: .6)
                    : (ready ? _amber.withValues(alpha: .55) : const Color(0x14FFFFFF))),
        boxShadow: lit != null ? [BoxShadow(color: lit!.withValues(alpha: .27), blurRadius: 22)] : null,
      );

  List<Shadow>? get glow => lit != null ? [Shadow(color: lit!.withValues(alpha: .6), blurRadius: 8)] : null;
}

/// صفحه‌ی پنل ۲۳ کلید: تصویر واقعی پنل بالا، زیرش زبانه‌های گروه‌ها (پل‌ها، کولر، پرده، سناریو، دزدگیر).
/// چیدمان و نقش کلیدها از خود پنل می‌آید (هر مدل صفحه‌ی خودش را دارد).
class Sd23Screen extends StatelessWidget {
  const Sd23Screen({super.key});

  Sd23Controller get c => Sd23Controller.instance;

  // ---------- رنگ هر کلید ----------

  Color? _litOf(int k) {
    final t = c.kindOf(k);
    if (t == '-') return null;
    if (t == 'n') {
      if (c.entry.value == 'arm') return _amber;
      final a = c.alarm.value;
      if (a == 2 || a == 4) return _red;
      if (a == 1 || a == 3) return _amber;
      return null;
    }
    if (t == 'c') return c.entry.value == 'new' ? _amber : null;
    if (Sd23Controller.isDigitKind(t)) return c.flashing.contains('d$t') ? _red : null;
    return c.isOn(k) ? _red : null;
  }

  /// لمس یک کلید در لیست‌ها (در حالت نصاب: ویرایش اسم و آیکون)
  void _tap(int k) {
    if (!c.isPressKey(k)) return;
    HapticFeedback.lightImpact();
    if (c.installer.value) {
      editKeySheet(k);
      return;
    }
    c.press(k);
  }

  /// لمس روی تصویر پنل: زبانه‌ی همان کلید باز و کلید پررنگ می‌شود
  void _pickOnPanel(int k) {
    if (c.kindOf(k) == '-') return;
    c.selectKey(k);
  }

  // ---------- صفحه ----------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Stack(
        children: [
          Positioned(
            left: -120,
            top: 40,
            child: Obx(() {
              final a = (0.12 + c.onCount * 0.04).clamp(0.0, 0.55).toDouble();
              return _glowCircle(360, _red.withValues(alpha: a));
            }),
          ),
          Positioned(right: -140, top: 420, child: _glowCircle(380, const Color(0x474660FF))),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(context),
                _panelTabs(context),
                Obx(() => c.tooNew.value
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text('این پنل نسخه‌ی جدیدتری دارد؛ برای همه‌ی امکاناتش برنامه را به‌روز کنید',
                            textAlign: TextAlign.center, style: TextStyle(color: _amber, fontSize: 11.5)),
                      )
                    : const SizedBox.shrink()),
                _miniPanel(),
                _tabBar(),
                Expanded(child: _content()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
          ),
        ),
      );

  Widget _chip(String text, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: _glass(radius: 999).copyWith(border: Border.all(color: color)),
          child: Text(text, style: TextStyle(color: color, fontSize: 12)),
        ),
      );

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          // شبکه‌ی CPU: برگشت به فهرست پنل‌های خانه
          Obx(() => Panel12Controller.instance.isNet.value && !c.demo.value
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: _chip('›  خانه', _cool, NetController.instance.back),
                )
              : const SizedBox.shrink()),
          Expanded(
            child: GestureDetector(
              onLongPress: () => askInstallerPin(() => c.setInstaller(true)),
              child: Obx(() => Text(c.modelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _text, fontSize: 19, fontWeight: FontWeight.w700))),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            if (c.installer.value) {
              return Row(mainAxisSize: MainAxisSize.min, children: [
                _chip('تنظیمات', _amber, installerSheet),
                const SizedBox(width: 6),
                _chip('نصاب  ✕', _amber, () => c.setInstaller(false)),
              ]);
            }
            if (c.demo.value) return _chip('حالت نمایشی  ✕', _cool, () => Get.back());
            final online = ConnectionKeeper.instance.state.value == LinkState.connected;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: _glass(radius: 999),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: online ? _ok : _amber),
                ),
                const SizedBox(width: 6),
                Text(online ? 'آنلاین' : 'در حال اتصال', style: TextStyle(color: online ? _ok : _amber, fontSize: 12)),
              ]),
            );
          }),
        ],
      ),
    );
  }

  // ---------- سربرگ پنل‌ها (دو پنل شبکه‌ای) ----------

  /// پنل ۱ (همین پنل) و پنل ۲ (پنلی که با کابل شبکه به آن وصل است)؛ نگه داشتن: تغییر اسم
  Widget _panelTabs(BuildContext context) {
    return Obx(() {
      if (!c.hasPeer.value) return const SizedBox.shrink();
      c.panelNames.length;
      final n = c.peerCount.value < 1 ? 1 : c.peerCount.value;   // (سه یا چهار پنل: هر پنل دیگر یک زبانه)
      final sel = c.panel.value == 0 ? 0 : c.peerIdx.value + 1, online = c.peerOnline.value;
      Widget tabOf(int i) {
        final on = sel == i;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              c.selectPanel(i);
            },
            onLongPress: () => _rename(context, i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: on ? _red.withValues(alpha: .18) : const Color(0x0AFFFFFF),
                border: Border.all(color: on ? _red.withValues(alpha: .8) : const Color(0x1FFFFFFF)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                  child: Text(c.panelName(i),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: on ? _text : _muted, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                if (i >= 1) ...[
                  const SizedBox(width: 6),
                  Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: c.peerOnlineOf(i) ? _ok : _amber)),
                ],
              ]),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Column(children: [
          Row(children: [for (int i = 0; i <= n; i++) tabOf(i)]),
          if (sel >= 1 && !online)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(n > 1 ? 'این پنل الان به شبکه وصل نیست (کابل شبکه را بررسی کنید)' : 'پنل دوم به این پنل وصل نیست (کابل شبکه را بررسی کنید)',
                  textAlign: TextAlign.center, style: const TextStyle(color: _amber, fontSize: 11.5)),
            ),
        ]),
      );
    });
  }

  void _rename(BuildContext context, int i) {
    final ctl = TextEditingController(text: c.panelNames[i] ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF17181D),
        title: Text('اسم ${c.panelName(i)}', style: const TextStyle(color: _text, fontSize: 16)),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLength: 20,
          style: const TextStyle(color: _text),
          decoration: const InputDecoration(hintText: 'مثلاً پذیرایی', hintStyle: TextStyle(color: _muted)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('انصراف')),
          TextButton(
            onPressed: () {
              c.renamePanel(i, ctl.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  // ---------- تصویر کامل پنل (بالا) ----------

  /// همان تصویر پنل برای صفحه‌های دیگر (مسافرت)
  Widget miniPanel() => _miniPanel();

  Widget _miniPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: _glass(radius: 22),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(() {
            // همه‌ی مقدارهایی که تصویر به آن‌ها وابسته است
            c.lay.value;
            c.bits.value;
            c.alarm.value;
            c.entry.value;
            c.highlight.value;
            c.flashing.length;
            c.labels.length;
            c.iconIds.length;
            if (c.model.value == 'e12') return _frame(_e12Panel());
            // پنل سیمکارتی به‌عنوان پنل ۲: عکس خودش (بیت n = کلید شبکه‌ی n، مثل پروگرمر)
            if (c.model.value == 'p12') {
              int net(int k) => _p12Net.indexOf(k);
              return Sim12Photo(isOn: (k) => net(k) >= 0 && c.isOn(net(k)), onTap: (k) {
                if (net(k) >= 0) _pickOnPanel(net(k));
              });
            }
            // پنل کوچک (۱ تا ۴ پل، شش پل: فقط کلیدهای ۱ تا ۸): شیشه به شکل خود پنل
            final small = c.layKnown.value && [for (int k = 8; k < Sd23Controller.keyCount; k++) c.kindOf(k)].every((t) => t == '-');
            if (small) return _smallPanel();
            return _frame(IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                      flex: 2,
                      child: Column(mainAxisSize: MainAxisSize.min, children: Sd23Controller.leftKeys.map(_miniKey).toList())),
                  const SizedBox(width: 6),
                  Expanded(flex: 3, child: _miniCenter()),
                  const SizedBox(width: 6),
                  Expanded(
                      flex: 2,
                      child: Column(mainAxisSize: MainAxisSize.min, children: Sd23Controller.rightKeys.map(_miniKey).toList())),
                ],
              ),
            ));
          }),
        ),
      ),
    );
  }

  /// شماره‌ی شبکه‌ی کلیدهای پنل سیمکارتی -> کلید روی پنل (پل ۱ تا ۱۲، کلید ۱۳ تا ۱۵، پرده‌ها، آسانسور)
  static const List<int> _p12Net = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 23, 24, 25, 26, 22];

  /// قاب سفید دور کلیدها (لبه‌ی شیشه)
  Widget _frame(Widget child, {double pad = 6}) => Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xD9FFFFFF), width: 1.5),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x8C363436), Color(0x8C141416)],
          ),
        ),
        child: child,
      );

  /// پنل‌های کوچک به شکل خودشان: ۱ و ۲ پل و ۴ پل مربع، شش پل ایستاده (دو ستون، چهار ردیف)
  Widget _smallPanel() {
    int n = 0;
    for (int k = 0; k < 8; k++) {
      if (c.kindOf(k) != '-') n = k + 1;
    }
    Widget key(int k) => Expanded(child: SizedBox(height: 44, child: FittedBox(child: SizedBox(width: 64, height: 32, child: _miniKey(k)))));
    Widget face;
    double w, ratio;
    if (n <= 2) {
      w = 190;
      ratio = 1;
      face = Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (int k = 0; k < (n < 1 ? 1 : n); k++) key(k)]);
    } else if (n <= 4) {
      w = 190;
      ratio = 1;
      face = Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        for (final r in const [
          [0, 1],
          [2, 3]
        ])
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final k in r) key(k)]),
      ]);
    } else {
      w = 200;
      ratio = 0.85;
      face = Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        for (int r = 0; r < 4; r++) Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [key(2 * r), key(2 * r + 1)]),
      ]);
    }
    return Center(child: SizedBox(width: w, child: AspectRatio(aspectRatio: ratio, child: _frame(face, pad: 10))));
  }

  /// یک کلید کوچک: آیکون + نوشته (کلیدهای صفحه‌کلید فقط نوشته)
  /// big: ۱۲ اقتصادی (آیکون و نوشته درشت‌تر نسبت به جای کلید)
  Widget _miniKey(int k, {bool big = false}) {
    final t = c.kindOf(k);
    final lit = _litOf(k);
    final base = _groupColor(c.groupOf(k));
    final fg = t == '-' ? _dim : (lit ?? base);
    final glow = lit != null ? [Shadow(color: lit.withValues(alpha: .6), blurRadius: 8)] : null;
    // ۱۲ اقتصادی: سناریوها فقط نوشته (جز احضار آسانسور)
    final scnText = c.model.value == 'e12' && c.groupOf(k) == Sd23Controller.gScn && t != 'E';
    final textOnly = t == 'n' || t == 'c' || Sd23Controller.isDigitKind(t) || scnText;
    final mark = c.highlight.value == k;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _pickOnPanel(k),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: big ? 0 : 2.5),
        height: big ? 33 : 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: mark ? _amber : Colors.transparent, width: 1.4),
        ),
        child: t == '-'
            ? const SizedBox.shrink()
            : textOnly
                ? Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(c.labelOf(k),
                          style: TextStyle(
                              color: Sd23Controller.isDigitKind(t) && lit == null ? const Color(0xFFFFE600) : fg,
                              fontSize: Sd23Controller.isDigitKind(t) ? 13 : scnText ? 10 : 7.5,
                              fontWeight: FontWeight.w600,
                              shadows: glow)),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PanelIcons.icon(c.iconOf(k), fg, big ? 17 : 14),
                      Text(c.labelOf(k),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: fg, fontSize: big ? 9 : 7.5, height: 1.0, fontWeight: FontWeight.w600, shadows: glow)),
                    ],
                  ),
      ),
    );
  }

  /// ۱۲ اقتصادی: چیدمان روی شیشه (از نقشه‌ی ۱۳۴۴×۸۹۶ مالک، بخش کلیدها 180..1164 × 180..730)؛ سه سناریو در یک خط
  static const Map<int, List<double>> _e12Box = {
    0: [228, 217, 413, 288], 1: [931, 217, 1116, 288], 2: [228, 352, 413, 422], 3: [931, 352, 1116, 422],
    4: [228, 486, 413, 556], 5: [931, 486, 1116, 556], 6: [228, 620, 413, 690], 7: [931, 620, 1116, 690],
    8: [469, 285, 616, 355], 9: [727, 285, 874, 355], 10: [470, 419, 617, 489], 11: [728, 420, 875, 490],
    20: [444, 596, 578, 660], 21: [606, 596, 740, 660], 22: [765, 596, 899, 660],
  };
  Widget _e12Panel() {
    const x0 = 180.0, y0 = 180.0, fw = 984.0, fh = 550.0;   // the keys' area of the glass (bigger keys on the phone)
    return AspectRatio(
      aspectRatio: fw / fh,
      child: LayoutBuilder(builder: (context, bc) {
        final sx = bc.maxWidth / fw, sy = bc.maxHeight / fh;
        // جای هر کلید روی شیشه، کمی بزرگ‌تر از نقشه (آیکون درشت‌تر)؛ بدون کادر دور کلید
        Widget box(List<double> b, Widget child, {double grow = 1.3}) {
          final cx = (b[0] + b[2]) / 2, cy = (b[1] + b[3]) / 2, hw = (b[2] - b[0]) / 2 * grow, hh = (b[3] - b[1]) / 2 * grow;
          return Positioned(
            left: (cx - hw - x0) * sx,
            top: (cy - hh - y0) * sy,
            width: 2 * hw * sx,
            height: 2 * hh * sy,
            child: child,
          );
        }
        return Stack(children: [
          for (final e in _e12Box.entries)
            box(e.value, FittedBox(fit: BoxFit.contain, child: SizedBox(width: 33 * (e.value[2] - e.value[0]) / (e.value[3] - e.value[1]), height: 33, child: _miniKey(e.key, big: true)))),
          box(const [808, 552, 855, 589], const FittedBox(child: Icon(Icons.wifi, color: Color(0x99FFFFFF))), grow: 1),
        ]);
      }),
    );
  }

  Widget _miniCenter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final r in Sd23Controller.middleRows) Row(children: [for (final k in r) Expanded(child: _miniKey(k))]),
        const SizedBox(height: 2),
        Row(children: [for (final k in Sd23Controller.bottomKeys) Expanded(child: _miniKey(k))]),
      ],
    );
  }

  // ---------- زبانه‌ها ----------

  String _tabTitle(String g) {
    switch (g) {
      case Sd23Controller.gPoles:
        return '${Sd23Controller.faNum(c.keysOf(g).length)} پل';
      case Sd23Controller.gCooler:
        return 'کولر';
      case Sd23Controller.gCurtain:
        return 'پرده';
      case Sd23Controller.gScn:
        return '${Sd23Controller.faNum(c.keysOf(g).length)} سناریو';
      case Sd23Controller.gAlarm:
        return 'دزدگیر';
    }
    return g;
  }

  Widget _tabBar() {
    return Obx(() {
      c.lay.value;
      final tabs = c.tabs;
      final cur = tabs.contains(c.tab.value) ? c.tab.value : (tabs.isNotEmpty ? tabs.first : '');
      if (tabs.length <= 1) return const SizedBox(height: 2);
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0x0DFFFFFF),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Row(children: [
          for (final g in tabs)
            Expanded(
              child: GestureDetector(
                onTap: () => c.tab.value = g,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: g == cur ? _groupTint(g).withValues(alpha: .16) : Colors.transparent,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_tabTitle(g),
                        style: TextStyle(
                            color: g == cur ? _groupTint(g) : _muted,
                            fontSize: 13,
                            fontWeight: g == cur ? FontWeight.w800 : FontWeight.w400)),
                  ),
                ),
              ),
            ),
        ]),
      );
    });
  }

  Color _groupTint(String g) => g == Sd23Controller.gPoles ? _red : (g == Sd23Controller.gAlarm ? _red : _groupColor(g));

  Widget _content() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: _glass(),
        child: Obx(() {
          c.lay.value;
          c.bits.value;
          c.alarm.value;
          c.entry.value;
          c.buf.value;
          c.message.value;
          c.flashing.length;
          c.labels.length;
          c.iconIds.length;
          c.installer.value;
          c.highlight.value;
          c.cf.length;
          final tabs = c.tabs;
          final g = tabs.contains(c.tab.value) ? c.tab.value : (tabs.isNotEmpty ? tabs.first : '');
          switch (g) {
            case Sd23Controller.gCooler:
              return _coolerZone();
            case Sd23Controller.gCurtain:
              return _curtainZone();
            case Sd23Controller.gScn:
              return _scnZone();
            case Sd23Controller.gAlarm:
              return _alarmZone();
            case Sd23Controller.gPoles:
              return _polesZone();
          }
          return const Center(child: Text('در حال خواندن از پنل…', style: TextStyle(color: _muted)));
        }),
      ),
    );
  }

  // ---------- پل‌ها ----------

  /// کلیدهای یک گروه، ردیف به ردیف مثل نمایشگر بالا: [چپ، راست]؛ -1 = جای خالی (کلید آن طرف در این گروه نیست)
  List<int> _gridOrder(List<int> keys) {
    final rows = <List<int>>[
      for (int i = 0; i < Sd23Controller.leftKeys.length; i++) [Sd23Controller.leftKeys[i], Sd23Controller.rightKeys[i]],
      ...Sd23Controller.middleRows,
    ];
    final out = <int>[], used = <int>{};
    for (final r in rows) {
      final a = keys.contains(r[0]), b = keys.contains(r[1]);
      if (!a && !b) continue;
      out..add(a ? r[0] : -1)..add(b ? r[1] : -1);
      used.addAll(r);
    }
    for (final k in keys) {
      if (!used.contains(k)) out.add(k);
    }
    return out;
  }

  Widget _polesZone() {
    final keys = c.keysOf(Sd23Controller.gPoles);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Row(children: [
          Expanded(
            child: Text('${Sd23Controller.faNum(c.polesOn)} روشن از ${Sd23Controller.faNum(keys.length)}',
                style: const TextStyle(color: _muted, fontSize: 12)),
          ),
          GestureDetector(
            onTap: c.polesOn == 0 ? null : c.allPolesOff,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0x0DFFFFFF),
                border: Border.all(color: const Color(0x29FFFFFF)),
              ),
              child: Text('خاموش کردن همه',
                  style: TextStyle(color: c.polesOn == 0 ? _dim : _text, fontSize: 11.5)),
            ),
          ),
        ]),
      ),
      // همان ترتیب نمایشگر بالا (چپ و راست مثل خود پنل): شبکه چپ‌به‌راست، نوشته‌ها راست‌به‌چپ
      Expanded(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: 2.5,
            cacheExtent: 3000,
            padding: EdgeInsets.zero,
            children: [
              for (final k in _gridOrder(keys))
                k < 0 ? const SizedBox.shrink() : Directionality(textDirection: TextDirection.rtl, child: _rowKey(k)),
            ],
          ),
        ),
      ),
    ]);
  }

  String? _subText(int k) {
    final t = c.kindOf(k);
    final onNow = c.isOn(k);
    switch (t) {
      case 'U':
        return onNow ? 'در حال باز شدن' : null;
      case 'W':
        return onNow ? 'در حال بسته شدن' : null;
      case 'D':
        return onNow ? 'روشن · خاموشی با تأخیر' : 'خاموشی با تأخیر';
      case 'P':
        return 'شاسی';
      case 'Y':
        return 'شاسی تأخیری';
    }
    return onNow ? 'روشن' : 'خاموش';
  }

  /// یک کلید بزرگ
  Widget _rowKey(int k) {
    final look = _Look(_litOf(k), mark: c.highlight.value == k);
    final sub = _subText(k);
    return GestureDetector(
      onTap: () => _tap(k),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: look.box(16),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            PanelIcons.icon(c.iconOf(k), look.fg, 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.labelOf(k),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: look.fg, fontSize: 13.5, fontWeight: FontWeight.w600, shadows: look.glow)),
                  if (sub != null)
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: look.lit ?? _muted, fontSize: 10.5)),
                ],
              ),
            ),
            if (c.installer.value) const Icon(Icons.edit, color: _amber, size: 16),
          ],
        ),
      ),
    );
  }

  // ---------- کولر آبی: مثل یک پنل ۴ کلید ----------

  Widget _coolerZone() {
    final pairs = c.coolerPairs;
    final pumps = [for (final k in c.keysOf(Sd23Controller.gCooler)) if (c.kindOf(k) == 'K') k];
    final n = pairs.length > pumps.length ? pairs.length : pumps.length;
    return ListView(padding: EdgeInsets.zero, children: [
      for (int i = 0; i < n; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _coolerPanel(i < pumps.length ? pumps[i] : -1, i < pairs.length ? pairs[i] : const <int>[]),
        ),
    ]);
  }

  Widget _coolerPanel(int pump, List<int> pair) {
    final slow = pair.isNotEmpty ? pair[0] : -1, fast = pair.length > 1 ? pair[1] : -1;
    final parts = <String>[];
    if (pump >= 0 && c.isOn(pump)) parts.add('پمپ روشن');
    if (slow >= 0 && c.isOn(slow)) parts.add('دور کند');
    if (fast >= 0 && c.isOn(fast)) parts.add('دور تند');
    Widget cell(int k, String icon) => k < 0 ? const SizedBox.shrink() : _bigKey(k, icon);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
        child: Row(children: [
          const Text('کولر آبی', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w800)),
          const Spacer(),
          Text(parts.isEmpty ? 'خاموش' : parts.join(' · '), style: const TextStyle(color: _muted, fontSize: 11.5)),
        ]),
      ),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xD9FFFFFF), width: 1.6),
          gradient: const LinearGradient(colors: [Color(0x99363436), Color(0x99141416)]),
        ),
        child: Column(children: [
          SizedBox(
            height: 92,
            child: Row(children: [
              Expanded(child: cell(pump, '00')),
              const SizedBox(width: 8),
              Expanded(child: cell(slow, '01')),
            ]),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            child: Row(children: [
              Expanded(child: cell(fast, '02')),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: c.coolerOff,
                  child: Container(
                    decoration: _Look(null).box(14),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.power_settings_new_rounded, color: _off, size: 26),
                      SizedBox(height: 4),
                      Text('خاموش', style: TextStyle(color: _off, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }

  /// کلید مربعی بزرگ (کولر، صفحه‌کلید، پرده)
  Widget _bigKey(int k, String icon) {
    final look = _Look(_litOf(k), mark: c.highlight.value == k);
    return GestureDetector(
      onTap: () => _tap(k),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: look.box(14),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          PanelIcons.icon(c.iconIds[k].isNotEmpty ? c.iconIds[k] : icon, look.fg, 26),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(c.labelOf(k),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: look.fg, fontSize: 13, fontWeight: FontWeight.w600, shadows: look.glow)),
          ),
        ]),
      ),
    );
  }

  // ---------- پرده ----------

  Widget _curtainZone() {
    return ListView(padding: EdgeInsets.zero, children: [
      for (final p in c.curtainPairs)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: _curt.withValues(alpha: .05),
              border: Border.all(color: _curt.withValues(alpha: .35)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(
                  child: Text(c.labels[p[0]].isNotEmpty ? c.labels[p[0]] : 'پرده',
                      style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                Text(
                    (c.isOn(p[0]) ? 'در حال باز شدن' : c.isOn(p[1]) ? 'در حال بسته شدن' : 'ایستاده') +
                        ((c.curPct[p[0]] ?? -1) >= 0 ? ' - ${Sd23Controller.faNum(c.curPct[p[0]]!)}٪ باز' : ''),
                    style: TextStyle(color: c.isOn(p[0]) || c.isOn(p[1]) ? _red : _muted, fontSize: 11.5)),
              ]),
              if ((c.curPct[p[0]] ?? -1) >= 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: c.curPct[p[0]]! / 100,
                      minHeight: 6,
                      color: _curt,
                      backgroundColor: _curt.withValues(alpha: .15),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                height: 76,
                child: Row(children: [
                  Expanded(child: _bigKey(p[0], '07')),
                  const SizedBox(width: 8),
                  Expanded(child: _bigKey(p[1], '07')),
                ]),
              ),
              if (c.installer.value && c.cf[p[0]] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _timeButton(p[0], '1', 'زمان حرکت', c.cf[p[0]]!.sec1, 'ثانیه'),
                ),
            ]),
          ),
        ),
      if (c.curtainPairs.isEmpty)
        for (final k in c.keysOf(Sd23Controller.gCurtain))
          Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(height: 64, child: _rowKey(k))),
    ]);
  }

  // ---------- سناریوها ----------

  Widget _scnZone() {
    final keys = c.keysOf(Sd23Controller.gScn);
    return ListView(padding: EdgeInsets.zero, children: [
      for (final k in keys)
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: _scnCard(k),
        ),
      const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Text('لمس کارت = اجرای سناریو، مثل لمس روی پنل',
            textAlign: TextAlign.center, style: TextStyle(color: Color(0x99F2F4F7), fontSize: 10.5)),
      ),
    ]);
  }

  Widget _scnCard(int k) {
    final t = c.kindOf(k);
    final run = c.isOn(k) && 'XZTOE'.contains(t);
    final mark = c.highlight.value == k;
    final cfk = c.cf[k];
    String? btn, btn2;
    VoidCallback? onBtn, onBtn2;
    if (t == 'Z' && c.installer.value && cfk != null) {               // نصاب: چراغ خواب و پل‌هایی که خاموش می‌شوند
      btn2 = 'پل‌ها';
      onBtn2 = () => Get.to(() => Sd23MaskEditor(mode: 'sleep', index: k));
    }
    if (t == 'S' || t == 'Q') {
      btn = 'ویرایش';
      onBtn = () => Get.to(() => Sd23MaskEditor(mode: t == 'S' ? 'custom' : 'group', index: k));
    } else if (t == 'M' && c.installer.value && cfk != null) {
      btn = 'پل‌های مستر';
      onBtn = () => Get.to(() => Sd23MaskEditor(mode: 'master', index: k));
    } else if ((t == 'X' || t == 'Z') && cfk != null) {
      final s = cfk.secs16;
      btn = s >= 60 && s % 60 == 0 ? '${Sd23Controller.faNum(s ~/ 60)} دقیقه' : '${Sd23Controller.faNum(s)} ثانیه';
      onBtn = () => _askNumber(k, 'T', 'زمان ${c.labelOf(k)}', 'ثانیه', s, 1, 65535);
    } else if ((t == 'T' || t == 'O') && cfk != null) {
      btn = '${Sd23Controller.faNum(cfk.minutes)} دقیقه';
      onBtn = () => _askNumber(k, 'M', t == 'T' ? 'زمان هواکش' : 'زمان تایمر خاموشی', 'دقیقه', cfk.minutes, 1, 255);
    }
    final line = c.scnLine(k);
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: run ? LinearGradient(colors: [_amber.withValues(alpha: .16), _amber.withValues(alpha: .04)]) : null,
        color: run ? null : const Color(0x09FFFFFF),
        border: Border.all(
            width: mark ? 1.6 : 1, color: mark || run ? _amber.withValues(alpha: .75) : const Color(0x1AFFFFFF)),
      ),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => c.installer.value ? editKeySheet(k) : c.press(k),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(c.labelOf(k),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _text, fontSize: 14.5, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Text('${c.kindName(k)} · ${c.placeName(k)}', style: const TextStyle(color: _amber, fontSize: 10.5)),
                ]),
                if (line.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(line, style: TextStyle(color: run ? _amber : _muted, fontSize: 11)),
                  ),
              ]),
            ),
          ),
        ),
        for (final b in [if (btn2 != null) [btn2, onBtn2], if (btn != null) [btn, onBtn]])
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: GestureDetector(
              onTap: b[1] as VoidCallback?,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: _amber.withValues(alpha: .08),
                  border: Border.all(color: _amber.withValues(alpha: .55)),
                ),
                child: Text(b[0] as String, style: const TextStyle(color: _amber, fontSize: 11.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
      ]),
    );
  }

  /// پنجره‌ی عوض کردن یک زمان
  void _askNumber(int k, String f, String title, String unit, int value, int min, int max) {
    final ctrl = TextEditingController(text: '$value');
    Get.dialog(AlertDialog(
      backgroundColor: const Color(0xFF16171C),
      title: Text(title, style: const TextStyle(color: _text, fontSize: 16)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _text, fontSize: 22),
        decoration: InputDecoration(suffixText: unit, helperText: 'از ${Sd23Controller.faNum(min)} تا ${Sd23Controller.faNum(max)}'),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('انصراف')),
        TextButton(
          onPressed: () {
            final v = int.tryParse(ctrl.text.trim());
            if (v == null || v < min || v > max) return;
            Get.back();
            c.saveTime(k, f, v);
          },
          child: const Text('ذخیره روی پنل'),
        ),
      ],
    ));
  }

  Widget _timeButton(int k, String f, String title, int value, String unit) {
    return GestureDetector(
      onTap: () => _askNumber(k, f, title, unit, value, 1, 255),
      child: Text('$title: ${Sd23Controller.faNum(value)} $unit  (ویرایش)',
          style: const TextStyle(color: _amber, fontSize: 12, decoration: TextDecoration.underline)),
    );
  }

  // ---------- دزدگیر ----------

  Widget _alarmZone() {
    final keys = c.keysOf(Sd23Controller.gAlarm);
    final onOff = keys.where((k) => c.kindOf(k) == 'n').toList();
    final pass = keys.where((k) => c.kindOf(k) == 'c').toList();
    final digits = keys.where((k) => Sd23Controller.isDigitKind(c.kindOf(k))).toList()
      ..sort((a, b) => c.kindOf(a).compareTo(c.kindOf(b)));
    final entering = c.entry.value.isNotEmpty;
    final msg = c.message.value.isNotEmpty ? c.message.value : c.alarmText;
    final msgType = c.message.value.isNotEmpty ? c.messageType.value : (c.alarm.value >= 3 ? 'err' : '');
    Widget keyBox(int k) {
      final t = c.kindOf(k);
      final digit = Sd23Controller.isDigitKind(t);
      final look = _Look(_litOf(k), ready: digit && entering, mark: c.highlight.value == k);
      final box = AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: look.box(16),
        child: Center(
          child: Text(c.labelOf(k),
              style: TextStyle(
                  color: digit && look.lit == null ? const Color(0xFFFFE600) : look.fg,
                  fontSize: digit ? 26 : 15,
                  fontWeight: FontWeight.w600,
                  shadows: look.glow)),
        ),
      );
      if (t == 'c') {
        // تغییر رمز: دو ثانیه نگه داشتن (مثل خود پنل)
        return Listener(
          onPointerDown: (_) => c.passDown(),
          onPointerUp: (_) => c.passUp(),
          onPointerCancel: (_) => c.passUp(),
          child: box,
        );
      }
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (t == 'n') {
            c.onOff();
          } else {
            c.digit(int.parse(t));
          }
        },
        child: box,
      );
    }

    final rows = <List<int>>[
      [...onOff, ...pass],
      for (int i = 0; i < digits.length; i += 3) digits.sublist(i, i + 3 > digits.length ? digits.length : i + 3),
    ];
    return Column(children: [
      SizedBox(
        height: 30,
        child: Row(children: [
          Expanded(
            child: Text(msg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    color: msgType == 'err' ? const Color(0xFFFF7A86) : (msgType == 'ok' ? _ok : _muted))),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: [
              for (int i = 0; i < 4; i++)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: entering ? _amber : const Color(0x40FFFFFF), width: 1.5),
                    color: entering && c.buf.value.length > i ? _amber : Colors.transparent,
                  ),
                ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      for (int r = 0; r < rows.length; r++) ...[
        if (r > 0) const SizedBox(height: 8),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: [
              for (int i = 0; i < rows[r].length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: keyBox(rows[r][i])),
              ],
            ]),
          ),
        ),
      ],
    ]);
  }

  // ---------- نصاب ----------

  /// تنظیمات نصاب: زمان‌های دزدگیر، خاموش شدن پنل و برگشت به تنظیمات پروگرم
  void installerSheet() {
    final t = c.alTimes;
    final arm = TextEditingController(text: t.isNotEmpty ? '${t[0]}' : '');
    final ent = TextEditingController(text: t.length > 1 ? '${t[1]}' : '');
    final sir = TextEditingController(text: t.length > 2 ? '${t[2]}' : '');
    final dark = TextEditingController(text: t.length > 3 ? '${t[3]}' : '');
    Widget field(String label, TextEditingController ctrl) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: _text),
            decoration: InputDecoration(labelText: label, suffixText: 'ثانیه'),
          ),
        );
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF14151A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('تنظیمات نصاب', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (c.hasAlarm.value) ...[
              field('دزدگیر: فعال شدن بعد از رمز (۰ = همان لحظه)', arm),
              field('دزدگیر: مهلت زدن رمز بعد از سنسور', ent),
              field('دزدگیر: زمان آژیر', sir),
            ],
            field('خاموش شدن پنل بعد از بی‌کاری (۰ = هرگز)', dark),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
              onPressed: () {
                int v(TextEditingController x, int d) => (int.tryParse(x.text.trim()) ?? d).clamp(0, 255).toInt();
                final cur = c.alTimes;
                c.saveAlarmTimes(v(arm, cur.isNotEmpty ? cur[0] : 20), v(ent, cur.length > 1 ? cur[1] : 30).clamp(1, 255).toInt(),
                    v(sir, cur.length > 2 ? cur[2] : 60).clamp(1, 255).toInt(), v(dark, cur.length > 3 ? cur[3] : 60));
                Get.back();
              },
              child: const Text('ذخیره روی پنل'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Get.back();
                Get.dialog(AlertDialog(
                  backgroundColor: const Color(0xFF16171C),
                  title: const Text('برگشت به تنظیمات پروگرم', style: TextStyle(color: _text, fontSize: 16)),
                  content: const Text(
                      'همه‌ی زمان‌هایی که از گوشی عوض شده و سناریوهای سفارشی و گروه‌های ذخیره‌شده پاک می‌شوند و پنل دوباره روشن می‌شود. سناریوهای گوشی و اسم کلیدها می‌مانند.',
                      style: TextStyle(color: _muted, fontSize: 13, height: 1.7)),
                  actions: [
                    TextButton(onPressed: () => Get.back(), child: const Text('انصراف')),
                    TextButton(
                      onPressed: () {
                        Get.back();
                        c.resetSettings();
                      },
                      child: const Text('برگشت', style: TextStyle(color: _red)),
                    ),
                  ],
                ));
              },
              child: const Text('برگشت به تنظیمات پروگرم'),
            ),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// اسم و آیکون یک کلید (حالت نصاب)؛ برای کلیدهای زمان‌دار، زمان هم
  void editKeySheet(int k) {
    final textCtrl = TextEditingController(text: c.labels[k]);
    String iconId = c.iconOf(k);
    final t = c.kindOf(k);
    final cfk = c.cf[k];

    Get.bottomSheet(
      StatefulBuilder(builder: (context, setState) {
        return Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF14151A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${c.placeName(k)} (${c.defaultLabel(k)})',
                    style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                const Text('آیکون', style: TextStyle(color: _muted, fontSize: 13)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 230,
                  child: GridView.count(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: .82,
                    children: PanelIcons.choices.map((id) {
                      final sel = id == iconId;
                      return GestureDetector(
                        onTap: () => setState(() => iconId = id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: sel ? _red.withValues(alpha: .18) : const Color(0x0DFFFFFF),
                            border: Border.all(color: sel ? _red : const Color(0x1AFFFFFF)),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            PanelIcons.icon(id, sel ? _red : _off, 28),
                            const SizedBox(height: 4),
                            Text(PanelIcons.nameOf(id),
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 9)),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('متن روی کلید (حداکثر ۲۰ حرف فارسی)', style: TextStyle(color: _muted, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: textCtrl,
                  style: const TextStyle(color: _text),
                  maxLength: 20,
                  decoration: const InputDecoration(
                    hintText: 'مثلاً لوستر پذیرایی',
                    hintStyle: TextStyle(color: Color(0x66FFFFFF)),
                    counterStyle: TextStyle(color: _muted),
                  ),
                ),
                if (cfk != null && (t == 'D' || t == 'P' || t == 'Y'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _timeButton(k, '1', t == 'D' ? 'تأخیر خاموشی' : t == 'P' ? 'زمان وصل' : 'تأخیر', cfk.sec1, 'ثانیه'),
                  ),
                if (cfk != null && t == 'Y' && cfk.sec2 > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _timeButton(k, '2', 'زمان وصل', cfk.sec2, 'ثانیه'),
                  ),
                const SizedBox(height: 8),
                Row(children: [
                  if (t == 'L')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => c.identify(k),
                        child: const Text('شناسایی روی پنل'),
                      ),
                    ),
                  if (t == 'L') const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
                      onPressed: () {
                        c.saveKey(index: k, iconId: iconId, label: textCtrl.text);
                        Get.back();
                      },
                      child: const Text('ذخیره روی پنل'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        );
      }),
      isScrollControlled: true,
    );
  }
}

/// تب مسافرت برای پنل ۲۳ کلید (در به‌روزرسانی بعدی)
class Sd23LaterPage extends StatelessWidget {
  final String title;

  const Sd23LaterPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.schedule_rounded, color: _amber, size: 40),
        const SizedBox(height: 14),
        Text(title,
            textAlign: TextAlign.center, style: const TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('این بخش برای پنل‌های ۲۳ کلید در به‌روزرسانی بعدی برنامه اضافه می‌شود.',
            textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12.5, height: 1.7)),
      ]),
    );
  }
}

/// صفحه‌هایی که فقط برای خود پنل وای‌فای‌دار است (سناریوهای گوشی، مسافرت): وقتی پنل ۲ انتخاب شده، راهنما
class Sd23OwnOnly extends StatelessWidget {
  final Widget child;
  final String what;

  const Sd23OwnOnly({super.key, required this.child, required this.what});

  @override
  Widget build(BuildContext context) {
    final c = Sd23Controller.instance;
    return Obx(() {
      if (c.panel.value != 1) return child;
      return Container(
        color: _bg,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.swap_horiz_rounded, color: _amber, size: 40),
          const SizedBox(height: 14),
          Text('$what برای ${c.panelName(0)} است',
              textAlign: TextAlign.center, style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('الان ${c.panelName(c.peerIdx.value + 1)} انتخاب شده است.', textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 12.5)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
            onPressed: () => c.selectPanel(0),
            child: Text('نمایش ${c.panelName(0)}'),
          ),
        ]),
      );
    });
  }
}

/// حالت نمایشی پنل ۲۳ کلید
class Sd23DemoPage extends StatefulWidget {
  final String model;

  const Sd23DemoPage({super.key, required this.model});

  @override
  State<Sd23DemoPage> createState() => _Sd23DemoPageState();
}

class _Sd23DemoPageState extends State<Sd23DemoPage> {
  @override
  void initState() {
    super.initState();
    Sd23Controller.instance.startDemo(widget.model);
  }

  @override
  void dispose() {
    Sd23Controller.instance.stopDemo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _bg,
      body: Stack(fit: StackFit.expand, children: [Sd23Screen(), Panel12Overlay()]),
    );
  }
}
