import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'sd23_controller.dart';

const Color _bg = Color(0xFF0B0C10);
const Color _text = Color(0xFFF2F4F7);
const Color _muted = Color(0xB8F2F4F7);
const Color _red = Color(0xFFFF3B4E);
const Color _amber = Color(0xFFFFB547);
const Color _cool = Color(0xFF7FD3FF);
const Color _curtColor = Color(0xFFC9A7FF);

/// ویرایش پل‌های یک سناریو:
///   mode 'custom' سناریوی سفارشی روی کلید پنل (هر پل روشن / خاموش / بدون تغییر)
///   mode 'group'  گروه روی کلید پنل (پل‌های انتخابی)
///   mode 'phone'  سناریوی گوشی (مثل سفارشی، به‌علاوه‌ی تایمر)
///   mode 'master' پل‌هایی که مستر روشن / خاموش می‌کند (نصاب)
class Sd23MaskEditor extends StatefulWidget {
  final String mode;

  /// شماره‌ی کلید پنل (custom / group) یا جای سناریوی گوشی (phone)
  final int index;

  const Sd23MaskEditor({super.key, required this.mode, required this.index});

  @override
  State<Sd23MaskEditor> createState() => _Sd23MaskEditorState();
}

class _Sd23MaskEditorState extends State<Sd23MaskEditor> {
  Sd23Controller get c => Sd23Controller.instance;

  late final TextEditingController _name;
  late final TextEditingController _mins;
  late final List<int> _poles; // پل‌های تکی (L D K)
  late final List<List<int>> _curtains; // (باز، بسته)
  late final List<List<int>> _coolers; // (کند، تند)
  final Map<int, int> _pole = {}; // ۰ روشن، ۱ خاموش، ۲ بدون تغییر
  final List<int> _curt = []; // ۰ باز، ۱ بسته، ۲ بدون تغییر
  final List<int> _coolc = []; // ۰ کند، ۱ تند، ۲ خاموش، ۳ بدون تغییر
  final Set<int> _sel = {}; // گروه
  String _tm = 'N';
  String _origName = '';

  bool get _master => widget.mode == 'master';
  bool get _group => widget.mode == 'group' || _master;
  bool get _phone => widget.mode == 'phone';

