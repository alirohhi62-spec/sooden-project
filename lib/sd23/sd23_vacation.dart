import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../panel12/panel12_vacation.dart' show Jalali;
import 'sd23_controller.dart';
import 'sd23_screen.dart';

const Color _bg = Color(0xFF0B0C10);
const Color _text = Color(0xFFF2F4F7);
const Color _muted = Color(0xB8F2F4F7);
const Color _red = Color(0xFFFF3B4E);
const Color _amber = Color(0xFFFFB547);
const Color _green = Color(0xFF7EE2AE);

/// برنامه‌ی مسافرت پنل‌های ۲۳ کلید: مثل پنل RF-12، با چراغ‌های همین پنل (پل معمولی و خاموشی تأخیری)
/// و همه‌ی پرده‌ها با هم. برنامه روی خود پنل ذخیره و با ساعت پنل اجرا می‌شود؛ ساعت پنل هر ۲ ساعت از اینترنت.
class Sd23VacationPage extends StatefulWidget {
  const Sd23VacationPage({super.key});

  @override
  State<Sd23VacationPage> createState() => _Sd23VacationPageState();
}

class _Sd23VacationPageState extends State<Sd23VacationPage> {
  Sd23Controller get c => Sd23Controller.instance;

  late Sd23Vacation v;
  bool dirty = false;
  Worker? _w, _wOk;

  static String _fa(int n) => Sd23Controller.faNum(n);

  static String _fa2(int n) => Sd23Controller.faNum(n).padLeft(2, '۰');

  static String _hm(int t) => '${_fa2((t ~/ 60) % 24)}:${_fa2(t % 60)}';

  @override
  void initState() {
    super.initState();
    v = (c.vacation.value ?? Sd23Vacation.defaults()).copy();
    _w = ever<Sd23Vacation?>(c.vacation, (p) {
      // برنامه از پنل رسید: اگر کاربر چیزی را تغییر نداده، همان را نشان بده
      if (!dirty && mounted) setState(() => v = (p ?? Sd23Vacation.defaults()).copy());
    });
    _wOk = ever<int>(c.vacSaveOk, (_) {
      if (!mounted) return;
      setState(() {
        dirty = false;
        v = (c.vacation.value ?? Sd23Vacation.defaults()).copy();
      });
    });
    c.loadVacation();
  }

