import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'sim12_controller.dart';

// ---------- رنگ‌ها (هم‌خانواده‌ی شیشه‌ی پنل) ----------
const Color _bg = Color(0xFF1D1E22);
const Color _card = Color(0xFF2A2B30);
const Color _key = Color(0xFF33343A);
const Color _line = Color(0xFF44464E);
const Color _text = Color(0xFFF2F2F4);
const Color _muted = Color(0xFFB9BAC2);
const Color _red = Color(0xFFC8102E);
const Color _redLit = Color(0xFFFF3B4E);
const Color _redBg = Color(0xFF5A1A24);
const Color _green = Color(0xFF2F7D4F);
const Color _greenLit = Color(0xFF3CCF6E);
const Color _amber = Color(0xFFE0A800);
const Color _amberBg = Color(0xFF3A2F12);
const Color _amberText = Color(0xFFFFD98A);

/// جای هر کلید روی عکس پنل (عکس ۲۰۰۰ × ۱۴۸۱)
const List<List<double>> _xy = [
  [1693, 440], [1250, 440], [1693, 560], [1250, 560], [1693, 685], [1250, 685], //
  [1693, 795], [1250, 795], [1693, 912], [1250, 912], [1693, 1035], [1250, 1035], //
  [295, 1210], [440, 1210], [588, 1210], //
  [1745, 1210], [1600, 1210], [1452, 1210], [1313, 1210], [1160, 1210], [1022, 1210], //
  [815, 1215], [370, 315], [263, 520], [478, 520], [263, 693], [475, 693],
];

class Sim12Screen extends StatelessWidget {
  const Sim12Screen({super.key});

