import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../sd23/sd23_editor.dart';
import '../sd23/sd23_screen.dart' show Sd23OwnOnly;
import 'panel12_controller.dart';
import 'panel12_screen.dart';

const Color _bg = Color(0xFF0B0C10);
const Color _text = Color(0xFFF2F4F7);
const Color _muted = Color(0xB8F2F4F7);
const Color _red = Color(0xFFFF3B4E);
const Color _amber = Color(0xFFFFB547);
const Color _white = Color(0xEBF6F7F9);

/// ترتیب کلیدها روی شیشه: ستون چپ ۱، ۳، ۵، ۷، ۹، ۱۱ و ستون راست ۲، ۴، ۶، ۸، ۱۰، ۱۲
const List<int> _leftKeys = [0, 2, 4, 6, 8, 10];
const List<int> _rightKeys = [1, 3, 5, 7, 9, 11];

/// تب سناریو: برای پنل RF-12 صفحه‌ی جدید، وگرنه صفحه‌ی قبلی
class Panel12ScenarioTabHost extends StatelessWidget {
  final Widget home;

  const Panel12ScenarioTabHost({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = Panel12Controller.instance;
      final known = c.modelKnown.value;
      final sd = c.isSd23.value || (!known && c.lastSd23.value);
      final showNew = !sd && (c.isRf12.value || (!known && c.lastRf12.value));
      final showOld = known && !c.isRf12.value && !c.isSd23.value;
      return Stack(fit: StackFit.expand, children: [
        Offstage(offstage: !showOld, child: home),
        if (sd) const Sd23OwnOnly(what: 'سناریوهای گوشی', child: Sd23PhonePage()),
        if (sd) const Panel12Overlay(),
        if (showNew) const Panel12Scenarios(),
        if (showNew) const Panel12Overlay(),
        if (!showNew && !showOld && !sd) const ColoredBox(color: _bg),
      ]);
    });
  }
}

class Panel12Scenarios extends StatelessWidget {
  const Panel12Scenarios({super.key});

  Panel12Controller get c => Panel12Controller.instance;

  static String _fa(int n) => Panel12Controller.faNum(n);