  @override
  void dispose() {
    _w?.dispose();
    _wOk?.dispose();
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
            const Sd23Screen().miniPanel(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Obx(() {
                  c.lay.value; // چیدمان پنل (چراغ‌ها و پرده‌ها)
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _clockCard(),
                    _dates(),
                    const SizedBox(height: 10),
                    for (int i = 0; i <= v.steps.length; i++) ...[
                      _stepCard(i),
                      const SizedBox(height: 8),
                    ],
                    if (v.steps.length < Sd23Controller.vacSteps) _addStep(),
                    const SizedBox(height: 10),
                    _saveButton(),
                    const SizedBox(height: 10),
                    const Text(
                      'برنامه روی خود پنل ذخیره و اجرا می‌شود و به گوشی نیازی ندارد. ساعت پنل هر ۲ ساعت از اینترنت '
                      '(از راه مودم) تنظیم می‌شود؛ اگر برق برود، با برگشتن برق و اینترنت ساعت دوباره تنظیم می‌شود و '
                      'پنل همان مرحله‌ای را که باید روشن باشد اجرا می‌کند.',
                      style: TextStyle(color: _muted, fontSize: 11, height: 1.6),
                    ),
                  ]);
                }),
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
              if (!c.clockOk.value && saved != null && saved.on) {
                t = 'ساعت پنل تنظیم نیست · برنامه تا تنظیم ساعت اجرا نمی‌شود';
                col = _amber;
              } else if (saved == null || !saved.on) {
                t = 'غیرفعال';
                col = _muted;
              } else {
                final last = c.vacLast.value;
                final run = last == 'E'
                    ? ' · آخرین اجرا: خاموشی'
                    : (int.tryParse(last) != null ? ' · آخرین اجرا: مرحله‌ی ${_fa(int.parse(last))}' : '');
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

  /// ساعت پنل: معلوم نیست (برق رفته و اینترنت نیست) یا از گوشی
  Widget _clockCard() {
    if (!c.clockKnown.value) return const SizedBox.shrink();
    String? t;
    if (!c.clockOk.value) {
      t = 'ساعت پنل معلوم نیست (برق رفته و هنوز به اینترنت وصل نشده). تا وقتی ساعت تنظیم نشود، برنامه‌ی مسافرت کاری نمی‌کند؛ '
          'با وصل شدن پنل به مودم و اینترنت، یا با اتصال همین گوشی، ساعت تنظیم می‌شود.';
    } else if (c.clockSrc.value == 'P') {
      t = 'ساعت پنل از گوشی تنظیم شده؛ پنل به اینترنت وصل نیست. برای اطمینان در نبودِ شما، پنل را به مودم وصل کنید.';
    }
    if (t == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _amber.withValues(alpha: .10),
          border: Border.all(color: _amber.withValues(alpha: .6)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.schedule_rounded, color: _amber, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(t, style: const TextStyle(color: _amber, fontSize: 11.5, height: 1.6))),
        ]),
      ),
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

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0x09FFFFFF),
          border: Border.all(color: const Color(0x1FFFFFFF)),
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
                textAlign: TextAlign.center, style: TextStyle(color: _text, fontSize: size, fontWeight: FontWeight.w700)),
          ),
          _sq('+', up),
        ]),
      );

  // ---------- تاریخ ----------

  Widget _dates() {
    final today = Sd23Controller.iranDay();
    final off = v.d0 - today;
    final rel = off == 0 ? ' (امشب)' : (off == 1 ? ' (فردا شب)' : '');
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
              Text(rep ? 'هر شب همین برنامه تا ${Jalali.dayText(v.d1)} تکرار می‌شود' : 'فقط یک شب اجرا می‌شود',
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
          Text('ساعت مرحله‌ی ۱ امشب گذشته؛ بعد از ذخیره، پنل همان مرحله‌ای را که الان باید روشن باشد اجرا می‌کند',
              style: TextStyle(color: _amber.withValues(alpha: .9), fontSize: 11)),
        ],
      ]),
    );
  }

  bool _firstStepPassed(int today) {
    if (v.d0 != today || v.steps.isEmpty || !v.on) return false;
    return v.steps.first.t <= Sd23Controller.iranMinute();
  }

  // ---------- مرحله‌ها ----------

  Widget _stepCard(int i) {
    final isEnd = i == v.steps.length;
    final s = isEnd ? null : v.steps[i];
    final t = isEnd ? v.te : s!.t;
    final cnt = s == null ? 0 : s.count;
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isEnd ? const Color(0xFF3A3B42) : const Color(0x2EFFFFFF)),
            child: Text(isEnd ? '■' : _fa(i + 1), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(isEnd ? 'پایان: خاموشی همه‌ی چراغ‌ها' : 'مرحله‌ی ${_fa(i + 1)}',
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
          _lights(s!),
        ],
        if (c.hasCurtain) ...[
          const SizedBox(height: 8),
          _curtainSeg(isEnd ? v.ce : s!.c, (x) => _edit(() {
                if (isEnd) {
                  v.ce = x;
                } else {
                  v.steps[i].c = x;
                }
              })),
        ],
      ]),
    );
  }

  /// چراغ‌های همین پنل، دو ستون مثل شیشه‌ی پنل (فرد چپ، زوج راست)
  Widget _lights(Sd23VacStep s) {
    final keys = c.vacLights;
    if (keys.isEmpty) {
      return const Text('این پنل چراغی برای برنامه‌ی مسافرت ندارد', style: TextStyle(color: _muted, fontSize: 11.5));
    }
    Widget key(int k) {
      final on = s.has(k);
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(
          onTap: () => _edit(() => s.lights ^= 1 << k),
          child: Container(
            height: 34,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
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

    final left = [for (int i = 0; i < keys.length; i += 2) keys[i]];
    final right = [for (int i = 1; i < keys.length; i += 2) keys[i]];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(children: [for (final k in left) key(k)])),
        const SizedBox(width: 8),
        Expanded(child: Column(children: [for (final k in right) key(k)])),
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
        onTap: () => _edit(() => v.steps.add(Sd23VacStep(t: (v.steps.last.t + 60) % 1440))),
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

  Widget _saveButton() {
    return Obx(() {
      final needSave = dirty || c.vacation.value == null;
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
                final err = c.saveVacation(v);
                if (err != null) c.notifyError(err);
              },
        child: Text(saving ? 'در حال ذخیره…' : (needSave ? 'ذخیره روی پنل' : 'ذخیره شده ✓'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      );
    });
  }
}