  Sim12Controller get c => Sim12Controller.instance;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: _bg,
        child: SafeArea(
          bottom: false,
          child: Obx(() {
            c.bits.value;
            c.link.value;
            return Column(children: [
              _header(),
              _panelPhoto(context),
              if (c.smsMode) _smsBanner(),
              _notice(),
              Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 0), child: _content(context))),
              _tabs(),
            ]);
          }),
        ),
      ),
    );
  }

  // ---------- بالای صفحه ----------

  Widget _header() {
    final sms = c.smsMode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(children: [
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('پنل سیمکارتی', style: TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w700)),
            Text('۱۲ پل · دزدگیر · سیمکارت', style: TextStyle(color: _muted, fontSize: 12)),
          ]),
        ),
        Material(
          color: sms ? _amberBg : const Color(0xFF163322),
          shape: StadiumBorder(side: BorderSide(color: sms ? _amber : _green)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: c.toggleLink,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: sms ? _amber : _greenLit)),
                const SizedBox(width: 6),
                Text(sms ? 'پیامک' : 'وای‌فای', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  /// عکس پنل: نمایشگر زنده‌ی همه‌ی کلیدها (لمس روی عکس هم کار می‌کند)
  Widget _panelPhoto(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 1000 / 740,
          child: LayoutBuilder(builder: (ctx, box) {
            final w = box.maxWidth, h = box.maxHeight;
            return Stack(children: [
              Positioned.fill(child: Image.asset('assets/images/sim12_panel.jpg', fit: BoxFit.cover)),
              for (int k = 0; k < Sim12Controller.keyCount; k++) _photoKey(k, _xy[k][0] / 2000 * w, _xy[k][1] / 1481 * h, w),
              Positioned(
                top: 8,
                right: 8,
                child: Row(children: [
                  _chip(_alarmText, _alarmColor),
                  const SizedBox(width: 6),
                  _chip('آنتن ${Sim12Controller.faNum(c.bars.value)}/۵', const Color(0x99000000)),
                ]),
              ),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _photoKey(int k, double x, double y, double w) {
    final on = c.isOn(k);
    final pole = k < 12;
    final s = w / 366;
    final bw = (pole ? 18 : 22) * s, bh = (pole ? 5 : 22) * s;
    final hit = 34.0 * s;
    return Positioned(
      left: x - hit / 2,
      top: y - hit / 2,
      width: hit,
      height: hit,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => c.press(k),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: bw,
            height: bh,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(pole ? 3 : 11 * s),
              color: pole ? (on ? _redLit : const Color(0xD9FFFFFF)) : (on ? const Color(0x55FF3B4E) : Colors.transparent),
              boxShadow: on ? [BoxShadow(color: _redLit.withValues(alpha: .9), blurRadius: 8 * s, spreadRadius: 1.5 * s)] : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String t, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 11)),
      );

  String get _alarmText {
    if (!c.alarmKnown.value) return 'دزدگیر: ؟';
    switch (c.alarm.value) {
      case 1:
        return 'دزدگیر: مهلت خروج';
      case 2:
        return c.armedZones.value == 7 || c.armedZones.value == 0 ? 'دزدگیر: فعال' : 'دزدگیر: نیمه‌فعال';
      case 3:
        return 'دزدگیر: مهلت ورود';
      case 4:
        return 'آژیر!';
    }
    return 'دزدگیر: غیرفعال';
  }

  Color get _alarmColor {
    switch (c.alarm.value) {
      case 0:
        return _green;
      case 1:
      case 3:
        return const Color(0xFF9A6A00);
    }
    return _red;
  }

  Widget _smsBanner() => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: _amberBg, borderRadius: BorderRadius.circular(10)),
        child: Text(
          c.smsWaiting.value
              ? 'پیامک فرستاده شد؛ منتظر جواب پنل…'
              : 'اینترنت در دسترس نیست — فرمان‌ها با پیامک به سیمکارت پنل می‌رود و جواب در همین صفحه نمایش داده می‌شود.${c.lastSmsAt.value.isNotEmpty ? ' آخرین جواب: ${c.lastSmsAt.value}' : ''}',
          style: const TextStyle(color: _amberText, fontSize: 12),
        ),
      );

  Widget _notice() {
    final t = c.message.value;
    if (t.isEmpty) return const SizedBox.shrink();
    final type = c.messageType.value;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: type == 'err' ? const Color(0xFF4A1C22) : type == 'ok' ? const Color(0xFF163322) : _card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(t, style: const TextStyle(color: _text, fontSize: 12.5)),
    );
  }

  // ---------- بخش‌ها ----------

  static const _tabList = [
    ['keys', 'کلیدها', Icons.lightbulb_outline],
    ['alarm', 'دزدگیر', Icons.shield_outlined],
    ['cur', 'پرده و آسانسور', Icons.curtains_outlined],
    ['scn', 'سناریو', Icons.auto_awesome_outlined],
    ['sim', 'سیمکارت', Icons.sim_card_outlined],
  ];

  Widget _tabs() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF26272C), border: Border(top: BorderSide(color: Color(0xFF3A3B42)))),
      child: Row(children: [
        for (final t in _tabList)
          Expanded(
            child: InkWell(
              onTap: () => c.tab.value = t[0] as String,
              child: SizedBox(
                height: 58,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                      width: 22,
                      height: 3,
                      decoration: BoxDecoration(
                          color: c.tab.value == t[0] ? _red : Colors.transparent, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 4),
                  Icon(t[2] as IconData, size: 20, color: c.tab.value == t[0] ? Colors.white : const Color(0xFF9A9BA3)),
                  const SizedBox(height: 2),
                  Text(t[1] as String,
                      maxLines: 1,
                      style: TextStyle(fontSize: 10.5, color: c.tab.value == t[0] ? Colors.white : const Color(0xFF9A9BA3))),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _content(BuildContext context) {
    switch (c.tab.value) {
      case 'alarm':
        return _alarmZone(context);
      case 'cur':
        return _curtainZone();
      case 'scn':
        return _scnZone();
      case 'sim':
        return _simZone(context);
    }
    return _keysZone(context);
  }

  // ---------- کلیدها: به ترتیب سه نمایشگر پنل، پل فرد راست و پل زوج چپ ----------

  Widget _keysZone(BuildContext context) {
    return ListView(padding: const EdgeInsets.only(bottom: 12), children: [
      Row(children: [
        Expanded(
            child: Text('${Sim12Controller.faNum(c.polesOn)} روشن', style: const TextStyle(color: _muted, fontSize: 12))),
        TextButton(
          onPressed: c.polesOn == 0 ? null : c.allOff,
          child: const Text('خاموش کردن همه (مستر)', style: TextStyle(fontSize: 12)),
        ),
      ]),
      for (int o = 0; o < 3; o++)
        _box(
          'نمایشگر ${Sim12Controller.faNum(o + 1)}',
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.9,
            children: [for (int j = 0; j < 4; j++) _poleKey(context, o * 4 + j)],
          ),
        ),
      _box(
        'کلیدهای پایین پنل',
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [
            for (int k = 12; k < 15; k++) ...[
              if (k > 12) const SizedBox(width: 8),
              Expanded(child: SizedBox(height: 52, child: Directionality(textDirection: TextDirection.rtl, child: _poleKey(context, k)))),
            ],
          ]),
        ),
      ),
    ]);
  }

  Widget _box(String title, Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 8),
          child,
        ]),
      );

  Widget _poleKey(BuildContext context, int k) {
    final on = c.isOn(k), wait = c.pendingKeys.contains(k);
    final none = c.kindOf(k) == '-';
    return Material(
      color: on ? _redBg : _key,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: on ? _red : _line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: none ? null : () => c.press(k),
        onLongPress: c.smsMode ? null : () => _rename(context, k),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.nameOf(k),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: none ? _muted : _text, fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text(k < 12 ? 'پل ${Sim12Controller.faNum(k + 1)} · ${c.kindText(k)}' : c.kindText(k),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10.5)),
              ]),
            ),
            wait
                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6, color: _muted))
                : Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? _redLit : const Color(0xFF55575F),
                      boxShadow: on ? [BoxShadow(color: _redLit.withValues(alpha: .7), blurRadius: 6)] : null,
                    ),
                  ),
          ]),
        ),
      ),
    );
  }

  void _rename(BuildContext context, int k) {
    final t = TextEditingController(text: c.labels[k]);
    Get.dialog(Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: _card,
        title: Text('اسم ${Sim12Controller.defaultName(k)}', style: const TextStyle(color: _text, fontSize: 15)),
        content: TextField(
          controller: t,
          maxLength: 10,
          autofocus: true,
          style: const TextStyle(color: _text),
          decoration: const InputDecoration(hintText: 'مثلاً لوستر سالن', hintStyle: TextStyle(color: _muted)),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('انصراف')),
          TextButton(
              onPressed: () {
                c.setLabel(k, t.text.trim());
                Get.back();
              },
              child: const Text('ذخیره')),
        ],
      ),
    ));
  }

  // ---------- دزدگیر ----------

  Widget _alarmZone(BuildContext context) {
    return ListView(padding: const EdgeInsets.only(bottom: 12), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _alarmColor, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Text('وضعیت دزدگیر', style: TextStyle(color: Color(0xFFE6E6EA), fontSize: 13)),
          const SizedBox(height: 4),
          Text(_alarmText.replaceFirst('دزدگیر: ', ''),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        ]),
      ),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3.0,
        children: [
          _bigBtn('فعال', _red, null, () => _withCode(context, (code) => c.arm(code))),
          _bigBtn('غیرفعال', _green, null, () => _withCode(context, (code) => c.disarm(code))),
          _bigBtn('فعال سریع (بدون تأخیر)', _card, _red, () => _withCode(context, (code) => c.arm(code, fast: true))),
          _bigBtn('نیمه‌فعال (انتخاب زون)', _card, _line, () => _pickZones(context)),
        ],
      ),
      const SizedBox(height: 8),
      if (c.alarm.value == 4)
        SizedBox(
          height: 48,
          child: _bigBtn('خاموش کردن آژیر', _amberBg, _amber, () => _withCode(context, (code) => c.disarm(code))),
        ),
      const SizedBox(height: 10),
      _box(
        'زون‌ها و سنسورها',
        Column(children: [
          for (int z = 0; z < 3; z++)
            _row('زون ${Sim12Controller.faNum(z + 1)}', _zoneState(z), _zoneColor(z), last: z == 2),
        ]),
      ),
      _box(
        'گزارش رویدادها',
        c.events.isEmpty
            ? const Text('رویدادی ثبت نشده', style: TextStyle(color: _muted, fontSize: 13))
            : Column(children: [
                for (final e in c.events.take(12))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      SizedBox(width: 92, child: Text(e.when, style: const TextStyle(color: _muted, fontSize: 12.5))),
                      Expanded(
                          child: Text(e.text,
                              style: TextStyle(color: e.isAlarm ? const Color(0xFFFF9B9B) : _text, fontSize: 13))),
                    ]),
                  ),
              ]),
      ),
    ]);
  }

  String _zoneState(int z) {
    final armed = c.alarm.value != 0 && ((c.armedZones.value >> z) & 1) == 1;
    final open = ((c.openZones.value >> z) & 1) == 1;
    if (open) return armed ? 'باز — فعال' : 'باز';
    return armed ? 'فعال' : 'عادی';
  }

  Color _zoneColor(int z) {
    final open = ((c.openZones.value >> z) & 1) == 1;
    if (open) return const Color(0xFFFF9B9B);
    return const Color(0xFF7FD39B);
  }

  Widget _row(String a, String b, Color bc, {bool last = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0xFF3A3B42)))),
        child: Row(children: [
          Expanded(child: Text(a, style: const TextStyle(color: _text, fontSize: 14))),
          Text(b, style: TextStyle(color: bc, fontSize: 13.5)),
        ]),
      );

  Widget _bigBtn(String t, Color bg, Color? border, VoidCallback onTap) => Material(
        color: bg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), side: border == null ? BorderSide.none : BorderSide(color: border)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
              child: Text(t,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
        ),
      );

  /// رمز دزدگیر (در حالت پیامک لازم نیست: شماره‌ی گوشی روی پنل ثبت است)
  void _withCode(BuildContext context, void Function(String) run) {
    if (c.smsMode) {
      run('');
      return;
    }
    if (c.savedCode.value.isNotEmpty) {
      run(c.savedCode.value);
      return;
    }
    final t = TextEditingController();
    final keep = false.obs;
    Get.dialog(Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: _card,
        title: const Text('رمز دزدگیر', style: TextStyle(color: _text, fontSize: 15)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: t,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _text, fontSize: 22, letterSpacing: 8),
          ),
          Obx(() => CheckboxListTile(
                value: keep.value,
                onChanged: (v) => keep.value = v ?? false,
                contentPadding: EdgeInsets.zero,
                title: const Text('روی این گوشی بماند', style: TextStyle(color: _muted, fontSize: 13)),
              )),
        ]),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('انصراف')),
          TextButton(
            onPressed: () {
              final code = t.text.trim();
              if (code.isEmpty) return;
              if (keep.value) c.setSavedCode(code);
              Get.back();
              run(code);
            },
            child: const Text('تأیید'),
          ),
        ],
      ),
    ));
  }

  void _pickZones(BuildContext context) {
    final z = (c.armedZones.value == 0 || c.armedZones.value == 7 ? 1 : c.armedZones.value).obs;
    Get.dialog(Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: _card,
        title: const Text('کدام زون‌ها فعال شوند؟', style: TextStyle(color: _text, fontSize: 15)),
        content: Obx(() => Column(mainAxisSize: MainAxisSize.min, children: [
              for (int i = 0; i < 3; i++)
                CheckboxListTile(
                  value: ((z.value >> i) & 1) == 1,
                  onChanged: (v) => z.value = v == true ? z.value | (1 << i) : z.value & ~(1 << i),
                  title: Text('زون ${Sim12Controller.faNum(i + 1)}', style: const TextStyle(color: _text)),
                ),
            ])),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('انصراف')),
          TextButton(
            onPressed: () {
              if (z.value == 0) return;
              Get.back();
              _withCode(context, (code) => c.arm(code, zones: z.value));
            },
            child: const Text('فعال کن'),
          ),
        ],
      ),
    ));
  }

  // ---------- پرده و آسانسور ----------

  Widget _curtainZone() {
    return ListView(padding: const EdgeInsets.only(bottom: 12), children: [
      for (int i = 0; i < 2; i++) _curtainCard(i),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Expanded(child: Text(c.nameOf(22), style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600))),
          SizedBox(width: 110, height: 48, child: _bigBtn('احضار', _red, null, () => c.press(22))),
        ]),
      ),
    ]);
  }

  Widget _curtainCard(int i) {
    final ko = 23 + i * 2, kc = ko + 1;
    final st = c.isOn(ko) ? 'در حال باز شدن' : c.isOn(kc) ? 'در حال بسته شدن' : 'ایستاده';
    final name = c.labels[ko].isNotEmpty ? c.labels[ko] : 'پرده ${Sim12Controller.faNum(i + 1)}';
    Widget b(String t, int op, bool lit) => Expanded(
          child: SizedBox(
            height: 48,
            child: Directionality(
                textDirection: TextDirection.rtl, child: _bigBtn(t, lit ? _redBg : _key, lit ? _red : _line, () => c.curtain(i, op))),
          ),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(name, style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600))),
          Text(st, style: TextStyle(color: c.isOn(ko) || c.isOn(kc) ? _redLit : _muted, fontSize: 12)),
        ]),
        const SizedBox(height: 8),
        // مثل پنل: پیکان چپ = باز، پیکان راست = بسته
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [
            b('باز', 0, c.isOn(ko)),
            const SizedBox(width: 8),
            b('توقف', 1, false),
            const SizedBox(width: 8),
            b('بسته', 2, c.isOn(kc)),
          ]),
        ),
      ]),
    );
  }

  // ---------- سناریو ----------

  Widget _scnZone() {
    return ListView(padding: const EdgeInsets.only(bottom: 12), children: [
      SizedBox(height: 56, child: _bigBtn('${c.nameOf(21)} — خاموش کردن همه', _red, null, () => c.press(21))),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.6,
        children: [
          for (int k = 15; k < 21; k++)
            Material(
              color: c.isOn(k) ? _redBg : _card,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), side: BorderSide(color: c.isOn(k) ? _red : _line)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => c.press(k),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(c.nameOf(k), style: const TextStyle(color: _text, fontSize: 14)),
                  Text('S${Sim12Controller.faNum(k - 14)} · ${c.kindText(k)}', style: const TextStyle(color: _muted, fontSize: 11)),
                ]),
              ),
            ),
        ],
      ),
    ]);
  }

  // ---------- سیمکارت ----------

  static const _ops = ['—', 'همراه اول', 'ایرانسل', 'رایتل'];

  Widget _simZone(BuildContext context) {
    final cr = c.credit.value;
    final crText = c.creditBusy.value || cr == '?' ? 'در حال استعلام…' : cr == '-' || cr.isEmpty ? '—' : '${Sim12Controller.faMoney(cr)} ریال';
    return ListView(padding: const EdgeInsets.only(bottom: 12), children: [
      _box(
        'وضعیت سیمکارت پنل',
        Column(children: [
          _row('ماژول سیمکارت', !c.simKnown.value ? '؟' : c.gsmOk.value ? 'وصل' : 'بدون سیمکارت', c.gsmOk.value ? const Color(0xFF7FD39B) : const Color(0xFFFF9B9B)),
          _row('آنتن', '${Sim12Controller.faNum(c.bars.value)} از ۵', _text),
          _row('اپراتور', _ops[c.operator.value.clamp(0, 3)], _text),
          _row('شارژ', crText, _text, last: true),
        ]),
      ),
      SizedBox(height: 48, child: _bigBtn('استعلام شارژ (USSD)', _key, _line, c.creditBusy.value ? () {} : c.checkCredit)),
      const SizedBox(height: 10),
      _box(
        'راه ارتباط',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('وای‌فای در دسترس باشد: مستقیم با پنل.\nنباشد: خودکار با پیامک به سیمکارت پنل (گوشی باید یکی از شماره‌های پیامک روی پنل باشد).',
              style: TextStyle(color: _text, fontSize: 13, height: 1.7)),
          const SizedBox(height: 10),
          _row('شماره سیمکارت پنل', c.panelNumber.value.isEmpty ? 'وارد نشده' : c.panelNumber.value,
              c.panelNumber.value.isEmpty ? const Color(0xFFFF9B9B) : _text,
              last: true),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: () => _editNumber(context), child: const Text('تغییر شماره')),
          ),
          if (c.savedCode.value.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(onPressed: () => c.setSavedCode(''), child: const Text('پاک کردن رمز ذخیره‌شده دزدگیر')),
            ),
        ]),
      ),
      SizedBox(height: 44, child: _bigBtn('تازه کردن وضعیت', _key, _line, c.refresh)),
    ]);
  }

  void _editNumber(BuildContext context) {
    final t = TextEditingController(text: c.panelNumber.value);
    Get.dialog(Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: _card,
        title: const Text('شماره سیمکارت پنل', style: TextStyle(color: _text, fontSize: 15)),
        content: TextField(
          controller: t,
          autofocus: true,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          style: const TextStyle(color: _text, fontSize: 18),
          decoration: const InputDecoration(hintText: '09xxxxxxxxx', hintStyle: TextStyle(color: _muted)),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('انصراف')),
          TextButton(
              onPressed: () {
                c.setPanelNumber(t.text.trim());
                Get.back();
              },
              child: const Text('ذخیره')),
        ],
      ),
    ));
  }
}

/// حالت نمایشی پنل سیمکارتی
class Sim12DemoPage extends StatefulWidget {
  const Sim12DemoPage({super.key});

  @override
  State<Sim12DemoPage> createState() => _Sim12DemoPageState();
}

class _Sim12DemoPageState extends State<Sim12DemoPage> {
  @override
  void initState() {
    super.initState();
    Sim12Controller.instance.startDemo();
  }

  @override
  void dispose() {
    Sim12Controller.instance.stopDemo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: _bg, body: Sim12Screen());
}

/// تب‌های سناریو و مسافرت برای پنل سیمکارتی: همه‌چیز در صفحه‌ی اصلی پنل است
class Sim12ElsewherePage extends StatelessWidget {
  const Sim12ElsewherePage({super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: _bg,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: const Text('برای پنل سیمکارتی، کلیدها، دزدگیر، پرده، سناریو و سیمکارت همه در صفحه‌ی اصلی پنل هستند.',
            textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(color: _muted, fontSize: 14, height: 1.7)),
      );
}
