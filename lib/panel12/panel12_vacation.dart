import '../sim12/sim12_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../sd23/sd23_screen.dart' show Sd23OwnOnly;
import '../sd23/sd23_vacation.dart';
import 'panel12_controller.dart';
import 'panel12_screen.dart';

const Color _bg = Color(0xFF0B0C10);
const Color _text = Color(0xFFF2F4F7);
const Color _muted = Color(0xB8F2F4F7);
const Color _red = Color(0xFFFF3B4E);
const Color _amber = Color(0xFFFFB547);
const Color _green = Color(0xFF7EE2AE);

/// تب مسافرت: برای پنل RF-12 برنامه‌ی مسافرت، وگرنه صفحه‌ی قبلی (امنیت)
class Panel12VacationTabHost extends StatelessWidget {
  final Widget home;

  const Panel12VacationTabHost({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = Panel12Controller.instance;
      final known = c.modelKnown.value;
      final sim = c.isSim12.value || (!known && c.lastSim12.value);
      final sd = !sim && (c.isSd23.value || (!known && c.lastSd23.value));
      final showNew = !sim && !sd && (c.isRf12.value || (!known && c.lastRf12.value));
      final showOld = known && !c.isRf12.value && !c.isSd23.value && !c.isSim12.value;
      return Stack(fit: StackFit.expand, children: [
        Offstage(offstage: !showOld, child: home),
        if (sim) const Sim12VacationPage(),
        if (sim) const Panel12Overlay(),
        if (sd) const Sd23OwnOnly(what: 'برنامه‌ی مسافرت', child: Sd23VacationPage()),
        if (sd) const Panel12Overlay(),
        if (showNew) const Panel12VacationScreen(),
        if (showNew) const Panel12Overlay(),
        if (!showNew && !showOld && !sd && !sim) const ColoredBox(color: _bg),
      ]);
    });
  }
}

/// تاریخ شمسی
class Jalali {
  static const months = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];
  static const weekdays = ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه']; // DateTime.weekday ۱ = دوشنبه

  static List<int> of(DateTime g) {
    int gy = g.year;
    final gm = g.month, gd = g.day;
    const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    int jy = gy <= 1600 ? 0 : 979;
    gy -= gy <= 1600 ? 621 : 1600;
    final gy2 = gm > 2 ? gy + 1 : gy;
    int days = 365 * gy + (gy2 + 3) ~/ 4 - (gy2 + 99) ~/ 100 + (gy2 + 399) ~/ 400 - 80 + gd + gdm[gm - 1];
    jy += 33 * (days ~/ 12053);
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    final jm = days < 186 ? 1 + days ~/ 31 : 7 + (days - 186) ~/ 30;
    final jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30);
    return [jy, jm, jd];
  }

  static String dayText(int day) {
    final j = of(Panel12Controller.dateOf(day));
    return '${Panel12Controller.faNum(j[2])} ${months[j[1] - 1]}';
  }

  static String weekday(int day) => weekdays[Panel12Controller.dateOf(day).weekday - 1];
}

class Panel12VacationScreen extends StatefulWidget {
  const Panel12VacationScreen({super.key});

  @override
  State<Panel12VacationScreen> createState() => _Panel12VacationScreenState();
}

class _Panel12VacationScreenState extends State<Panel12VacationScreen> {
  Panel12Controller get c => Panel12Controller.instance;

  late Panel12Vacation v;
  bool dirty = false;
  int active = -1; // مرحله‌ی در حال پیش‌نمایش
  Worker? _w, _wOk;

  static String _fa(int n) => Panel12Controller.faNum(n);

  static String _hm(int t) {
    final h = (t ~/ 60) % 24, m = t % 60;
    return '${_fa2(h)}:${_fa2(m)}';
  }

  static String _fa2(int n) => Panel12Controller.faNum(n).padLeft(2, '۰');