  static String _dur(int mins) {
    final h = mins ~/ 60, m = mins % 60;
    final parts = <String>[];
    if (h > 0) parts.add('${_fa(h)} ساعت');
    if (m > 0) parts.add('${_fa(m)} دقیقه');
    return parts.isEmpty ? '${_fa(0)} دقیقه' : parts.join(' و ');
  }

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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('سناریوها', style: TextStyle(color: _text, fontSize: 19, fontWeight: FontWeight.w700)),
              ),
            ),
            const Panel12Screen().miniPanel(zones: false),
            Expanded(child: Obx(() => _list(context))),
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

  Widget _list(BuildContext context) {
    final items = <Widget>[];
    for (int i = 0; i < Panel12Controller.scenarioCount; i++) {
      final sc = c.scenarios[i];
      if (sc != null) items.add(_row(context, i, sc));
    }
    if (c.freeScenarioSlot >= 0) {
      items.add(GestureDetector(
        onTap: () {
          final idx = c.freeScenarioSlot;
          _editSheet(context, idx, Panel12Scenario(st: '0000000000', name: c.defaultScenarioName()), isNew: true);
        },
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x4DFFFFFF), width: 1.5),
          ),
          child: const Text('＋ افزودن سناریو', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => items[i],
    );
  }

  Widget _row(BuildContext context, int i, Panel12Scenario sc) {
    final left = c.pending[i];
    final timerText = left != null
        ? (sc.tm == 'F' ? '⏳ خاموشی تا ${_dur(left)} دیگر' : '⏳ اجرا تا ${_dur(left)} دیگر')
        : (sc.tm == 'F'
            ? '⏱ خاموشی خودکار بعد از ${_dur(sc.mins)}'
            : (sc.tm == 'D' ? '⏱ اجرا بعد از ${_dur(sc.mins)}' : ''));
    final curtain = sc.c == 'O' ? ' · پرده باز' : (sc.c == 'C' ? ' · پرده بسته' : '');
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        c.runScenario(i);
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0x09FFFFFF),
          // ردیف فقط وقتی روشن می‌شود که پنل اجرای سناریو را تأیید کند
          border: Border.all(
              color: c.scenarioRan.contains(i)
                  ? _red
                  : (left != null ? _amber.withValues(alpha: .55) : const Color(0x14FFFFFF))),
        ),
        child: Row(children: [
          _dots(sc),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(sc.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text('${_fa(sc.onCount)} روشن · بقیه خاموش$curtain',
                  style: const TextStyle(color: _muted, fontSize: 11)),
              if (timerText.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(children: [
                  Flexible(
                    child: Text(timerText,
                        style: TextStyle(
                            color: left != null ? _amber : _muted, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                  if (left != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => c.cancelScenario(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8), border: Border.all(color: _amber.withValues(alpha: .5))),
                        child: const Text('لغو', style: TextStyle(color: _amber, fontSize: 11)),
                      ),
                    ),
                  ],
                ]),
              ],
            ]),
          ),
          GestureDetector(
            onTap: () => _editSheet(context, i, sc.copy()),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x26FFFFFF))),
              child: const Icon(Icons.edit, color: _text, size: 18),
            ),
          ),
        ]),
      ),
    );
  }

  /// پیش‌نمایش نقطه‌ای: دو ستون مثل شیشه‌ی پنل
  Widget _dots(Panel12Scenario sc) {
    Color colorOf(int k) {
      if (k < 10) {
        final v = sc.st[k];
        return v == '1' ? _red : _white;
      }
      final on = (k == 10 && sc.c == 'O') || (k == 11 && sc.c == 'C');
      return on ? _red : const Color(0x24FFFFFF);
    }

    Widget col(List<int> keys) => Column(mainAxisSize: MainAxisSize.min, children: [
          for (final k in keys)
            Container(
              width: 10,
              height: 8,
              margin: const EdgeInsets.symmetric(vertical: 1.5),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: colorOf(k)),
            ),
        ]);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0x33FFFFFF))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [col(_leftKeys), const SizedBox(width: 3), col(_rightKeys)]),
      ),
    );
  }

  // ---------- تعریف و ویرایش ----------

  void _editSheet(BuildContext context, int idx, Panel12Scenario sc, {bool isNew = false}) {
    final nameCtrl = TextEditingController(text: sc.name);
    Get.bottomSheet(
      StatefulBuilder(builder: (context, setState) {
        Widget seg(List<List<String>> opts, String value, void Function(String) pick) => Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0x0DFFFFFF)),
              child: Row(children: [
                for (final o in opts)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => pick(o[0])),
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: value == o[0] ? (o[0] == '-' || o[0] == 'N' ? const Color(0x2EFFFFFF) : _red) : null,
                        ),
                        child: Text(o[1],
                            style: TextStyle(
                                color: value == o[0] ? Colors.white : _muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
              ]),
            );

        // هر کلید دو حالت دارد: روشن یا خاموش (کلیدی که انتخاب نشود موقع اجرا خاموش می‌شود)
        Widget key(int k) {
          final on = sc.st[k] == '1';
          return GestureDetector(
            onTap: () => setState(() {
              sc.st = sc.st.substring(0, k) + (on ? '0' : '1') + sc.st.substring(k + 1);
            }),
            child: Opacity(
              opacity: 1,
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: on ? _red.withValues(alpha: .18) : const Color(0x0AFFFFFF),
                  border: Border.all(color: on ? _red.withValues(alpha: .7) : const Color(0x1FFFFFFF)),
                ),
                child: Text(c.labelOf(k),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: on ? _red : _text, fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ),
          );
        }

        Widget stepper(String label, String value, VoidCallback down, VoidCallback up) => Column(children: [
              Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _sq('−', () => setState(down)),
                  SizedBox(
                      width: 52,
                      child: Text(value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _text, fontSize: 24, fontWeight: FontWeight.w700))),
                  _sq('+', () => setState(up)),
                ]),
              ),
            ]);

        final h = sc.mins ~/ 60, m = sc.mins % 60;
        return Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(color: Color(0xFF14151A), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: nameCtrl,
                    maxLength: 24,
                    style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(counterText: '', hintText: 'نام سناریو'),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
                  onPressed: () {
                    sc.name = nameCtrl.text;
                    c.saveScenario(idx, sc);
                    Get.back();
                  },
                  child: const Text('ذخیره'),
                ),
              ]),
              const SizedBox(height: 10),
              const Text('کلیدهای روشن را انتخاب کنید (بقیه موقع اجرا خاموش می‌شوند)', style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 8),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xB3FFFFFF), width: 1.5)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(children: [for (final k in [0, 2, 4, 6, 8]) Padding(padding: const EdgeInsets.only(bottom: 6), child: key(k))])),
                    const SizedBox(width: 10),
                    Expanded(child: Column(children: [for (final k in [1, 3, 5, 7, 9]) Padding(padding: const EdgeInsets.only(bottom: 6), child: key(k))])),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              const Text('پرده (فقط یکی)', style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 6),
              seg(const [['O', 'باز'], ['C', 'بسته'], ['-', 'بدون تغییر']], sc.c, (v) => sc.c = v),
              const SizedBox(height: 12),
              const Text('⏱ تایمر', style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              seg(const [['N', 'بدون تایمر'], ['F', 'خاموشی خودکار'], ['D', 'اجرا با تأخیر']], sc.tm, (v) {
                sc.tm = v;
                if (v != 'N' && sc.mins == 0) sc.mins = 60;
              }),
              if (sc.tm != 'N') ...[
                const SizedBox(height: 6),
                Text(
                    sc.tm == 'F'
                        ? 'با لمس اجرا می‌شود و بعد از این مدت، چراغ‌هایی که روشن کرده خاموش می‌شوند'
                        : 'بعد از لمس، با این فاصله اجرا می‌شود',
                    style: const TextStyle(color: _muted, fontSize: 11)),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  stepper('ساعت', _fa(h), () => sc.mins = (h > 0 ? h - 1 : 0) * 60 + m,
                      () => sc.mins = (h < 99 ? h + 1 : 99) * 60 + m),
                  const SizedBox(width: 24),
                  stepper('دقیقه', _fa(m), () => sc.mins = h * 60 + (m + 55) % 60, () => sc.mins = h * 60 + (m + 5) % 60),
                ]),
              ],
              if (!isNew) ...[
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    c.deleteScenario(idx);
                    Get.back();
                  },
                  child: const Text('حذف این سناریو', style: TextStyle(color: Color(0xFFFF7A86))),
                ),
              ],
            ]),
          ),
        );
      }),
      isScrollControlled: true,
    );
  }

  Widget _sq(String t, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x26FFFFFF))),
          child: Text(t, style: const TextStyle(color: _text, fontSize: 18)),
        ),
      );
}