  @override
  void initState() {
    super.initState();
    _poles = [for (final k in c.scnPoles) if ('LDK'.contains(c.kindOf(k))) k];
    _curtains = c.curtainPairs.where((p) => p[0] < 20 && p[1] < 20).toList();
    _coolers = c.coolerPairs.where((p) => p[0] < 20 && p[1] < 20).toList();
    int on = 0, off = 0;
    String st = '2' * 20;
    if (_phone) {
      final p = widget.index < c.phone.length ? c.phone[widget.index] : null;
      _origName = p?.name ?? '';
      _tm = p?.tm ?? 'N';
      _mins = TextEditingController(text: p != null && p.mins > 0 ? '${p.mins}' : '30');
      if (p != null) st = p.st;
      for (int k = 0; k < 20; k++) {
        if (st[k] == '1') on |= 1 << k;
        if (st[k] == '0') off |= 1 << k;
      }
    } else {
      _mins = TextEditingController(text: '30');
      _origName = c.labels[widget.index];
      final cf = c.cf[widget.index];
      on = cf?.on ?? 0;
      off = cf?.off ?? 0;
    }
    _name = TextEditingController(text: _origName);
    bool b(int m, int k) => ((m >> k) & 1) == 1;
    for (final k in _poles) {
      _pole[k] = b(on, k) ? 0 : (b(off, k) ? 1 : 2);
      if (b(on, k)) _sel.add(k);
    }
    for (final p in _curtains) {
      _curt.add(b(on, p[0]) ? 0 : (b(on, p[1]) ? 1 : 2));
    }
    for (final p in _coolers) {
      _coolc.add(b(on, p[0]) ? 0 : (b(on, p[1]) ? 1 : (b(off, p[0]) && b(off, p[1]) ? 2 : 3)));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _mins.dispose();
    super.dispose();
  }

  /// وضعیت همین الان پنل
  void _fromPanel() {
    setState(() {
      for (final k in _poles) {
        _pole[k] = c.isOn(k) ? 0 : 1;
        if (c.isOn(k)) {
          _sel.add(k);
        } else {
          _sel.remove(k);
        }
      }
      for (int i = 0; i < _curtains.length; i++) {
        _curt[i] = 2;
      }
      for (int i = 0; i < _coolers.length; i++) {
        final p = _coolers[i];
        _coolc[i] = c.isOn(p[0]) ? 0 : (c.isOn(p[1]) ? 1 : 2);
      }
    });
  }

  /// پل‌های روشن و خاموش
  List<int> _masks() {
    int on = 0, off = 0;
    if (_group) {
      for (final k in _sel) {
        on |= 1 << k;
      }
      return [on, 0];
    }
    _pole.forEach((k, v) {
      if (v == 0) on |= 1 << k;
      if (v == 1) off |= 1 << k;
    });
    for (int i = 0; i < _curtains.length; i++) {
      if (_curt[i] == 0) on |= 1 << _curtains[i][0];
      if (_curt[i] == 1) on |= 1 << _curtains[i][1];
    }
    for (int i = 0; i < _coolers.length; i++) {
      final f = _coolers[i][0], g = _coolers[i][1];
      if (_coolc[i] == 0) {
        on |= 1 << f;
        off |= 1 << g;
      } else if (_coolc[i] == 1) {
        on |= 1 << g;
        off |= 1 << f;
      } else if (_coolc[i] == 2) {
        off |= (1 << f) | (1 << g);
      }
    }
    return [on, off];
  }

  void _save() {
    final m = _masks();
    if (_phone) {
      final st = List<String>.filled(20, '2');
      for (int k = 0; k < 20; k++) {
        if (((m[0] >> k) & 1) == 1) st[k] = '1';
        if (((m[1] >> k) & 1) == 1) st[k] = '0';
      }
      // پرده: فقط یک طرف '1'؛ طرف دیگر بدون تغییر
      final mins = int.tryParse(_mins.text.trim()) ?? 0;
      if (_tm != 'N' && (mins < 1 || mins > 9999)) {
        Get.snackbar('زمان درست نیست', 'بین ۱ تا ۹۹۹۹ دقیقه', colorText: _text, backgroundColor: const Color(0xCC1E1F25));
        return;
      }
      c.savePhone(widget.index, Sd23PhoneScn(st: st.join(), tm: _tm, mins: _tm == 'N' ? 0 : mins, name: _name.text));
      Get.back();
      return;
    }
    final k = widget.index;
    final name = _name.text.trim();
    if (name != _origName.trim()) {
      c.saveKey(index: k, iconId: c.iconIds[k], label: name);
      Future.delayed(const Duration(milliseconds: 900), () => c.saveMasks(k, m[0], m[1]));
    } else {
      c.saveMasks(k, m[0], m[1]);
    }
    Get.back();
  }

  Widget _seg(List<String> labels, int value, void Function(int) onPick, {List<Color>? colors}) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: const Color(0x0DFFFFFF)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (int i = 0; i < labels.length; i++)
          GestureDetector(
            onTap: () => setState(() => onPick(i)),
            child: Container(
              height: 34,
              constraints: const BoxConstraints(minWidth: 46),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: i == value ? (colors != null ? colors[i] : const Color(0x29F2F4F7)).withValues(alpha: .22) : Colors.transparent,
              ),
              child: Text(labels[i],
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: i == value ? (colors != null ? colors[i] : _text) : const Color(0x80F2F4F7))),
            ),
          ),
      ]),
    );
  }

  Widget _row(String name, Color color, Widget right) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: const Color(0x08FFFFFF)),
      child: Row(children: [
        Expanded(
          child: Text(name,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w600)),
        ),
        right,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _phone
        ? (_origName.isEmpty ? 'سناریوی جدید گوشی' : 'سناریوی «$_origName»')
        : _master
            ? 'پل‌های مستر «${c.labelOf(widget.index)}»'
            : (_group ? 'گروه «${c.labelOf(widget.index)}»' : 'سناریوی «${c.labelOf(widget.index)}»');
    final rows = <Widget>[];
    if (_group) {
      for (final k in _poles) {
        final on = _sel.contains(k);
        rows.add(GestureDetector(
          onTap: () => setState(() => on ? _sel.remove(k) : _sel.add(k)),
          child: _row(
              c.labelOf(k),
              on ? _amber : _text,
              Icon(on ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  color: on ? _amber : const Color(0x66F2F4F7))),
        ));
      }
    } else {
      for (int i = 0; i < _curtains.length; i++) {
        rows.add(_row(c.labels[_curtains[i][0]].isNotEmpty ? c.labels[_curtains[i][0]] : 'پرده', _curtColor,
            _seg(['باز', 'بسته', '—'], _curt[i], (v) => _curt[i] = v)));
      }
      for (int i = 0; i < _coolers.length; i++) {
        rows.add(_row('کولر', _cool, _seg(['کند', 'تند', 'خاموش', '—'], _coolc[i], (v) => _coolc[i] = v)));
      }
      for (final k in _poles) {
        rows.add(_row(c.labelOf(k), _pole[k] == 0 ? _red : (_pole[k] == 2 ? const Color(0x8CF2F4F7) : _text),
            _seg(['روشن', 'خاموش', '—'], _pole[k] ?? 2, (v) => _pole[k] = v, colors: const [_red, _text, _muted])));
      }
    }
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_forward_rounded, color: _text),
                  tooltip: 'بازگشت',
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w800)),
                    if (!_phone) Text('${c.placeName(widget.index)} پنل', style: const TextStyle(color: _muted, fontSize: 11)),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _name,
                maxLength: _phone ? 9 : 20,
                style: const TextStyle(color: _text),
                decoration: InputDecoration(
                  labelText: _phone ? 'اسم سناریو' : (_master ? 'اسم کلید مستر' : (_group ? 'اسم گروه' : 'اسم سناریو')),
                  counterStyle: const TextStyle(color: _muted),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Text(
                  _master
                      ? 'پل‌هایی را که مستر روشن و خاموش کند تیک بزنید. با لمس مستر: اگر همه روشن‌اند همه خاموش، وگرنه همه روشن.'
                      : _group
                      ? 'پل‌های این گروه را انتخاب کنید. با لمس کلید روی پنل: همه با هم روشن، یا اگر یکی روشن است همه خاموش.'
                      : 'برای هر پل: روشن، خاموش یا «—» (بدون تغییر).',
                  style: const TextStyle(color: _muted, fontSize: 11.5, height: 1.6)),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x24FFFFFF)),
                  color: const Color(0x09FFFFFF),
                ),
                child: rows.isEmpty
                    ? const Center(child: Text('پلی برای انتخاب نیست', style: TextStyle(color: _muted)))
                    : ListView(padding: EdgeInsets.zero, children: rows),
              ),
            ),
            if (_phone)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(children: [
                  _seg(['بدون تایمر', 'خاموشی بعد از', 'اجرا بعد از'], 'NFD'.indexOf(_tm), (v) => _tm = 'NFD'[v],
                      colors: const [_text, _amber, _amber]),
                  const SizedBox(width: 8),
                  if (_tm != 'N')
                    Expanded(
                      child: TextField(
                        controller: _mins,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _text),
                        decoration: const InputDecoration(suffixText: 'دقیقه', isDense: true),
                      ),
                    ),
                ]),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (!_group)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: _amber,
                        side: BorderSide(color: _amber.withValues(alpha: .6)),
                        minimumSize: const Size.fromHeight(46)),
                    onPressed: _fromPanel,
                    child: const Text('برداشتن از وضعیت فعلی پنل'),
                  ),
                if (_group)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: _amber,
                        side: BorderSide(color: _amber.withValues(alpha: .6)),
                        minimumSize: const Size.fromHeight(46)),
                    onPressed: _fromPanel,
                    child: const Text('پل‌هایی که الان روشن‌اند'),
                  ),
                const SizedBox(height: 8),
                Row(children: [
                  if (_phone && widget.index < c.phone.length && c.phone[widget.index] != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: _red, side: const BorderSide(color: _red), minimumSize: const Size.fromHeight(50)),
                        onPressed: () {
                          c.deletePhone(widget.index);
                          Get.back();
                        },
                        child: const Text('حذف'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _red, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
                      onPressed: _save,
                      child: const Text('ذخیره روی پنل', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// تب سناریو برای پنل ۲۳ کلید: سناریوهای گوشی (روی خود پنل ذخیره و اجرا می‌شوند، تایمرشان را هم پنل می‌شمارد)
class Sd23PhonePage extends StatelessWidget {
  const Sd23PhonePage({super.key});

  Sd23Controller get c => Sd23Controller.instance;

  String _timerText(Sd23PhoneScn s) {
    if (s.tm == 'F') return 'خاموشی بعد از ${Sd23Controller.faNum(s.mins)} دقیقه';
    if (s.tm == 'D') return 'اجرا بعد از ${Sd23Controller.faNum(s.mins)} دقیقه';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: Obx(() {
          final list = c.phone.toList();
          final ran = c.phoneRan.toSet();
          final pend = Map<int, String>.from(c.pending);
          final free = c.freePhoneSlot;
          final cards = <Widget>[];
          for (int i = 0; i < list.length; i++) {
            final s = list[i];
            if (s == null) continue;
            final p = pend[i];
            final sub = [
              '${Sd23Controller.faNum(s.onCount)} روشن · ${Sd23Controller.faNum(s.offCount)} خاموش',
              if (_timerText(s).isNotEmpty) _timerText(s),
            ].join(' · ');
            cards.add(Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minHeight: 66),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: ran.contains(i) ? _amber.withValues(alpha: .16) : const Color(0x0AFFFFFF),
                  border: Border.all(color: ran.contains(i) || p != null ? _amber.withValues(alpha: .7) : const Color(0x1AFFFFFF)),
                ),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => c.runPhone(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.name, style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(sub, style: const TextStyle(color: _muted, fontSize: 11)),
                          if (p != null && p.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                  '${p[0] == 'D' ? 'اجرا' : 'خاموشی'} تا ${Sd23Controller.faNum(int.tryParse(p.substring(1)) ?? 0)} دقیقه‌ی دیگر',
                                  style: const TextStyle(color: _amber, fontSize: 11.5, fontWeight: FontWeight.w600)),
                            ),
                        ]),
                      ),
                    ),
                  ),
                  if (p != null)
                    TextButton(onPressed: () => c.cancelPhone(i), child: const Text('لغو', style: TextStyle(color: _amber))),
                  IconButton(
                    onPressed: () => Get.to(() => Sd23MaskEditor(mode: 'phone', index: i)),
                    icon: const Icon(Icons.edit_rounded, color: _muted, size: 20),
                    tooltip: 'ویرایش',
                  ),
                ]),
              ),
            ));
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text('سناریوهای گوشی', style: TextStyle(color: _text, fontSize: 19, fontWeight: FontWeight.w700)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('روی خود پنل ذخیره می‌شوند؛ تایمرشان را هم پنل می‌شمارد. لمس = اجرا.',
                  style: TextStyle(color: _muted, fontSize: 11.5)),
            ),
            Expanded(
              child: !c.hasSettings.value
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(c.hasCf.value ? 'این پنل سناریوی گوشی ندارد.' : 'این پنل هنوز سناریوی گوشی ندارد (فریمور پنل باید به‌روز شود).',
                            textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 13)),
                      ),
                    )
                  : ListView(padding: const EdgeInsets.symmetric(horizontal: 14), children: [
                      ...cards,
                      if (cards.isEmpty && c.phoneLoaded.value)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('هنوز سناریویی نساخته‌اید.', textAlign: TextAlign.center, style: TextStyle(color: _muted)),
                        ),
                      if (!c.phoneLoaded.value)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('در حال خواندن از پنل…', textAlign: TextAlign.center, style: TextStyle(color: _muted)),
                        ),
                      if (free >= 0 && c.phoneLoaded.value)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 90),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                                foregroundColor: _amber,
                                side: BorderSide(color: _amber.withValues(alpha: .6)),
                                minimumSize: const Size.fromHeight(52)),
                            onPressed: () => Get.to(() => Sd23MaskEditor(mode: 'phone', index: free)),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('سناریوی جدید'),
                          ),
                        ),
                    ]),
            ),
          ]);
        }),
      ),
    );
  }
}