  @override
  void initState() {
    super.initState();
    v = (c.vacation.value ?? Panel12Vacation.defaults()).copy();
    _w = ever<Panel12Vacation?>(c.vacation, (p) {
      // برنامه از پنل رسید: اگر کاربر چیزی را تغییر نداده، همان را نشان بده
      if (!dirty && mounted) setState(() => v = (p ?? Panel12Vacation.defaults()).copy());
    });
    // ذخیره فقط وقتی تمام است که پنل همان برنامه را برگرداند
    _wOk = ever<int>(c.vacSaveOk, (_) {
      if (!mounted) return;
      setState(() {
        dirty = false;
        v = (c.vacation.value ?? Panel12Vacation.defaults()).copy();
      });
    });
  }

  @override
  void dispose() {
    _w?.dispose();
    _wOk?.dispose();
    c.stopPreview();
    super.dispose();
  }

  void _edit(void Function() f) => setState(() {
        f();
        dirty = true;
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Stack(children: [
        Positioned(left: -120, top: 40, child: _glow(360, _red.withValues(alpha: .18))),
        Positioned(right: -140, top: 420, child: _glow(380, const Color(0x404660FF))),
        SafeArea(
          bottom: false,
          child: Column(children: [
            _header(),
            const Panel12Screen().miniPanel(zones: false),
            Expanded(
              // همه‌ی کارت‌ها همیشه ساخته می‌شوند (فهرست کوتاه است)
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _dates(),
                  const SizedBox(height: 10),
                  for (int i = 0; i <= v.steps.length; i++) ...[
                    _stepCard(i),
                    const SizedBox(height: 8),
                  ],
                  if (v.steps.length < Panel12Controller.vacSteps) _addStep(),
                  const SizedBox(height: 10),
                  _bottomButtons(),
                  const SizedBox(height: 10),
                  const Text(
                    'برنامه روی خود پنل ذخیره و اجرا می‌شود و به گوشی نیازی ندارد. ساعت پنل با هر بار اتصال گوشی تنظیم می‌شود؛ '
                    'اگر در نبودِ شما برق قطع شود، برنامه تا اتصال دوباره‌ی یک گوشی متوقف می‌ماند.',
                    style: TextStyle(color: _muted, fontSize: 11, height: 1.6),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _glow(double size, Color color) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])),
        ),
      );

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('سناریو مسافرت', style: TextStyle(color: _text, fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Obx(() {
              final saved = c.vacation.value;
              String t;
              Color col;
              if (!c.panelClockOk.value && saved != null && saved.on) {
                t = 'ساعت پنل تنظیم نیست (قطع برق) · گوشی را به پنل وصل کنید';
                col = _amber;
              } else if (saved == null || !saved.on) {
                t = 'غیرفعال';
                col = _muted;
              } else {
                final last = c.vacLast.value;
                final run = last.isEmpty ? '' : (last == 'E' ? ' · آخرین اجرا: خاموشی' : ' · آخرین اجرا: مرحله‌ی ${_fa(int.tryParse(last) ?? 0)}');
                t = 'فعال · شروع ${Jalali.weekday(saved.d0)} ${Jalali.dayText(saved.d0)} ساعت ${_hm(saved.steps.first.t)}$run';
                col = _green;
              }
              return Text(t, style: TextStyle(color: col, fontSize: 11.5, fontWeight: FontWeight.w600));
            }),
          ]),
        ),
        _switch(v.on, () => _edit(() => v.on = !v.on)),
      ]),
    );
  }

  Widget _switch(bool on, VoidCallback tap) => GestureDetector(
        onTap: tap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 50,
          height: 28,
          padding: const EdgeInsets.all(3),
          alignment: on ? Alignment.centerLeft : Alignment.centerRight,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: on ? _red : const Color(0x2EFFFFFF)),
          child: Container(width: 22, height: 22, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
        ),
      );

  Widget _card({required Widget child, bool lit = false}) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: lit ? _red.withValues(alpha: .10) : const Color(0x09FFFFFF),
          border: Border.all(color: lit ? _red : const Color(0x1FFFFFFF)),
          boxShadow: lit ? [BoxShadow(color: _red.withValues(alpha: .33), blurRadius: 26)] : null,
        ),
        child: child,
      );

  Widget _sq(String t, VoidCallback onTap) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x26FFFFFF))),
          child: Text(t, style: const TextStyle(color: _text, fontSize: 18)),
        ),
      );

  Widget _stepper(String value, VoidCallback down, VoidCallback up, {double width = 96, double size = 15}) =>
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _sq('−', down),
          SizedBox(
            width: width,
            child: Text(value,
                textAlign: TextAlign.center,
                style: TextStyle(color: _text, fontSize: size, fontWeight: FontWeight.w700)),
          ),
          _sq('+', up),
        ]),
      );

  // ---------- تاریخ ----------

  Widget _dates() {
    final today = Panel12Controller.dayNumber(DateTime.now());
    final off = v.d0 - today;
    final rel = off == 0 ? ' (امروز)' : (off == 1 ? ' (فردا)' : '');
    final rep = v.repeat;
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Text('شروع', style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
          const Spacer(),
          Column(children: [
            _stepper(Jalali.dayText(v.d0), () {
              if (v.d0 > today) {
                _edit(() {
                  final r = v.repeat;
                  v.d0--;
                  if (!r) v.d1 = v.d0;
                });
              }
            }, () {
              _edit(() {
                final r = v.repeat;
                v.d0++;
                if (!r || v.d1 < v.d0 + 1) v.d1 = r ? v.d0 + 1 : v.d0;
              });
            }),
            const SizedBox(height: 2),
            Text('${Jalali.weekday(v.d0)}$rel', style: const TextStyle(color: _muted, fontSize: 11)),
          ]),
        ]),
        const SizedBox(height: 10),
        const Divider(color: Color(0x14FFFFFF), height: 1),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('تکرار هر شب تا روز بازگشت', style: TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(rep ? 'هر شب همین برنامه تا ${Jalali.dayText(v.d1)} تکرار می‌شود' : 'فقط یک بار اجرا می‌شود',
                  style: const TextStyle(color: _muted, fontSize: 11)),
            ]),
          ),
          _switch(rep, () => _edit(() => v.d1 = rep ? v.d0 : v.d0 + 7)),
        ]),
        if (rep) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Text('تا', style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
            const Spacer(),
            _stepper(Jalali.dayText(v.d1), () {
              if (v.d1 > v.d0 + 1) _edit(() => v.d1--);
            }, () {
              if (v.d1 < v.d0 + 365) _edit(() => v.d1++);
            }),
          ]),
        ],
        if (_firstStepPassed(today)) ...[
          const SizedBox(height: 8),
          Text('ساعت مرحله‌ی ۱ امروز گذشته؛ امشب از مرحله‌ی بعدی شروع می‌شود',
              style: TextStyle(color: _amber.withValues(alpha: .9), fontSize: 11)),
        ],
      ]),
    );
  }

  bool _firstStepPassed(int today) {
    if (v.d0 != today || v.steps.isEmpty) return false;
    final n = DateTime.now();
    return v.steps.first.t <= n.hour * 60 + n.minute;
  }

  // ---------- مرحله‌ها ----------

  Widget _stepCard(int i) {
    final isEnd = i == v.steps.length;
    final s = isEnd ? null : v.steps[i];
    final t = isEnd ? v.te : s!.t;
    final cnt = s == null ? 0 : s.k.where((e) => e).length;
    final hint = isEnd
        ? 'همه‌ی چراغ‌ها خاموش می‌شوند'
        : (i == 0
            ? 'این چراغ‌ها روشن می‌شوند (${_fa(cnt)} چراغ)'
            : 'چراغ‌های مرحله‌ی قبل خاموش و این‌ها روشن می‌شوند (${_fa(cnt)} چراغ)');
    void setT(int nt) => _edit(() {
          if (isEnd) {
            v.te = nt;
          } else {
            v.steps[i].t = nt;
          }
        });

    return _card(
      lit: active == i,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: active == i ? _red : (isEnd ? const Color(0xFF3A3B42) : const Color(0x2EFFFFFF))),
            child: Text(isEnd ? '■' : _fa(i + 1), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(isEnd ? 'پایان: خاموشی کامل پنل' : 'مرحله‌ی ${_fa(i + 1)}',
                style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          if (!isEnd && v.steps.length > 1)
            GestureDetector(
              onTap: () => _edit(() => v.steps.removeAt(i)),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Text('✕', style: TextStyle(color: Color(0xFFFF7A86), fontSize: 15)),
              ),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Text('ساعت', style: TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(width: 6),
          if (v.nextDay(i)) const Text('(روز بعد)', style: TextStyle(color: _amber, fontSize: 11)),
          const Spacer(),
          _stepper(_hm(t), () => setT((t + 1440 - 15) % 1440), () => setT((t + 15) % 1440), width: 70, size: 20),
        ]),
        const SizedBox(height: 6),
        Text(hint, style: const TextStyle(color: _muted, fontSize: 11)),
        if (!isEnd) ...[
          const SizedBox(height: 8),
          _keys(s!),
        ],
        const SizedBox(height: 8),
        _curtainSeg(isEnd ? v.ce : s!.c, (x) => _edit(() {
              if (isEnd) {
                v.ce = x;
              } else {
                v.steps[i].c = x;
              }
            })),
      ]),
    );
  }

  Widget _keys(Panel12VacStep s) {
    Widget key(int k) {
      final on = s.k[k];
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(
          onTap: () => _edit(() => s.k[k] = !s.k[k]),
          child: Container(
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: on ? _red.withValues(alpha: .18) : const Color(0x0AFFFFFF),
              border: Border.all(color: on ? _red.withValues(alpha: .7) : const Color(0x1FFFFFFF)),
            ),
            child: Text(c.labelOf(k),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: on ? _red : _text, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }

    // مثل شیشه‌ی پنل: ستون چپ فردها، ستون راست زوج‌ها
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(children: [for (final k in [0, 2, 4, 6, 8]) key(k)])),
        const SizedBox(width: 8),
        Expanded(child: Column(children: [for (final k in [1, 3, 5, 7, 9]) key(k)])),
      ]),
    );
  }

  Widget _curtainSeg(String value, void Function(String) pick) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0x0DFFFFFF)),
        child: Row(children: [
          for (final o in const [
            ['O', 'پرده باز'],
            ['C', 'پرده بسته'],
            ['-', 'بدون تغییر']
          ])
            Expanded(
              child: GestureDetector(
                onTap: () => pick(o[0]),
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: value == o[0] ? (o[0] == '-' ? const Color(0x2EFFFFFF) : _red) : null,
                  ),
                  child: Text(o[1],
                      style: TextStyle(color: value == o[0] ? Colors.white : _muted, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ]),
      );

  Widget _addStep() => GestureDetector(
        onTap: () => _edit(() => v.steps.add(Panel12VacStep(t: (v.steps.last.t + 60) % 1440))),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x4DFFFFFF), width: 1.5),
          ),
          child: const Text('＋ افزودن مرحله', style: TextStyle(color: _text, fontSize: 14.5, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _bottomButtons() {
    final needSave = dirty || c.vacation.value == null;
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: _text,
            side: const BorderSide(color: Color(0x40FFFFFF)),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            if (active >= 0) {
              c.stopPreview();
              setState(() => active = -1);
              return;
            }
            c.previewVacation(v.copy(), (a) {
              if (mounted) setState(() => active = a);
            });
          },
          child: Text(active >= 0 ? '■ توقف پیش‌نمایش' : '▶ پیش‌نمایش', style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Obx(() {
          final saving = c.vacSaving.value;
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: needSave ? _red : const Color(0x2EFFFFFF),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: saving
                ? null
                : () {
                    c.stopPreview();
                    if (active >= 0) setState(() => active = -1);
                    final err = c.saveVacation(v);
                    if (err != null) c.notify(err, 'err');
                  },
            child: Text(saving ? 'در حال ذخیره…' : (needSave ? 'ذخیره روی پنل' : 'ذخیره شده ✓'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          );
        }),
      ),
    ]);
  }
}
